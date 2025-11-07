import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFAlarmsScreen extends StatefulWidget {
  const SFAlarmsScreen({super.key});

  @override
  State<SFAlarmsScreen> createState() => _SFAlarmsScreenState();
}

class _SFAlarmsScreenState extends State<SFAlarmsScreen> {
  final SimulatorService _simulator = SimulatorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearHistoryDialog();
            },
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: StreamBuilder<SimulatorState>(
        stream: _simulator.stateStream,
        initialData: _simulator.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data!;
          final activeFault = state.activeFault;
          final faultHistory = _simulator.getFaultHistory();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Faults Section
                const Text(
                  'Active Faults',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (activeFault == FaultType.none)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Faults',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'System operating normally',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _FaultCard(
                    faultType: activeFault,
                    timestamp: DateTime.now(),
                    isActive: true,
                    onTap: () {
                      _showFaultDetail(activeFault);
                    },
                  ),
                const SizedBox(height: 32),
                // Fault History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fault History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (faultHistory.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _showClearHistoryDialog();
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (faultHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Fault History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Faults will appear here when they occur',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...faultHistory.reversed.map((fault) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FaultCard(
                          faultType: fault.faultType,
                          timestamp: fault.timestamp,
                          isActive: false,
                          cleared: fault.cleared,
                          clearedAt: fault.clearedAt,
                          onTap: () {
                            _showFaultDetail(fault.faultType);
                          },
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFaultDetail(FaultType faultType) {
    final faultInfo = _getFaultInfo(faultType);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FaultDetailSheet(faultInfo: faultInfo),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Fault History'),
        content: const Text('Are you sure you want to clear all fault history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _simulator.clearFaultHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fault history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  FaultInfo _getFaultInfo(FaultType faultType) {
    switch (faultType) {
      case FaultType.eStop:
        return FaultInfo(
          name: 'Emergency Stop',
          icon: Icons.emergency,
          color: Colors.red,
          cause: 'Emergency stop button pressed or safety circuit activated',
          effect: 'All outputs immediately disabled. System enters faulted state. Conveyor stops immediately.',
          interlockReason: 'Safety interlock prevents any output activation until E-Stop is reset',
          recommendedAction: '1. Verify the area is safe\n2. Release/reset the E-Stop button\n3. Press Reset Faults button to clear the fault\n4. Restart the system',
        );
      case FaultType.sensorStuck:
        return FaultInfo(
          name: 'Sensor Stuck',
          icon: Icons.sensors_off,
          color: Colors.orange,
          cause: 'Inductive or capacitive sensor stuck in ON state, possibly due to debris, mechanical failure, or wiring issue',
          effect: 'Sensor readings remain high continuously. Sorting logic fails - parts may be mis-sorted. Reject rate increases.',
          interlockReason: 'System continues operation but with degraded performance. No hard interlock, but sorting accuracy is compromised.',
          recommendedAction: '1. Check sensor for physical obstruction\n2. Inspect sensor wiring and connections\n3. Clean sensor face if dirty\n4. Test sensor response manually\n5. Replace sensor if faulty',
        );
      case FaultType.paddleJam:
        return FaultInfo(
          name: 'Paddle Jam',
          icon: Icons.warning,
          color: Colors.amber,
          cause: 'Paddle mechanism jammed, possibly due to part obstruction, mechanical wear, or actuator failure',
          effect: 'Paddle cannot move to sort parts. Parts are not sorted correctly and counted as rejects. Throughput decreases.',
          interlockReason: 'Paddle operations are disabled. System continues running but sorting is ineffective.',
          recommendedAction: '1. Stop the conveyor\n2. Inspect paddle mechanism for obstructions\n3. Check for mechanical damage\n4. Manually test paddle movement\n5. Clear any jammed parts\n6. Reset fault and test',
        );
      case FaultType.vacuumLeak:
        return FaultInfo(
          name: 'Vacuum Leak',
          icon: Icons.leak_add,
          color: Colors.purple,
          cause: 'Vacuum system leak detected, possibly due to damaged hose, loose connection, or pump failure',
          effect: 'Vacuum pressure insufficient. Parts cannot be picked up reliably. Pick and place operations fail.',
          interlockReason: 'Vacuum operations disabled. System continues but part handling is compromised.',
          recommendedAction: '1. Check vacuum hoses for damage or leaks\n2. Inspect all connections\n3. Verify vacuum pump operation\n4. Check vacuum pressure sensor\n5. Replace damaged components\n6. Reset fault after repair',
        );
      case FaultType.none:
        return FaultInfo(
          name: 'No Fault',
          icon: Icons.check_circle,
          color: Colors.green,
          cause: 'System operating normally',
          effect: 'No faults detected',
          interlockReason: 'No interlocks active',
          recommendedAction: 'Continue normal operation',
        );
    }
  }
}

class FaultInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String cause;
  final String effect;
  final String interlockReason;
  final String recommendedAction;

  FaultInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.cause,
    required this.effect,
    required this.interlockReason,
    required this.recommendedAction,
  });
}

