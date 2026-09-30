class ApiError {
  final int? status;
  final String? error;
  final String? message;
  final String? timestamp;

  const ApiError({
    this.status,
    this.error,
    this.message,
    this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      status: json['status'] as int?,
      error: json['error'] as String?,
      message: json['message'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'error': error,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
