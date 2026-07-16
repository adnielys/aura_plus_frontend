import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/core/storage/token_storage.dart';
import 'package:aura_plus/main.dart';

/// TokenStorage en memoria: evita depender del keystore real en los tests.
class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage() : super(const FlutterSecureStorage());

  String? _access;
  String? _refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => _access;

  @override
  Future<String?> readRefresh() async => _refresh;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  testWidgets('Arranca y, sin sesión, aterriza en el login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => _FakeTokenStorage()),
        ],
        child: const AuraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign in'), findsOneWidget);
  });
}
