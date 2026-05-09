# Análisis Paso 13: Mejorar debugprint-scanner-kdebugmode

**AGENTE:** lgn | **PASO:** 13 | **Fase:** mvp | **Prioridad:** Baja

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `debugprint_scanner.dart` existe | ls scripts/ | ✅ | scripts/debugprint_scanner.dart |
| 2 | Función `_isInsideDebugModeBlock` existe | grep | ✅ | Line 160-178 |
| 3 | `memory_monitor.dart` tiene debugPrint en kDebugMode | grep | ✅ | Line 61-63 |
| 4 | `clip_review_page.dart` tiene debugPrint sin kDebugMode | grep | ✅ | Line 91, 159, 197 |
| 5 | `new_project_page.dart` tiene debugPrint sin kDebugMode | grep | ✅ | Line 265, 271 |
| 6 | `device_info_service.dart` tiene debugPrint sin kDebugMode | grep | ✅ | Line 51 |
| 7 | `clip_storage_service.dart` tiene 11 debugPrint sin kDebugMode | grep | ✅ | Line 38, 120, 136, 141, 155, 160, 185, 198, 201, 233, 237 |
| 8 | `vrm_pipeline.dart` tiene 8 debugPrint sin kDebugMode | grep | ✅ | Line 29, 42, 57, 77, 84, 120, 127, 136, 139 |
| 9 | `voice_command_service.dart` tiene 4 debugPrint | grep | ✅ | Line 37, 47, 94, 108 |
| 10 | `preparation_page.dart` tiene 7 debugPrint | grep | ✅ | Line 65, 70, 71, 75, 83, 101 |
| 11 | `schema_validator.dart` tiene 3 debugPrint | grep | ✅ | Line 21, 23, 29 |
| 12 | `script_studio_advance_page.dart` tiene 8 debugPrint | grep | ✅ | Line 710-718 |
| 13 | `platform_services.dart` tiene 16 debugPrint | grep | ✅ | Line 11-167 (múltiples) |
| 14 | LoggerService.log disponible | read | ✅ | `lib/core/services/logger_service.dart` |
| 15 | Import pattern correcto | grep | ✅ | package:vrm_app/core/services/logger_service.dart |

**Discrepancias encontradas:**

| # | Discrepancia | Resolución |
|---|---|---|
| 1 | Scanner YA tiene lógica para kDebugMode (Line 160-178), pero NO detecta `if (!kReleaseMode)` | Ampliar detección a `!kReleaseMode` |
| 2 | 55 debugPrint residuales encontrados en lib/ sin kDebugMode wrapper | Migrar a LoggerService |
| 3 | `memory_monitor.dart:61` tiene `debugPrint` dentro de `if (kDebugMode)` - es un falso positivo esperado | Scanner debe ignorarlo (funciona correctamente) |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ **Schema:** No aplica (cambio en script/Dart, no base de datos)
- ✅ **Integridad referencial:** No aplica
- ✅ **RLS policies:** No aplica
- ✅ **Índices necesarios:** No aplica
- ✅ **Tipos de datos:** No aplica

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones afectadas

**`debugprint_scanner.dart`**

| Función | Parámetros | Retorno | Propósito |
|---|---|---|---|
| `_isInsideDebugModeBlock(List<String> lines, int lineIdx)` | lines: todas las líneas del archivo, lineIdx: índice actual | bool | Detecta si la línea está dentro de bloque `if (kDebugMode)` o `if (!kReleaseMode)` |
| `_findDebugPrintCalls(List<String> lines)` | lines: líneas del archivo | List<_DebugPrintMatch> | Encuentra todas las llamadas debugPrint no comentadas |
| `_fixDebugPrintCalls(File file, String content, List<String> lines)` | file: archivo, content: texto, lines: líneas | int | Reemplaza debugPrint por LoggerService.log() |

### Patrones existentes

```dart
// Pattern en memory_monitor.dart:61-63 (CORRECTO - dentro de kDebugMode)
if (kDebugMode) {
  debugPrint('[MemoryMonitor] Sample $_sampleCount taken');
}

// Pattern incorrecto - sin wrapper kDebugMode
debugPrint('[ClipReviewPage] Video initialization failed: $e');  // Line 91
```

### Importancia del fix

El scanner actual (Line 172) solo detecta:
- `l.contains('kDebugMode')` 
- `l.contains('!kReleaseMode')`

