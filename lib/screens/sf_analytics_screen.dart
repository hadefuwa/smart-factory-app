import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFAnalyticsScreen extends StatefulWidget {
  const SFAnalyticsScreen({super.key});

  @override
  State<SFAnalyticsScreen> createState() => _SFAnalyticsScreenState();
}

class _SFAnalyticsScreenState extends State<SFAnalyticsScreen> {
  Duration _selectedWindow = const Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Analytics'),
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
                // KPI Tiles
                Row(
                  children: [
                    Expanded(
                      child: _KPITile(
                        label: 'Throughput Now',
                        value: '${state.throughput.toStringAsFixed(1)}/min',
                        color: Colors.amber,
                        icon: Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KPITile(
                        label: 'FPY Now',
                        value: '${state.fpy.toStringAsFixed(1)}%',
                        color: Colors.blue,
                        icon: Icons.analytics,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _KPITile(
                  label: 'Rejects Today',
                  value: state.rejectCount.toString(),
                  color: Colors.red,
                  icon: Icons.warning,
                ),
                const SizedBox(height: 24),

                // Charts Section
                _SectionCard(
                  title: 'Performance Charts',
                  child: Column(
                    children: [
                      _ChartPlaceholder(
                        title: 'Throughput (Last 10 min)',
                        icon: Icons.show_chart,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      _ChartPlaceholder(
                        title: 'FPY (Last 10 min)',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _ChartPlaceholder(
                        title: 'Rejects per Minute',
                        icon: Icons.bar_chart,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Export Section
                _SectionCard(
                  title: 'Export Data',
                  child: Column(
                    children: [
                      const Text(
                        'Select time window:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _TimeWindowChip(
                            label: 'Last 15 min',
                            duration: const Duration(minutes: 15),
                            isSelected: _selectedWindow == const Duration(minutes: 15),
                            onTap: () => setState(() => _selectedWindow = const Duration(minutes: 15)),
                          ),
                          _TimeWindowChip(
                            label: 'Last hour',
                            duration: const Duration(hours: 1),
                            isSelected: _selectedWindow == const Duration(hours: 1),
                            onTap: () => setState(() => _selectedWindow = const Duration(hours: 1)),
                          ),
                          _TimeWindowChip(
                            label: 'Today',
                            duration: const Duration(hours: 24),
                            isSelected: _selectedWindow == const Duration(hours: 24),
                            onTap: () => setState(() => _selectedWindow = const Duration(hours: 24)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _exportMetrics(simulator),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Metrics CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _exportEvents(simulator),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Event Log CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportMetrics(SimulatorService simulator) async {
    try {
      final metrics = simulator.getMetricsHistory(window: _selectedWindow);

      if (metrics.isEmpty) {
        _showMessage('No metrics data available for the selected window', isError: true);
        return;
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'SF2_metrics_$timestamp.csv';

      // Create CSV content
      final csv = StringBuffer();
      csv.writeln('Timestamp,Throughput,FPY,Rejects,Total');
      for (final snapshot in metrics) {
        csv.writeln('${snapshot.timestamp.toIso8601String()},${snapshot.throughput},${snapshot.fpy},${snapshot.rejectCount},${snapshot.totalCount}');
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv.toString());

      _showMessage('Exported to: ${file.path}');
    } catch (e) {
      _showMessage('Error exporting metrics: $e', isError: true);
    }
  }

  Future<void> _exportEvents(SimulatorService simulator) async {
    try {
      final events = simulator.getEventLog(window: _selectedWindow);

      if (events.isEmpty) {
        _showMessage('No event data available for the selected window', isError: true);
        return;
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'SF2_events_$timestamp.csv';

      // Create CSV content
      final csv = StringBuffer();
      csv.writeln('Timestamp,Name,Value,Type');
      for (final event in events) {
        csv.writeln('${event.timestamp.toIso8601String()},${event.name},${event.value},${event.type}');
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv.toString());

      _showMessage('Exported to: ${file.path}');
    } catch (e) {
      _showMessage('Error exporting events: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _KPITile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KPITile({
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ChartPlaceholder({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chart visualization',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeWindowChip extends StatelessWidget {
  final String label;
  final Duration duration;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeWindowChip({
    required this.label,
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
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
