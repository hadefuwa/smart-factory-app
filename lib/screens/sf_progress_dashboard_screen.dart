import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/worksheet.dart';
import '../models/student_progress.dart';
import '../services/progress_tracking_service.dart';
import '../widgets/app_drawer.dart';

class SFProgressDashboardScreen extends StatefulWidget {
  const SFProgressDashboardScreen({super.key});

  @override
  State<SFProgressDashboardScreen> createState() => _SFProgressDashboardScreenState();
}

class _SFProgressDashboardScreenState extends State<SFProgressDashboardScreen> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  StudentProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await _progressService.getCurrentProgress();
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(context),
            tooltip: 'Export Progress',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgress,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress == null
              ? const Center(child: Text('No progress data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Student Info Card
                      _StudentInfoCard(progress: _progress!),
                      const SizedBox(height: 24),
                      // Overall Progress
                      _OverallProgressCard(progress: _progress!),
                      const SizedBox(height: 24),
                      // Time Spent
                      _TimeSpentCard(progress: _progress!),
                      const SizedBox(height: 24),
                      // Performance Metrics
                      _PerformanceMetricsCard(progress: _progress!),
                      const SizedBox(height: 24),
                      // Worksheet Progress List
                      _WorksheetProgressList(progress: _progress!),
                      const SizedBox(height: 24),
                      // Quiz Results
                      if (_progress!.quizResults.isNotEmpty) ...[
                        _QuizResultsCard(progress: _progress!),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Progress Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              subtitle: const Text('Comma-separated values file'),
              onTap: () {
                Navigator.pop(context);
                _exportProgressCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Portable Document Format'),
              onTap: () {
                Navigator.pop(context);
                _exportProgressPDF();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProgressCSV() async {
    if (_progress == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'SF2_Progress_${_progress!.studentId}_$timestamp.csv';

      final csv = StringBuffer();
      csv.writeln('Smart Factory Progress Report');
      csv.writeln('Student: ${_progress!.studentName}');
      csv.writeln('Student ID: ${_progress!.studentId}');
      csv.writeln('Generated: ${DateTime.now().toIso8601String()}');
      csv.writeln('');
      csv.writeln('Overall Statistics');
      csv.writeln('Total Time Spent,${_formatDuration(_progress!.totalTimeSpent)}');
      csv.writeln('First Access,${_progress!.firstAccessDate?.toIso8601String() ?? "N/A"}');
      csv.writeln('Last Access,${_progress!.lastAccessDate?.toIso8601String() ?? "N/A"}');
      csv.writeln('');

      final worksheets = Worksheet.getWorksheets();
      csv.writeln('Worksheet Progress');
      csv.writeln('Worksheet ID,Title,Completed,Time Spent,Steps Completed,Total Steps,Started At,Completed At');
      for (final worksheet in worksheets) {
        final wp = _progress!.worksheetProgress[worksheet.id];
        csv.writeln(
          '${worksheet.id},'
          '"${worksheet.title}",'
          '${wp?.isCompleted ?? false},'
          '${wp != null ? _formatDuration(wp.timeSpent) : "0:00"},'
          '${wp?.stepsCompleted ?? 0},'
          '${wp?.totalSteps ?? worksheet.steps.length},'
          '${wp?.startedAt?.toIso8601String() ?? "N/A"},'
          '${wp?.completedAt?.toIso8601String() ?? "N/A"}',
        );
      }
      csv.writeln('');

      if (_progress!.quizResults.isNotEmpty) {
        csv.writeln('Quiz Results');
        csv.writeln('Quiz ID,Quiz Name,Score,Correct Answers,Total Questions,Time Taken,Completed At');
        for (final result in _progress!.quizResults.values) {
          csv.writeln(
            '${result.quizId},'
            '"${result.quizName}",'
            '${result.score.toStringAsFixed(1)},'
            '${result.correctAnswers},'
            '${result.totalQuestions},'
            '${_formatDuration(result.timeTaken)},'
            '${result.completedAt.toIso8601String()}',
          );
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportProgressPDF() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export coming soon! Use CSV export for now.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _StudentInfoCard extends StatelessWidget {
  final StudentProgress progress;

  const _StudentInfoCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.studentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${progress.studentId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
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

class _OverallProgressCard extends StatelessWidget {
  final StudentProgress progress;

  const _OverallProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final worksheets = Worksheet.getWorksheets();
    final completionPercent = progress.getCompletionPercentage(worksheets.length);
    final completed = progress.worksheetProgress.values.where((p) => p.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / ${worksheets.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${completionPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completionPercent / 100,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _TimeSpentCard extends StatelessWidget {
  final StudentProgress progress;

  const _TimeSpentCard({required this.progress});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Time Spent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(progress.totalTimeSpent),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          if (progress.firstAccessDate != null)
            Text(
              'First access: ${_formatDate(progress.firstAccessDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PerformanceMetricsCard extends StatelessWidget {
  final StudentProgress progress;

  const _PerformanceMetricsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final avgQuizScore = progress.getAverageQuizScore();
    final completedWorksheets = progress.worksheetProgress.values.where((p) => p.isCompleted).length;
    final totalWorksheets = Worksheet.getWorksheets().length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Worksheets Completed',
                  value: '$completedWorksheets / $totalWorksheets',
                  icon: Icons.assignment,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricItem(
                  label: 'Average Quiz Score',
                  value: progress.quizResults.isEmpty
                      ? 'N/A'
                      : '${avgQuizScore.toStringAsFixed(1)}%',
                  icon: Icons.quiz,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorksheetProgressList extends StatelessWidget {
  final StudentProgress progress;

  const _WorksheetProgressList({required this.progress});

  @override
  Widget build(BuildContext context) {
    final worksheets = Worksheet.getWorksheets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Worksheet Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...worksheets.map((worksheet) {
          final wp = progress.worksheetProgress[worksheet.id];
          return _WorksheetProgressItem(
            worksheet: worksheet,
            progress: wp,
          );
        }),
      ],
    );
  }
}

class _WorksheetProgressItem extends StatelessWidget {
  final Worksheet worksheet;
  final WorksheetProgress? progress;

  const _WorksheetProgressItem({
    required this.worksheet,
    this.progress,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress?.isCompleted ?? false;
    final timeSpent = progress?.timeSpent ?? Duration.zero;
    final stepsCompleted = progress?.stepsCompleted ?? 0;
    final totalSteps = progress?.totalSteps ?? worksheet.steps.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${worksheet.id}: ${worksheet.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(timeSpent),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.checklist,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$stepsCompleted / $totalSteps',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResultsCard extends StatelessWidget {
  final StudentProgress progress;

  const _QuizResultsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...progress.quizResults.values.map((result) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.quizName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${result.correctAnswers} / ${result.totalQuestions} correct',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(result.score).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${result.score.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(result.score),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

