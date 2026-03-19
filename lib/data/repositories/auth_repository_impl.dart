import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl({required AuthDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, String>> signUp(
      String username, String password) async {
    try {
      final id = await _dataSource.signUp(username, password);
      return Right(id);
    } catch (e, st) {
      debugPrint('[AuthRepository] signUp error: $e\n$st');
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signIn(
      String username, String password) async {
    try {
      final id = await _dataSource.signIn(username, password);
      return Right(id);
    } catch (e, st) {
      debugPrint('[AuthRepository] signIn error: $e\n$st');
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e, st) {
      debugPrint('[AuthRepository] signOut error: $e\n$st');
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<String?> getCurrentUserId() => _dataSource.getCurrentUserId();
}
