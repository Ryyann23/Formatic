class AiHistory {
  final int id;
  final String userId;
  final String question;
  final String answer;
  final DateTime createdAt;

  AiHistory({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory AiHistory.fromJson(Map<String, dynamic> json) => AiHistory(
    id: json['id'],
    userId: json['user_id'],
    question: json['question'],
    answer: json['answer'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'question': question,
    'answer': answer,
    'created_at': createdAt.toIso8601String(),
  };
}
