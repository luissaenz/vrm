# 🧠 PROCESO DE ANÁLISIS TÉCNICO (ANALISTA) v5.2 — UNIFICADO

### 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | Directorio `assets/store/screenshots` existe | `ls assets/store/screenshots` | ✅ | Directorio contiene 5 imágenes |
| 2 | Imágenes cumplen resolución 1080x1920+ | `dart run scripts/store_prep_cli.dart check` | ❌ | Falla: Resolución insuficiente en los 5 archivos |
| 3 | Script de validación `store_prep_cli.dart` | `ls scripts/store_prep_cli.dart` | ✅ | Archivo existe, L668: `dims.width >= 1080 && dims.height >= 1920` |

**Discrepancias encontradas:**
- Las capturas actuales en `assets/store/screenshots/` (ej. `step1_idea.png`) tienen una resolución inferior a 1080x1920px y fallan la validación del CLI. Deben ser reemplazadas mediante capturas desde un dispositivo real (no emulador).

---

### 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: No aplica.
- ✅ Integridad referencial: No aplica.
- ✅ RLS policies: No aplica.
- ✅ Índices necesarios: No aplica.
- ✅ Tipos de datos: No aplica. Assets binarios (.png).

---

### 2️⃣ Análisis de Código (ETAPA 2)

- ✅ Funciones/clases nuevas: No aplica. Tarea de recursos gráficos.
- ✅ Patrones: Se sigue convención de nombramiento `stepN_name.png` en carpeta `assets/store/screenshots/`.
- ✅ Modularidad: No aplica.
- ✅ Calidad: Imágenes deben mantener un aspecto claro, sin compresión con pérdida excesiva (archivos .png de alta calidad).
- ✅ Imports exactos: No aplica.

---

### 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: No aplica.
- ✅ Middleware: No aplica.
- ✅ Flujos: No aplica.
- ✅ Contratos: No aplica.
- ✅ Error handling: No aplica.

---

### 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: UX visual de cara a tiendas (App Store, Play Store) que muestran el flujo end-to-end funcional.
- ✅ Coherencia: Las imágenes deben ser representativas del MVP.
- ✅ Alineación: Bloqueante 🔴 remanente para publicación real.
- ✅ Gaps: La recolección manual de 5 screenshots puede ser propensa a error humano en resoluciones o en la ubicación física de archivos.
- ✅ **DX & Tooling (OBLIGATORIO):**

### Herramienta Propuesta: capture_store_screenshots.sh
- **Qué automatiza:** Captura 5 screenshots secuenciales directamente desde el dispositivo físico conectado vía ADB y las transfiere a la ruta correcta (`assets/store/screenshots/`) con la convención de nombres requerida, validando su resolución localmente.
- **Tipo:** script bash (ADB wrapper).
- **Cómo se usa:** `./scripts/capture_store_screenshots.sh` (Pide apretar ENTER antes de cada captura).
- **Impacto para el usuario final:** Elimina la fricción de copiar/pegar y renombrar manualmente desde el dispositivo móvil, asegurando la ruta y validando instantáneamente la resolución.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso.

---

### 5️⃣ Criterios de Aceptación

✅ [DATA] 5 imágenes PNG estáticas en carpeta de assets store.
✅ [CODE] No introduce breaking changes en el código; CLI valida las resoluciones y cantidades.
✅ [BACKEND] No aplica.
✅ [FULLSTACK] Screenshots reflejan el estado final del flujo MVP. Capturadas en dispositivo real, `store_prep_cli.dart check` pasa en verde.
✅ [DX] Herramienta `capture_store_screenshots.sh` ejecuta correctamente llamadas ADB y guarda los assets localmente.

---

### 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Screenshots rechazadas por stores | Alta | Capturas usando emulador con marcos irreales o barras de estado irregulares | Usar estrictamente dispositivo físico para capturar y asegurar limpieza de barra de estado |
| Fallo en la resolución exigida | Media | Dispositivo con menor DPI o escalado no nativo | Verificación obligatoria con `store_prep_cli.dart` (≥ 1080x1920 Android, ≥ 1284x2778 iOS) |

---

### 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Script de auto-captura ADB | `{paths.scripts}/capture_store_screenshots.sh` | Bash script: ciclo de 5 iteraciones llamando `adb shell screencap -p` y `adb pull` | — | DX | Baja | 0.5h | Ninguna | → verificar: `./scripts/capture_store_screenshots.sh --help` muestra uso |
| 1 | Capturar Pantallas (Dashboard, Script, Grabación, Revisión, Exportación) | `{paths.root}/assets/store/screenshots/step1_idea.png` a `step5_export.png` | Archivos binarios PNG, resolución >= 1080x1920 | Convención de nombres `step[N]_[desc].png` | FULLSTACK | Baja | 1.0h | Tarea 0 | → verificar: `dart run scripts/store_prep_cli.dart check` no reporta error de "Resolución insuficiente" |

**Tiempo total estimado:** 1.5 horas
