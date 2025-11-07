import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';

class SFIOScreen extends StatelessWidget {
  const SFIOScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();

    return StreamBuilder<SimulatorState>(
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
                const SizedBox(height: 32),
                const Text(
                  'PLC IO Table',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _PLCIOTable(state: state, simulator: simulator),
              ],
            ),
          );
        },
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

class _PLCIOTable extends StatelessWidget {
  final SimulatorState state;
  final SimulatorService simulator;

  const _PLCIOTable({required this.state, required this.simulator});

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inputs Section
          _buildSectionHeader('Inputs (I)', Colors.blue, Icons.arrow_downward, isFirst: true),
          _buildTableHeader(['Address', 'Description', 'Status', 'Force']),
          _buildTableRow('I0.0', 'First Gate', state.firstGate, true, 'I0.0'),
          _buildTableRow('I0.1', 'Inductive Sensor', state.inductive, true, 'I0.1'),
          _buildTableRow('I0.2', 'Capacitive Sensor', state.capacitive, true, 'I0.2'),
          _buildTableRow('I0.3', 'Photo Gate', state.photoGate, true, 'I0.3'),
          _buildTableRow('I0.4', 'E-Stop', state.eStop, true, 'I0.4'),
          _buildTableRow('I0.5', 'Gantry Home', state.gantryHome, true, 'I0.5'),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2A2A3E), height: 1),
          const SizedBox(height: 8),
          // Outputs Section
          _buildSectionHeader('Outputs (Q)', Colors.green, Icons.arrow_upward),
          _buildTableHeader(['Address', 'Description', 'Status', 'Force']),
          _buildTableRow('Q0.0', 'Conveyor', state.conveyor, false, 'Q0.0'),
          _buildTableRow('Q0.1', 'Paddle Steel', state.paddleSteel, false, 'Q0.1'),
          _buildTableRow('Q0.2', 'Paddle Aluminium', state.paddleAluminium, false, 'Q0.2'),
          _buildTableRow('Q0.3', 'Plunger Down', state.plungerDown, false, 'Q0.3'),
          _buildTableRow('Q0.4', 'Vacuum', state.vacuum, false, 'Q0.4'),
          _buildTableRow('Q0.5', 'Gantry Step', state.gantryStep, false, 'Q0.5'),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2A2A3E), height: 1),
          const SizedBox(height: 8),
          // Memory Bits Section
          _buildSectionHeader('Memory Bits (M)', Colors.orange, Icons.storage),
          _buildTableHeader(['Address', 'Description', 'Status', '']),
          _buildMemoryRow('M0.0', 'System Running', state.isRunning),
          _buildMemoryRow('M0.1', 'System Fault', state.activeFault != FaultType.none),
          _buildMemoryRow('M0.2', 'E-Stop Active', state.activeFault == FaultType.eStop),
          _buildMemoryRow('M0.3', 'Sensor Fault', state.activeFault == FaultType.sensorStuck),
          _buildMemoryRow('M0.4', 'Paddle Jam', state.activeFault == FaultType.paddleJam),
          _buildMemoryRow('M0.5', 'Vacuum Leak', state.activeFault == FaultType.vacuumLeak),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon, {bool isFirst = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: isFirst
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              headers[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              headers[1],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              headers[2],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              headers[3],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String address, String description, bool status, bool isInput, String ioAddress) {
    final isForced = simulator.isForced(ioAddress) != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        color: isForced ? Colors.orange.withValues(alpha: 0.1) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (isForced) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.flag,
                    size: 12,
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: status
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () {
                      if (isInput) {
                        simulator.forceInput(ioAddress, true);
                      } else {
                        if (simulator.currentState.activeFault != FaultType.eStop) {
                          simulator.forceOutput(ioAddress, true);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
                      foregroundColor: Colors.green,
                    ),
                    child: const Text(
                      'ON',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () {
                      if (isInput) {
                        simulator.forceInput(ioAddress, false);
                      } else {
                        if (simulator.currentState.activeFault != FaultType.eStop) {
                          simulator.forceOutput(ioAddress, false);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'OFF',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: isForced
                        ? () {
                            if (isInput) {
                              simulator.clearInputForce(ioAddress);
                            } else {
                              simulator.clearOutputForce(ioAddress);
                            }
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      side: BorderSide(
                        color: isForced
                            ? Colors.orange.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                      foregroundColor: isForced ? Colors.orange : Colors.grey,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryRow(String address, String description, bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              address,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: status
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 4,
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
