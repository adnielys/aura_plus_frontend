# SPEC — Contenido Emocional V2 (Frontend)

> Espejo de `C:\dev\auraplus-backend\docs\SPEC_CONTENIDO_EMOCIONAL_V2.md`.
> Cierra los huecos psicológicos del lado UI. El contrato manda: los endpoints
> nuevos deben existir en `openapi.yaml` del backend antes de consumirlos.
> Documento de diseño asociado: `Revision_Mockups_Guia_Disenador.md` (proyecto Aura+).

## Alcance frontend

| # | Hueco | Solución frontend | Fase del roadmap |
|---|---|---|---|
| 1 | Cierre de ciclo | `CycleCloseFlow` (3 pantallas + reflexión opcional) | 5 (constelación) |
| 2 | "Al límite" recurrente | Render del mensaje `support_bridge` como tarjeta suave | 4 (cierre del día) |
| 5 | Onboarding sin reflejo | Microcopy reactivo + pantalla final de contrato emocional | 2 (pulido pendiente) |

Los huecos 3 y 4 (variantes y psicoeducación) son solo datos del backend: el
frontend ya pinta lo que el servidor manda, sin cambios.

---

## 1. CycleCloseFlow (Fase 5)

### 1.1 Disparo

- Al abrir la galaxia (y opcionalmente al arrancar la app tras login):
  `GET /constellation/closing`.
  - 404 `no_pending_closing` → flujo normal, sin ceremonia.
  - 200 → navegar a `CycleCloseFlow` con `{constellation, messages}`.
- El flujo NO es bloqueante: botón discreto "Ahora no" en la pantalla 1 pospone
  (no hace ack; reaparecerá la próxima vez).

### 1.2 Las 3 pantallas (un `PageView`, transiciones suaves)

**Pantalla 1 — Contemplar.** La constelación cerrada completa (mismo
`ConstellationWidget` de la galaxia, modo contemplación: sin contadores, sin
posiciones vacías destacadas) + `messages.intro`. CTA: "Seguir" · "Ahora no".

**Pantalla 2 — Significado.** Solo texto: `messages.meaning`, centrado, tipografía
serif grande, fondo cielo. Debajo, la reflexión opcional de un toque:

> "¿Qué fue lo que más te sostuvo este ciclo?"
> Chips: `Los momentos para mí` · `Mi gente` · `Lo pequeño de cada día` · `Prefiero solo cerrar`

- Chip elegido (≠ "Prefiero solo cerrar") → `POST /constellation/{id}/reflection`
  con el anchor mapeado (`self_moments` | `my_people` | `small_daily`).
- "Prefiero solo cerrar" NO llama a nada y avanza con la misma animación y la
  misma dignidad visual que las otras opciones (regla de tono: saltar no es la
  opción mala).

**Pantalla 3 — Transición.** `messages.transition` + botón primario
**"Abrir mi nuevo cielo"** → `POST /constellation/{id}/closing-ack` → navegar a
la galaxia con la constelación nueva (el rollover ya ocurrió en el servidor).

### 1.3 Reglas de tono en UI (heredan GUARD_TONE_03/04 + GUARD_CYCLE_01)

- Jamás mostrar: nº de días sin registrar, % de ciclo, comparación con ciclos
  anteriores, "X de 28 días".
- `stars_earned` puede superar `stars_max`: el widget debe soportarlo (estrellas
  extra orbitan/brillan alrededor del dibujo, nunca un contador "9/9 + 3").
- La ceremonia es visualmente idéntica en calidez para 1 estrella que para 40.

### 1.4 Estado y errores

- Provider Riverpod `cycleClosingProvider` (Future del endpoint, invalidado tras ack).
- Error de red en `/closing` → silencio (flujo normal); la ceremonia no compite
  con el uso diario. Error en ack → reintento silencioso al próximo arranque
  (el backend es idempotente).

---

## 2. Tarjeta de mensaje puente (Fase 4)

`SessionResult` incluye un campo **`support_bridge: String?`** (string ya
resuelto, mismo estilo que `closing_message`). Solo viene poblado en la
respuesta del `POST /session` que cierra el día; en GET y doble cierre es null.

- Si es no-null, se pinta DESPUÉS del mensaje de cierre normal, nunca en su lugar.
- Widget: `SupportBridgeCard` — tarjeta con fondo más cálido (rosa sereno),
  icono suave (nunca alerta/advertencia), el texto del servidor tal cual.
- Sin botones de acción en el MVP (no hay directorio de ayuda): es un mensaje,
  no un flujo. Se cierra con el mismo gesto que el resto del cierre del día.
- Prohibido añadir en cliente: contadores, "hemos notado que...", enlaces externos.

---

## 3. Onboarding: reflejo emocional (Fase 2 — pulido)

### 3.1 Microcopy reactivo en el paso 4 ("¿Qué es lo que más pesa ahora?")

Al seleccionar un chip aparece una línea de reflejo (AnimatedSwitcher, texto
secundario bajo los chips). Strings locales del cliente (no vienen del backend):

| Selección | Línea |
|---|---|
| El trabajo | Cuando el trabajo lo llena todo, un espacio tuyo se vuelve más necesario, no menos. |
| Mi familia y hogar | Sostener un hogar es trabajo invisible. Aquí sí se ve. |
| Yo misma | Que aparezcas tú en la lista ya es un buen comienzo. |
| Mis relaciones | Los vínculos también se cansan. Vamos poco a poco. |
| Todo a la vez | Cuando todo pesa a la vez, empezar por algo mínimo no es poco: es lo sensato. |

Ubicación sugerida: `features/onboarding/presentation/widgets/pain_reflection.dart`
con un mapa `MainPain → String` (constante, testeable).

### 3.2 Pantalla final del onboarding (contrato emocional)

Tras el paso 6 y antes del submit (o como estado de éxito del submit):

> "Eso es todo lo que necesito, {name}. Aquí no hay metas que cumplir ni nada
> que demostrar. Empezamos cuando quieras."

Botón único: **"Entrar a mi espacio"**.

### 3.3 Tests

- Mapa `MainPain → línea` completo (5/5) y sin strings vacíos.
- La línea cambia al cambiar la selección.
- Flujo de cierre: chip de reflexión dispara el POST correcto; "Prefiero solo
  cerrar" no dispara red; ack navega a galaxia.

---

## 4. CONTRACT_MAPPING — reconciliación nueva (#11)

Añadir a `docs/CONTRACT_MAPPING.md` cuando el backend publique el contrato:

- `GET /constellation/closing` → `CycleClosing = {constellation, messages{intro, meaning, transition}}`; 404 = no hay ceremonia (caso normal, no error de UX).
- `POST /constellation/{id}/closing-ack` → sin body, idempotente.
- `POST /constellation/{id}/reflection` → `{anchor}` en snake_case
  (`self_moments` | `my_people` | `small_daily`), mapeo explícito de enum como
  siempre (nunca `.name`).
- `SessionResult.support_bridge: String?` — campo nuevo, nullable. El
  `fromJson` de `SessionResult` debe tolerar su ausencia (backend viejo) y
  cualquier campo desconocido futuro (parser tolerante).
