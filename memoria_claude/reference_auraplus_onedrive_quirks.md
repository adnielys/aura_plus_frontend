---
name: reference-auraplus-onedrive-quirks
description: "El repo aura-plus-mvp está en OneDrive y eso impone restricciones: archivos no pueden borrarse via rm, SQLite con I/O errors en el mount, propagación entre Write tool y bash no es inmediata."
metadata:
  type: reference
---

El proyecto Aura+ vive en `C:\Users\kalvo\OneDrive\Documentos\Proyectos Trabajo\APK Concebir\aura-plus-mvp` (montado bajo `/sessions/<id>/mnt/aura-plus-mvp/`). Restricciones observadas:

1. **`rm` y `os.remove` fallan con "Operation not permitted"** dentro del mount. Para reemplazar contenido de un archivo, usar `cat > file <<EOF ... EOF` (overwrite vía bash) o el Write tool. Para "borrar", sobrescribir con contenido vacío o nuevo.

2. **SQLite directo en el mount → `disk I/O error`**. Usar `/tmp/aura_dev.db` para el DB de desarrollo. `.env` ya configurado así: `DATABASE_URL=sqlite+aiosqlite:////tmp/aura_dev.db`.

3. **Propagación Write tool → bash NO es inmediata** en ocasiones. Si después de un Write el archivo aparece vacío en bash, usar `cat > file <<EOF` desde bash en su lugar.

4. **pytest necesita TMPDIR=/tmp** para evitar RecursionError en limpieza de tempdirs. Comando: `TMPDIR=/tmp pytest -p no:cacheprovider --rootdir=/tmp -o cache_dir=/tmp/.pytest_cache`.

5. **PATH al instalar deps**: pip pone binarios en `/sessions/<id>/.local/bin` que no está en PATH por defecto. `export PATH="$PATH:/sessions/<id>/.local/bin"` antes de `alembic`, `uvicorn`, `pytest`.
