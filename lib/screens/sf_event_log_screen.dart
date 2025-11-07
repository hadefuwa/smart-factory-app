import 'package:flutter/material.dart';
import '../models/metrics_data.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFEventLogScreen extends StatefulWidget {
  const SFEventLogScreen({super.key});

  @override
  State<SFEventLogScreen> createState() => _SFEventLogScreenState();
}

class _SFEventLogScreenState extends State<SFEventLogScreen> {
  final SimulatorService _simulator = SimulatorService();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filterType = 'all'; // 'all', 'input', 'output', 'force'

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<EventLogEntry> _getFilteredEvents(List<EventLogEntry> events) {
    if (_filterType == 'all') return events;
    return events.where((e) => e.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Event Log'),
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 8),
                    Text('All Events'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'input',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Inputs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'output',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Outputs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'force',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Force Operations'),
                  ],
                ),
              ),
            ],
          ),
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.arrow_downward : Icons.pause,
              color: _autoScroll ? purple : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
          ),
          // Clear log button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearDialog();
            },
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: StreamBuilder<List<EventLogEntry>>(
        stream: Stream.periodic(
          const Duration(milliseconds: 100),
          (_) => _simulator.getEventLog(),
        ),
        builder: (context, snapshot) {
          final allEvents = snapshot.data ?? _simulator.getEventLog();
          final events = _getFilteredEvents(allEvents);
          
          // Auto-scroll to bottom when new entries arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_autoScroll) _scrollToBottom();
          });

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start the system to see IO changes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter indicator
              if (_filterType != 'all')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: purple.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(
                        _filterType == 'input'
                            ? Icons.arrow_downward
                            : _filterType == 'output'
                                ? Icons.arrow_upward
                                : Icons.flag,
                        size: 16,
                        color: purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Showing ${_filterType == 'input' ? 'Inputs' : _filterType == 'output' ? 'Outputs' : 'Force Operations'} only',
                        style: TextStyle(
                          color: purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterType = 'all';
                          });
                        },
                        child: const Text('Clear Filter'),
                      ),
                    ],
                  ),
                ),
              // Event list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final entry = events[index];
                    return _EventLogTile(entry: entry);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Event Log'),
        content: const Text('Are you sure you want to clear all event log entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Note: SimulatorService doesn't have a clear method, but events auto-expire after 1 hour
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event log will clear automatically after 1 hour'),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _EventLogTile extends StatelessWidget {
  final EventLogEntry entry;

  const _EventLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;
    
    // Determine colors based on type
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    
    if (entry.type == 'input') {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
      borderColor = Colors.blue.withValues(alpha: 0.3);
      iconColor = Colors.blue;
      icon = Icons.arrow_downward;
    } else if (entry.type == 'output') {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.withValues(alpha: 0.3);
      iconColor = Colors.green;
      icon = Icons.arrow_upward;
    } else if (entry.type == 'force') {
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      borderColor = Colors.orange.withValues(alpha: 0.3);
      iconColor = Colors.orange;
      icon = Icons.flag;
    } else {
      backgroundColor = purple.withValues(alpha: 0.1);
      borderColor = purple.withValues(alpha: 0.3);
      iconColor = purple;
      icon = Icons.info;
    }

    // Determine value display
    final bool isOn = entry.value.toLowerCase() == 'true' || entry.value.toLowerCase() == 'on';
    final bool isOff = entry.value.toLowerCase() == 'false' || entry.value.toLowerCase() == 'off' || entry.value.isEmpty;
    final bool hasValue = entry.value.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type indicator icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Event content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(entry.timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (hasValue)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOn
                              ? Colors.green
                              : isOff
                                  ? Colors.grey
                                  : iconColor,
                          shape: BoxShape.circle,
                          boxShadow: isOn
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
                      const SizedBox(width: 8),
                      Text(
                        isOn
                            ? 'ON'
                            : isOff
                                ? 'OFF'
                                : entry.value,
                        style: TextStyle(
                          color: isOn
                              ? Colors.green
                              : isOff
                                  ? Colors.grey
                                  : Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    entry.type == 'force' ? 'Force cleared' : 'Event',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                // Type badge
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.type.toUpperCase(),
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    }
  }
}

