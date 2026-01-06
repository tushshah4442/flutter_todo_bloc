// Custom Exception wrapper
class AppError implements Exception {
  final String message;

  AppError(this.message);

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  NetworkError([String message = "No Internet Connection"]) : super(message);
}

class ServerError extends AppError {
  ServerError([String message = "Server Error"]) : super(message);
}

class CacheError extends AppError {
  CacheError([String message = "Cache Error"]) : super(message);
}
