enum LoginStatus {
  success,
  pending,
  rejected,
  blocked,
  invalidCredentials,
  notFound,
  serverError,
  networkError,
}

class AuthResponse {
  final LoginStatus status;
  final String message;
  final dynamic data; // To hold token or driver object if needed

  AuthResponse({
    required this.status,
    required this.message,
    this.data,
  });
}
