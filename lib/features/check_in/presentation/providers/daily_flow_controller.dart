import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../data/datasources/check_in_remote_data_source.dart';
import '../../data/repositories/check_in_repository_impl.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/repositories/check_in_repository.dart';

/// Inyección del repositorio de check-in.
final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepositoryImpl(CheckInRemoteDataSource(ref.watch(dioProvider)));
});

/// El día de hoy: `null` = aún sin check-in (Home invita a hacerlo);
/// con valor = check-in + recomendación listos para pintar.
final dailyFlowProvider =
    AsyncNotifierProvider<DailyFlowController, CheckInResult?>(
  DailyFlowController.new,
);

class DailyFlowController extends AsyncNotifier<CheckInResult?> {
  CheckInRepository get _repository => ref.read(checkInRepositoryProvider);

  @override
  Future<CheckInResult?> build() => _repository.today();

  /// Registra el estado de hoy. Devuelve true si quedó registrado (o ya
  /// existía: GUARD_CHECKIN_01 lo trata como éxito).
  Future<bool> submit(EmotionalState emotionalState) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.submit(emotionalState);
      state = AsyncData(result);
      return true;
    } on Failure catch (failure) {
      state = AsyncError(failure, StackTrace.current);
      return false;
    }
  }

  /// Refresca el día (p. ej. al volver al Home).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.today);
  }

  /// Sustituye el hábito del `slot` por otro del banco (cambia CUÁL, nunca
  /// CUÁNTOS). Devuelve null si quedó aplicado; si no, el mensaje sin culpa
  /// del servidor para el snackbar.
  Future<String?> swapHabit({required int slot, required String habitId}) async {
    try {
      final result =
          await _repository.swapHabit(slot: slot, habitId: habitId);
      state = AsyncData(result);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    }
  }
}
