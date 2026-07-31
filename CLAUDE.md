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
      Pulido: [x] fuente serif Poltawski Nowy bundleada (assets/fonts) · [x] diseño
      del mockup (frase continua + copy EN) · [x] CONTRATO EMOCIONAL (SPEC V2 §3,
      textos aprobados jul 2026): reflejo del paso 4 con AnimatedSwitcher (mapa
      testeable en widgets/pain_reflection.dart) + pantalla final "That's all I
      need, {name}" → "Enter my space ✦" (submit NO marca completo; lo hace
      enterSpace). Check-in = solo energía (5 niveles); las 15 emociones fuera
      del MVP. Ciclo menstrual: HECHO (Bloque 3, ver sección Mi ciclo).
- [x] 3 — Check-in + Home (POST /check-in → CheckInResult, HomeScreen con HabitCard×2).
- [x] 4 — Cierre del día (DayCloseScreen, POST /session, ClosingMessageCard, celebración).
      Incluye SupportBridgeCard para message_type `support_bridge` (SPEC V2 §2):
      tarjeta suave tras el cierre normal, nunca lo sustituye; parser tolerante a
      tipos de mensaje desconocidos.
- [x] 5 — Constelación: pestaña + CycleCloseFlow (SPEC V2 §1, con retrospectiva
      2.5) + My sky con las 20 piezas REALES del diseñador por ciclo (imageAsset
      derivado del cycle_number; los nombres históricos quedan congelados, por
      eso en cuentas de prueba renombradas puede no coincidir nombre↔dibujo —
      en cuentas nuevas siempre coincide).
- [x] 6 — Perfil + voz de Aura + Mi ciclo + Círculo + notificación local.
      Cola offline del cierre: HECHA. Recuperación de contraseña: HECHA.
      Pendiente real: prueba en dispositivo físico (ver mapa_flujos_aura.html).

## Backend (para conectar)
Local prod-parity: `docker compose up --build -d` en `C:\dev\auraplus-backend`
→ `http://localhost:8000`, Swagger en `/docs`, `/health` da 200. Auth Bearer JWT.

## Acompañante (companion) — YA EN LA APP (jul 2026)
features/companion/: la conversación con Aura NO es una pestaña — es una
puerta siempre abierta + dos momentos. CompanionDoor: frase al pie del
Home ("Do you want to tell me something? / I'm here, no rush"), SIN badge,
SIN contador, y Aura JAMÁS inicia (un chat con puntito rojo sería una
tarea pendiente más, y la app promete un mensaje al día). CompanionInvite:
solo tras check-in hard/exhausted. Ambas desaparecen si el servidor tiene
la flag apagada (404 -> nada, nunca una promesa vacía). En la pantalla:
Aura en SERIF (su voz de los cierres), ella en sans; el chip de
suggested_action lo manda el SERVIDOR y se pinta como invitación, jamás
como orden. Decisión de producto: NO va en la pestaña Cycle (es opt-in, o
sea invisible para quien más lo necesita; y sus temas no son del ciclo).

## My sky · historia del ciclo — YA EN LA APP (jul 2026)
Tocar un ciclo YA cerrado en la galaxia abre su relato (bottom sheet con
la estética nocturna de la tarjeta): "YOUR CYCLE, AS A STORY" + arte +
fechas/presencia/✦ + renglones de la retrospectiva (mismos iconos del
paso 2.5) + cierre + su reflexión anclada. cycleStoryProvider.family
sobre GET /constellation/{id}/story — el servidor lo regenera
determinista (releer jamás cambia el texto ni avanza rotaciones). El
ciclo ACTUAL no es tappable: aún se escribe.

## Cola offline del cierre — YA EN LA APP (jul 2026)
El registro jamás se pierde por la red. Si POST /session falla por RED
(NetworkFailure, no validación), el cierre se guarda en shared_preferences
(PendingCloseStore, máx 1) y la celebración va en DIFERIDO: mismo ritual,
copy aprobado ("Your day is saved with me…"), chip "Waiting for
connection", SIN estrellas (GUARD_STAR_02) y sin botón a la constelación.
Reintento SILENCIOSO al arrancar y al entrar al Home (initState); entra ->
las estrellas aparecen con normalidad (GUARD_SESSION_01 lo hace
idempotente). Un pendiente solo vale SU día: fecha vieja o 4xx -> se
descarta sin aviso (el silencio nunca castiga). closeDay devuelve
CloseOutcome {closed|savedOffline|failed}. OJO verificación: el reintento
del Home puede caer antes de que la red del emulador esté lista — el del
arranque lo recoge.

