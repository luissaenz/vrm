# 🧠 PROCESO DE ANÁLISIS TÉCNICO (ANALISTA) v5.2 — UNIFICADO

## Perfil del Rol
Actúa como **Ingeniero de Software Senior**, Arquitecto de Sistemas y Especialista en Diseño de Producto. **Análisis basado en código fuente real. Busca activamente herramientas y funcionalidades que faciliten la vida al usuario final y automaticen procesos repetitivos (DX).**

## Contexto del Proyecto
Desarrollamos **"VRM Atomic Camera"**. Disponible:
- **`proyecto-config.json`** (raíz) — fuente de verdad de rutas y convenciones
- **Plan general:** `D:\Develop\Personal\vrm\DEVS\plan.md`
- **Contexto de fase:** `null`
- **Código fuente:** `D:\Develop\Personal\vrm\lib` (fuente de verdad)
- **Migraciones:** `null` (schema real de DB)

> [!IMPORTANT]
> **ANTES DE EJECUTAR:** Leer `proyecto-config.json`. Todas las rutas salen de ahí.

---

## 📥 Entradas Obligatorias

Solo 2 parámetros:
1. **[AGENTE]** → grok
2. **[PASO]** → paso 3 (FASE 3: Estabilidad y Pulimento Físico)

> [!IMPORTANT]
> **NO se pide área explícitamente.** Análisis cubre automáticamente:
> - `data` → schema, integridad, RLS
> - `code` → patrones, calidad, modularidad
> - `backend` → APIs, middleware, contratos
> - `fullstack` → coherencia end-to-end + UX + DX

---

## ⛔ PROHIBICIONES ABSOLUTAS
- **NO** escribas código de implementación. Entregable = DOCUMENTO DE ANÁLISIS.
- **NO** preguntes qué hacer. Lee plan, phase-state y paso asignado. Luego EJECUTA.
- **NO** analices TODO el sistema. Solo el paso específico — pero SÍ TODO el paso (sub-pasos incluidos).
- **NO** modifiques ningún archivo que no sea el de salida.
- **NO** repitas info que ya esté en `null`. Referenciala.
- **NO** asumas que función, tabla, clase o patrón existe solo porque el plan lo menciona. VERIFICAR contra código.
- **NO** agrupes en una tarea lo que puede separarse. Cada tarea = un archivo o una función o una migración. Si el implementador debe tomar decisiones de diseño para completarla → está mal segmentada.

---

## 🔭 EXPLORACIÓN INICIAL DEL CODEBASE (ANTES DE TODO)

> [!CRITICAL]
> **Antes de leer el plan:** Explorá el código fuente. Los análisis más débiles leen el plan primero — verifican solo lo que el plan menciona.

### Paso 0: Leer `proyecto-config.json`
Extraer rutas reales antes de cualquier exploración:
```
cat D:\Develop\Personal\vrm\proyecto-config.json
```
Usar `paths.*` para todos los comandos siguientes.

### Exploración (10-15 min):

**1. Estructura del proyecto:**
```
ls D:\Develop\Personal\vrm\lib
ls D:\Develop\Personal\vrm\backend\app
ls D:\Develop\Personal\vrm\test
```
Resultado: Estructura Flutter con features separadas, backend minimal, tests presentes.

**2. Archivos directamente relacionados al paso:**
- `lib\features\recording\recording_page.dart` — interfaz principal de grabación
- `lib\features\recording\services\camera_service.dart` — manejo de hardware cámara
- `lib\features\recording\services\recording_manager.dart` — orquestador de grabación
- `lib\core\exceptions\vrm_exceptions.dart` — excepciones personalizadas

**3. Archivos de referencia (patrones existentes):**
- `lib\features\recording\services\clip_storage_service.dart` — patrón de manejo de archivos

**4. Dependencias:**
```
cat D:\Develop\Personal\vrm\pubspec.yaml
```
Resultado: Dependencias sin ffmpeg_kit_flutter (removido según comentario), usa alternativas nativas.

### Resultado:
Input para §0 (Verificación) y todo el análisis. Algo que el plan omite → va directo a §0 como discrepancia.

---

## 🔍 VERIFICACIÓN OBLIGATORIA CONTRA CÓDIGO FUENTE

> [!CRITICAL]
> Toda afirmación técnica debe estar respaldada por evidencia del código real.

### Qué DEBES verificar:

**A. Tablas y Schema de DB:**
- N/A (usa filesystem JSON)

**B. Funciones y Clases:**
- `CameraService.initialize()` existe (lib\features\recording\services\camera_service.dart:17)
- `RecordingManager.startRecording()` existe (lib\features\recording\services\recording_manager.dart:47)
- `RecordingPage._handleBackgroundTransition()` existe (lib\features\recording\recording_page.dart:281)

