import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFHomeScreen extends StatelessWidget {
  const SFHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();
    final purple = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Smart Factory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: StreamBuilder<SimulatorState>(
        stream: simulator.stateStream,
        initialData: simulator.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.computer, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Simulation mode',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status Card
                _StatusCard(state: state, purple: purple),
                const SizedBox(height: 24),

                // Live Metrics
                _MetricsRow(state: state),
                const SizedBox(height: 24),

                // Control Buttons
                _ControlButtons(state: state, simulator: simulator),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SimulatorState state;
  final Color purple;

  const _StatusCard({required this.state, required this.purple});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (state.systemState) {
      case SystemState.running:
        statusColor = Colors.green;
        statusText = 'Running';
        statusIcon = Icons.play_circle;
        break;
      case SystemState.stopped:
        statusColor = Colors.grey;
        statusText = 'Stopped';
        statusIcon = Icons.stop_circle;
        break;
      case SystemState.paused:
        statusColor = Colors.amber;
        statusText = 'Paused';
        statusIcon = Icons.pause_circle;
        break;
      case SystemState.faulted:
        statusColor = Colors.red;
        statusText = 'Faulted';
        statusIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 64),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (state.activeFault != FaultType.none) ...[
            const SizedBox(height: 8),
            Text(
              _getFaultMessage(state.activeFault),
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getFaultMessage(FaultType fault) {
    switch (fault) {
      case FaultType.eStop:
        return 'Emergency Stop Active';
      case FaultType.sensorStuck:
        return 'Sensor Stuck - Check I/O';
      case FaultType.paddleJam:
        return 'Paddle Jam Detected';
      case FaultType.vacuumLeak:
        return 'Vacuum Leak Detected';
      case FaultType.none:
        return '';
    }
  }
}

class _MetricsRow extends StatelessWidget {
  final SimulatorState state;

  const _MetricsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricTile(
              label: 'Produced',
              value: state.producedCount.toString(),
              color: Colors.green,
              icon: Icons.check_circle_outline,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricTile(
              label: 'Rejects',
              value: state.rejectCount.toString(),
              color: Colors.red,
              icon: Icons.cancel_outlined,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricTile(
              label: 'FPY',
              value: '${state.fpy.toStringAsFixed(1)}%',
              color: Colors.blue,
              icon: Icons.analytics_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricTile(
              label: 'Throughput',
              value: '${state.throughput.toStringAsFixed(1)}/min',
              color: Colors.amber,
              icon: Icons.speed_outlined,
            )),
          ],
        ),
        const SizedBox(height: 12),
        _MetricTile(
          label: 'Uptime',
          value: _formatDuration(state.uptime),
          color: Colors.purple,
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final SimulatorState state;
  final SimulatorService simulator;

  const _ControlButtons({required this.state, required this.simulator});

  @override
  Widget build(BuildContext context) {
    final canStart = !state.isRunning && state.activeFault == FaultType.none;
    final canStop = state.isRunning;
    final canReset = state.activeFault != FaultType.none;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                label: 'Start line',
                icon: Icons.play_arrow,
                color: Colors.green,
                enabled: canStart,
                onPressed: canStart ? () => simulator.start() : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ControlButton(
                label: 'Stop line',
                icon: Icons.stop,
                color: Colors.amber,
                enabled: canStop,
                onPressed: canStop ? () => simulator.stop() : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ControlButton(
          label: 'Reset faults',
          icon: Icons.refresh,
          color: Colors.red,
          enabled: canReset,
          onPressed: canReset ? () => simulator.resetFaults() : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade800,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade900,
        disabledForegroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
