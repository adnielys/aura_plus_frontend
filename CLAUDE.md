# CLAUDE.md — Aura+ Frontend (Flutter)

> Léeme al iniciar cada sesión. Acompaña al backend `C:\dev\auraplus-backend`.
> Los dos repos se conectan **solo** por el contrato `openapi.yaml`. Trabaja en
> español, como senior dev / arquitecto, con clean code. Ante la duda:
> ¿esto reduce carga mental de la usuaria o la aumenta?

## Qué es esto
Frontend del MVP de Aura+ (Flutter). App de acompañamiento emocional para madres
con alta carga mental. **Aura+ no evalúa, acompaña.** El producto emocional manda
sobre la feature list.

## Filosofía que la UI DEBE respetar (no-negociable)
- El registro mismo es el logro; ninguna respuesta es incorrecta ("no fue posible" suma).
- El silencio nunca castiga. Una sola notificación al día.
- Nunca se compara con días anteriores. **Nunca** se pinta "días sin abrir",
  "racha rota", "% restante" ni `days_remaining`/`progress` (UX_06/07, GUARD_TONE_04).
- La constelación solo muestra cuánto llevas, jamás cuánto falta.

## Arquitectura (no negociable)
Feature-First + Clean Architecture. Riverpod (estado) · GoRouter (navegación) ·
Dio (HTTP) · flutter_secure_storage (tokens) · shared_preferences (flags).

```
lib/
├── main.dart                    ProviderScope + MaterialApp.router
├── core/
│   ├── config/app_config.dart   base URL por plataforma (#9)
│   ├── theme/                    app_colors, app_theme
│   ├── router/                   app_router (GoRouter + rutas)
│   ├── network/                  Dio client + AuthInterceptor (refresh rotado)
│   ├── error/                    Failures/excepciones tipadas
│   └── constants/
├── features/<feature>/
│   ├── data/        datasources (Dio) · models (DTO + fromJson) · repositories (impl)
│   ├── domain/      entities (puras) · repositories (abstractas)
│   └── presentation/ screens · widgets · providers (Riverpod)
└── shared/widgets/  componentes transversales reutilizables
```

Reglas:
- `domain/` es PURO: sin Dio, sin Flutter, sin JSON. Entities inmutables.
- La capa `data` desenvuelve el **envelope** `{success, data, meta}` antes de parsear (#1).
- Una feature no importa la lógica de otra; lo transversal vive en `core` o `shared`.
- El cálculo de estrellas es del SERVIDOR: el cliente nunca recalcula, solo pinta.

## 6 features → 12 pantallas
auth · onboarding · check_in (incluye Home) · session (cierre del día) ·
constellation · profile.

## Reconciliaciones contrato ↔ Dart (críticas)
Ver `docs/CONTRACT_MAPPING.md`. Resumen: envelope siempre; `CheckInResult` =
{check_in, recommendation, messages}; `SessionResult` = {session, constellation}
(no hace falta GET extra); `habit_2`/`habit_2_result` nullable (CARE/ANCHOR);
constelación sin `days_remaining`/`progress`; refresh ROTADO (guardar el par nuevo);
enums en snake_case con mapeo explícito; base URL por plataforma.

## Reglas de trabajo (cómo proceder)
1. Trabaja por **incrementos**; cada uno corre y pasa gates antes de continuar.
2. **El contrato manda.** Antes de tocar un endpoint, revisa `openapi.yaml` del backend.
3. Gates de cierre: `flutter analyze` limpio + `flutter test` verde + corrida manual
   en el emulador. No marcar "hecho" sin gates verdes.
4. Cambios pequeños y revisables. Sin reescrituras masivas sin confirmar.
5. Explica el "por qué" de cada diff; la usuaria revisa antes de aplicar y commitea.

## Roadmap (6 incrementos)
- [x] 0 — Fundamentos: estructura + pubspec + CLAUDE.md + CONTRACT_MAPPING.
- [x] 1 — Auth conectado: tema, Dio + AuthInterceptor, secure_storage, AuthRepository,
      login, splash, router por sesión. Meta: loguearse desde el emulador contra Docker.
- [x] 2 — Onboarding: tema alineado al maquetado (magenta #C01448 + serif), enums
      compartidos (shared/domain), UserProfile, OnboardingController (6 pasos en un
      PageView/AnimatedSwitcher), SelectableChip + SoftPrimaryButton, POST
      /onboarding/complete, router por AuthStatus + OnboardingStatus (splash consulta
      GET /status). Tests: mapeo de enums + validación por paso + submit.
      Pulido: [x] fuente serif Poltawski Nowy bundleada (assets/fonts). Pendiente:
      adoptar el diseño del mockup (frase continua + rosa sereno + copy EN);
      pantalla de registro (hoy se registra vía Swagger); microcopy reactivo del
      paso 4 + pantalla final de contrato emocional (SPEC_CONTENIDO_EMOCIONAL_V2 §3).
      Check-in = solo energía (5 niveles); las 15 emociones fuera del MVP.
      Ciclo menstrual: APLAZADO.
- [ ] 3 — Check-in + Home (POST /check-in → CheckInResult, HomeScreen con HabitCard×2).
- [ ] 4 — Cierre del día (DayCloseScreen, POST /session, ClosingMessageCard, celebración).
      Incluye SupportBridgeCard para message_type `support_bridge` (SPEC V2 §2):
      tarjeta suave tras el cierre normal, nunca lo sustituye; parser tolerante a
      tipos de mensaje desconocidos.
- [ ] 5 — Constelación (ConstellationWidget CustomPainter, GalaxyScreen, CelebrationScreen).
      Incluye CycleCloseFlow (SPEC V2 §1): GET /constellation/closing al entrar,
      3 pantallas (contemplar → significado + reflexión opcional → transición),
      closing-ack idempotente. El widget soporta stars_earned > stars_max.
- [ ] 6 — Perfil + FCM + cola offline + pulido.

## Backend (para conectar)
Local prod-parity: `docker compose up --build -d` en `C:\dev\auraplus-backend`
→ `http://localhost:8000`, Swagger en `/docs`, `/health` da 200. Auth Bearer JWT.

## Fuera del MVP de frontend
`/care/*` (no hay pantallas de cuidado en esta spec). Pilar 2 y 3 Carril A: futuro.

## Comandos
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Correr (emulador, lo hace la usuaria): `flutter run`
- Dispositivo físico: `flutter run --dart-define=API_BASE_URL=http://<IP-LAN>:8000`

## Fuentes de verdad
`docs/HANDOFF_AURAPLUS.md` (en el repo MVP) y `openapi.yaml` del backend. Ante
conflicto entre intuición y contrato/tests, gana el código testeado del backend.
