import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../data/datasources/session_remote_data_source.dart';
import '../../data/models/session_result_model.dart';
import '../../data/pending_close_store.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/session_result.dart';
import '../../domain/repositories/session_repository.dart';

/// Inyección del repositorio de cierre del día.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(SessionRemoteDataSource(ref.watch(dioProvider)));
});

/// Inyección del almacén del cierre pendiente (cola offline).
final pendingCloseStoreProvider = Provider<PendingCloseStore>((ref) {
  return PendingCloseStore();
});

/// true = hay un cierre de HOY esperando red (la celebración lo pinta en
/// diferido, sin estrellas: las pone el servidor al sincronizar).
final pendingCloseProvider = FutureProvider<bool>((ref) async {
  final pending = await ref.watch(pendingCloseStoreProvider).load();
  return pending != null && !pending.isStale(DateTime.now());
});

/// Cómo terminó el intento de cerrar el día.
enum CloseOutcome {
  /// El servidor lo tiene: celebración normal con estrellas.
  closed,

  /// Sin red: quedó guardado en el teléfono y se reintenta en silencio.
  savedOffline,

  /// Error de negocio (no de red): la UI muestra el snackbar sin culpa.
  failed,
}

/// Cierre de hoy según el SERVIDOR (`GET /session/today`): null = día abierto.
/// A diferencia del estado en memoria del cierre, sobrevive reinicios de la
/// app; Home lo usa para pintar la opción elegida TACHADA.
final todaySessionProvider = FutureProvider<DailySession?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<Object?>('/session/today');
    return DailySessionModel.fromJson(unwrapEnvelope(response.data) as Map);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  } on ApiException catch (e) {
    if (e.httpStatus == 404) return null;
    rethrow;
  }
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

  /// Cierra el día. Con red -> [CloseOutcome.closed] (o ya lo estaba:
  /// GUARD_SESSION_01 devuelve la existente). SIN red -> el registro no se
  /// pierde: queda guardado y se reintenta en silencio ([savedOffline]).
  Future<CloseOutcome> closeDay({
    required HabitResult habit1Result,
    HabitResult? habit2Result,
    HabitResult? habit3Result,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.close(
        habit1Result: habit1Result,
        habit2Result: habit2Result,
        habit3Result: habit3Result,
        reflection: reflection,
      );
      state = AsyncData(result);
      return CloseOutcome.closed;
    } on NetworkFailure {
      await ref.read(pendingCloseStoreProvider).save(
            PendingClose(
              date: DateTime.now(),
              habit1Result: habit1Result,
              habit2Result: habit2Result,
              habit3Result: habit3Result,
              reflection: reflection,
            ),
          );
      ref.invalidate(pendingCloseProvider);
      state = const AsyncData(null);
      return CloseOutcome.savedOffline;
    } on Failure catch (failure) {
      state = AsyncError(failure, StackTrace.current);
      return CloseOutcome.failed;
    }
  }

  /// Reintento SILENCIOSO del cierre pendiente (al arrancar y al volver al
  /// Home). Devuelve true si algo entró al servidor (para refrescar la UI).
  ///
  /// - Fecha vieja -> se descarta sin aviso (el silencio nunca castiga).
  /// - Error de negocio (4xx) -> también se descarta: GUARD_SESSION_01 hace
  ///   que "ya estaba cerrado" responda 200, así que un 4xx real significa
  ///   que ese cierre ya no puede entrar.
  /// - Sin red todavía -> se conserva y se reintentará después.
  Future<bool> retryPendingClose() async {
    final store = ref.read(pendingCloseStoreProvider);
    final pending = await store.load();
    if (pending == null) return false;
    if (pending.isStale(DateTime.now())) {
      await store.clear();
      ref.invalidate(pendingCloseProvider);
      return false;
    }
    try {
      final result = await _repository.close(
        habit1Result: pending.habit1Result,
        habit2Result: pending.habit2Result,
        habit3Result: pending.habit3Result,
        reflection: pending.reflection,
      );
      await store.clear();
      state = AsyncData(result);
      ref.invalidate(pendingCloseProvider);
      return true;
    } on NetworkFailure {
      return false; // sigue sin red: el borrador espera
    } on Failure {
      await store.clear();
      ref.invalidate(pendingCloseProvider);
      return false;
    }
  }
}
