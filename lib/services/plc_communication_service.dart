import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../models/data_stream_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PLC Communication Service using Moka7 via MethodChannel (Android only)
///
/// This service provides communication with Siemens S7 PLCs using the Moka7 library
/// (pure Java implementation) on Android. No native libraries required!
class PLCCommunicationService {
  static final PLCCommunicationService _instance = PLCCommunicationService._internal();
  factory PLCCommunicationService() => _instance;
  PLCCommunicationService._internal();

  static const String _prefKeyPlcIp = 'plc_ip_address';
  static const String _prefKeyLiveMode = 'live_mode_enabled';
  static const String _prefKeyRack = 'plc_rack';
  static const String _prefKeySlot = 'plc_slot';

  // MethodChannel for communicating with Android native code
  static const platform = MethodChannel('com.matrixtsl.smart_factory/plc');

  String? _plcIpAddress;
  int _rack = 0;
  int _slot = 1;
  bool _isLiveMode = true;
  Timer? _connectionTimer;
  bool _isConnected = false;
  String _lastError = '';

  // Connection retry settings
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  DateTime? _lastConnectionAttempt;
  static const Duration _connectionAttemptInterval = Duration(seconds: 5);

  final _logController = StreamController<DataStreamLogEntry>.broadcast();
  Stream<DataStreamLogEntry> get logStream => _logController.stream;

  final List<DataStreamLogEntry> _logHistory = [];
  static const int _maxLogEntries = 1000;

