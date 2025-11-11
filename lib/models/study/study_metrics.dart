class StudyMetrics {
  final String id;
  final String userId;
  final DateTime date;
  final int totalMinutes;
  final int pomodoroSessions;
  final int flashcardsStudied;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyMetrics({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalMinutes,
    required this.pomodoroSessions,
    required this.flashcardsStudied,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudyMetrics.fromJson(Map<String, dynamic> json) {
    return StudyMetrics(
      id: json['id'].toString(),
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      totalMinutes: json['total_minutes'] ?? 0,
      pomodoroSessions: json['pomodoro_sessions'] ?? 0,
      flashcardsStudied: json['flashcards_studied'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'total_minutes': totalMinutes,
      'pomodoro_sessions': pomodoroSessions,
      'flashcards_studied': flashcardsStudied,
    };
  }
}
