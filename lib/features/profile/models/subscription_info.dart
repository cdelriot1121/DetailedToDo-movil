class SubscriptionInfo {
  final String plan;
  final String status;
  final DateTime? expiresAt;
  final DateTime? nextPaymentDate;
  final double amount;
  final String currency;
  final bool willRenew;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.expiresAt,
    this.nextPaymentDate,
    required this.amount,
    required this.currency,
    required this.willRenew,
  });

  bool get isPlus => plan.toUpperCase() == 'PLUS';
  bool get isActive =>
      status.toUpperCase() == 'ACTIVE' || status.toLowerCase() == 'authorized';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String? ?? 'FREE',
      status: json['status'] as String? ?? 'NONE',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      nextPaymentDate: json['nextPaymentDate'] != null
          ? DateTime.tryParse(json['nextPaymentDate'].toString())
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 3500.0,
      currency: json['currency'] as String? ?? 'COP',
      willRenew: json['willRenew'] as bool? ?? false,
    );
  }
}