  // Initialize and load settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _plcIpAddress = prefs.getString(_prefKeyPlcIp) ?? '192.168.0.99';
    _rack = prefs.getInt(_prefKeyRack) ?? 0;
    _slot = prefs.getInt(_prefKeySlot) ?? 1;
    _isLiveMode = prefs.getBool(_prefKeyLiveMode) ?? true;
  }

  // Get PLC IP address
  String get plcIpAddress => _plcIpAddress ?? '192.168.0.99';

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
      await disconnect();
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
      await disconnect();
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
      await disconnect();
    }
  }

  // Connect to PLC using Moka7 via MethodChannel
  Future<bool> connect() async {
    // Check if running on Android
    if (!Platform.isAndroid) {
      _lastError = 'PLC connection is only supported on Android devices';
      _logDataStream('TX', 'ERROR', 'PLATFORM_NOT_SUPPORTED',
        '⚠️ PLC connection is only supported on Android (Moka7 implementation).');
      _isConnected = false;
      return false;
    }

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
      if (_isConnected) {
        return true;
      }

      _logDataStream('TX', 'CONNECTION', 'CONNECT',
        'Connecting to S7 PLC at $_plcIpAddress (Rack: $_rack, Slot: $_slot) using Moka7...');

      // Try to connect with retries
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          _logDataStream('TX', 'MOKA7', 'CONNECT',
            'Attempting connection (${attempt + 1}/$_maxRetries)...');

          final result = await platform.invokeMethod('connect', {
            'ip': _plcIpAddress,
            'rack': _rack,
            'slot': _slot,
          });

          if (result['success'] == true) {
            _isConnected = true;
            _lastError = '';
            _logDataStream('RX', 'CONNECTION', 'CONNECTED',
              '✓ Successfully connected to S7 PLC using Moka7! ${result['message']}');

            // Start periodic status check
            _startPeriodicStatusCheck();
            return true;
          }
        } on PlatformException catch (e) {
          _lastError = 'Connection error: ${e.message}';
          _logDataStream('RX', 'ERROR', 'CONNECTION_FAILED',
            '${e.message} (attempt ${attempt + 1}/$_maxRetries)');
        } catch (e) {
          _lastError = 'Connection error: $e';
          _logDataStream('RX', 'ERROR', 'CONNECTION_FAILED',
            '$e (attempt ${attempt + 1}/$_maxRetries)');
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
      _isConnected = false;
      return false;
    }
  }

  // Disconnect from PLC
  Future<void> disconnect() async {
    _connectionTimer?.cancel();
    _connectionTimer = null;

    if (_isConnected && Platform.isAndroid) {
      _logDataStream('TX', 'CONNECTION', 'DISCONNECT', 'Disconnecting from PLC...');
      try {
        await platform.invokeMethod('disconnect');
        _isConnected = false;
        _logDataStream('RX', 'CONNECTION', 'DISCONNECTED', 'Disconnected from PLC');
      } catch (e) {
        _logDataStream('RX', 'ERROR', 'DISCONNECT', 'Error during disconnect: $e');
      }
    }
    _isConnected = false;
  }

  // Read data block bytes
  Future<Uint8List?> readDataBlock(int dbNumber, int start, int size) async {
    if (!_isConnected) {
      _logDataStream('TX', 'ERROR', 'READ', 'Not connected to PLC');
      return null;
    }

    try {
      _logDataStream('TX', 'S7', 'READ_DB',
        'Reading DB$dbNumber from byte $start, size $size bytes');

      final result = await platform.invokeMethod('readDB', {
        'dbNumber': dbNumber,
        'start': start,
        'size': size,
      });

      // Convert List<dynamic> to Uint8List
      final data = Uint8List.fromList(List<int>.from(result));

      _logDataStream('RX', 'S7', 'READ_DB',
        'Read ${data.length} bytes: ${_hexDump(data)}');

      return data;
    } on PlatformException catch (e) {
      _lastError = 'Error reading DB$dbNumber: ${e.message}';
      _logDataStream('RX', 'ERROR', 'READ_DB', _lastError);
      return null;
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber: $e';
      _logDataStream('RX', 'ERROR', 'READ_DB', _lastError);
      return null;
    }
  }

  // Write data block bytes
  Future<bool> writeDataBlock(int dbNumber, int start, Uint8List data) async {
    if (!_isConnected) {
      _logDataStream('TX', 'ERROR', 'WRITE', 'Not connected to PLC');
      return false;
    }

    try {
      _logDataStream('TX', 'S7', 'WRITE_DB',
        'Writing DB$dbNumber at byte $start, ${data.length} bytes: ${_hexDump(data)}');

      await platform.invokeMethod('writeDB', {
        'dbNumber': dbNumber,
        'start': start,
        'data': data.toList(),
      });

      _logDataStream('RX', 'S7', 'WRITE_DB', 'Write successful');
      return true;
    } on PlatformException catch (e) {
      _lastError = 'Error writing DB$dbNumber: ${e.message}';
      _logDataStream('RX', 'ERROR', 'WRITE_DB', _lastError);
      return false;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber: $e';
      _logDataStream('RX', 'ERROR', 'WRITE_DB', _lastError);
      return false;
    }
  }

  // Read Merkers (M memory) - Not implemented in basic Moka7 setup
  // For merkers, you would need to extend the Android implementation
  Future<Uint8List?> readMerkers(int start, int size) async {
    _logDataStream('TX', 'ERROR', 'READ_MERKERS',
      'Merkers not yet implemented in Moka7 wrapper. Use readDataBlock instead.');
    return null;
  }

  // Write Merkers (M memory) - Not implemented in basic Moka7 setup
  Future<bool> writeMerkers(int start, Uint8List data) async {
    _logDataStream('TX', 'ERROR', 'WRITE_MERKERS',
      'Merkers not yet implemented in Moka7 wrapper. Use writeDataBlock instead.');
    return false;
  }

  // Read REAL (float) value from data block
  Future<double?> readDbReal(int dbNumber, int offset) async {
    try {
      if (!_isConnected) {
        return null;
      }

      final result = await platform.invokeMethod('readReal', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
      });

      return (result as num).toDouble();
    } on PlatformException catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBD$offset: ${e.message}';
      _logDataStream('RX', 'ERROR', 'READ_REAL', _lastError);
      return null;
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
        return false;
      }

      await platform.invokeMethod('writeReal', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
        'value': value,
      });

      return true;
    } on PlatformException catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBD$offset: ${e.message}';
      _logDataStream('TX', 'ERROR', 'WRITE_REAL', _lastError);
      return false;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBD$offset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_REAL', _lastError);
      return false;
    }
  }

  // Read BOOL value from data block
  Future<bool?> readDbBool(int dbNumber, int byteOffset, int bitOffset) async {
    try {
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return null;
      }

      if (!_isConnected) {
        return null;
      }

      final result = await platform.invokeMethod('readBool', {
        'dbNumber': dbNumber,
        'byteOffset': byteOffset,
        'bitOffset': bitOffset,
      });

      return result as bool;
    } on PlatformException catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBX$byteOffset.$bitOffset: ${e.message}';
      _logDataStream('RX', 'ERROR', 'READ_BOOL', _lastError);
      return null;
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBX$byteOffset.$bitOffset: $e';
      _logDataStream('RX', 'ERROR', 'READ_BOOL', _lastError);
      return null;
    }
  }

  // Write BOOL value to data block
  Future<bool> writeDbBool(int dbNumber, int byteOffset, int bitOffset, bool value) async {
    try {
      if (bitOffset < 0 || bitOffset > 7) {
        _lastError = 'Bit offset must be between 0 and 7';
        return false;
      }

      if (!_isConnected) {
        return false;
      }

      await platform.invokeMethod('writeBool', {
        'dbNumber': dbNumber,
        'byteOffset': byteOffset,
        'bitOffset': bitOffset,
        'value': value,
      });

      return true;
    } on PlatformException catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBX$byteOffset.$bitOffset: ${e.message}';
      _logDataStream('TX', 'ERROR', 'WRITE_BOOL', _lastError);
      return false;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBX$byteOffset.$bitOffset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_BOOL', _lastError);
      return false;
    }
  }

  // Read INT value from data block
  Future<int?> readDbInt(int dbNumber, int offset) async {
    try {
      if (!_isConnected) {
        return null;
      }

      final result = await platform.invokeMethod('readInt', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
      });

      return result as int;
    } on PlatformException catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBW$offset: ${e.message}';
      _logDataStream('RX', 'ERROR', 'READ_INT', _lastError);
      return null;
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
        return false;
      }

      await platform.invokeMethod('writeInt', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
        'value': value,
      });

      return true;
    } on PlatformException catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBW$offset: ${e.message}';
      _logDataStream('TX', 'ERROR', 'WRITE_INT', _lastError);
      return false;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBW$offset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_INT', _lastError);
      return false;
    }
  }

  // Read DINT value from data block
  Future<int?> readDbDInt(int dbNumber, int offset) async {
    try {
      if (!_isConnected) {
        return null;
      }

      final result = await platform.invokeMethod('readDInt', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
      });

      return result as int;
    } on PlatformException catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBD$offset: ${e.message}';
      _logDataStream('RX', 'ERROR', 'READ_DINT', _lastError);
      return null;
    } catch (e) {
      _lastError = 'Error reading DB$dbNumber.DBD$offset: $e';
      _logDataStream('RX', 'ERROR', 'READ_DINT', _lastError);
      return null;
    }
  }

  // Write DINT value to data block
  Future<bool> writeDbDInt(int dbNumber, int offset, int value) async {
    try {
      if (!_isConnected) {
        return false;
      }

      await platform.invokeMethod('writeDInt', {
        'dbNumber': dbNumber,
        'byteOffset': offset,
        'value': value,
      });

      return true;
    } on PlatformException catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBD$offset: ${e.message}';
      _logDataStream('TX', 'ERROR', 'WRITE_DINT', _lastError);
      return false;
    } catch (e) {
      _lastError = 'Error writing DB$dbNumber.DBD$offset: $e';
      _logDataStream('TX', 'ERROR', 'WRITE_DINT', _lastError);
      return false;
    }
  }

  // Read Merker bit - Not implemented in basic setup
  Future<bool?> readMBit(int byteOffset, int bitOffset) async {
    _logDataStream('TX', 'ERROR', 'READ_M_BIT',
      'Merker bits not yet implemented in Moka7 wrapper.');
    return null;
  }

  // Write Merker bit - Not implemented in basic setup
  Future<bool> writeMBit(int byteOffset, int bitOffset, bool value) async {
    _logDataStream('TX', 'ERROR', 'WRITE_M_BIT',
      'Merker bits not yet implemented in Moka7 wrapper.');
    return false;
  }

  // Start periodic status check
  void _startPeriodicStatusCheck() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        if (_isConnected && _isLiveMode && Platform.isAndroid) {
          try {
            // Check connection status via MethodChannel
            final status = await platform.invokeMethod('getConnectionStatus');
            if (status['connected'] != true) {
              _isConnected = false;
              _logDataStream('RX', 'ERROR', 'HEARTBEAT', 'Connection lost');
            }
          } catch (e) {
            _logDataStream('RX', 'ERROR', 'HEARTBEAT', 'Heartbeat failed: $e');
          }
        }
      },
    );
  }

  // Helper to create hex dump for debugging
  String _hexDump(Uint8List data, {int maxBytes = 32}) {
    final bytes = data.length > maxBytes ? data.sublist(0, maxBytes) : data;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    return data.length > maxBytes ? '$hex... (${data.length} total)' : hex;
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
  List<DataStreamLogEntry> getLogHistory() {
    return List.unmodifiable(_logHistory);
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
      'ip': _plcIpAddress ?? '192.168.0.99',
      'rack': _rack,
      'slot': _slot,
      'lastError': _lastError,
      'liveMode': _isLiveMode,
    };
  }

  void dispose() {
    disconnect();
    _logController.close();
  }
}

// Extension for bit manipulation
extension BitMap on int {
  bool getBit(int pos) {
    final x = this >> pos;
    return x & 1 == 1;
  }

  int setBit(int pos, bool bit) {
    final x = 1 << pos;
    if (bit) {
      return this | x;
    }
    return getBit(pos) ? this ^ x : this;
  }
}
