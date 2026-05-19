# 🔒 Seguridad — VRM Atomic Camera

> Generado por SETUP v3.2. Fuente: código real en `D:\Develop\Personal\vrm`. Nada inventado.
> **Carga condicional:** cuando el paso toca autenticación, autorización, RLS, permisos o acceso a DB.

## Autenticación

- **Patrón:** ❌ No existe. MVP es 100% offline/single-user sin login.
- **Librería:** Ninguna. `auth_library` = `null` en proyecto-config.json.
- **Flujo:** No aplica.
- **NUNCA:** Agregar autenticación sin definir modelo de datos de usuario y backend.

## Autorización

- **Patrón:** ❌ No existe. Sin roles, sin permisos, sin guards.
- **Granularidad:** No aplica.
- **Cómo se protege un endpoint nuevo:** No aplica — no hay backend desplegado ni endpoints protegidos.

## RLS (Row Level Security)

- **¿Existe?:** ❌ No. No hay base de datos SQL. Persistencia = JSON en filesystem local.
- **Patrón real:** No aplica.
- **Variable usada:** No aplica.
- **Cast aplicado:** No aplica.
- **TODA tabla nueva debe tener RLS:** ❌ No aplica.

## Variables Sensibles

- **Almacenamiento:** `backend/.env.example` para variables de entorno del backend (OpenAI API key, etc.). Android keystore en `android/vrm-release-key.jks`, passwords en `android/key.properties`.
  - **Evidencia:** `backend/.env.example`, `android/key.properties:1-2`, `.gitignore` (cubre `*.jks`, `*.keystore`, `/android/key.properties`)
- **Acceso en código:** `os.getenv` en Python (backend). `key.properties` leído por Gradle en build.
- **NUNCA:** hardcodear secrets, logear valores de `.env`, commitear `.env` con valores reales, commitear `.jks` o `key.properties` (verificado: `.gitignore` los excluye)

## Validación de Input

- **Librería:** `json_schema: ^5.2.2` para validación de estructuras JSON. Schemas en `lib/core/schemas/`.
  - **Evidencia:** `pubspec.yaml:66`, `lib/core/schemas/`
- **Dónde se valida:** En el pipeline (`VRMPipeline.execute()`) antes de procesar. También en `PipelineFactory` al construir stages.
- **SIEMPRE validar antes de:** persistir en disco, ejecutar queries con input del usuario

## Permisos de Dispositivo

- **Librería:** `permission_handler: ^11.3.0` — `pubspec.yaml:43`
- **Permisos solicitados:** Cámara, micrófono, almacenamiento (fotos/video)
- **Flujo:** Solicitar permiso → si denegado, mostrar diálogo explicativo → si denegado permanentemente, guiar a settings del OS
- **AndroidManifest.xml** e **Info.plist** documentan el uso de cada permiso

## ⚠️ No detectado

- Rate limiting — no aplica (single-user offline)
- Cifrado de datos en reposo — JSON en filesystem sin cifrar. Aceptable para MVP (datos no sensibles)
- HTTPS / certificados — backend no desplegado. Cuando se despliegue, requerir HTTPS
- Secrets rotation — no hay mecanismo. Keystore generado una vez con validez 10000 días.