class _FaultCard extends StatelessWidget {
  final FaultType faultType;
  final DateTime timestamp;
  final bool isActive;
  final bool cleared;
  final DateTime? clearedAt;
  final VoidCallback onTap;

  const _FaultCard({
    required this.faultType,
    required this.timestamp,
    required this.isActive,
    this.cleared = false,
    this.clearedAt,
    required this.onTap,
  });

  String _getFaultName(FaultType faultType) {
    switch (faultType) {
      case FaultType.eStop:
        return 'Emergency Stop';
      case FaultType.sensorStuck:
        return 'Sensor Stuck';
      case FaultType.paddleJam:
        return 'Paddle Jam';
      case FaultType.vacuumLeak:
        return 'Vacuum Leak';
      case FaultType.none:
        return 'No Fault';
    }
  }

  IconData _getFaultIcon(FaultType faultType) {
    switch (faultType) {
      case FaultType.eStop:
        return Icons.emergency;
      case FaultType.sensorStuck:
        return Icons.sensors_off;
      case FaultType.paddleJam:
        return Icons.warning;
      case FaultType.vacuumLeak:
        return Icons.leak_add;
      case FaultType.none:
        return Icons.check_circle;
    }
  }

  Color _getFaultColor(FaultType faultType) {
    switch (faultType) {
      case FaultType.eStop:
        return Colors.red;
      case FaultType.sensorStuck:
        return Colors.orange;
      case FaultType.paddleJam:
        return Colors.amber;
      case FaultType.vacuumLeak:
        return Colors.purple;
      case FaultType.none:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFaultColor(faultType);
    final icon = _getFaultIcon(faultType);
    final name = _getFaultName(faultType);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
            width: isActive ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? color : Colors.white,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (cleared)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CLEARED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  if (cleared && clearedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cleared: ${_formatTimestamp(clearedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _FaultDetailSheet extends StatelessWidget {
  final FaultInfo faultInfo;

  const _FaultDetailSheet({required this.faultInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: faultInfo.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        faultInfo.icon,
                        color: faultInfo.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faultInfo.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: faultInfo.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'FAULT DETAIL',
                              style: TextStyle(
                                color: faultInfo.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Cause
                _DetailSection(
                  title: 'Cause',
                  icon: Icons.info_outline,
                  content: faultInfo.cause,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                // Effect
                _DetailSection(
                  title: 'Effect',
                  icon: Icons.bolt,
                  content: faultInfo.effect,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                // Interlock Reason
                _DetailSection(
                  title: 'Interlock Reason',
                  icon: Icons.lock,
                  content: faultInfo.interlockReason,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                // Recommended Action
                _DetailSection(
                  title: 'Recommended Action',
                  icon: Icons.build,
                  content: faultInfo.recommendedAction,
                  color: Colors.green,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final Color color;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

