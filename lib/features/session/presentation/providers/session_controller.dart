import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../data/datasources/session_remote_data_source.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/session_result.dart';
import '../../domain/repositories/session_repository.dart';

/// Inyección del repositorio de cierre del día.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(SessionRemoteDataSource(ref.watch(dioProvider)));
});

/// El cierre de hoy: `null` = día aún abierto; con valor = cerrado en esta
/// sesión de app (la celebración lo pinta).
final sessionControllerProvider =
    NotifierProvider<SessionController, AsyncValue<SessionResult?>>(
  SessionController.new,
);

class SessionController extends Notifier<AsyncValue<SessionResult?>> {
  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  AsyncValue<SessionResult?> build() => const AsyncData(null);

  /// Cierra el día. Devuelve true si quedó cerrado (o ya lo estaba:
  /// GUARD_SESSION_01 devuelve la sesión existente).
  Future<bool> closeDay({
    required HabitResult habit1Result,
    HabitResult? habit2Result,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.close(
        habit1Result: habit1Result,
        habit2Result: habit2Result,
        reflection: reflection,
      );
      state = AsyncData(result);
      return true;
    } on Failure catch (failure) {
      state = AsyncError(failure, StackTrace.current);
      return false;
    }
  }
}
