---
name: auraplus-frontend
description: "Frontend Flutter de Aura+ vive en C:\\dev\\aura_plus (cascarón nuevo elegido por la usuaria), NO en auraplus-app que decía el handoff ni en aura_v4."
metadata:
  type: project
---

El frontend Flutter del MVP de Aura+ se construye en **`C:\dev\aura_plus`**, un proyecto
`flutter create` nuevo que la usuaria eligió porque le levanta y tiene la versión actual de
Flutter (sdk ^3.12.0). Descartados: `aura_v4` (dentro de aura-plus-mvp, tenía 20 archivos pero
se dejó) y `auraplus-app` (ruta que el handoff sugería, no se usó).

Fuente de verdad del traspaso: `docs/HANDOFF_AURAPLUS.md` en el repo MVP
(`C:\Users\kalvo\OneDrive\Documentos\Proyectos Trabajo\APK Concebir\aura-plus-mvp\docs`).
Contrato: `C:\dev\auraplus-backend\openapi.yaml`. El `RUNBOOK_FLUTTER_FRONTEND.md` que el
handoff cita NO está en las carpetas montadas.

**Prompt 0 hecho (2026-06-23):** stack en pubspec (riverpod, go_router, dio,
flutter_secure_storage, shared_preferences; firebase comentado para Fase 6), estructura
Feature-First (6 features × data/domain/presentation), `CLAUDE.md` del repo Flutter,
`docs/CONTRACT_MAPPING.md` (10 reconciliaciones), `core/config/app_config.dart` (base URL por
plataforma), `main.dart` limpio con MaterialApp.router.

**Estado 2026-07:** incrementos 0-2 hechos (auth conectado + onboarding 6 pasos con chips).
Fuente Poltawski Nowy bundleada en `assets/fonts` (reemplazó el Georgia solo-iOS) + assets del
mockup copiados. **Decisión de la usuaria — onboarding híbrido:** conservar los 6 campos del
contrato pero vestidos con el look del mockup (frase continua editable "My name is ___...",
rosa sereno, copy en inglés, welcome screen previa con welcome.png); tiempo diario y momento
preferido quedan como pasos con tarjetas (el mockup no los cubre). La "edad" que pide el
mockup NO existe en el backend → solo visual, no se envía. Siguiente: incremento 3 (check-in
+ Home).

Backend ya completo (~268 tests, 21 guards, corre en Docker/Postgres). Gates del frontend:
`flutter analyze` limpio + `flutter test` verde + corrida manual en emulador. Ver
[[auraplus-project]] y [[reference_auraplus_onedrive_quirks]] (rm bloqueado en OneDrive, pero
aura_plus está en C:\dev, no en OneDrive).