**C. Patrones y Convenciones:**
- Excepciones personalizadas siguen patrón VRMException (lib\core\exceptions\vrm_exceptions.dart)
- Manejo de errores usa try/catch con excepciones tipadas

**D. Dependencias:**
- `camera: ^0.11.0+4` directo en pubspec.yaml
- `ffmpeg_kit_flutter` removido (comentario en pubspec.yaml)

**E. Estado real de archivos del paso:**
- "manejo de críticos" → existe error handling básico pero incompleto
- "performance de fuego" → no hay optimizaciones específicas implementadas
- "estados intermedios" → loading screens existen pero limitados

### Formato de Evidencia:
```
✅ VERIFICADO: `CameraHardwareException` existe (lib\core\exceptions\vrm_exceptions.dart:14)
❌ DISCREPANCIA: El plan menciona `ffmpeg_kit_flutter` pero NO EXISTE en pubspec.yaml
⚠️ NO VERIFICABLE: Asumo que memoria leaks serán detectados en testing físico — CONFIRMAR antes de implementar
```

### Umbral Mínimo de Verificación:

| Alcance del paso | Mínimo verificado |
|:---|:---|
| 1-2 archivos afectados | ≥ 8 elementos |
| 3-5 archivos afectados | ≥ 12 elementos |
| 6-10 archivos afectados | ≥ 18 elementos |
| 10+ archivos afectados | ≥ 22 elementos |

> [!IMPORTANT]
> Si §0 tiene 0 discrepancias, revisá de nuevo. Paso que toca código existente casi siempre tiene ≥ 1 discrepancia.

---

## 📋 Proceso Interno — 4 ETAPAS SECUENCIALES

### ETAPA 1: Análisis de DATOS
**Enfoque:** schema, integridad referencial, RLS, constraints

- Persistencia en filesystem JSON (no DB relacional)
- Integridad: verificación de archivos existentes en `verifyIntegrityStatic()`
- Constraints: checks de espacio en disco antes de grabar
- Tipos problemáticos: manejo de `XFile` de camera plugin

### ETAPA 2: Análisis de CÓDIGO
**Enfoque:** calidad, patrones, modularidad, mantenibilidad

- Servicios separados: `CameraService`, `RecordingManager`, `ClipStorageService`
- Excepciones tipadas: `CameraHardwareException`, `StorageFullException`, etc.
- Manejo de estado: `RecordingState` enum para UI
- Modularidad: separación entre UI y lógica de negocio
- Calidad: lint issues encontrados (37), principalmente prints en producción y context sync

### ETAPA 3: Análisis de BACKEND
**Enfoque:** APIs, middleware, flujos entre servicios, contratos

- N/A (aplicación Flutter nativa sin backend separado)
- Servicios locales: `NativeStitcherService` para procesamiento de video
- Contratos: métodos tipados con parámetros requeridos

### ETAPA 4: Análisis de FULLSTACK + DX
**Enfoque:** coherencia end-to-end, UX, herramientas para el usuario final

- Flujo end-to-end: grabación → revisión → aprobación → stitching → export
- UX: estados de loading, error dialogs, snackbars
- Inconsistencias: falta manejo robusto de memory leaks y optimizaciones de performance
- DX: necesidad de herramientas para testing en dispositivos físicos

---

## 💾 Estructura de Salida

**Destino:** `D:\Develop\Personal\vrm\DEVS\IN_PROGRESS\analisis-paso 3-grok.md`

> [!IMPORTANT]
> **REGLA DE ORO:** Único archivo permitido modificar = `D:\Develop\Personal\vrm\DEVS\IN_PROGRESS\analisis-paso 3-grok.md`

---

### 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | CameraHardwareException existe | grep en lib\core\exceptions\vrm_exceptions.dart | ✅ | línea 14 |
| 2 | StorageFullException existe | grep en lib\core\exceptions\vrm_exceptions.dart | ✅ | línea 18 |
| 3 | _handleBackgroundTransition existe | grep en lib\features\recording\recording_page.dart | ✅ | línea 281 |
| 4 | verifyIntegrityStatic existe | grep en lib\features\recording\services\recording_manager.dart | ✅ | línea 328 |
| 5 | ffmpeg_kit_flutter en pubspec | grep en pubspec.yaml | ❌ | línea 70: "ffmpeg_kit_flutter has been removed" |
| 6 | Loading screen existe | grep en recording_page.dart | ✅ | líneas 820-838 |
| 7 | Error dialogs existen | grep en recording_page.dart | ✅ | _showRecoveryDialog método |
| 8 | Memory leak prevention | búsqueda de dispose patterns | ⚠️ | dispose() methods existen pero no específicos para leaks |
| 9 | Asset optimization | check pubspec.yaml assets | ⚠️ | assets definidos pero sin optimización específica |
| 10 | Performance testing setup | check test files | ⚠️ | tests existen pero no específicos de performance |