## Tercer hábito con 30+ — YA EN LA APP (jul 2026)
El máximo diario sube a 3 SOLO si ella declaró "Some time (30 min+)" y su
estado es positivo (el servidor decide; el cliente solo pinta). Contrato:
`habit_3`/`habit_3_result` nullables (mismo patrón que habit_2).
`Recommendation.habits` = [h1, ?h2, ?h3]: Home y Reco pintan N tarjetas sin
tocar el layout; el cierre manda `habit_3_result`; el ⇄ acepta slot 3 y el
sheet recibe `others` (lista) — el sustituto no comparte área con ninguno.
El pill del Reco tiene variante "Three small gestures, in 3 areas".

## Care (Pilar 3 · Carril B · Etapa 1) — YA EN LA APP
`features/care/`: fila CUIDADO en el perfil (A1) + directorio (A2) + consentir
y pedir (A3) + petición enviada (A4) + respuesta recibida (A5/A5b) + episodio
y cierre B-3 (A6). Verde sereno #3E7C7B (AppColors.careAccent), clínico lila.
Reglas: provider_response es PARALELO (jamás mueve su status); el contacto del
profesional solo llega con accepted; polling suave al entrar (initState
invalida careCurrentReferralProvider) — care JAMÁS llega por push
(GUARD_CARE_09). Vista única gobernada por resolveCareView (testeada).

## Hábitos propios: editar/retirar — YA EN LA APP (jul 2026, decisiones A+B)
Menú ⋮ SOLO en los suyos (catálogo): "Edit" únicamente si visibility ==
private (decisión B; un compartido no se edita: se retira y se crea otro)
y "Retire" siempre. Editar reusa HabitCreateScreen en MODO EDICIÓN
(HabitCreateArgs.edit: prefill, sin palanca de compartir, botón "Save
changes", PATCH /habits/{id}). Retirar: diálogo sereno ("Retire this
gesture? It leaves the bank and Aura won't suggest it again. Every day
you lived it stays in your story." · Keep it / Retire) -> DELETE — sale
del banco de TODAS (decisión A) y los gestos pasados quedan intactos.

## Hábitos v2 — YA EN LA APP
Catálogo con buscador (texto + chips de área, `filterCatalog` testeado) y
badges "tuyo" / "tuyo · en revisión". Crear el propio: HabitCreateScreen
(H2/H3) — privado o compartido al banco común (pending_review hasta que el
admin publique; el rechazo NO existe como evento). Desde el ⇄: fila "Crear
uno nuevo para este hueco" (área fija + duración ≤ presupuesto, sustituye
directo vía HabitCreateArgs). El catálogo refetchea al entrar (initState
invalida habitsCatalogProvider).

## Mis áreas — YA EN LA APP
Fila "Mis áreas" del perfil → AreasScreen (contemplativa, JAMÁS dashboard:
sin %, sin metas, sin "te falta"): 4 tarjetas con las definiciones EXACTAS
del Documento Maestro §06 + presencia del ciclo (misma luz del Home) +
"Lo que más te pesa ahora" (main_pain editable, un tap = PATCH /profile).
Tocar un área → AreaGesturesScreen (M3): gestos REGISTRADOS de 28 días con
resultado en dignidad (Lo hice/A medias/No fue posible) y salida secundaria
al banco filtrado. Fechas cercanas via shared/utils/dates.dart (hoy/ayer/N de mes).

## Exportar historia — YA EN LA APP (jul 2026)
Botón "Export my story ✦" al pie de Historia: GET /session/export
(text/plain, ResponseType.plain — SIN envelope) y hoja de compartir del
sistema vía share_plus (texto directo, sin archivos temporales: ella
decide dónde guardarlo). Formato diario elegido por recomendación;
PDF/JSON evolucionables encima. El servidor compone TODO (textos exactos
persistidos); el cliente solo comparte.

## Historia v2 — YA EN LA APP
Lista viva (V1): color del estado por día (barrita interna — OJO: un borde
izquierdo grueso NO convive con borderRadius en Flutter), nº de gestos,
grupos Esta semana / Antes (groupHistory, testeado), español. Tocar un día →
HistoryDayScreen (V2): hero del estado, gestos con resultado en dignidad,
"Lo que Aura te dijo esa noche" (texto EXACTO persistido) y "Tu palabra"
(reflection) si existe. Nada editable: la memoria no se retoca.

