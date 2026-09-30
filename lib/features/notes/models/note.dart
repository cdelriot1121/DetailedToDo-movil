class Note {
  final String id;
  final String title;
  final String content;
  final String? folder;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.folder,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'];
    List<String> tagList = [];
    if (rawTags is List) {
      tagList = rawTags.map((e) => e.toString()).toList();
    }

    return Note(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      folder: json['folder'] as String?,
      tags: tagList,
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
      'content': content,
      'folder': folder,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? folder,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