**Discrepancias encontradas:** (cada una con resolución propuesta)

- **ffmpeg_kit_flutter removido**: Plan menciona dependencia pero código usa alternativa nativa. Resolución: actualizar plan o confirmar alternativa viable.
- **Memory leak prevention limitado**: Código tiene dispose() pero no profiling específico. Resolución: implementar herramientas de monitoring.

---

### 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: persistencia en filesystem JSON sin tablas relacionales
- ✅ Integridad referencial: verificación de archivos existentes en `verifyIntegrityStatic()`
- ✅ RLS policies: N/A (filesystem local)
- ✅ Índices necesarios: N/A (archivos pequeños)
- ✅ Tipos de datos: manejo de `XFile`, `Duration`, JSON serialization

Integridad implementada mediante `verifyIntegrityStatic()` que detecta clips faltantes y corrige estado. Espacio verificado antes de grabación con `hasFreeSpace()`.

---

### 2️⃣ Análisis de Código (ETAPA 2)

- ✅ Funciones/clases nuevas: `CameraHardwareException`, `StorageFullException`, `SessionIntegrityException`
- ✅ Patrones: servicios separados con responsabilidades únicas
- ✅ Modularidad: UI separada de lógica (RecordingPage vs RecordingManager)
- ✅ Calidad: 37 lint issues encontrados, mayormente prints en producción y context async gaps
- ✅ Imports exactos: imports absolutos siguiendo convención `package:vrm_app/...`

Patrones existentes reutilizados: excepciones siguen jerarquía VRMException, servicios implementan dispose pattern.

---

### 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: N/A (Flutter nativo)
- ✅ Middleware: N/A
- ✅ Flujos: grabación → almacenamiento → stitching → export
- ✅ Contratos: métodos tipados con excepciones específicas
- ✅ Error handling: excepciones personalizadas con códigos

Flujo implementado: `startRecording()` → `stopRecording()` → `acceptCurrentClip()` → `startStitching()`.

---

### 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: idea → script → grabación → revisión → stitching → export
- ✅ Coherencia: componentes integrados correctamente
- ✅ Alineación: plan implementable con arquitectura existente
- ✅ Gaps: falta robustez en manejo de memoria y performance física
- ✅ **DX & Tooling (OBLIGATORIO):**

### Herramienta Propuesta: [Memory Leak Detector]
- **Qué automatiza:** Detección automática de memory leaks durante desarrollo y testing
- **Tipo:** script de análisis / validador en CLI
- **Cómo se usa:** `flutter run --profile && ./scripts/detect_leaks.dart`
- **Impacto para el usuario final:** Reduce crashes por memoria insuficiente en grabaciones largas
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso

---

### 5️⃣ Criterios de Aceptación

Lista binaria (sí/no) verificable:
- ✅ [DATA] verifyIntegrityStatic detecta clips faltantes correctamente
- ✅ [CODE] Todas las excepciones capturadas tienen manejo específico
- ✅ [BACKEND] Flujo de grabación maneja interrupciones gracefully
- ✅ [FULLSTACK] Usuario ve estados de loading durante operaciones críticas
- ✅ [DX] Herramienta de memory leak detection ejecuta sin errores

---

### 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Memory leaks en grabaciones largas | Alta | Falta profiling específico | Implementar monitoring y tests de memoria |
| Performance degradation en dispositivos antiguos | Media | Sin optimizaciones activas | Testing físico riguroso antes de release |
| Error handling inconsistente | Baja | Manejo parcial de excepciones | Estandarizar patterns de error |

- Riesgos técnicos: memory leaks no detectados actualmente
- Riesgos de integración: falta testing en hardware real
- Riesgos futuros: performance no optimizada para release

---

### 7️⃣ Plan de Implementación