## Notificación diaria — LOCAL (sin Google)
La cuenta Google del proyecto está restringida por territorio: FCM queda
DORMIDO (integración tolerante: se activa sola al soltar google-services.json
en android/app/ y el service account en el backend). La diaria del MVP va por
flutter_local_notifications: ventana de 14 días a preferred_time, copy
rotatorio sereno (core/notifications/local_daily_notifications.dart), se
reprograma en cada arranque y cambio de ajustes, se cancela al logout.
Alarmas INEXACTAS (sin permiso especial); sobrevive reinicios (BootReceiver).

## Bloque 2 (quick wins) — YA EN LA APP · PREMIUM EXCLUIDO
Premium quedó FUERA del producto (decisión jul 2026): sin fila "Go Premium",
sin gating — todo para todas. Q1 My sky: GalaxyScreen rediseñada (cards de
cielo nocturno con fechas, days present, ✦ y reflexión; actual con NOW);
entrada "View my sky ✦" en la pestaña constelación. Q3 Historia total:
historyProvider pagina con before/limit (fetchHistoryPage), scroll infinito,
grupos THIS WEEK/mes (groupHistoryMonths, testeado; año solo si distinto).
Q4 voz de Aura: MessageStyle (warm|brief|why) en enums + perfil; pantalla
"How Aura speaks to you" (selector con ejemplos, un tap = PATCH); fila en
SETTINGS. Q2 retrospectiva: paso 2.5 del CycleCloseFlow ("YOUR CYCLE, AS A
STORY", renglones con emoji por key presence/area/hard_days/stars + cierre);
tolerante: sin bloque `retrospective` del servidor, el paso no existe.

## Mi ciclo (Bloque 3) — YA EN LA APP · GRATIS
features/cycle/: tab Cycle real (sustituyó el COMING SOON). C1 invitación
opt-in (3 puertas; posparto/lactancia = primera ciudadana; nota 🔒) → C1b
mínimos (fecha con "Not sure" + regularidad — irregular/not_sure son
respuestas completas) → C2 estación interior (winter=hecho, resto "may" +
"An estimate, never a verdict") con "My period started today" → C4 ajustes
(chip toggle, pausar, "Erase all my cycle data" con confirmación = hard
delete). C3: chip discreto en Home (_SeasonChip) solo si tracking + señal +
show_chip. El dato JAMÁS va en push ni compartido (guards en el servidor).

## Círculo de Apoyo (Bloque 4) — YA EN LA APP · GRATIS
features/circle/: fila "My circle" en CARE del perfil → una pantalla con 3
caras (S1 intro con "They would see"/"never see" usando el ESPEJO real, S2
invitar con consentimiento informado, S3 gestión: miembros, Remove
inmediato y silencioso, espejo semanal, pausa D3 de un toque). El miembro
ve una página WEB en inglés (sin app): resumen agregado semanal — jamás
palabras ni día a día; revocado/vencido/pausado = la misma página neutra.
Antivigilancia inversa: la app jamás muestra si abrieron el enlace.

## Idioma de la UI — INGLÉS (unificado)
Toda la copy visible de la app está en inglés (decisión de producto).
Los COMENTARIOS del código siguen en español (convención del repo). Los
MENSAJES EMOCIONALES del servidor (cierres, ceremonia, CARE_CLOSE — SPEC
V2) siguen en español: traducirlos es tocar copy de producto aprobado y
espera decisión aparte, igual que el email al profesional y las páginas P2.

## Fuera del MVP de frontend
Pilar 2 y 3 Carril A: futuro. Carril B Etapa 2 (mensajería async): requiere
revisión legal + redefinir GUARD_CARE_09 — ver diagrama_carril_b_flujo.html.

## Comandos
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Correr (emulador, lo hace la usuaria): `flutter run`
- Dispositivo físico: `flutter run --dart-define=API_BASE_URL=http://<IP-LAN>:8000`

## Fuentes de verdad
`docs/HANDOFF_AURAPLUS.md` (en el repo MVP) y `openapi.yaml` del backend. Ante
conflicto entre intuición y contrato/tests, gana el código testeado del backend.
