---
name: auraplus-project
description: Estado del MVP Aura+ (backend FastAPI + frontend Flutter) y specs de contenido emocional
metadata:
  type: project
---

Aura+ = MVP de acompañamiento emocional para madres con alta carga mental ("no evalúa, acompaña"). Repos actuales: backend `C:\dev\auraplus-backend` (FastAPI), frontend `C:\dev\aura_plus` (Flutter), conectados solo por openapi.yaml. (El repo viejo aura-plus-mvp en OneDrive quedó como referencia de diseños/docs.)

Estado a 2026-07-10 (auditado):
- Backend: incrementos 1–6 construidos (motores, persistencia, check-in, session, patrones, FCM, cron, guards 19/19, Docker) + Pilar 3 Carril B (care_network B-1 + care B-2). Pendiente: deploy staging, incremento 7 (Contenido Emocional V2) e incremento 8 (cierre de atención care B-3). Había cambios sin commitear.
- Frontend: fases 0–2 (auth + onboarding + home placeholder). Fases 3–6 sin empezar.

Specs escritas tras revisión psicológica del contenido (2026-07-10):
- `auraplus-backend/docs/SPEC_CONTENIDO_EMOCIONAL_V2.md` — ceremonia cierre de ciclo, patrón HARD_RECURRING + support_bridge (campo nullable en SessionResult, NO lista messages), seed upsert + variantes, guards 20–23.
- `auraplus-backend/docs/SPEC_CARE_CIERRE_ATENCION_B3.md` — estados closed/archived, close_outcome voluntario, CARE_CLOSE neutral al resultado, GUARD_CARE_09.
- `aura_plus/docs/SPEC_CONTENIDO_EMOCIONAL_V2.md` + CONTRACT_MAPPING #11.
- Proyecto "Aura +" (OneDrive): Revision_Psicologica_Contenido.md, Revision_Mockups_Guia_Disenador.md, PLAN_PROMPTS_CLAUDE_CODE.md (secuencia B0–B5, F0–F3 para Claude Code).

Marco de producto para care: continuidad de acompañamiento — derivar sin abandonar, recibir de vuelta sin interrogar; el episodio lo cierra la usuaria, archivado silencioso, care jamás en push. Ver [[auraplus-frontend]].

Decisión de producto clave (constelación): la usuaria eligió la "Opción 3 — cierre por ciclo": `is_complete` por FECHA (28 días desde start_date), stars_max=9 son solo posiciones visuales, estrellas ilimitadas. Descartó el MVP literal (inflación gamificada) y stars_max≈100 (rompía GUARD_TONE_04). Ya blindado en el CLAUDE.md del backend.

Artefactos de diseño/specs (Pilar 3 Cuidado, sesión 2026-07):
- `aura-plus-mvp/docs/AuraPlus_Backend_Specs_Pilar3_Cuidado.docx` y `AuraPlus_Frontend_Specs_Pilar3_Cuidado.docx` (también copias en `auraplus-backend/docs/`): motor `evaluate_care_signal()` (3 ejes, ventana 14d), instrumentos PHQ-2/GAD-2/EPDS, guards CARE_01-08. Umbrales (12/7/14 días) PROVISIONALES hasta calibración clínica; números de crisis (112, Telefonseelsorge, 024) son ejemplos a confirmar por país.
- `aura-plus-mvp/frontend/mockups_pilar3_cuidado.html` — 6 pantallas de Cuidado (misma estética que `mockups_v3_showcase.html`, que tiene las 15 pantallas del MVP).
- `aura-plus-mvp/docs/AuraPlus_Propuesta_Ciclo_Completo.pdf` (+ Word en carpeta "Aura +").

Despliegue en tiendas: ver [[auraplus-despliegue-tiendas]]. Entorno de build: ver [[auraplus-entorno-flutter]].