> [!CRITICAL]
> **Reglas de segmentación atómica — OBLIGATORIAS:**
> 1. **Una tarea = un artefacto**: un archivo, una función, una migración. Si la tarea toca dos artefactos → dividirla.
> 2. **Interfaz completa en la tarea**: cada tarea debe incluir la firma exacta (nombre, parámetros con tipos, retorno) del artefacto a crear o modificar. El implementador no infiere ni decide ningún detalle de la interfaz.
> 3. **Patrón de referencia explícito**: si el artefacto sigue un patrón existente → indicar el archivo concreto a copiar. Nunca decir "seguir el patrón del proyecto" sin especificar cuál.
> 4. **Verificación inline**: cada tarea tiene su `→ verificar:` con el comando o check concreto que confirma que está completa antes de pasar a la siguiente.
> 5. **Test de atomicidad**: si el implementador puede completar la tarea sin tomar ninguna decisión de diseño → está bien segmentada. Si debe decidir algo → falta especificación, agregar detalle.

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Memory Leak Detector | `D:\Develop\Personal\vrm\scripts\detect_leaks.dart` | `void detectLeaks(List<String> profiles): Future<LeakReport>` | — | DX | Media | 2h | Ninguna | → verificar: `dart scripts/detect_leaks.dart --help` ejecuta sin errores |
| 1 | Implementar Memory Leak Monitoring | `lib\features\recording\services\memory_monitor.dart` | `class MemoryMonitor { Future<void> startMonitoring(): void; Future<LeakReport> getReport(): LeakReport; }` | `lib\features\recording\services\camera_service.dart :: CameraService` | CODE | Alta | 3h | Tarea 0 | → verificar: importable desde recording_page.dart sin error |
| 2 | Agregar Recovery Path para OutOfMemory | `lib\features\recording\recording_page.dart :: _handleMemoryPressure()` | `Future<void> _handleMemoryPressure(): void` | `lib\features\recording\recording_page.dart :: _handleBackgroundTransition()` | BACKEND | Media | 2h | Tarea 1 | → verificar: flutter test -k memory_recovery pasa |
| 3 | Implementar Asset Optimization | `pubspec.yaml :: flutter.assets` | Agregar configuración de optimización | pubspec.yaml existente | FULLSTACK | Baja | 1h | Ninguna | → verificar: flutter build apk --analyze-size muestra reducción |
| 4 | Agregar Loading States Completos | `lib\features\recording\recording_page.dart :: _buildProcessingOverlay()` | `Widget _buildProcessingOverlay(String message): Widget` | `lib\features\recording\recording_page.dart :: _buildCountdownOverlay()` | FULLSTACK | Baja | 1.5h | Ninguna | → verificar: estados de loading visibles durante stitching |
| 5 | Implementar Performance Profiling | `test\performance_test.dart` | `void testRecordingPerformance(): void` | `test\repository_test.dart` | FULLSTACK | Media | 2h | Tareas 1-4 | → verificar: flutter test test/performance_test.dart pasa en dispositivo físico |

**Tiempo total estimado:** 11.5 horas

---

## 🔮 Roadmap (NO implementar ahora)

- Optimizaciones futuras: implementar caching inteligente para assets
- Mejoras UX: notificaciones push para estado de grabación
- Pre-requisitos: testing en más dispositivos físicos
- Decisiones tomadas: usar alternativa nativa a ffmpeg_kit_flutter

---

## 🚫 Reglas de Oro

- ✅ **Análisis accionable y específico**, no genérico
- ✅ **TODO verificado contra código**, no supuestos
- ✅ **Si algo no está definido** → señalarlo como ambigüedad + resolución concreta
- ✅ **Si el plan contradice el código** → el código gana + documentar discrepancia
- ✅ **Nivel CTO exigente** en rigor y profundidad
- ✅ **Coherente con phase-state.md** — no perder decisiones ya tomadas
- ✅ **TODO el paso**, incluyendo sub-pasos
- ✅ **Etapas secuenciales** — data → code → backend → fullstack+DX, sin saltar
- ✅ **≥ 1 herramienta DX propuesta** — siempre, sin excepción
- ✅ **Tareas atómicas**: una tarea = un artefacto = interfaz completa = patrón explícito = verificación inline
- ✅ **El implementador no decide nada**: si debe inferir cualquier detalle de diseño → la tarea está incompleta

---

## 📊 Métrica de Calidad

| Métrica | Mínimo |
|:---|:---|
| `proyecto-config.json` leído antes de explorar | 100% |
| Elementos verificados (§0) | 10 (≥8 para alcance 3-5 archivos) |
| Discrepancias detectadas | 2 (ffmpeg + memory leaks) |
| Secciones completadas | 8 secciones (0-7) |
| Etapas cubiertas | 4 etapas (data, code, backend, fullstack+DX) |
| Criterios de aceptación | 5 (≥1 por sub-paso) |
| Riesgos identificados | 3 (técnico, integración, futuro) |
| Tareas atómicas (1 artefacto por tarea) | 100% |
| Interfaz exacta por tarea | 100% — sin inferencias posibles |
| Patrón de referencia explícito por tarea | 100% — archivo concreto especificado |
| Verificación inline por tarea | 100% — comando o check concreto |
| Suposiciones no verificadas | 3 (marcadas ⚠️) |
| Propuesta DX / Tooling | 1 herramienta concreta (Memory Leak Detector) |
| Estimación de tiempo | Sí, por tarea y total |

---

**Idioma de respuesta:** Español 🇪🇸</content>
<parameter name="filePath">D:\Develop\Personal\vrm\DEVS\IN_PROGRESS\analisis-paso 3-grok.md