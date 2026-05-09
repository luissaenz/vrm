# Análisis FINAL Unificado — Paso 11: Reparar-widget-test-roto

**Paso:** 11 — Reparar-widget-test-roto
**Fase:** mvp
**Prioridad:** Baja
**Origen:** Sugerencia 🔵 de validación — Paso 04
**Fecha unificación:** 2026-05-09

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---|:---|:---|:---|:---|
| Lm1 | ✅ | 1 (D1: plan desactualizado) | ✅ test_suite_validator.dart | ✅ (12 verificaciones con líneas) | 4.0 |
| opus | ✅ | 1 (D1: plan desactualizado) | ✅ test_coverage_report.dart | ✅ (12 verificaciones con líneas) | 4.5 |
| glm | ✅ | 4 (D1: plan desactualizado; D2: plan asume roto; D3: SharedPreferences frágil; D4: dirs vacíos) | ✅ vrm_test_runner | ✅ (14 verificaciones con líneas) | 4.2 |
| step | ✅ | 1 (plan desactualizado) | ✅ create_widget_test.dart | ✅ (10 verificaciones con líneas) | 3.5 |
| ds | ✅ | 3 (D1: plan desactualizado; D2: opción ya ejecutada; D3: no tracking en phase-state) | ✅ test-smoke-validator | ✅ (12 verificaciones con líneas) | 3.0 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| D1 | Plan dice "Eliminar o reparar widget_test.dart que falla por referencia a widget counter inexistente" — código real: YA REPARADO en Paso 05, 0 refs counter, pasa 18/18 | Lm1, opus, glm, step, ds | ✅ `test/widget_test.dart:7` — test `App renders without crash` | Plan desactualizado. Acción real: mejorar test existente (Opción B). Eliminar y Opción A descartadas. |
| D2 | Plan ofrece "Eliminar o reemplazar" — test NO está roto, solo es mínimo | glm, opus | ✅ `test/widget_test.dart:7-12` — smoke test funcional pero trivial | Opción B unánime: reemplazar con tests que verifiquen widgets VRM reales |
| D3 | SharedPreferences sin mock explícito → fragilidad en test | Lm1, opus, glm | ✅ `lib/features/settings/services/settings_service.dart:40-45` usa `SharedPreferences.getInstance()` | Agregar `SharedPreferences.setMockInitialValues({})` en setUp |
| D4 | Directorios test vacíos (`test/features/export/services/`, `test/recording/models/`) | glm | ✅ dirs existen sin archivos | Documentar como roadmap. No bloquea MVP. |
| D5 | `AppLocalizations` import en main.dart puede fallar en test sin `generate: true` | glm | ✅ `lib/main.dart:3` | Si pumpAndSettle falla, usar pump() como fallback. No bloquea MVP. |

---

## 1️⃣ Resumen Ejecutivo

- **Objetivo:** Reemplazar `widget_test.dart` (smoke test mínimo) con tests que verifiquen renderizado real de `DashboardPage` y `OnboardingFlow`. El test actual YA funciona (fue reparado en Paso 05) pero solo verifica `MaterialApp` existe — cualquier app Flutter pasaría.
- **Corrección crítica al plan:** Plan dice "falla por referencia a widget counter inexistente". Código real: test ya fue reparado, 0 refs counter, pasa 18/18. Tarea real = mejorar test existente, no reparar.
- **DX seleccionada:** `test_coverage_report.dart` — fusiona propuestas de Lm1/opus/glm. Escanea `test/` y `lib/features/`, reporta cobertura por feature, detecta features sin tests.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path

1. Ejecutar `dart run scripts/test_coverage_report.dart` → reporte de cobertura por feature
2. Reemplazar contenido de `test/widget_test.dart` con 3 testWidgets en `group('VRMApp Widget Tests')` con `SharedPreferences.setMockInitialValues({})` en setUp
3. Ejecutar `flutter test` → 20/20 tests pasan (18 existentes + 2 nuevos; se reemplaza 1 test mínimo por 2-3 útiles)
4. Ejecutar `flutter analyze` → 0 errores

