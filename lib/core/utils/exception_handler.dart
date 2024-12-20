import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rioko_ni/core/errors/exception.dart';
import 'package:rioko_ni/core/errors/failure.dart';

mixin ExceptionHandler {
  String get l10n => 'core.errors';
  Future<Either<Failure, T>> execute<T>(Future<T> Function() function) async {
    try {
      return Right(await function());
    } on SocketException catch (_, stack) {
      return Left(
        ConnectionFailure(
          tr('$l10n.socketException'),
          stack: stack,
        ),
      );
    } on HttpException catch (_, stack) {
      return Left(
        ServerFailure(
          tr('$l10n.httpException'),
          stack: stack,
        ),
      );
    } on FormatException catch (_, stack) {
      return Left(
        ServerFailure(
          tr('$l10n.formatException'),
          stack: stack,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, stack: e.stack));
    } on RequestException catch (e) {
      return Left(RequestFailure(e.message, stack: e.stack));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, stack: e.stack));
    } catch (e, stack) {
      return Left(RepositoryFailure('$e', stack: stack));
    }
  }
}
