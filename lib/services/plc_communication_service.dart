import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../models/data_stream_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PLCCommunicationService {
  static final PLCCommunicationService _instance = PLCCommunicationService._internal();
  factory PLCCommunicationService() => _instance;
  PLCCommunicationService._internal();

  static const String _prefKeyPlcIp = 'plc_ip_address';
  static const String _prefKeyLiveMode = 'live_mode_enabled';
  static const String _prefKeyRack = 'plc_rack';
  static const String _prefKeySlot = 'plc_slot';
  
  String? _plcIpAddress;
  int _rack = 0;
  int _slot = 1;
  bool _isLiveMode = true; // Default to live mode
  Socket? _socket;
  Timer? _connectionTimer;
  bool _isConnected = false;
  int _pduReference = 0;
  String _lastError = '';
  
  // Connection retry settings
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  DateTime? _lastConnectionAttempt;
  static const Duration _connectionAttemptInterval = Duration(seconds: 5);

  final _logController = StreamController<DataStreamLogEntry>.broadcast();
  Stream<DataStreamLogEntry> get logStream => _logController.stream;

  final List<DataStreamLogEntry> _logHistory = [];
  static const int _maxLogEntries = 1000;

  // Initialize and load settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _plcIpAddress = prefs.getString(_prefKeyPlcIp) ?? '192.168.7.2';
    _rack = prefs.getInt(_prefKeyRack) ?? 0;
    _slot = prefs.getInt(_prefKeySlot) ?? 1;
    _isLiveMode = prefs.getBool(_prefKeyLiveMode) ?? true; // Default to live mode
  }

  // Get PLC IP address
  String get plcIpAddress => _plcIpAddress ?? '192.168.7.2';
  
  // Get rack
  int get rack => _rack;
  
  // Get slot
  int get slot => _slot;

  // Set PLC IP address
  Future<void> setPlcIpAddress(String ip) async {
    _plcIpAddress = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyPlcIp, ip);
    _logDataStream('TX', 'SETTINGS', 'IP_ADDRESS', 'IP address set to $ip');
    
    // Reconnect if in live mode
    if (_isLiveMode && _isConnected) {
      disconnect();
      await connect();
    }
  }

  // Set rack and slot
  Future<void> setRackSlot(int rack, int slot) async {
    _rack = rack;
    _slot = slot;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyRack, rack);
    await prefs.setInt(_prefKeySlot, slot);
    _logDataStream('TX', 'SETTINGS', 'RACK_SLOT', 'Rack: $rack, Slot: $slot');
    
    // Reconnect if in live mode
    if (_isLiveMode && _isConnected) {
      disconnect();
      await connect();
    }
  }

  // Check if live mode is enabled
  bool get isLiveMode => _isLiveMode;

  // Set live mode
  Future<void> setLiveMode(bool enabled) async {
    _isLiveMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLiveMode, enabled);
    
    if (enabled) {
      _logDataStream('TX', 'SETTINGS', 'MODE', 'Live mode enabled');
      await connect();
    } else {
      _logDataStream('TX', 'SETTINGS', 'MODE', 'Simulation mode enabled');
      disconnect();
    }
  }

  // Connect to PLC using S7 protocol with retry logic
  Future<bool> connect() async {
    if (!_isLiveMode || _plcIpAddress == null) {
      return false;
    }

    try {
      final currentTime = DateTime.now();
      
      // Don't attempt connection too frequently
      if (_lastConnectionAttempt != null &&
          currentTime.difference(_lastConnectionAttempt!) < _connectionAttemptInterval) {
        return _isConnected;
      }
      
      _lastConnectionAttempt = currentTime;
      
      // Check if already connected
      if (_isConnected && _socket != null) {
        return true;
      }
      
      _logDataStream('TX', 'CONNECTION', 'CONNECT', 'Connecting to S7-1200 at $_plcIpAddress (Rack: $_rack, Slot: $_slot)...');
      
      // Try to connect with retries
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          // S7 protocol uses port 102
          _socket?.close(); // Close any existing socket
          _socket = await Socket.connect(
            _plcIpAddress!,
            102,
            timeout: const Duration(seconds: 5),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

          // S7 Connection Request (ISO Connection)
          final connectionRequest = _buildS7ConnectionRequest();
          _socket!.add(connectionRequest);
          await _socket!.flush();
          
          _logDataStream('TX', 'S7', 'CONNECTION_REQUEST', 'Sent S7 connection request (attempt ${attempt + 1}/$_maxRetries)');

          // Wait for response
          final response = await _socket!.first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Response timeout'),
          );

          if (_parseS7ConnectionResponse(response)) {
            _isConnected = true;
            _lastError = '';
            _logDataStream('RX', 'CONNECTION', 'CONNECTED', 'Successfully connected to S7-1200');
            
            // Set up data listener
            _socket!.listen(
              (data) {
                _handleReceivedData(data);
              },
              onError: (error) {
                _lastError = 'Socket error: $error';
                _logDataStream('RX', 'ERROR', 'SOCKET_ERROR', error.toString());
                _isConnected = false;
              },
              onDone: () {
                _logDataStream('RX', 'CONNECTION', 'DISCONNECTED', 'PLC connection closed');
                _isConnected = false;
              },
            );

            // Start periodic status check
            _startPeriodicStatusCheck();
            return true;
          } else {
            _lastError = 'Invalid S7 connection response';
            _logDataStream('RX', 'ERROR', 'CONNECTION_FAILED', 'Invalid S7 connection response (attempt ${attempt + 1}/$_maxRetries)');
            _socket?.close();
            _socket = null;
          }
        } catch (e) {
          _lastError = 'Connection error: $e';
          _logDataStream('RX', 'ERROR', 'CONNECTION_FAILED', '$e (attempt ${attempt + 1}/$_maxRetries)');
          _socket?.close();
          _socket = null;
        }
        
        // Wait before retry
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
        }
      }
      
      _isConnected = false;
      return false;
    } catch (e) {
      _lastError = 'Connection error: $e';
      _logDataStream('RX', 'ERROR', 'CONNECTION_FAILED', e.toString());
      _socket?.close();
      _socket = null;
      _isConnected = false;
      return false;
    }
  }

  // Build S7 ISO Connection Request
  Uint8List _buildS7ConnectionRequest() {
    // ISO TPKT Header
    final tpkt = Uint8List(4);
    tpkt[0] = 0x03; // Version
    tpkt[1] = 0x00; // Reserved
    tpkt[2] = 0x00; // Length high byte (will be set)
    tpkt[3] = 0x16; // Length low byte (22 bytes)

    // ISO COTP Header
    final cotp = Uint8List(7);
    cotp[0] = 0x11; // Length
    cotp[1] = 0xE0; // PDU Type: Connection Request
    cotp[2] = 0x00; // Destination reference high
    cotp[3] = 0x00; // Destination reference low
    cotp[4] = 0x00; // Source reference high
    cotp[5] = 0x01; // Source reference low
    cotp[6] = 0x00; // Class/Options

    // S7 Communication Setup
    final s7Setup = Uint8List(11);
    s7Setup[0] = 0x02; // Function: Setup communication
    s7Setup[1] = 0xF0; // Reserved
    s7Setup[2] = 0x80; // Reserved
    s7Setup[3] = 0x32; // Max PDU length high (1024 bytes)
    s7Setup[4] = 0x01; // Max PDU length low
    s7Setup[5] = 0x00; // Max parallel jobs
    s7Setup[6] = 0x01; // Max parallel jobs
    s7Setup[7] = 0x01; // Max parallel jobs
    s7Setup[8] = 0x01; // Max parallel jobs
    s7Setup[9] = _rack; // Rack
    s7Setup[10] = _slot; // Slot

    return Uint8List.fromList([...tpkt, ...cotp, ...s7Setup]);
  }

  // Parse S7 Connection Response
  bool _parseS7ConnectionResponse(List<int> data) {
    if (data.length < 27) return false;
    
    // Check TPKT header
    if (data[0] != 0x03 || data[1] != 0x00) return false;
    
    // Check COTP header
    if (data[4] != 0x11 || data[5] != 0xD0) return false; // Connection confirm
    
    // Check S7 response
    if (data[17] != 0x03 || data[18] != 0x00) return false; // Setup communication response
    
    return true;
  }

  // Disconnect from PLC
  void disconnect() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    
    if (_socket != null) {
      _logDataStream('TX', 'CONNECTION', 'DISCONNECT', 'Disconnecting from PLC...');
      _socket!.close();
      _socket = null;
      _isConnected = false;
    }
  }

  // Read from PLC (S7 Read)
  Future<List<int>?> readArea(String area, int dbNumber, int start, int size) async {
    if (!_isConnected || _socket == null) {
      _logDataStream('TX', 'ERROR', 'READ', 'Not connected to PLC');
      return null;
    }

    try {
      // Map area string to area code
      int areaCode;
      switch (area.toUpperCase()) {
        case 'DB':
          areaCode = 0x84; // Data block
          break;
        case 'INPUT':
          areaCode = 0x81; // Inputs
          break;
        case 'OUTPUT':
          areaCode = 0x82; // Outputs
          break;
        case 'MEMORY':
          areaCode = 0x83; // Memory
          break;
        default:
          areaCode = 0x84; // Default to DB
      }

      final request = _buildS7ReadRequest(areaCode, dbNumber, start, size);
      _socket!.add(request);
      await _socket!.flush();

      _logDataStream(
        'TX',
        'S7',
        'READ',
        'Reading $size bytes from $area${dbNumber > 0 ? '.DB$dbNumber' : ''} at address $start',
      );

      // Wait for response (simplified - in production you'd need proper response handling)
      return null; // Response handled in _handleReceivedData
    } catch (e) {
      _logDataStream('TX', 'ERROR', 'READ', e.toString());
      return null;
    }
  }

  // Build S7 Read Request
  Uint8List _buildS7ReadRequest(int area, int dbNumber, int start, int size) {
    _pduReference = (_pduReference + 1) % 65536;
    
    // TPKT Header
    final tpkt = Uint8List(4);
    tpkt[0] = 0x03;
    tpkt[1] = 0x00;
    final totalLength = 31 + size;
    tpkt[2] = (totalLength >> 8) & 0xFF;
    tpkt[3] = totalLength & 0xFF;

    // COTP Data Header
    final cotp = Uint8List(4);
    cotp[0] = 0x02; // Length
    cotp[1] = 0xF0; // PDU Type: Data
    cotp[2] = 0x80; // TPDU number

    // S7 Header
    final s7Header = Uint8List(12);
    s7Header[0] = 0x32; // Protocol ID
    s7Header[1] = 0x01; // Job type: Request
    s7Header[2] = (_pduReference >> 8) & 0xFF; // PDU reference high
    s7Header[3] = _pduReference & 0xFF; // PDU reference low
    s7Header[4] = 0x00; // Parameter length high
    s7Header[5] = 0x0F; // Parameter length low (15 bytes)
    s7Header[6] = 0x00; // Data length high
    s7Header[7] = 0x00; // Data length low

    // S7 Read Request Parameter
    final param = Uint8List(15);
    param[0] = 0x04; // Function: Read
    param[1] = 0x01; // Number of items
    param[2] = 0x12; // Variable specification
    param[3] = 0x0A; // Length of following address specification
    param[4] = 0x10; // Syntax ID: S7Any
    param[5] = area; // Transport size
    param[6] = (size >> 8) & 0xFF; // Length high
    param[7] = size & 0xFF; // Length low
    param[8] = (dbNumber >> 8) & 0xFF; // DB number high
    param[9] = dbNumber & 0xFF; // DB number low
    param[10] = area == 0x84 ? 0x84 : 0x00; // Area code
    param[11] = (start >> 24) & 0xFF; // Address byte 0
    param[12] = (start >> 16) & 0xFF; // Address byte 1
    param[13] = (start >> 8) & 0xFF; // Address byte 2
    param[14] = start & 0xFF; // Address byte 3

    return Uint8List.fromList([...tpkt, ...cotp, ...s7Header, ...param]);
  }

  // Write to PLC (S7 Write)
  Future<bool> writeArea(String area, int dbNumber, int start, List<int> data) async {
    if (!_isConnected || _socket == null) {
      _logDataStream('TX', 'ERROR', 'WRITE', 'Not connected to PLC');
      return false;
    }

    try {
      // Map area string to area code
      int areaCode;
      switch (area.toUpperCase()) {
        case 'DB':
          areaCode = 0x84;
          break;
        case 'INPUT':
          areaCode = 0x81;
          break;
        case 'OUTPUT':
          areaCode = 0x82;
          break;
        case 'MEMORY':
          areaCode = 0x83;
          break;
        default:
          areaCode = 0x84;
      }

      final request = _buildS7WriteRequest(areaCode, dbNumber, start, data);
      _socket!.add(request);
      await _socket!.flush();

      _logDataStream(
        'TX',
        'S7',
        'WRITE',
        'Writing ${data.length} bytes to $area${dbNumber > 0 ? '.DB$dbNumber' : ''} at address $start',
      );

      return true;
    } catch (e) {
      _logDataStream('TX', 'ERROR', 'WRITE', e.toString());
      return false;
    }
  }

  // Build S7 Write Request
  Uint8List _buildS7WriteRequest(int area, int dbNumber, int start, List<int> data) {
    _pduReference = (_pduReference + 1) % 65536;
    
    final dataLength = data.length;
    final totalLength = 35 + dataLength;
    
    // TPKT Header
    final tpkt = Uint8List(4);
    tpkt[0] = 0x03;
    tpkt[1] = 0x00;
    tpkt[2] = (totalLength >> 8) & 0xFF;
    tpkt[3] = totalLength & 0xFF;

    // COTP Data Header
    final cotp = Uint8List(4);
    cotp[0] = 0x02;
    cotp[1] = 0xF0;
    cotp[2] = 0x80;

    // S7 Header
    final s7Header = Uint8List(12);
    s7Header[0] = 0x32;
    s7Header[1] = 0x01;
    s7Header[2] = (_pduReference >> 8) & 0xFF;
    s7Header[3] = _pduReference & 0xFF;
    s7Header[4] = 0x00;
    s7Header[5] = 0x0F; // Parameter length (15 bytes)
    s7Header[6] = (dataLength >> 8) & 0xFF; // Data length high
    s7Header[7] = dataLength & 0xFF; // Data length low

    // S7 Write Request Parameter
    final param = Uint8List(15);
    param[0] = 0x05; // Function: Write
    param[1] = 0x01; // Number of items
    param[2] = 0x12;
    param[3] = 0x0A;
    param[4] = 0x10;
    param[5] = area;
    param[6] = (dataLength >> 8) & 0xFF;
    param[7] = dataLength & 0xFF;
    param[8] = (dbNumber >> 8) & 0xFF;
    param[9] = dbNumber & 0xFF;
    param[10] = area == 0x84 ? 0x84 : 0x00;
    param[11] = (start >> 24) & 0xFF;
    param[12] = (start >> 16) & 0xFF;
    param[13] = (start >> 8) & 0xFF;
    param[14] = start & 0xFF;

    // Data
    final dataHeader = Uint8List(4);
    dataHeader[0] = 0x00; // Return code
    dataHeader[1] = 0x04; // Transport size
    dataHeader[2] = (dataLength >> 8) & 0xFF;
    dataHeader[3] = dataLength & 0xFF;

    return Uint8List.fromList([...tpkt, ...cotp, ...s7Header, ...param, ...dataHeader, ...data]);
  }

  // Handle received data from PLC
  void _handleReceivedData(List<int> data) {
    if (data.isEmpty) return;

    // Parse S7 response
    final hexString = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _logDataStream(
      'RX',
      'S7',
      'RESPONSE',
      'Received ${data.length} bytes: $hexString',
    );

    // Parse S7 response and extract data
    if (data.length >= 25) {
      // Check if it's a read response
      if (data[17] == 0x04) { // Read function
        final dataLength = (data[25] << 8) | data[26];
        if (data.length >= 27 + dataLength) {
          final readData = data.sublist(27, 27 + dataLength);
          _logDataStream(
            'RX',
            'S7',
            'READ_DATA',
            'Read ${readData.length} bytes: ${readData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          );
        }
      } else if (data[17] == 0x05) { // Write function
        _logDataStream('RX', 'S7', 'WRITE_CONFIRM', 'Write confirmed');
      }
    }
  }

  // Start periodic status check
  void _startPeriodicStatusCheck() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_isConnected && _isLiveMode) {
          // Read inputs (I area) - example: read 10 bytes from input area
          readArea('INPUT', 0, 0, 10);
        }
      },
    );
  }

  // Log data stream entry
  void _logDataStream(String direction, String category, String type, String message) {
    final entry = DataStreamLogEntry(
      timestamp: DateTime.now(),
      direction: direction,
      address: '$category.$type',
      value: message,
      description: null,
    );

    _logHistory.add(entry);
    
    // Keep only last N entries
    if (_logHistory.length > _maxLogEntries) {
      _logHistory.removeAt(0);
    }

    _logController.add(entry);
  }

  // Get log history
  List<DataStreamLogEntry> getLogHistory({int? limit}) {
    if (limit == null) return List.from(_logHistory);
    return _logHistory.length > limit
        ? _logHistory.sublist(_logHistory.length - limit)
        : List.from(_logHistory);
  }

  // Clear log history
  void clearLogHistory() {
    _logHistory.clear();
    _logDataStream('TX', 'LOG', 'CLEAR', 'Log history cleared');
  }

  // Check connection status
  bool get isConnected => _isConnected;
  
  // Get last error message
  String get lastError => _lastError;
  
  // Get connection status info
  Map<String, dynamic> getStatus() {
    return {
      'connected': _isConnected,
      'ip': _plcIpAddress ?? '192.168.7.2',
      'rack': _rack,
      'slot': _slot,
      'lastError': _lastError,
      'liveMode': _isLiveMode,
    };
  }
  
  // Read REAL (float) value from data block
  Future<double?> readDbReal(int dbNumber, int offset) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return null;
      }
      
      final data = await readArea('DB', dbNumber, offset, 4);
      if (data == null || data.length < 4) {
        _lastError = 'Error reading DB$dbNumber.DBD$offset: Invalid data';
        return null;
      }
      
      // Convert bytes to REAL (IEEE 754 float)
      final bytes = Uint8List.fromList(data);
      final byteData = ByteData.sublistView(bytes);
      return byteData.getFloat32(0, Endian.big);
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBD$offset: $e';
      _logDataStream('RX', 'ERROR', 'READ_REAL', _lastError);
      return null;
    }
  }
  
  // Write REAL (float) value to data block
  Future<bool> writeDbReal(int dbNumber, int offset, double value) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return false;
      }
      
      // Convert REAL to bytes (IEEE 754 float)
      final byteData = ByteData(4);
      byteData.setFloat32(0, value, Endian.big);
      final data = byteData.buffer.asUint8List();
      
      final success = await writeArea('DB', dbNumber, offset, data);
      if (!success) {
        _lastError = 'Error writing DB$dbNumber.DBD$offset: Write failed';
      }
      return success;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBD$offset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_REAL', _lastError);
      return false;
    }
  }
  
  // Read BOOL value from data block
  Future<bool?> readDbBool(int dbNumber, int byteOffset, int bitOffset) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return null;
      }
      
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return null;
      }
      
      final data = await readArea('DB', dbNumber, byteOffset, 1);
      if (data == null || data.isEmpty) {
        _lastError = 'Error reading DB$dbNumber.DBX$byteOffset.$bitOffset: Invalid data';
        return null;
      }
      
      // Extract bit
      final byteValue = data[0];
      return ((byteValue >> bitOffset) & 1) == 1;
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBX$byteOffset.$bitOffset: $e';
      _logDataStream('RX', 'ERROR', 'READ_BOOL', _lastError);
      return null;
    }
  }
  
  // Write BOOL value to data block (read-modify-write)
  Future<bool> writeDbBool(int dbNumber, int byteOffset, int bitOffset, bool value) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return false;
      }
      
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return false;
      }
      
      // Read current byte
      final currentData = await readArea('DB', dbNumber, byteOffset, 1);
      if (currentData == null || currentData.isEmpty) {
        _lastError = 'Error reading DB$dbNumber.DBX$byteOffset.$bitOffset: Read failed';
        return false;
      }
      
      // Modify bit
      int byteValue = currentData[0];
      if (value) {
        byteValue |= (1 << bitOffset);
      } else {
        byteValue &= ~(1 << bitOffset);
      }
      
      // Write back
      final success = await writeArea('DB', dbNumber, byteOffset, [byteValue]);
      if (!success) {
        _lastError = 'Error writing DB$dbNumber.DBX$byteOffset.$bitOffset: Write failed';
      }
      return success;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBX$byteOffset.$bitOffset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_BOOL', _lastError);
      return false;
    }
  }
  
  // Read Merker (M memory) bit
  Future<bool?> readMBit(int byteOffset, int bitOffset) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return null;
      }
      
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return null;
      }
      
      final data = await readArea('MEMORY', 0, byteOffset, 1);
      if (data == null || data.isEmpty) {
        _lastError = 'Error reading M$byteOffset.$bitOffset: Invalid data';
        return null;
      }
      
      // Extract bit
      final byteValue = data[0];
      return ((byteValue >> bitOffset) & 1) == 1;
    } catch (e) {
      _lastError = 'Error reading M$byteOffset.$bitOffset: $e';
      _logDataStream('RX', 'ERROR', 'READ_M_BIT', _lastError);
      return null;
    }
  }
  
  // Write Merker (M memory) bit (read-modify-write)
  Future<bool> writeMBit(int byteOffset, int bitOffset, bool value) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return false;
      }
      
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return false;
      }
      
      // Read current byte
      final currentData = await readArea('MEMORY', 0, byteOffset, 1);
      if (currentData == null || currentData.isEmpty) {
        _lastError = 'Error reading M$byteOffset.$bitOffset: Read failed';
        return false;
      }
      
      // Modify bit
      int byteValue = currentData[0];
      if (value) {
        byteValue |= (1 << bitOffset);
      } else {
        byteValue &= ~(1 << bitOffset);
      }
      
      // Write back
      final success = await writeArea('MEMORY', 0, byteOffset, [byteValue]);
      if (!success) {
        _lastError = 'Error writing M$byteOffset.$bitOffset: Write failed';
      }
      return success;
    } catch (e) {
      _lastError = 'Error writing M$byteOffset.$bitOffset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_M_BIT', _lastError);
      return false;
    }
  }
  
  // Read INT value from data block
  Future<int?> readDbInt(int dbNumber, int offset) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return null;
      }
      
      final data = await readArea('DB', dbNumber, offset, 2);
      if (data == null || data.length < 2) {
        _lastError = 'Error reading DB$dbNumber.DBW$offset: Invalid data';
        return null;
      }
      
      // Convert bytes to INT (big-endian)
      final bytes = Uint8List.fromList(data);
      final byteData = ByteData.sublistView(bytes);
      return byteData.getInt16(0, Endian.big);
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBW$offset: $e';
      _logDataStream('RX', 'ERROR', 'READ_INT', _lastError);
      return null;
    }
  }
  
  // Write INT value to data block
  Future<bool> writeDbInt(int dbNumber, int offset, int value) async {
    try {
      if (!_isConnected) {
        _lastError = 'Not connected to PLC';
        return false;
      }
      
      // Convert INT to bytes (big-endian)
      final byteData = ByteData(2);
      byteData.setInt16(0, value, Endian.big);
      final data = byteData.buffer.asUint8List();
      
      final success = await writeArea('DB', dbNumber, offset, data);
      if (!success) {
        _lastError = 'Error writing DB$dbNumber.DBW$offset: Write failed';
      }
      return success;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBW$offset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_INT', _lastError);
      return false;
    }
  }

  void dispose() {
    disconnect();
    _logController.close();
  }
}
