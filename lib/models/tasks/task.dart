class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'title': title, 'description': description};
  }
}
