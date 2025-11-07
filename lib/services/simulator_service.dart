import 'dart:async';
import 'dart:math';
import '../models/simulator_state.dart';
import '../models/metrics_data.dart';

class SimulatorService {
  static final SimulatorService _instance = SimulatorService._internal();
  factory SimulatorService() => _instance;
  SimulatorService._internal();

  final _stateController = StreamController<SimulatorState>.broadcast();
  Stream<SimulatorState> get stateStream => _stateController.stream;

  SimulatorState _state = SimulatorState();
  Timer? _simulationTimer;
  DateTime? _startTime;
  final Random _random = Random();

  // Simulation configuration
  double _speedScaling = 1.0;
  Map<PartMaterial, double> _materialMix = {
    PartMaterial.steel: 0.33,
    PartMaterial.aluminium: 0.33,
    PartMaterial.plastic: 0.34,
  };
  bool _randomFaultsEnabled = false;

  // Data logging
  final List<MetricsSnapshot> _metricsHistory = [];
  final List<EventLogEntry> _eventLog = [];
  BatchRecord? _currentBatch;

  // Fault history tracking
  final List<FaultRecord> _faultHistory = [];

  // Virtual parts on conveyor
  final List<_VirtualPart> _parts = [];
  int _nextPartId = 0;

  // Force tracking for inputs and outputs
  final Map<String, bool?> _forcedIO = {}; // null = not forced, true/false = forced value

  SimulatorState get currentState => _state;

  void setSpeedScaling(double scaling) {
    _speedScaling = scaling.clamp(0.1, 2.0);
  }

  void setMaterialMix(Map<PartMaterial, double> mix) {
    _materialMix = Map.from(mix);
  }

  void setRandomFaults(bool enabled) {
    _randomFaultsEnabled = enabled;
  }