### Edge Cases MVP

- Si `pumpAndSettle()` timeout por `_loadThemeMode()` async → usar `pump(Duration(seconds: 1))` como fallback
- Si `OnboardingFlow` requiere providers complejos → test simplificado que solo verifique no-crash con `startWithOnboarding: true`
- Si `DashboardPage` falla por `ProjectRepository` → usar `pump()` en vez de `pumpAndSettle()` y verificar solo MaterialApp + Scaffold

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

#### Archivo 1: `test/widget_test.dart`
- **Ruta real:** `D:\Develop\Personal\vrm\test\widget_test.dart`
- **Tipo de cambio:** Modificación (reemplazo completo)
- **Descripción:** Reemplazar smoke test mínimo con group de 3 testWidgets que verifican renderizado real de VRMApp
- **Interfaces clave:**
  - `testWidgets('App renders MaterialApp without crash', ...)`
  - `testWidgets('App shows DashboardPage when startWithOnboarding=false', ...)`
  - `testWidgets('App shows OnboardingFlow when startWithOnboarding=true', ...)`
- **Patrones a seguir:** `test/pipeline_test.dart:4-6` (group + test), `test/repository_test.dart:142-156` (FakePathProvider setUp)

#### Archivo 2: `scripts/test_coverage_report.dart` (nuevo)
- **Ruta real:** `D:\Develop\Personal\vrm\scripts\test_coverage_report.dart`
- **Tipo de cambio:** Creación
- **Descripción:** CLI que escanea `test/` y `lib/features/`, cruza resultados, reporta features con/sin tests
- **Interfaces clave:** `void main(List<String> args)` — sin args = reporte completo
- **Patrones a seguir:** `scripts/debugprint_scanner.dart` (276L, CLI scan + report)

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: test_coverage_report.dart
- **Qué automatiza:** Escanea `test/` y `lib/features/`, cuenta tests por archivo, lista features sin cobertura. Previene regresiones de cobertura cuando se agregan features.
- **Tipo:** CLI / script Dart
- **Ubicación:** D:\Develop\Personal\vrm\scripts\test_coverage_report.dart
- **Cómo se usa:** `dart run scripts/test_coverage_report.dart`
- **Impacto para el usuario final:** Visibilidad de cobertura en ~1s. Detecta features sin tests. Roadmap auto-generado.
- **El implementador DEBE usarla** para completar las tareas 1..N del paso.
```

---

## 4️⃣ Decisiones Tecnológicas

1. **Opción B (reemplazar) sobre Opción A (eliminar):** Test mínimo tiene valor como smoke test pero valor real es mínimo. 5/5 agentes recomiendan reemplazar. Unánime.
2. **3 testWidgets en group()** sobre test individual: Consistente con patrón `pipeline_test.dart`. Organiza tests por comportamientos.
3. **SharedPreferences.setMockInitialValues({})** en setUp: Elimina fragilidad oculta. Detected por Lm1, opus, glm. Patrón ya usado en `repository_test.dart`.
4. **pumpAndSettle() con fallback pump():** Si async _loadThemeMode() no resuelve, usar `pump(Duration(seconds: 1))`. Recomendado por opus.
5. **test_coverage_report.dart** fusiona propuestas de Lm1 (test_suite_validator), opus (test_coverage_report), glm (vrm_test_runner): Mismo concepto, nombres distintos. Se unifica nombre yscope de opus (más detallado) + funcionalidad de glm (directorios vacíos).
6. ⚠️ Plan dice "falla por referencia a widget counter inexistente" pero código real usa `VRMApp(startWithOnboarding: false)` y pasa 18/18. Se implementa mejora, no reparación.
7. ⚠️ ds propone marcar Paso 11 como completado sin cambios de código. Descartado: 4/5 agentes recomiendan mejorar test. Se implementa Opción B.
8. **step propone create_widget_test.dart (generador de tests):** Descartado. Valor marginal para MVP — genera boilerplate que no se usa inmediatamente. test_coverage_report cubre necesidad DX real.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [CODE] widget_test.dart compila sin errores
✅ [CODE] widget_test.dart contiene ≥2 testWidgets verificando VRMApp/DashboardPage/OnboardingFlow
✅ [CODE] 0 referencias a "counter", "increment" u otros artefactos template Flutter
✅ [CODE] Tests usan group('VRMApp Widget Tests', ...) para organización
✅ [CODE] SharedPreferences.setMockInitialValues({}) en setUp() de widget tests
✅ [FULLSTACK] flutter test pasa 20/20 (17 existentes + 3 nuevos — reemplaza 1)
✅ [FULLSTACK] flutter analyze 0 errores
✅ [DX] test_coverage_report.dart ejecuta sin errores y reporta cobertura por feature
```

