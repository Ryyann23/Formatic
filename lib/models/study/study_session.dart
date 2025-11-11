class StudySession {
  final String id;
  final String userId;
  final String sessionType;
  final int durationMinutes;
  final bool completed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudySession({
    required this.id,
    required this.userId,
    required this.sessionType,
    required this.durationMinutes,
    this.completed = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'].toString(),
      userId: json['user_id'],
      sessionType: json['session_type'],
      durationMinutes: json['duration_minutes'],
      completed: json['completed'] ?? false,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'session_type': sessionType,
      'duration_minutes': durationMinutes,
      'completed': completed,
      'notes': notes,
    };
  }
}
