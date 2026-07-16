# CONTRACT_MAPPING — openapi.yaml ↔ Dart

> Costura de desacople entre el frontend Flutter y el backend FastAPI. La única
> fuente de verdad del contrato es `C:\dev\auraplus-backend\openapi.yaml`. Este
> documento traduce ese contrato a la capa `data` de Dart y fija las
> reconciliaciones que evitan bugs (hoy 11). Si el contrato cambia, se actualiza aquí.

## 0. Envelope (todas las respuestas)

Éxito: `{ success: true, data: <payload>, meta?: { version, timestamp } }`
Error: `{ success: false, error: { code, message, http_status } }`

La capa `data` **desenvuelve `data`** antes de parsear el DTO. Un único helper en
`core/network` extrae `data` o lanza una `ApiFailure(code, message, httpStatus)`
desde `error`. Los `fromJson` de los modelos reciben ya el contenido de `data`.

## 1. Autenticación

| Endpoint | Request | Response (`data`) |
|---|---|---|
| `POST /auth/register` | `RegisterRequest{email, password(≥8), name(≤50)}` | `AuthTokens` |
| `POST /auth/login` | `LoginRequest{email, password}` | `AuthTokens` |
| `POST /auth/refresh` | `{refresh_token}` | `AuthTokens` (**par NUEVO**) |
| `POST /auth/logout` | `{refresh_token}` | envelope vacío |
| `DELETE /auth/account` | — (Bearer) | envelope vacío |

`AuthTokens` = `{access_token, refresh_token, token_type=bearer}`.

**Reconciliación #6 (refresh ROTADO):** `/auth/refresh` devuelve un par nuevo. El
`AuthInterceptor` DEBE guardar el par nuevo en secure_storage. Reusar el refresh
viejo dispara reuse-detection en el backend → revoca la sesión → logout forzado.
Serializar refresh concurrentes (un solo refresh en vuelo; los demás esperan).

## 2. Onboarding

| Endpoint | Payload |
|---|---|
| `GET /onboarding/status` | `data: { onboarding_completed: bool }` (o `UserProfile`) |
| `POST /onboarding/complete` | req `OnboardingData` → `data: UserProfile` |

`OnboardingData` (requeridos: `name`, `daily_time_slot`, `preferred_moment`):
`name(≤50)`, `initial_feeling: EmotionalState?`, `children_count: int≥0`,
`children_ages: [baby|small|school|teen]`, `main_pain: work|family|self|relationships|all`,
`daily_time_slot: TimeSlot`, `preferred_moment: PreferredMoment`.

## 3. Check-in + recomendación (Home)

| Endpoint | Payload |
|---|---|
| `GET /check-in/today` | `CheckInResult` o null si no hay |
| `POST /check-in` | req `{emotional_state: EmotionalState}` → `CheckInResult` |
| `GET /recommendation/today` | `CheckInResult` |

**Reconciliación #2:** `CheckInResult = { check_in, recommendation, messages }`. Parsear los 3.
- `check_in: CheckIn{id, date, emotional_state}`
- `recommendation: Recommendation{id, habit_1: Habit, habit_2: Habit?}`
- `messages: SystemMessages{start_of_day, recommendation}`
- `Habit{id, title, aura_copy, area: HabitArea, duration_minutes(≤20)}`

**Reconciliación #4:** `habit_2` es **nullable** (modo CARE/ANCHOR → null). La Home
pinta 1 o 2 `HabitCard` según venga.

**GUARD_CHECKIN_01:** repetir check-in el mismo día devuelve el existente con 200
(no es error). La UI lo trata como idempotente.

## 4. Cierre del día (Session)

| Endpoint | Payload |
|---|---|
| `GET /session/today` | `SessionResult` o null |
| `POST /session` | req `SessionCreate` → `SessionResult` |
| `GET /session/week` | `data: [WeekDay]` |

`SessionCreate` (requerido `habit_1_result`): `habit_1_result: HabitResult`,
`habit_2_result: HabitResult?`, `reflection: string?(≤200)`.

**Reconciliación #3:** `SessionResult = { session, constellation }`. La constelación
ya viene actualizada → **no hace falta un GET extra** tras cerrar el día.
- `session: DailySession{id, date, habit_1_result, habit_2_result?, reflection?, stars_earned, stars_breakdown, closing_message}`
- `stars_earned` y `stars_breakdown` los calcula el SERVIDOR. El cliente solo los muestra.

**Reconciliación #4 (de nuevo):** `habit_2_result` nullable.
`WeekDay{date, stars_earned, emotional_state?, had_session}`.

## 5. Constelación

| Endpoint | Payload |
|---|---|
| `GET /constellation/current` | `Constellation` |
| `GET /constellation/all` | `data: [Constellation]` |

`Constellation{ id, name, cycle_number, stars_earned, stars_max=9, is_complete,
is_current, completed_at?, star_positions: [StarPosition] }`.
`StarPosition{ index(1..9), is_earned, x(0..1), y(0..1) }`.

