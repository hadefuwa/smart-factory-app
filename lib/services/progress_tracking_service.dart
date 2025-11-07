import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_progress.dart';

class ProgressTrackingService {
  static final ProgressTrackingService _instance = ProgressTrackingService._internal();
  factory ProgressTrackingService() => _instance;
  ProgressTrackingService._internal();

  static const String _prefKeyProgress = 'student_progress';
  static const String _prefKeyCurrentStudentId = 'current_student_id';
  static const String _prefKeyCurrentStudentName = 'current_student_name';

  StudentProgress? _currentProgress;
  final Map<String, StudentProgress> _allStudents = {};

  // Get current student progress
  Future<StudentProgress> getCurrentProgress() async {
    if (_currentProgress != null) return _currentProgress!;

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString(_prefKeyCurrentStudentId) ?? 'default_student';
    final studentName = prefs.getString(_prefKeyCurrentStudentName) ?? 'Student';

    await loadProgress();
    _currentProgress = _allStudents[studentId] ??
        StudentProgress(
          studentId: studentId,
          studentName: studentName,
          firstAccessDate: DateTime.now(),
        );

    return _currentProgress!;
  }

  // Set current student
  Future<void> setCurrentStudent(String studentId, String studentName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCurrentStudentId, studentId);
    await prefs.setString(_prefKeyCurrentStudentName, studentName);

    await loadProgress();
    _currentProgress = _allStudents[studentId] ??
        StudentProgress(
          studentId: studentId,
          studentName: studentName,
          firstAccessDate: DateTime.now(),
        );
  }

  // Load all progress from storage
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_prefKeyProgress);

    if (progressJson != null) {
      try {
        final data = json.decode(progressJson) as Map<String, dynamic>;
        _allStudents.clear();
        data.forEach((key, value) {
          _allStudents[key] = StudentProgress.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        // Handle error - start fresh
        _allStudents.clear();
      }
    }
  }

  // Save progress to storage
  Future<void> saveProgress() async {
    if (_currentProgress == null) return;

    _allStudents[_currentProgress!.studentId] = _currentProgress!;

    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    _allStudents.forEach((key, value) {
      data[key] = value.toJson();
    });

    await prefs.setString(_prefKeyProgress, json.encode(data));
  }

  // Start worksheet session
  Future<void> startWorksheet(String worksheetId, int totalSteps) async {
    final progress = await getCurrentProgress();
    final worksheetProgress = progress.worksheetProgress[worksheetId] ??
        WorksheetProgress(
          worksheetId: worksheetId,
          totalSteps: totalSteps,
        );

    final updatedProgress = worksheetProgress.copyWith(
      startedAt: worksheetProgress.startedAt ?? DateTime.now(),
      totalSteps: totalSteps,
    );

    _currentProgress = progress.copyWith(
      worksheetProgress: {
        ...progress.worksheetProgress,
        worksheetId: updatedProgress,
      },
      lastAccessDate: DateTime.now(),
    );

    await saveProgress();
  }

  // Update worksheet progress
  Future<void> updateWorksheetProgress(
    String worksheetId,
    int stepsCompleted,
  ) async {
    final progress = await getCurrentProgress();
    final worksheetProgress = progress.worksheetProgress[worksheetId];

    if (worksheetProgress != null) {
      final updatedProgress = worksheetProgress.copyWith(
        stepsCompleted: stepsCompleted,
      );

      _currentProgress = progress.copyWith(
        worksheetProgress: {
          ...progress.worksheetProgress,
          worksheetId: updatedProgress,
        },
        lastAccessDate: DateTime.now(),
      );

      await saveProgress();
    }
  }

  // Complete worksheet
  Future<void> completeWorksheet(String worksheetId, Duration timeSpent) async {
    final progress = await getCurrentProgress();
    final worksheetProgress = progress.worksheetProgress[worksheetId];

    if (worksheetProgress != null) {
      final updatedProgress = worksheetProgress.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        timeSpent: worksheetProgress.timeSpent + timeSpent,
        stepsCompleted: worksheetProgress.totalSteps,
      );

      _currentProgress = progress.copyWith(
        worksheetProgress: {
          ...progress.worksheetProgress,
          worksheetId: updatedProgress,
        },
        totalTimeSpent: progress.totalTimeSpent + timeSpent,
        lastAccessDate: DateTime.now(),
      );

      await saveProgress();
    }
  }

  // Add quiz result
  Future<void> addQuizResult(QuizResult result) async {
    final progress = await getCurrentProgress();

    _currentProgress = progress.copyWith(
      quizResults: {
        ...progress.quizResults,
        result.quizId: result,
      },
      lastAccessDate: DateTime.now(),
    );

    await saveProgress();
  }

  // Update time spent (called periodically)
  Future<void> updateTimeSpent(Duration additionalTime) async {
    final progress = await getCurrentProgress();

    _currentProgress = progress.copyWith(
      totalTimeSpent: progress.totalTimeSpent + additionalTime,
      lastAccessDate: DateTime.now(),
    );

    // Save periodically (not every call to avoid too many writes)
    if (additionalTime.inSeconds >= 60) {
      await saveProgress();
    }
  }

  // Get all students (for teacher dashboard)
  Future<List<StudentProgress>> getAllStudents() async {
    await loadProgress();
    return _allStudents.values.toList();
  }

  // Get student by ID
  Future<StudentProgress?> getStudentById(String studentId) async {
    await loadProgress();
    return _allStudents[studentId];
  }

  // Clear all progress (for testing/reset)
  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyProgress);
    _allStudents.clear();
    _currentProgress = null;
  }
}

