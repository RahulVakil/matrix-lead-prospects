/// Sealed failure hierarchy matching compass_v2_mobile pattern.
/// Used with fpdart Either<Failure, T> throughout repositories.
sealed class Failure {
  const Failure();

  R when<R>({
    required R Function(String? message, int? statusCode) server,
    required R Function(String? message) network,
    required R Function(String? message) unknown,
  }) =>
      switch (this) {
        ServerFailure(:final message, :final statusCode) =>
          server(message, statusCode),
        NetworkFailure(:final message) => network(message),
        UnknownFailure(:final message) => unknown(message),
      };
}

final class ServerFailure extends Failure {
  final String? message;
  final int? statusCode;
  const ServerFailure({this.message, this.statusCode});
}

final class NetworkFailure extends Failure {
  final String? message;
  const NetworkFailure({this.message});
}

final class UnknownFailure extends Failure {
  final String? message;
  const UnknownFailure({this.message});
}
