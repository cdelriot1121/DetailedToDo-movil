class Subtask {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? createdAt;

  const Subtask({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.createdAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      completed: (json['status'] as String?)?.toUpperCase() == 'COMPLETED' ||
          (json['completed'] as bool? ?? false),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': completed ? 'COMPLETED' : 'PENDING',
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Subtask copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
