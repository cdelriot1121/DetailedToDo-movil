class User {
  final String id;
  final String name;
  final String email;
  final String plan;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.plan = 'FREE',
    this.subscriptionStatus = 'NONE',
    this.subscriptionExpiresAt,
    this.createdAt,
  });

  bool get isPlus => plan.toUpperCase() == 'PLUS';

  bool get hasActiveSubscription =>
      isPlus &&
      (subscriptionExpiresAt == null ||
          subscriptionExpiresAt!.isAfter(DateTime.now()));

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      plan: json['plan'] as String? ?? 'FREE',
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'NONE',
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'plan': plan,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? plan,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
