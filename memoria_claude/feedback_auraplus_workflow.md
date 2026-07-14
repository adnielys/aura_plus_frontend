---
name: feedback-auraplus-workflow
description: "Adnielys (Aura+) prefiere respuestas concisas en español, decisiones de diseño consultadas vía AskUserQuestion antes de codificar, y arranque rápido sobre el plan ya definido en /docs/AuraPlus_Cowork_Guide.md."
metadata:
  type: feedback
---

En el proyecto Aura+ Adnielys:
- Pide arrancar directo cuando ya hay guía aprobada — "lee y arranca".
- Espera que se respete la guía como contrato (10 entidades exactas, 14 guards, 4 modos del motor).
- Prefiere respuestas en español, concisas, sin recapitular cada paso.

**Why:** Ya hizo el trabajo de planificación previa (la guía es exhaustiva). Re-discutirla es churn.

**How to apply:**
- Antes de codificar, hacer AskUserQuestion solo en decisiones que la guía deja ambiguas (ej: subset vs full catálogo, mapping de campos).
- Usar TaskCreate proactivamente para que vea progreso bloque por bloque.
- Al cerrar un bloque, dar verificación end-to-end real (curl o smoke test), no solo "todo verde".