**Funcionales:**
- [ ] DashboardPage se renderiza cuando startWithOnboarding=false
- [ ] OnboardingFlow se renderiza cuando startWithOnboarding=true
- [ ] VRMApp no crashea al instanciarse (smoke test preservado)

**Técnicos:**
- [ ] 0 referencias a counter/increment en widget_test.dart
- [ ] SharedPreferences mock explícito en setUp()
- [ ] Tests organizados en group()
- [ ] flutter analyze 0 errores

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** test_coverage_report.dart | Media | 1h | Ninguna |
| 1 | Reemplazar widget_test.dart con tests útiles (group + setUp + 3 testWidgets) | Media | 0.5h | Tarea 0 |
| 2 | Validar suite completa (flutter test + flutter analyze) | Baja | 0.25h | Tarea 1 |
| **TOTAL** | | | **1.75h** | |

> [!IMPORTANT]
> **Tarea 0 siempre = DX & Tooling.** Implementador DEBE ejecutarla primero y usar la herramienta resultante para el resto del paso (dogfooding obligatorio).

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| SharedPreferences sin mock rompe test | Media | `SettingsService.instance.getThemeMode()` usa `SharedPreferences.getInstance()` | `SharedPreferences.setMockInitialValues({})` en setUp. Patrón repository_test.dart. |
| pumpAndSettle timeout en CI | Media | `_loadThemeMode()` async en initState | Fallback: `pump(Duration(seconds: 1))` si pumpAndSettle falla |
| OnboardingFlow requiere state complejo | Media | Puede fallar sin providers mockeados | Simplificar: verificar no-crash con pump() en vez de pumpAndSettle() |
| AppLocalizations no generados en test | Baja | main.dart:3 importa app_localizations.dart generado | Si falla, agregar `generate: true` en pubspec.yaml o mock localizations |
| Falso sentido de cobertura | Baja | Test solo verifica renderizado, no funcionalidad completa | Aceptable para MVP. Post-MVP: widget tests por feature. |
| Directorios test vacíos dan falsa cobertura | Baja | test/features/export/services/ y test/recording/models/ existen vacíos | test_coverage_report.dart los detecta y reporta |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|---|---|---|---|
| TP-1 | Smoke test: VRMApp renders MaterialApp | `VRMApp(startWithOnboarding: false)` | `find.byType(MaterialApp)` ✓ |
| TP-2 | DashboardPage renderiza con startWithOnboarding=false | `VRMApp(startWithOnboarding: false)` + pumpAndSettle | `find.byType(DashboardPage)` ✓ |
| TP-3 | OnboardingFlow renderiza con startWithOnboarding=true | `VRMApp(startWithOnboarding: true)` + pumpAndSettle | `find.byType(OnboardingFlow)` ✓ |
| TP-4 | Suite completa pasa | `flutter test` | 20/20 passed, 0 failed |
| TP-5 | DX tool ejecuta | `dart run scripts/test_coverage_report.dart` | Reporte con features con/sin tests |

Comando para ejecutar tests: `flutter test` / `flutter analyze`

---

## 💾 Archivo de Salida

**Destino:** `D:\Develop\Personal\vrm\DEVS\IN_PROGRESS\analisis-FINAL.md`