**Problema:** Si hay espacios extras o formato diferente, falla. Ejemplo:
```dart
if(kDebugMode)  // sin espacio - no detectado
if (kDebugMode ) // espacio antes del ) - no detectado
```

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ **APIs/endpoints:** No aplica (script de desarrollo)
- ✅ **Middleware:** No aplica
- ✅ **Flujos:** No aplica
- ✅ **Contratos:** No aplica
- ✅ **Error handling:** No aplica

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo
Script `debugprint_scanner.dart` → Escanea `lib/` → Reporta debugPrint → Modo `--fix` reemplaza con LoggerService

### Coherencia
- ✅ El scanner ya sigue el patrón de `store_prep_cli.dart` (CLI con flags)
- ✅ Usa `LoggerService` como target de migración

### Herramienta Propuesta: `debugprint_scanner_improved.dart`

```markdown
### Herramienta Propuesta: debugprint-scanner-v2
- **Qué automatiza:** Elimina falsos positivos en detección de debugPrint dentro de bloques kDebugMode
- **Tipo:** Script CLI
- **Cómo se usa:** `dart run scripts/debugprint_scanner.dart scan` o `dart run scripts/debugprint_scanner.dart fix`
- **Impacto para el usuario final:** No pierde tiempo revisando debugPrint intencionales de debug mode
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] `_isInsideDebugModeBlock()` detecta kDebugMode con variaciones de espaciado
✅ [CODE] `_isInsideDebugModeBlock()` detecta !kReleaseMode 
✅ [CODE] Scanner ignora debugPrint dentro de bloques kDebugMode
✅ [CODE] Scanner ignora debugPrint dentro de bloques !kReleaseMode
✅ [CODE] Scanner reporta solo 55 debugPrint residuales (no el de memory_monitor)
✅ [DX] debugprint_scanner.dart --fix ejecuta sin errores
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Falso negativo en detección | Media | kDebugMode con formato inesperado | Añadir regex flexible |
| debugPrint dentro de función anidada | Baja | No analiza braceDepth correctamente | Verificar braceDepth < 0 |
| Romper imports existentes | Baja | _fixDebugPrintCalls agrega import duplicado | Verificar antes de agregar |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX & Tooling: scanner robusto | `scripts/debugprint_scanner.dart` | `_isInsideDebugModeBlock(): bool` | memoria existente, regex flexible | CODE | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta memory_monitor.dart |
| 1 | Validar scanner funciona | `scripts/debugprint_scanner.dart` | Modificado Line 160-178 | — | CODE | Baja | 0.2h | Tarea 0 | → verificar: memory_monitor.dart NO aparece en reporte |
| 2 | (Opcional) Migrar debugPrint residuales | múltiples archivos en lib/ | Reemplazar por LoggerService.log() | `memory_monitor.dart:56` | CODE | Media | 2h | Tarea 1 | → verificar: `dart run scripts/debugprint_scanner.dart` reporta 0 |

**Tiempo total estimado:** 0.7h (solo scanner) / 2.7h (scanner + migración)

---

## 🔍 Detalles Técnicos de la Mejora

### Problema actual en `_isInsideDebugModeBlock`

```dart
// Line 172 - PROBLEMA: detección literal, no flexible
if (braceDepth > 0 && (l.contains('kDebugMode') || l.contains('!kReleaseMode'))) {
  return true;
}
```

### Solución propuesta

```dart
// Regex flexible para detectar variaciones
final debugModePattern = RegExp(r'kDebugMode\s*\)|\!kReleaseMode\s*\)');
if (braceDepth > 0 && debugModePattern.hasMatch(l)) {
  return true;
}
```

### Archivos con debugPrint residuales (55 total)

| Archivo | Cantidad | Estado |
|---|---|---|
| `lib/features/recording/clip_review_page.dart` | 3 | Sin kDebugMode |
| `lib/features/new_project/new_project_page.dart` | 2 | Sin kDebugMode |
| `lib/features/account/services/device_info_service.dart` | 1 | Sin kDebugMode |
| `lib/features/recording/services/clip_storage_service.dart` | 11 | Sin kDebugMode |
| `lib/core/api_service.dart` | 1 | Sin kDebugMode |
| `lib/core/pipeline/vrm_pipeline.dart` | 8 | Sin kDebugMode |
| `lib/features/recording/services/voice_command_service.dart` | 4 | Sin kDebugMode |
| `lib/features/preparation/preparation_page.dart` | 6 | Sin kDebugMode |
| `lib/core/services/schema_validator.dart` | 3 | Sin kDebugMode |
| `lib/features/assistant/script_studio_advance_page.dart` | 8 | Sin kDebugMode |
| `lib/features/social_accounts/platform_services.dart` | 16 | Sin kDebugMode |

**NOTA:** `memory_monitor.dart` tiene 1 debugPrint PERO está dentro de `if (kDebugMode)` - es un falso positivo que el scanner debe ignorar correctamente.