  void start() {
    if (_state.isRunning || _state.activeFault != FaultType.none) return;

    _startTime = DateTime.now();
    _currentBatch = BatchRecord(
      id: 'BATCH_${DateTime.now().millisecondsSinceEpoch}',
      recipe: _state.currentRecipe,
      target: _state.batchTarget,
      startTime: _startTime!,
    );

    _state = _state.copyWith(
      systemState: SystemState.running,
      isRunning: true,
      conveyor: true,
    );
    _logEvent('Conveyor', 'true', 'output');
    _stateController.add(_state);

    // Start simulation timer - updates 10 times per second
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _simulationStep(),
    );
  }

  void stop() {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_currentBatch != null && _startTime != null) {
      _currentBatch = BatchRecord(
        id: _currentBatch!.id,
        recipe: _currentBatch!.recipe,
        target: _currentBatch!.target,
        startTime: _currentBatch!.startTime,
        endTime: DateTime.now(),
        produced: _state.producedCount,
        rejects: _state.rejectCount,
      );
    }

    _state = _state.copyWith(
      systemState: SystemState.stopped,
      isRunning: false,
      conveyor: false,
      paddleSteel: false,
      paddleAluminium: false,
      plungerDown: false,
      vacuum: false,
      firstGate: false,
      inductive: false,
      capacitive: false,
      photoGate: false,
    );
    _logEvent('Conveyor', 'false', 'output');
    _stateController.add(_state);
    _parts.clear();
  }

  void resetFaults() {
    if (_state.activeFault == FaultType.none) return;

    // Mark current fault as cleared in history
    if (_faultHistory.isNotEmpty) {
      final lastFault = _faultHistory.last;
      if (lastFault.faultType == _state.activeFault && !lastFault.cleared) {
        _faultHistory[_faultHistory.length - 1] = FaultRecord(
          faultType: lastFault.faultType,
          timestamp: lastFault.timestamp,
          cleared: true,
          clearedAt: DateTime.now(),
        );
      }
    }

    _state = _state.copyWith(
      activeFault: FaultType.none,
      systemState: SystemState.stopped,
      eStop: false,
    );
    _logEvent('E-Stop', 'false', 'input');
    _stateController.add(_state);
  }

  void injectFault(FaultType fault) {
    if (fault == FaultType.none) return;

    // Record fault in history
    _faultHistory.add(FaultRecord(
      faultType: fault,
      timestamp: DateTime.now(),
      cleared: false,
    ));

    _state = _state.copyWith(
      activeFault: fault,
      systemState: SystemState.faulted,
    );

    if (fault == FaultType.eStop) {
      stop();
      _state = _state.copyWith(
        eStop: true,
        systemState: SystemState.faulted,
      );
      _logEvent('E-Stop', 'true', 'input');
    }

    _stateController.add(_state);
  }

  void setConveyorSpeed(int speed) {
    _state = _state.copyWith(conveyorSpeed: speed.clamp(0, 100));
    _stateController.add(_state);
  }

  void setBatchTarget(int target) {
    _state = _state.copyWith(batchTarget: target.clamp(1, 10000));
    _stateController.add(_state);
  }

  void jogConveyor(bool on) {
    if (!_canActivateOutput()) return;
    _state = _state.copyWith(conveyor: on);
    _logEvent('Conveyor', on.toString(), 'output');
    _stateController.add(_state);
  }

  void pulsePaddle(bool isSteel) {
    if (!_canActivateOutput()) return;
    if (_state.activeFault == FaultType.paddleJam) return;

    if (isSteel) {
      _state = _state.copyWith(paddleSteel: true);
      _logEvent('Paddle Steel', 'true', 'output');
      _stateController.add(_state);
      Future.delayed(const Duration(milliseconds: 500), () {
        _state = _state.copyWith(paddleSteel: false);
        _logEvent('Paddle Steel', 'false', 'output');
        _stateController.add(_state);
      });
    } else {
      _state = _state.copyWith(paddleAluminium: true);
      _logEvent('Paddle Aluminium', 'true', 'output');
      _stateController.add(_state);
      Future.delayed(const Duration(milliseconds: 500), () {
        _state = _state.copyWith(paddleAluminium: false);
        _logEvent('Paddle Aluminium', 'false', 'output');
        _stateController.add(_state);
      });
    }
  }

  void togglePlunger(bool down) {
    if (!_canActivateOutput()) return;
    if (_state.conveyor) return; // Interlock: can't move plunger while conveyor running

    _state = _state.copyWith(plungerDown: down);
    _logEvent('Plunger Down', down.toString(), 'output');
    _stateController.add(_state);
  }

  void toggleVacuum(bool on) {
    if (!_canActivateOutput()) return;

    _state = _state.copyWith(vacuum: on);
    _logEvent('Vacuum', on.toString(), 'output');
    _stateController.add(_state);
  }

  // Force input methods
  void forceInput(String address, bool value) {
    _forcedIO[address] = value;
    _applyForcedInput(address, value);
    _logEvent('Force Input $address', value.toString(), 'force');
    _stateController.add(_state);
  }

  void clearInputForce(String address) {
    _forcedIO.remove(address);
    _logEvent('Clear Force Input $address', '', 'force');
    _stateController.add(_state);
  }

  // Force output methods
  void forceOutput(String address, bool value) {
    if (!_canActivateOutput()) return;
    _forcedIO[address] = value;
    _applyForcedOutput(address, value);
    _logEvent('Force Output $address', value.toString(), 'force');
    _stateController.add(_state);
  }

  void clearOutputForce(String address) {
    _forcedIO.remove(address);
    _logEvent('Clear Force Output $address', '', 'force');
    _stateController.add(_state);
  }

  // Check if an IO is forced
  bool? isForced(String address) {
    return _forcedIO[address];
  }

  // Apply forced input value
  void _applyForcedInput(String address, bool value) {
    switch (address) {
      case 'I0.0':
        _state = _state.copyWith(firstGate: value);
        break;
      case 'I0.1':
        _state = _state.copyWith(inductive: value);
        break;
      case 'I0.2':
        _state = _state.copyWith(capacitive: value);
        break;
      case 'I0.3':
        _state = _state.copyWith(photoGate: value);
        break;
      case 'I0.4':
        _state = _state.copyWith(eStop: value);
        break;
      case 'I0.5':
        _state = _state.copyWith(gantryHome: value);
        break;
    }
  }

  // Apply forced output value
  void _applyForcedOutput(String address, bool value) {
    switch (address) {
      case 'Q0.0':
        _state = _state.copyWith(conveyor: value);
        break;
      case 'Q0.1':
        _state = _state.copyWith(paddleSteel: value);
        break;
      case 'Q0.2':
        _state = _state.copyWith(paddleAluminium: value);
        break;
      case 'Q0.3':
        _state = _state.copyWith(plungerDown: value);
        break;
      case 'Q0.4':
        _state = _state.copyWith(vacuum: value);
        break;
      case 'Q0.5':
        _state = _state.copyWith(gantryStep: value);
        break;
    }
  }

  bool _canActivateOutput() {
    return _state.activeFault != FaultType.eStop;
  }

  void _simulationStep() {
    if (!_state.isRunning) return;

    // Update uptime
    if (_startTime != null) {
      _state = _state.copyWith(
        uptime: DateTime.now().difference(_startTime!),
      );
    }

    // Spawn new parts based on speed
    final spawnChance = (_state.conveyorSpeed / 100.0) * _speedScaling * 0.3;
    if (_random.nextDouble() < spawnChance) {
      _spawnPart();
    }

    // Move parts along conveyor and trigger sensors
    _moveParts();

    // Calculate metrics
    _calculateMetrics();

    // Random faults
    if (_randomFaultsEnabled && _random.nextDouble() < 0.0001) {
      final faults = [FaultType.sensorStuck, FaultType.paddleJam, FaultType.vacuumLeak];
      injectFault(faults[_random.nextInt(faults.length)]);
    }

    // Log metrics every 1 second (10 steps)
    if (DateTime.now().millisecondsSinceEpoch % 1000 < 100) {
      _logMetrics();
    }

    _stateController.add(_state);

    // Check if batch is complete
    if (_state.producedCount >= _state.batchTarget) {
      stop();
    }
  }

  void _spawnPart() {
    final rand = _random.nextDouble();
    PartMaterial material;

    if (rand < _materialMix[PartMaterial.steel]!) {
      material = PartMaterial.steel;
    } else if (rand < _materialMix[PartMaterial.steel]! + _materialMix[PartMaterial.aluminium]!) {
      material = PartMaterial.aluminium;
    } else {
      material = PartMaterial.plastic;
    }

    _parts.add(_VirtualPart(
      id: _nextPartId++,
      material: material,
      position: 0.0,
    ));
  }

  void _moveParts() {
    final speed = (_state.conveyorSpeed / 100.0) * _speedScaling * 0.1;
    final toRemove = <_VirtualPart>[];

    // Reset sensors
    bool firstGate = false;
    bool inductive = false;
    bool capacitive = false;
    bool photoGate = false;

    for (final part in _parts) {
      part.position += speed;

      // Trigger sensors at specific positions
      if (part.position >= 0.2 && part.position < 0.25) {
        firstGate = true;
        if (!part.detectedAtFirstGate) {
          part.detectedAtFirstGate = true;
        }
      }

      if (part.position >= 0.4 && part.position < 0.45) {
        if (part.material == PartMaterial.steel && _state.activeFault != FaultType.sensorStuck) {
          inductive = true;
          if (!part.sorted) {
            _sortPart(part, true);
          }
        } else if (part.material == PartMaterial.aluminium && _state.activeFault != FaultType.sensorStuck) {
          capacitive = true;
          if (!part.sorted) {
            _sortPart(part, false);
          }
        }
      }

      if (part.position >= 0.9 && part.position < 0.95) {
        photoGate = true;
        if (!part.counted) {
          part.counted = true;
          if (part.material == PartMaterial.plastic && !part.sorted) {
            _state = _state.copyWith(
              plasticCount: _state.plasticCount + 1,
              totalCount: _state.totalCount + 1,
            );
          }
        }
      }

      if (part.position >= 1.0) {
        toRemove.add(part);
      }
    }

    // Update sensor states (only if not forced)
    bool sensorsChanged = false;
    if (!_forcedIO.containsKey('I0.0') && _state.firstGate != firstGate) {
      _logEvent('First Gate', firstGate.toString(), 'input');
      sensorsChanged = true;
    }
    if (!_forcedIO.containsKey('I0.1') && _state.inductive != inductive) {
      _logEvent('Inductive', inductive.toString(), 'input');
      sensorsChanged = true;
    }
    if (!_forcedIO.containsKey('I0.2') && _state.capacitive != capacitive) {
      _logEvent('Capacitive', capacitive.toString(), 'input');
      sensorsChanged = true;
    }
    if (!_forcedIO.containsKey('I0.3') && _state.photoGate != photoGate) {
      _logEvent('Photo Gate', photoGate.toString(), 'input');
      sensorsChanged = true;
    }

    if (sensorsChanged || _state.activeFault == FaultType.sensorStuck) {
      _state = _state.copyWith(
        firstGate: _forcedIO.containsKey('I0.0') 
            ? _forcedIO['I0.0']! 
            : (_state.activeFault == FaultType.sensorStuck ? true : firstGate),
        inductive: _forcedIO.containsKey('I0.1')
            ? _forcedIO['I0.1']!
            : (_state.activeFault == FaultType.sensorStuck ? _state.inductive : inductive),
        capacitive: _forcedIO.containsKey('I0.2')
            ? _forcedIO['I0.2']!
            : (_state.activeFault == FaultType.sensorStuck ? _state.capacitive : capacitive),
        photoGate: _forcedIO.containsKey('I0.3')
            ? _forcedIO['I0.3']!
            : photoGate,
      );
    }

    _parts.removeWhere((p) => toRemove.contains(p));
  }

  void _sortPart(_VirtualPart part, bool isSteel) {
    if (_state.activeFault == FaultType.paddleJam) {
      // Paddle jam causes mis-sorts
      _state = _state.copyWith(
        rejectCount: _state.rejectCount + 1,
        totalCount: _state.totalCount + 1,
      );
      part.sorted = true;
      return;
    }

    if (isSteel) {
      _state = _state.copyWith(
        paddleSteel: true,
        steelCount: _state.steelCount + 1,
        totalCount: _state.totalCount + 1,
      );
      _logEvent('Paddle Steel', 'true', 'output');
      Future.delayed(const Duration(milliseconds: 500), () {
        _state = _state.copyWith(paddleSteel: false);
        _logEvent('Paddle Steel', 'false', 'output');
        _stateController.add(_state);
      });
    } else {
      _state = _state.copyWith(
        paddleAluminium: true,
        aluminiumCount: _state.aluminiumCount + 1,
        totalCount: _state.totalCount + 1,
      );
      _logEvent('Paddle Aluminium', 'true', 'output');
      Future.delayed(const Duration(milliseconds: 500), () {
        _state = _state.copyWith(paddleAluminium: false);
        _logEvent('Paddle Aluminium', 'false', 'output');
        _stateController.add(_state);
      });
    }

    part.sorted = true;
  }

  void _calculateMetrics() {
    // Calculate throughput (items per minute)
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!);
      if (elapsed.inSeconds > 0) {
        _state = _state.copyWith(
          throughput: (_state.totalCount / elapsed.inSeconds) * 60.0,
        );
      }
    }

    // Calculate FPY
    if (_state.totalCount > 0) {
      final goodCount = _state.producedCount;
      _state = _state.copyWith(
        fpy: (goodCount / _state.totalCount) * 100.0,
      );
    }
  }

  void _logMetrics() {
    _metricsHistory.add(MetricsSnapshot(
      timestamp: DateTime.now(),
      throughput: _state.throughput,
      fpy: _state.fpy,
      rejectCount: _state.rejectCount,
      totalCount: _state.totalCount,
    ));

    // Keep only last 10 minutes
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _metricsHistory.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  void _logEvent(String name, String value, String type) {
    _eventLog.add(EventLogEntry(
      timestamp: DateTime.now(),
      name: name,
      value: value,
      type: type,
    ));

    // Keep only last hour
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _eventLog.removeWhere((e) => e.timestamp.isBefore(cutoff));
  }

  List<MetricsSnapshot> getMetricsHistory({Duration? window}) {
    if (window == null) return List.from(_metricsHistory);

    final cutoff = DateTime.now().subtract(window);
    return _metricsHistory.where((m) => m.timestamp.isAfter(cutoff)).toList();
  }

  List<EventLogEntry> getEventLog({Duration? window}) {
    if (window == null) return List.from(_eventLog);

    final cutoff = DateTime.now().subtract(window);
    return _eventLog.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  // Get active fault
  FaultType get activeFault => _state.activeFault;

  // Get fault history
  List<FaultRecord> getFaultHistory() {
    return List.unmodifiable(_faultHistory);
  }

  // Clear fault history
  void clearFaultHistory() {
    _faultHistory.clear();
  }

  // Get parts for visualization
  List<PartInfo> getParts() {
    return _parts.map((part) => PartInfo(
      id: part.id,
      material: part.material,
      position: part.position,
      detectedAtFirstGate: part.detectedAtFirstGate,
      sorted: part.sorted,
      counted: part.counted,
    )).toList();
  }

  void dispose() {
    _simulationTimer?.cancel();
    _stateController.close();
  }
}

// Public part info model for visualization
class PartInfo {
  final int id;
  final PartMaterial material;
  final double position;
  final bool detectedAtFirstGate;
  final bool sorted;
  final bool counted;

  PartInfo({
    required this.id,
    required this.material,
    required this.position,
    required this.detectedAtFirstGate,
    required this.sorted,
    required this.counted,
  });
}

// Fault record model
class FaultRecord {
  final FaultType faultType;
  final DateTime timestamp;
  final bool cleared;
  final DateTime? clearedAt;

  FaultRecord({
    required this.faultType,
    required this.timestamp,
    required this.cleared,
    this.clearedAt,
  });
}

class _VirtualPart {
  final int id;
  final PartMaterial material;
  double position;
  bool detectedAtFirstGate = false;
  bool sorted = false;
  bool counted = false;

  _VirtualPart({
    required this.id,
    required this.material,
    required this.position,
  });
}
