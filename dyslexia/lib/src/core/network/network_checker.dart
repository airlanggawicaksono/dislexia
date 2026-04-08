import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

typedef EitherNetwork<T> = Future<Either<Failure, T>> Function();

class NetworkInfo {
  Future<Either<Failure, T>> check<T>({
    required EitherNetwork<T> connected,
    required EitherNetwork<T> notConnected,
  }) async {
    return connected.call();
  }

  Future<bool> get checkIsConnected async => true;

  bool get getIsConnected => true;

  // no-op setter kept for API compatibility
  set setIsConnected(bool _) {}
}
