import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'An unexpected server error occurred'])
    : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Failed to load cached data'])
    : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message = 'Please check your internet connection',
  ]) : super(message);
}