**Reconciliación #5 (la más sensible — GUARD_TONE_04):**
- `stars_earned` es **ilimitado** y append-only. El widget enciende `min(stars_earned, 9)` posiciones.
- `stars_max=9` = posiciones VISUALES del dibujo, NO un umbral de cierre.
- `is_complete` se dispara por **fecha** (start + 28 días), no por conteo.
- **NO existen** `days_remaining` ni `progress` en el contrato y **no se pintan** métricas de cuánto falta.
- `completed_at != null` → dispara `CelebrationScreen`. El servidor no manda texto eufórico.

## 6. Perfil y notificaciones

| Endpoint | Payload |
|---|---|
| `GET /profile` | `UserProfile` |
| `PATCH /profile` | `ProfileUpdate{name?, daily_time_slot?, preferred_moment?}` → `UserProfile` |
| `GET /notification-settings` | `NotificationPreference{is_enabled, preferred_time, timezone}` |
| `PATCH /notification-settings` | `NotificationPreferenceUpdate{is_enabled?, preferred_time?, timezone?, fcm_token?}` |

`UserProfile{id, name, children_count, children_ages, main_pain?, daily_time_slot,
preferred_moment, onboarding_completed}`.

**Reconciliación #8:** `NotificationPreference` de salida **NO** trae `fcm_token`
(write-only; solo se envía en el PATCH). **GUARD_TONE_03:** la API nunca devuelve
`days_missed`/`streak_broken`/`failed_days`; la UI tampoco los inventa.

## 7. Enums — snake_case ↔ Dart

**Reconciliación #7:** el contrato usa snake_case; en Dart, mapeo EXPLÍCITO (no confiar en `.name`).

| Enum | Valores (contrato) |
|---|---|
| `EmotionalState` | energy, tranquil, scattered, exhausted, hard |
| `HabitArea` | self, family, relationships, work |
| `HabitResult` | done, partial, not_possible |
| `TimeSlot` | minimal, short, medium |
| `PreferredMoment` | early_morning, morning, midday, night |

Cada enum Dart expone `toJson()/fromJson()` con el string exacto del contrato.

## 8. Red y base URL

**Reconciliación #9** (`core/config/app_config.dart`):
- Android emulador → `http://10.0.2.2:8000`
- iOS simulador / web → `http://localhost:8000`
- Dispositivo físico → IP de la LAN vía `--dart-define=API_BASE_URL=...`

Headers: `Authorization: Bearer <access_token>` en endpoints autenticados. El
`AuthInterceptor` añade el token, intercepta 401, refresca (rotado) y reintenta una vez.

## 9. Fuera del MVP de frontend

**Reconciliación #10:** los endpoints `/care/*` (providers, referral, consent) quedan
**fuera** de esta spec Flutter. No hay pantallas de cuidado en el MVP.

## 10. Contenido Emocional V2 — cierre de ciclo y mensaje puente

**Reconciliación #11** (spec: `SPEC_CONTENIDO_EMOCIONAL_V2.md`; backend
`docs/SPEC_CONTENIDO_EMOCIONAL_V2.md`). Endpoints nuevos:

| Endpoint | Payload |
|---|---|
| `GET /constellation/closing` | `CycleClosing` o **404 `no_pending_closing`** |
| `POST /constellation/{id}/closing-ack` | sin body → envelope vacío (idempotente) |
| `POST /constellation/{id}/reflection` | `{anchor}` → envelope vacío |

- `CycleClosing = { constellation: Constellation, messages: { intro, meaning, transition } }`.
- El **404 de `/closing` es flujo normal** (no hay ceremonia pendiente), no un error de UX.
- `anchor`: `self_moments | my_people | small_daily` (snake_case, mapeo explícito).
  "Prefiero solo cerrar" = **no llamar** al endpoint.
- `SessionResult` gana **`support_bridge: String?`** (string resuelto, como
  `closing_message`). Poblado solo en el POST que cierra el día; null en GET y
  doble cierre. El `fromJson` tolera ausencia del campo (backend viejo) — nunca
  romper el parseo del cierre del día.

## #12 — Escala del check-in: 5 estados cualitativos (no gradiente)

Decision: DECISION_CHECKIN_ESCALA_ESTADOS.md (2026-07-15, CERRADA). El enum del contrato
manda; la escala de bateria del maquetado (energized/steady/soso/low/empty) queda descartada.
Labels definitivos: energy=Con energia/Energized ('Lista para avanzar hoy'), tranquil=Tranquila/Steady
('En modo sostenido'), scattered=Dispersa/Scattered ('La mente va en mil direcciones'),
exhausted=Agotada/Running on empty ('Pide pausa'), hard=Al limite/At my limit ('Hoy pesa mas').
Los 5 chips con identica dignidad visual: sin orden semaforico, sin rojo, sin gradiente.
