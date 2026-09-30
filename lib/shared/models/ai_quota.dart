class AIQuota {
  final int used;
  final int limit;
  final int remaining;
  final String plan;

  const AIQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.plan,
  });

  factory AIQuota.fromJson(Map<String, dynamic> json) {
    return AIQuota(
      used: (json['requestsUsed'] ?? json['usedToday'] ?? json['used'] as num?)?.toInt() ?? 0,
      limit: (json['requestsLimit'] ?? json['dailyLimit'] ?? json['limit'] as num?)?.toInt() ?? 5,
      remaining: (json['requestsRemaining'] ?? json['remaining'] as num?)?.toInt() ?? 0,
      plan: json['plan'] as String? ?? 'FREE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used': used,
      'limit': limit,
      'remaining': remaining,
      'plan': plan,
    };
  }

  double get progressPercentage {
    if (limit <= 0) return 0.0;
    return (remaining / limit).clamp(0.0, 1.0);
  }
}
