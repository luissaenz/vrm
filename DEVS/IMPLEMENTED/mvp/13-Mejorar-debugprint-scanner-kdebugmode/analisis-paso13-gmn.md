# 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `debugprint_scanner.dart` | `scripts/debugprint_scanner.dart` | ✅ | L8 |
| 2 | `_isInsideDebugModeBlock` | `scripts/debugprint_scanner.dart` | ✅ | L157. Backward scan flaw. |
| 3 | `memory_monitor.dart` | `lib/features/recording/services/memory_monitor.dart` | ✅ | L32 |
| 4 | `kDebugMode` usage | `memory_monitor.dart` | ✅ | L61-62 |

**Discrepancias:**
- Backward scan en `_isInsideDebugModeBlock` falla con `{` `}` en misma línea/anidados. → Replace con forward block tracking en `_findDebugPrintCalls`.

---

### 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: N/A. Script.
- ✅ Integridad referencial: N/A.
- ✅ RLS policies: N/A.
- ✅ Índices: N/A.
- ✅ Tipos de datos: N/A.

---

### 2️⃣ Análisis de Código (ETAPA 2)

- ✅ Funciones mod: `_findDebugPrintCalls(List<String> lines)`. Drop `_isInsideDebugModeBlock`.
- ✅ Patrones: Forward AST-lite parse.
- ✅ Modularidad: High. Single script.
- ✅ Calidad: Low cyclomatic. Fix nested braces.
- ✅ Imports exactos: `dart:io`.

---

### 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: N/A.
- ✅ Middleware: N/A.
- ✅ Flujos: N/A.
- ✅ Contratos: N/A.
- ✅ Error handling: N/A.

---

### 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: CLI → Output.
- ✅ Coherencia: Mejor DX. Cero false positives.
- ✅ Alineación: Script existe.
- ✅ Gaps: Ninguno.
- ✅ **DX & Tooling (OBLIGATORIO):**

```
### Herramienta Propuesta: debugprint_scanner_fix
- **Qué automatiza:** Detect residual debugPrint w/o false pos.
- **Tipo:** script
- **Cómo se usa:** `dart run scripts/debugprint_scanner.dart`
- **Impacto para el usuario final:** Less CLI noise.
- **Prioridad:** Tarea 0
```

---

### 5️⃣ Criterios de Aceptación

✅ [DATA] N/A
✅ [CODE] `_findDebugPrintCalls` usa forward scan.
✅ [BACKEND] N/A
✅ [FULLSTACK] N/A
✅ [DX] Scanner ignora `memory_monitor.dart` y otros en `kDebugMode`.

---

### 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Nested blocks | Media | `kDebugMode` inside other ifs | Stack-based depth tracking |
| Multi-line string | Baja | Braces in strings | Simple ignore o regex |

---

### 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Fix scanner | `{paths.scripts}/debugprint_scanner.dart` | `List<_DebugPrintMatch> _findDebugPrintCalls(List<String> lines)` | — | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/debugprint_scanner.dart` ignore `memory_monitor.dart` |

**Tiempo total estimado:** 1h
