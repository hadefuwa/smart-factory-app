import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/worksheet.dart';
import '../models/student_progress.dart';
import '../services/progress_tracking_service.dart';
import '../widgets/app_drawer.dart';

class SFTeacherDashboardScreen extends StatefulWidget {
  const SFTeacherDashboardScreen({super.key});

  @override
  State<SFTeacherDashboardScreen> createState() => _SFTeacherDashboardScreenState();
}

class _SFTeacherDashboardScreenState extends State<SFTeacherDashboardScreen> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  List<StudentProgress> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _progressService.getAllStudents();
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(context),
            tooltip: 'Export All Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No student data available',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Statistics
                      _SummaryStatisticsCard(students: _students),
                      const SizedBox(height: 24),
                      // Comparison Chart
                      _ComparisonChart(students: _students),
                      const SizedBox(height: 24),
                      // Student List
                      const Text(
                        'All Students',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._students.map((student) => _StudentCard(
                            student: student,
                            onTap: () => _showStudentDetails(context, student),
                          )),
                    ],
                  ),
                ),
    );
  }

  void _showStudentDetails(BuildContext context, StudentProgress student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StudentDetailScreen(student: student),
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
              'Export All Student Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              subtitle: const Text('All student progress data'),
              onTap: () {
                Navigator.pop(context);
                _exportAllStudentsCSV();
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

  Future<void> _exportAllStudentsCSV() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'SF2_AllStudents_$timestamp.csv';

      final csv = StringBuffer();
      csv.writeln('Smart Factory - All Students Progress Report');
      csv.writeln('Generated: ${DateTime.now().toIso8601String()}');
      csv.writeln('Total Students: ${_students.length}');
      csv.writeln('');

      // Summary
      csv.writeln('Summary Statistics');
      csv.writeln('Metric,Value');
      final totalTime = _students.fold<Duration>(
        Duration.zero,
        (sum, s) => sum + s.totalTimeSpent,
      );
      csv.writeln('Total Time Spent,${_formatDuration(totalTime)}');
      final totalCompleted = _students.fold<int>(
        0,
        (sum, s) => sum + s.worksheetProgress.values.where((p) => p.isCompleted).length,
      );
      csv.writeln('Total Worksheets Completed,$totalCompleted');
      csv.writeln('');

      // Student data
      csv.writeln('Student Data');
      csv.writeln('Student ID,Student Name,Worksheets Completed,Total Time,Average Quiz Score,First Access,Last Access');
      for (final student in _students) {
        final worksheets = Worksheet.getWorksheets();
        final completed = student.worksheetProgress.values.where((p) => p.isCompleted).length;
        final avgScore = student.getAverageQuizScore();
        csv.writeln(
          '${student.studentId},'
          '"${student.studentName}",'
          '$completed/${worksheets.length},'
          '${_formatDuration(student.totalTimeSpent)},'
          '${avgScore.toStringAsFixed(1)},'
          '${student.firstAccessDate?.toIso8601String() ?? "N/A"},'
          '${student.lastAccessDate?.toIso8601String() ?? "N/A"}',
        );
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class _SummaryStatisticsCard extends StatelessWidget {
  final List<StudentProgress> students;

  const _SummaryStatisticsCard({required this.students});

  @override
  Widget build(BuildContext context) {
    final totalStudents = students.length;
    final totalTime = students.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.totalTimeSpent,
    );
    final totalCompleted = students.fold<int>(
      0,
      (sum, s) => sum + s.worksheetProgress.values.where((p) => p.isCompleted).length,
    );
    final avgQuizScore = students.isEmpty
        ? 0.0
        : students.fold<double>(
                0.0,
                (sum, s) => sum + s.getAverageQuizScore(),
              ) /
            students.length;

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
          const Text(
            'Summary Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Students',
                  value: totalStudents.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Total Time',
                  value: _formatDuration(totalTime),
                  icon: Icons.access_time,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Worksheets Completed',
                  value: totalCompleted.toString(),
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Avg Quiz Score',
                  value: avgQuizScore.toStringAsFixed(1),
                  icon: Icons.quiz,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
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

class _ComparisonChart extends StatelessWidget {
  final List<StudentProgress> students;

  const _ComparisonChart({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    final worksheets = Worksheet.getWorksheets();
    final maxCompletion = worksheets.length.toDouble();

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
            'Student Comparison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...students.take(10).map((student) {
            final completed = student.worksheetProgress.values
                .where((p) => p.isCompleted)
                .length;
            final percentage = maxCompletion > 0 ? (completed / maxCompletion) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          student.studentName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$completed / ${worksheets.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 0.8
                            ? Colors.green
                            : percentage >= 0.5
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (students.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${students.length - 10} more students',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentProgress student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final worksheets = Worksheet.getWorksheets();
    final completed = student.worksheetProgress.values.where((p) => p.isCompleted).length;
    final completionPercent = student.getCompletionPercentage(worksheets.length);
    final avgQuizScore = student.getAverageQuizScore();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completed / ${worksheets.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.quiz,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          student.quizResults.isEmpty
                              ? 'No quizzes'
                              : '${avgQuizScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCompletionColor(completionPercent).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${completionPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getCompletionColor(completionPercent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompletionColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _StudentDetailScreen extends StatelessWidget {
  final StudentProgress student;

  const _StudentDetailScreen({required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.studentName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Student ID: ${student.studentId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            // Same widgets as progress dashboard but for single student
            // (Reusing would require refactoring, but for now showing key info)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Total Time', _formatDuration(student.totalTimeSpent)),
                  _DetailRow(
                    'Worksheets Completed',
                    '${student.worksheetProgress.values.where((p) => p.isCompleted).length}',
                  ),
                  _DetailRow(
                    'Average Quiz Score',
                    student.quizResults.isEmpty
                        ? 'N/A'
                        : '${student.getAverageQuizScore().toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

