class StudentProgress {
  final String studentId;
  final String studentName;
  final Map<String, WorksheetProgress> worksheetProgress;
  final Map<String, QuizResult> quizResults;
  final DateTime? firstAccessDate;
  final DateTime? lastAccessDate;
  final Duration totalTimeSpent;

  StudentProgress({
    required this.studentId,
    required this.studentName,
    Map<String, WorksheetProgress>? worksheetProgress,
    Map<String, QuizResult>? quizResults,
    this.firstAccessDate,
    this.lastAccessDate,
    Duration? totalTimeSpent,
  })  : worksheetProgress = worksheetProgress ?? {},
        quizResults = quizResults ?? {},
        totalTimeSpent = totalTimeSpent ?? Duration.zero;

  StudentProgress copyWith({
    String? studentId,
    String? studentName,
    Map<String, WorksheetProgress>? worksheetProgress,
    Map<String, QuizResult>? quizResults,
    DateTime? firstAccessDate,
    DateTime? lastAccessDate,
    Duration? totalTimeSpent,
  }) {
    return StudentProgress(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      worksheetProgress: worksheetProgress ?? this.worksheetProgress,
      quizResults: quizResults ?? this.quizResults,
      firstAccessDate: firstAccessDate ?? this.firstAccessDate,
      lastAccessDate: lastAccessDate ?? this.lastAccessDate,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'worksheetProgress': worksheetProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'quizResults': quizResults.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'firstAccessDate': firstAccessDate?.toIso8601String(),
      'lastAccessDate': lastAccessDate?.toIso8601String(),
      'totalTimeSpent': totalTimeSpent.inSeconds,
    };
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      worksheetProgress: (json['worksheetProgress'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          WorksheetProgress.fromJson(value as Map<String, dynamic>),
        ),
      ) ?? {},
      quizResults: (json['quizResults'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          QuizResult.fromJson(value as Map<String, dynamic>),
        ),
      ) ?? {},
      firstAccessDate: json['firstAccessDate'] != null
          ? DateTime.parse(json['firstAccessDate'] as String)
          : null,
      lastAccessDate: json['lastAccessDate'] != null
          ? DateTime.parse(json['lastAccessDate'] as String)
          : null,
      totalTimeSpent: Duration(seconds: json['totalTimeSpent'] as int? ?? 0),
    );
  }

  // Calculate completion percentage
  double getCompletionPercentage(int totalWorksheets) {
    if (totalWorksheets == 0) return 0.0;
    final completed = worksheetProgress.values.where((p) => p.isCompleted).length;
    return (completed / totalWorksheets) * 100;
  }

  // Get average quiz score
  double getAverageQuizScore() {
    if (quizResults.isEmpty) return 0.0;
    final totalScore = quizResults.values.fold<double>(
      0.0,
      (sum, result) => sum + result.score,
    );
    return totalScore / quizResults.length;
  }
}

class WorksheetProgress {
  final String worksheetId;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration timeSpent;
  final int stepsCompleted;
  final int totalSteps;

  WorksheetProgress({
    required this.worksheetId,
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
    Duration? timeSpent,
    this.stepsCompleted = 0,
    this.totalSteps = 0,
  }) : timeSpent = timeSpent ?? Duration.zero;

  WorksheetProgress copyWith({
    String? worksheetId,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? timeSpent,
    int? stepsCompleted,
    int? totalSteps,
  }) {
    return WorksheetProgress(
      worksheetId: worksheetId ?? this.worksheetId,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worksheetId': worksheetId,
      'isCompleted': isCompleted,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpent': timeSpent.inSeconds,
      'stepsCompleted': stepsCompleted,
      'totalSteps': totalSteps,
    };
  }

  factory WorksheetProgress.fromJson(Map<String, dynamic> json) {
    return WorksheetProgress(
      worksheetId: json['worksheetId'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeSpent: Duration(seconds: json['timeSpent'] as int? ?? 0),
      stepsCompleted: json['stepsCompleted'] as int? ?? 0,
      totalSteps: json['totalSteps'] as int? ?? 0,
    );
  }
}

class QuizResult {
  final String quizId;
  final String quizName;
  final double score; // 0-100
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final Duration timeTaken;
  final Map<String, bool> questionResults; // questionId -> isCorrect

  QuizResult({
    required this.quizId,
    required this.quizName,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    Duration? timeTaken,
    Map<String, bool>? questionResults,
  })  : timeTaken = timeTaken ?? Duration.zero,
        questionResults = questionResults ?? {};

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizName': quizName,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken.inSeconds,
      'questionResults': questionResults,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      quizName: json['quizName'] as String,
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      timeTaken: Duration(seconds: json['timeTaken'] as int? ?? 0),
      questionResults: (json['questionResults'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ) ?? {},
    );
  }
}

