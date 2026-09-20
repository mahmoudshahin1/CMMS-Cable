/// Thrown when the user provides invalid email or password.
class InvalidCredentialsException implements Exception {
  final String message;

  const InvalidCredentialsException([
    this.message = 'بيانات الدخول غير صحيحة',
  ]);

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// Thrown when there is no internet connection or the server is unreachable.
class NetworkException implements Exception {
  final String message;

  const NetworkException([
    this.message = 'لا يوجد اتصال بالإنترنت',
  ]);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a user is authenticated but has no profile row in
/// `public.user_profiles`.
class ProfileNotFoundException implements Exception {
  final String userId;
  final String message;

  const ProfileNotFoundException({
    required this.userId,
    this.message = 'لم يتم العثور على الملف الشخصي',
  });

  @override
  String toString() => 'ProfileNotFoundException($userId): $message';
}
