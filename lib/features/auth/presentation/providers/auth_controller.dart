import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Estado de sesión que gobierna la navegación (splash → login | home).
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Estado inmutable del controlador de auth.
class AuthState {
  const AuthState({
    required this.status,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

/// Inyección del repositorio de auth a partir de la red y el almacenamiento.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(dioProvider)),
    ref.watch(tokenStorageProvider),
  );
});

/// Controlador de sesión. La UI llama a sus métodos y observa [AuthState].
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState.unknown();

  /// Restaura la sesión al arrancar (lo usa el splash).
  Future<void> restoreSession() async {
    final hasSession = await _repository.hasActiveSession();
    state = state.copyWith(
      status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login({required String email, required String password}) {
    return _submit(() => _repository.login(email: email, password: password));
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _submit(
      () => _repository.register(email: email, password: password, name: name),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  /// Ejecuta una acción de auth manejando loading y errores de forma uniforme.
  Future<void> _submit(Future<void> Function() action) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await action();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isSubmitting: false,
      );
    } on Failure catch (failure) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: failure.message,
      );
    }
  }
}
