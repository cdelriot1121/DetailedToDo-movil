class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final DateTime? reminderDate;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.location,
    this.reminderDate,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Backend returns dateTime or startDate or date
    final dateStr = json['dateTime'] ?? json['startDate'] ?? json['date'] ?? json['start'];
    final startDate = dateStr != null
        ? DateTime.tryParse(dateStr.toString()) ?? DateTime.now()
        : DateTime.now();

    final endStr = json['endDate'] ?? json['end'];
    final endDate = endStr != null ? DateTime.tryParse(endStr.toString()) : null;

    final remStr = json['reminderDate'] ?? json['reminder'];
    final reminderDate = remStr != null ? DateTime.tryParse(remStr.toString()) : null;

    final rawTags = json['tags'];
    final List<String> parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : [];

    return Event(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: startDate,
      endDate: endDate,
      location: json['location'] as String?,
      reminderDate: reminderDate,
      tags: parsedTags,
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
      if (description != null) 'description': description,
      'dateTime': startDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (location != null) 'location': location,
      if (reminderDate != null) 'reminderDate': reminderDate?.toIso8601String(),
      'tags': tags,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    DateTime? reminderDate,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      reminderDate: reminderDate ?? this.reminderDate,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
