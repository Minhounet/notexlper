import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base class for all use cases.
///
/// [Type] is the return type of the use case.
/// [Params] is the input parameters type.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when a use case doesn't need any parameters.
class NoParams {
  const NoParams();
}
