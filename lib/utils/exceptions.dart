abstract class CustomException implements Exception {
  final String message;

  const CustomException(this.message);

  @override
  String toString() => message;
}

class NoLoginException extends CustomException {
  const NoLoginException(super.message);
}

class LoginExpiredException extends CustomException {
  const LoginExpiredException(super.message);
}