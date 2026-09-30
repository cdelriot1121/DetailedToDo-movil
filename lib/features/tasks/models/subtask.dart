class Subtask {
  final String id;
  final String title;
  final bool completed;
  final DateTime? createdAt;

  const Subtask({
    required this.id,
    required this.title,
    this.completed = false,
    this.createdAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
