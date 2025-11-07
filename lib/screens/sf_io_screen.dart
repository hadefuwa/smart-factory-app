import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFIOScreen extends StatelessWidget {
  const SFIOScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('I/O Live'),
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
                const Text(
                  'Inputs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _InputsGrid(state: state),
                const SizedBox(height: 32),
                const Text(
                  'Outputs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _OutputsGrid(state: state, simulator: simulator),
                if (state.activeFault == FaultType.eStop) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Blocked by E-Stop',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.conveyor && !state.isRunning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Stop conveyor first',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InputsGrid extends StatelessWidget {
  final SimulatorState state;

  const _InputsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _IOTile(
          label: 'First Gate',
          icon: Icons.sensors,
          isActive: state.firstGate,
          isInput: true,
        ),
        _IOTile(
          label: 'Inductive',
          icon: Icons.bolt,
          isActive: state.inductive,
          isInput: true,
        ),
        _IOTile(
          label: 'Capacitive',
          icon: Icons.electric_bolt,
          isActive: state.capacitive,
          isInput: true,
        ),
        _IOTile(
          label: 'Photo Gate',
          icon: Icons.camera,
          isActive: state.photoGate,
          isInput: true,
        ),
        _IOTile(
          label: 'E-Stop',
          icon: Icons.emergency,
          isActive: state.eStop,
          isInput: true,
        ),
        _IOTile(
          label: 'Gantry Home',
          icon: Icons.home,
          isActive: state.gantryHome,
          isInput: true,
        ),
      ],
    );
  }
}

class _OutputsGrid extends StatelessWidget {
  final SimulatorState state;
  final SimulatorService simulator;

  const _OutputsGrid({required this.state, required this.simulator});

  @override
  Widget build(BuildContext context) {
    final canActivate = state.activeFault != FaultType.eStop;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _IOTile(
          label: 'Conveyor',
          icon: Icons.conveyor_belt,
          isActive: state.conveyor,
          isInput: false,
          enabled: canActivate,
          onTap: () => _showOutputDialog(context, 'Conveyor', () {
            simulator.jogConveyor(!state.conveyor);
          }),
        ),
        _IOTile(
          label: 'Paddle Steel',
          icon: Icons.arrow_back,
          isActive: state.paddleSteel,
          isInput: false,
          enabled: canActivate,
          onTap: () => _showOutputDialog(context, 'Paddle Steel', () {
            simulator.pulsePaddle(true);
          }),
        ),
        _IOTile(
          label: 'Paddle Aluminium',
          icon: Icons.arrow_forward,
          isActive: state.paddleAluminium,
          isInput: false,
          enabled: canActivate,
          onTap: () => _showOutputDialog(context, 'Paddle Aluminium', () {
            simulator.pulsePaddle(false);
          }),
        ),
        _IOTile(
          label: 'Plunger Down',
          icon: Icons.arrow_downward,
          isActive: state.plungerDown,
          isInput: false,
          enabled: canActivate && !state.conveyor,
          onTap: () => _showOutputDialog(context, 'Plunger Down', () {
            simulator.togglePlunger(!state.plungerDown);
          }),
        ),
        _IOTile(
          label: 'Vacuum',
          icon: Icons.air,
          isActive: state.vacuum,
          isInput: false,
          enabled: canActivate,
          onTap: () => _showOutputDialog(context, 'Vacuum', () {
            simulator.toggleVacuum(!state.vacuum);
          }),
        ),
        _IOTile(
          label: 'Gantry Step',
          icon: Icons.stairs,
          isActive: state.gantryStep,
          isInput: false,
          enabled: false, // Not implemented in sim
        ),
      ],
    );
  }

  void _showOutputDialog(BuildContext context, String name, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activate $name'),
        content: const Text('Do you want to activate this output?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name activated')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _IOTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isInput;
  final bool enabled;
  final VoidCallback? onTap;

  const _IOTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isInput,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return InkWell(
      onTap: !isInput && enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
