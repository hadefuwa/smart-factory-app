import 'dart:async';
import 'package:flutter/material.dart';
import '../models/worksheet.dart';
import '../services/progress_tracking_service.dart';

class SFWorksheetsScreen extends StatefulWidget {
  const SFWorksheetsScreen({super.key});

  @override
  State<SFWorksheetsScreen> createState() => _SFWorksheetsScreenState();
}

class _SFWorksheetsScreenState extends State<SFWorksheetsScreen> {
  final Set<String> _completedWorksheets = {};
  final ProgressTrackingService _progressService = ProgressTrackingService();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.getCurrentProgress();
    setState(() {
      _completedWorksheets.clear();
      for (final entry in progress.worksheetProgress.entries) {
        if (entry.value.isCompleted) {
          _completedWorksheets.add(entry.key);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final worksheets = Worksheet.getWorksheets();
    final completionPercent = (_completedWorksheets.length / worksheets.length * 100).toInt();

    return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_completedWorksheets.length}/${worksheets.length} completed',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _completedWorksheets.length / worksheets.length,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completionPercent% complete',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: worksheets.length,
              itemBuilder: (context, index) {
                final worksheet = worksheets[index];
                final isCompleted = _completedWorksheets.contains(worksheet.id);

                return _WorksheetCard(
                  worksheet: worksheet,
                  isCompleted: isCompleted,
                  onStart: () => _openWorksheet(context, worksheet),
                  onToggleComplete: () async {
                    if (isCompleted) {
                      setState(() {
                        _completedWorksheets.remove(worksheet.id);
                      });
                    } else {
                      setState(() {
                        _completedWorksheets.add(worksheet.id);
                      });
                    }
                    await _loadProgress();
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  void _openWorksheet(BuildContext context, Worksheet worksheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WorksheetDetailScreen(
          worksheet: worksheet,
          isCompleted: _completedWorksheets.contains(worksheet.id),
          onComplete: () async {
            setState(() {
              _completedWorksheets.add(worksheet.id);
            });
            await _loadProgress();
          },
        ),
      ),
    );
  }
}

class _WorksheetCard extends StatelessWidget {
  final Worksheet worksheet;
  final bool isCompleted;
  final VoidCallback onStart;
  final VoidCallback onToggleComplete;

  const _WorksheetCard({
    required this.worksheet,
    required this.isCompleted,
    required this.onStart,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.assignment,
                  color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${worksheet.id}: ${worksheet.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worksheet.goal,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${worksheet.estimatedMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorksheetDetailScreen extends StatefulWidget {
  final Worksheet worksheet;
  final bool isCompleted;
  final VoidCallback onComplete;

  const _WorksheetDetailScreen({
    required this.worksheet,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<_WorksheetDetailScreen> createState() => _WorksheetDetailScreenState();
}

class _WorksheetDetailScreenState extends State<_WorksheetDetailScreen> {
  final Set<int> _checkedSteps = {};
  final ProgressTrackingService _progressService = ProgressTrackingService();
  DateTime? _startTime;
  Timer? _timeTracker;

  @override
  void initState() {
    super.initState();
    _startWorksheet();
    _loadProgress();
  }

  Future<void> _startWorksheet() async {
    _startTime = DateTime.now();
    await _progressService.startWorksheet(
      widget.worksheet.id,
      widget.worksheet.steps.length,
    );

    // Track time every minute
    _timeTracker = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _progressService.updateTimeSpent(const Duration(minutes: 1));
    });
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.getCurrentProgress();
    final wp = progress.worksheetProgress[widget.worksheet.id];
    if (wp != null) {
      setState(() {
        _checkedSteps.clear();
        for (int i = 0; i < wp.stepsCompleted; i++) {
          _checkedSteps.add(i);
        }
      });
    }
  }

  @override
  void dispose() {
    _timeTracker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = _checkedSteps.length == widget.worksheet.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worksheet.id),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.worksheet.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.worksheet.goal,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimated time: ${widget.worksheet.estimatedMinutes} minutes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Steps to Complete:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(widget.worksheet.steps.length, (index) {
              final step = widget.worksheet.steps[index];
              final isChecked = _checkedSteps.contains(index);

              return CheckboxListTile(
                value: isChecked,
                onChanged: (value) async {
                  setState(() {
                    if (value == true) {
                      _checkedSteps.add(index);
                    } else {
                      _checkedSteps.remove(index);
                    }
                  });
                  await _progressService.updateWorksheetProgress(
                    widget.worksheet.id,
                    _checkedSteps.length,
                  );
                },
                title: Text(step),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const SizedBox(height: 24),
            if (!widget.isCompleted)
              ElevatedButton.icon(
                onPressed: allChecked
                    ? () async {
                        final timeSpent = _startTime != null
                            ? DateTime.now().difference(_startTime!)
                            : Duration.zero;
                        await _progressService.completeWorksheet(
                          widget.worksheet.id,
                          timeSpent,
                        );
                        widget.onComplete();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Worksheet marked as complete!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
