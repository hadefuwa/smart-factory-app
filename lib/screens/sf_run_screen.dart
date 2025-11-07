import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFRunScreen extends StatelessWidget {
  const SFRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Run Control'),
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
                _RecipeSection(state: state),
                const SizedBox(height: 24),
                _SetpointsSection(state: state, simulator: simulator),
                const SizedBox(height: 24),
                _LiveCountersSection(state: state),
                const SizedBox(height: 24),
                _ManualJogSection(state: state, simulator: simulator),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecipeSection extends StatelessWidget {
  final SimulatorState state;

  const _RecipeSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recipe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.currentRecipe,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically sorts steel, aluminium, and plastic materials',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _SetpointsSection extends StatelessWidget {
  final SimulatorState state;
  final SimulatorService simulator;

  const _SetpointsSection({required this.state, required this.simulator});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Setpoints',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conveyor Speed: ${state.conveyorSpeed}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: state.conveyorSpeed.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${state.conveyorSpeed}%',
                      onChanged: (value) {
                        simulator.setConveyorSpeed(value.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Target: ${state.batchTarget}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => simulator.setBatchTarget(50),
                            child: const Text('50'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => simulator.setBatchTarget(100),
                            child: const Text('100'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => simulator.setBatchTarget(200),
                            child: const Text('200'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => simulator.setBatchTarget(500),
                            child: const Text('500'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveCountersSection extends StatelessWidget {
  final SimulatorState state;

  const _LiveCountersSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Live Counters',
      child: Column(
        children: [
          _CounterRow(
            label: 'Steel',
            value: state.steelCount,
            color: Colors.grey,
            icon: Icons.category,
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: 'Aluminium',
            value: state.aluminiumCount,
            color: Colors.lightBlue,
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: 'Plastic',
            value: state.plasticCount,
            color: Colors.orange,
            icon: Icons.recycling,
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: 'Rejects',
            value: state.rejectCount,
            color: Colors.red,
            icon: Icons.warning,
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: 'Remaining',
            value: state.remainingCount,
            color: Colors.green,
            icon: Icons.pending,
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualJogSection extends StatelessWidget {
  final SimulatorState state;
  final SimulatorService simulator;

  const _ManualJogSection({required this.state, required this.simulator});

  @override
  Widget build(BuildContext context) {
    final canJog = state.activeFault != FaultType.eStop;
    final canPlunger = canJog && !state.conveyor;

    return _SectionCard(
      title: 'Manual Jog',
      child: Column(
        children: [
          if (state.activeFault == FaultType.eStop)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Outputs are disabled during an emergency stop.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (!canPlunger && canJog)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plunger blocked while conveyor is running.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _JogButton(
                  label: 'Conveyor jog',
                  icon: Icons.play_arrow,
                  enabled: canJog,
                  isActive: state.conveyor,
                  onPressed: (value) => simulator.jogConveyor(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PulseButton(
                  label: 'Left paddle',
                  icon: Icons.arrow_back,
                  enabled: canJog,
                  onPressed: () => simulator.pulsePaddle(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PulseButton(
                  label: 'Right paddle',
                  icon: Icons.arrow_forward,
                  enabled: canJog,
                  onPressed: () => simulator.pulsePaddle(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _JogButton(
                  label: 'Plunger down',
                  icon: Icons.arrow_downward,
                  enabled: canPlunger,
                  isActive: state.plungerDown,
                  onPressed: (value) => simulator.togglePlunger(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _JogButton(
                  label: 'Vacuum',
                  icon: Icons.air,
                  enabled: canJog,
                  isActive: state.vacuum,
                  onPressed: (value) => simulator.toggleVacuum(value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isActive;
  final Function(bool) onPressed;

  const _JogButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? () => onPressed(!isActive) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled && isActive ? Colors.green : Colors.grey.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PulseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PulseButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
