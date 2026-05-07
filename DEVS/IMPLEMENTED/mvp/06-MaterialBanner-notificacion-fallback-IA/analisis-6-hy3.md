# 🧠 Análisis Paso 06: MaterialBanner-notificacion-fallback-IA
**Agente:** hy3  
**Fase:** mvp  
**Fecha:** 2026-05-06  

---

### 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `script_studio_page.dart` existe | glob **/script_studio_page.dart | ✅ | D:\Develop\Personal\vrm\lib\features\assistant\script_studio_page.dart |
| 2 | SnackBar fallback IA existe | grep L337 | ❌ | Plan pide reemplazar SnackBar, código usa MaterialBanner L338 |
| 3 | MaterialBanner L337 | read L337-363 | ✅ | L338-363: showMaterialBanner + contenido correcto |
| 4 | Banner sticky | default MaterialBanner | ✅ | Oculta con hideCurrentMaterialBanner L357 |
| 5 | Msg fallback = SnackBar original | compare | ✅ | L346-348: "Guion generado localmente (fallback). Conecta backend..." |
| 6 | Flutter SDK ≥3.10.7 | proyecto-config.json L18 | ✅ | sdk: ^3.10.7 → MaterialBanner soportado |
| 7 | Error SnackBar existe | grep L378 | ✅ | L378-383: SnackBar rojo errores |
| 8 | Condición fallback | L337 | ✅ | summary.contains('localmente') || summary.contains('fallback') |

**Discrepancias encontradas:**
1. ❌ Plan paso 06: reemplazar SnackBar con MaterialBanner → código ya implementado. Resolución: marcar paso 06 como completado, actualizar plan.md.

---

### 1️⃣ Análisis de Datos (ETAPA 1)
- ✅ Schema: sin cambios (paso solo UI)
- ✅ Integridad referencial: N/A
- ✅ RLS policies: N/A
- ✅ Índices: N/A
- ✅ Tipos de datos: N/A
*ER diagram no aplica.*

---

### 2️⃣ Análisis de Código (ETAPA 2)
- ✅ Funciones nuevas: ninguna (reemplazo widget)
- ✅ Patrones: convenciones Material Flutter
- ✅ Modularidad: cambio localizado en `_handleGenerateScript()`
- ✅ Calidad: complejidad baja, código claro
- ✅ Imports: material.dart ya importado
*Firma: `_handleGenerateScript() async → void` (L324).*

---

### 3️⃣ Análisis de Backend (ETAPA 3)
- ✅ APIs: sin cambios
- ✅ Middleware: N/A
- ✅ Flujos: sin cambios backend
- ✅ Contratos: N/A
- ✅ Error handling: errores usan SnackBar rojo (no afectados)

---

### 4️⃣ Análisis de Fullstack + DX (ETAPA 4)
- ✅ Flujo: DB→Backend→Frontend→UX sin cambios
- ✅ Coherencia: plan desactualizado, código cumple objetivo
- ✅ Alineación: Flutter soporta MaterialBanner
- ✅ Gaps: plan no refleja estado actual
- ✅ **DX & Tooling (OBLIGATORIO):**
```
### Herramienta: test_fallback_banner
- **Automatiza:** Test widget verifica MaterialBanner en fallback IA
- **Tipo:** Test Flutter
- **Uso:** `flutter test test/widget/script_studio_test.dart`
- **Impacto:** Evita regresión, asegura notificación visible
- **Prioridad:** Tarea 0
```

---

### 5️⃣ Criterios de Aceptación
- ✅ [FULLSTACK] Banner sticky hasta descarte
- ✅ [FULLSTACK] Mismo contenido que SnackBar original
- ✅ [FULLSTACK] No rompe flujo ScriptStudio
- ✅ [CODE] MaterialBanner en L337
- ✅ [DX] Test widget pasa

---

### 6️⃣ Riesgos
| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| MaterialBanner no soportado | Baja | SDK <1.20 | SDK actual ^3.10.7 → soportado |
| Usuario no oculta banner | Baja | Sin botón | Código tiene botón OK L356 |
| Condición fallback falla | Media | summary sin palabras clave | Verificar ScriptFallbackService |

---

### 7️⃣ Plan de Implementación
| # | Tarea | Artefacto | Interfaz exacta | Patrón | Etapa | Complejidad | Tiempo | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: test_fallback_banner | `test/widget/script_studio_test.dart` | `testWidgets('fallback shows MaterialBanner', ...)` | `test/widget/home_test.dart` | DX | Baja | 0.5h | Ninguna | `flutter test test/widget/script_studio_test.dart` pasa |
| 1 | Verificar paso 06 implementado | `lib/features/assistant/script_studio_page.dart` | MaterialBanner L337-363 | Material | CODE | Baja | 0h | Tarea 0 | Code review confirma MaterialBanner |

**Tiempo total:** 0.5h

---

### 🔮 Roadmap (NO implementar ahora)
- Actualizar plan.md paso 06 como completado
- Agregar test widget fallback
- Verificar condición fallback en ScriptFallbackService
