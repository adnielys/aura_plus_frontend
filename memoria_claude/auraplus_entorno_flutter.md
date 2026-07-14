---
name: auraplus-entorno-flutter
description: Entorno de build Flutter/Android de la usuaria — mirrors chinos, Gradle init script, emulador, adb fuera del PATH
metadata:
  type: reference
---

Entorno Windows de la usuaria para compilar el frontend Flutter de Aura+ (no está documentado en ningún repo):

- `FLUTTER_STORAGE_BASE_URL` apunta al mirror chino `https://storage.flutter-io.cn` (por bloqueos/red). Aviso "Flutter assets will be downloaded from storage.flutter-io.cn" es normal.
- Mirrors Gradle en `%USERPROFILE%\.gradle\init.d\repo-mirrors.gradle`: Aliyun (google/central/gradle-plugin/public) + `https://storage.flutter-io.cn/download.flutter.io` para el engine (`io.flutter:*`). CRÍTICO: sin `clear()` y con `RepositoriesMode.PREFER_SETTINGS` — un `clear()` rompe la resolución del engine de Flutter.
- OneDrive ralentiza el I/O de Gradle (builds de 10-14 min); por eso los repos activos viven en `C:\dev\` (ver [[auraplus-frontend]]). El proyecto viejo en OneDrive (`aura-plus-mvp/aura_v4`) sufría esto.
- Emulador: el AVD Pixel 7 + API 33 se colgaba en el logo de Google (boot infinito → error "Can't find service: package" al instalar). Solución acordada: AVD Pixel 6 + API 34 "Google APIs" (sin Play Store), RAM 2048 MB, Graphics Hardware GLES 2.0.
- `adb` no está en el PATH; usar `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` o agregarlo con setx.
- Primera build Android tarda 10-15 min incluso con mirrors; las siguientes ~60 s (cache). No cancelar aunque parezca colgada.
