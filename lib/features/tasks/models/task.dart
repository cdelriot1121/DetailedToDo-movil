import 'subtask.dart';

enum TaskPriority {
  low('LOW', 'Baja'),
  medium('MEDIUM', 'Media'),
  high('HIGH', 'Alta');

  final String value;
  final String label;

  const TaskPriority(this.value, this.label);

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.medium;
    switch (value.toUpperCase()) {
      case 'HIGH':
        return TaskPriority.high;
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
      default:
        return TaskPriority.medium;
    }
  }
}

enum TaskStatus {
  pending('PENDING', 'Pendiente'),
  inProgress('IN_PROGRESS', 'En progreso'),
  completed('COMPLETED', 'Completada');

  final String value;
  final String label;

  const TaskStatus(this.value, this.label);

  static TaskStatus fromString(String? value) {
    if (value == null) return TaskStatus.pending;
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'PENDING':
      default:
        return TaskStatus.pending;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final String? folder;
  final List<String> tags;
  final List<Subtask> subtasks;
  final String? subtasksGenerationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminderDate,
    this.folder,
    this.tags = const [],
    this.subtasks = const [],
    this.subtasksGenerationStatus,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isAIGenerating => subtasksGenerationStatus == 'PENDING';

  int get completedSubtasksCount =>
      subtasks.where((s) => s.completed).length;

  int get totalSubtasksCount => subtasks.length;

  double get subtasksProgress {
    if (subtasks.isEmpty) return 0.0;
    return completedSubtasksCount / subtasks.length;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var rawSubtasks = json['subtasks'];
    List<Subtask> subtaskList = [];
    if (rawSubtasks is List) {
      subtaskList = rawSubtasks
          .map((item) => Subtask.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var rawTags = json['tags'];
    List<String> tagList = [];
    if (rawTags is List) {
      tagList = rawTags.map((e) => e.toString()).toList();
    }

    return Task(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: TaskStatus.fromString(json['status'] as String?),
      priority: TaskPriority.fromString(json['priority'] as String?),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      reminderDate: json['reminderDate'] != null
          ? DateTime.tryParse(json['reminderDate'].toString())
          : null,
      folder: json['folder'] as String?,
      tags: tagList,
      subtasks: subtaskList,
      subtasksGenerationStatus: json['subtasksGenerationStatus'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'dueDate': dueDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'folder': folder,
      'tags': tags,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'subtasksGenerationStatus': subtasksGenerationStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? folder,
    List<String>? tags,
    List<Subtask>? subtasks,
    String? subtasksGenerationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      subtasksGenerationStatus:
          subtasksGenerationStatus ?? this.subtasksGenerationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
