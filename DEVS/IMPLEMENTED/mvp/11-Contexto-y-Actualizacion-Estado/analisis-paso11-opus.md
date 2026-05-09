# 🧠 Análisis Técnico — Paso 11: Reparar-widget-test-roto

**Agente:** opus
**Fecha:** 2026-05-09
**Paso:** 11 — Reparar-widget-test-roto
**Fase:** mvp

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `widget_test.dart` existe | ls `test/` | ✅ | `test/widget_test.dart` (373 bytes, 14 líneas) |
| 2 | Referencia "counter" en widget_test | grep `counter` en widget_test.dart | ✅ AUSENTE | 0 resultados — NO hay referencia a counter |
| 3 | Test actual = `'App renders without crash'` | Lectura directa L7 | ✅ | `testWidgets('App renders without crash', ...)` |
| 4 | `VRMApp(startWithOnboarding: false)` es firma válida | main.dart L28-29 | ✅ | `const VRMApp({super.key, required this.startWithOnboarding})` |
| 5 | Test busca `MaterialApp` widget | widget_test.dart L11 | ✅ | `expect(find.byType(MaterialApp), findsOneWidget)` |
| 6 | `flutter test` pasa 18/18 | Ejecución real | ✅ | Exit code 0 — "All tests passed!" — 18/18 |
| 7 | `flutter analyze` 0 errores | Ejecución real | ✅ | "No issues found!" |
| 8 | phase-state registra widget_test reparado | phase-state.md L84, L316 | ✅ | "widget_test.dart reparado (renderiza VRMApp sin crash)" |
| 9 | Paso 05 docs confirman fix | phase-state.md L316 | ✅ | "widget_test.dart reparado" en correcciones Paso 05 |
| 10 | Tests existentes: repository_test (6) | `test/repository_test.dart` | ✅ | 6 tests — save/load/list/delete/search/count |
| 11 | Tests existentes: pipeline_test (4) | `test/pipeline_test.dart` | ✅ | 4 tests — exec/factory/config/validate |
| 12 | Tests existentes: error_handling_test (6) | `test/error_handling_test.dart` | ✅ | 6 tests — plugin exceptions + hierarchy |

### Discrepancias encontradas:

| # | Plan dice | Código real | Resolución |
|---|---|---|---|
| D1 | "Eliminar o reparar `widget_test.dart` que falla por referencia a widget counter inexistente" | widget_test.dart YA REPARADO en Paso 05. 0 refs "counter". Test pasa. 18/18. | **Plan desactualizado.** Test ya funciona. Tarea real = decidir si mantener test mínimo actual o reemplazar con test más útil. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**N/A para este paso.** Paso 11 = test puro. 0 tablas, 0 schema, 0 persistencia afectada.

- ✅ Sin cambios schema
- ✅ Sin foreign keys / constraints
- ✅ Sin RLS
- ✅ Sin índices
- ✅ Sin tipos de datos

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Estado actual `widget_test.dart` (14L):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

### Evaluación:

| Aspecto | Veredicto |
|---|---|
| ¿Compila? | ✅ Sí |
| ¿Pasa? | ✅ Sí |
| ¿Cubre funcionalidad real? | ⚠️ MÍNIMO — solo verifica MaterialApp existe |
| ¿Test template Flutter? | ❌ NO — ya fue reparado. Nombre cambió de counter a "App renders without crash" |
| ¿Valor para regresión? | 🟡 Bajo — detecta solo si `VRMApp` crashea al instanciar |

### Opciones del plan:

- **Opción A: Eliminar** → 17/17 tests. Pierde detección crash en VRMApp.
- **Opción B: Reemplazar con test útil** → 18/18 tests (o más). Verifica renderizado real pantalla principal.

**Recomendación → Opción B.** Test actual es funcional pero trivial. Reemplazar con test que verifique:
1. `DashboardPage` renderiza cuando `startWithOnboarding: false`
2. Rutas named (`/dashboard`, `/onboarding`) registradas
3. ThemeMode dark aplicado por defecto

### Patrones test existentes:

| Patrón | Archivo referencia | Uso |
|---|---|---|
| Unit test puro (model/service) | `repository_test.dart` | `test()` + setUp/tearDown + FakePathProvider |
| Widget test con `pumpWidget` | `widget_test.dart` (actual) | `testWidgets()` + `tester.pumpWidget()` |
| Exception validation | `error_handling_test.dart` | `throwsA(isA<>())` + catch + metadata |

### Test mejorado propuesto — firma + imports:

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/main.dart';

void main() {
  group('VRMApp Widget Tests', () {
    testWidgets('App renders MaterialApp without crash', ...);
    testWidgets('App shows DashboardPage when startWithOnboarding=false', ...);
    testWidgets('App shows OnboardingFlow when startWithOnboarding=true', ...);
    testWidgets('App applies dark theme by default', ...);
  });
}
```

Nota: `SettingsService.instance.getThemeMode()` usa SharedPreferences → necesita mock o test acepta loading state (MaterialApp sin home en _isLoading).

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**N/A para este paso.** 0 endpoints, 0 middleware, 0 flujos backend afectados.

- ✅ Sin APIs
- ✅ Sin middleware
- ✅ Sin contratos
- ✅ Sin error handling backend

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end:

```
widget_test.dart → pumpWidget(VRMApp) → MaterialApp renders → ✅
                                       (loading state → empty MaterialApp)
                                       (loaded state → DashboardPage o OnboardingFlow)
```

### Coherencia:

- Test actual NO verifica loaded state → solo ve MaterialApp del loading state (L57-63 main.dart)
- `_loadThemeMode()` es async → `tester.pump()` puede no completar Future → test ve loading MaterialApp, no DashboardPage
- Esto explica por qué test "funciona" — verifica widget trivial, no funcionalidad real

### Gaps:

| Gap | Impacto |
|---|---|
| Test no espera a `_loadThemeMode()` | Solo ve loading state, no real app |
| 0 widget tests para features core | No hay tests para DashboardPage, RecordingPage, etc. |
| Test count: 18 tests en 5 archivos | Cobertura UI = 1 test mínimo |

### DX & Tooling (OBLIGATORIO):

```
### Herramienta Propuesta: test_coverage_report.dart
- **Qué automatiza:** Escanea `test/` y `lib/features/`, genera reporte de cobertura por feature. Detecta features sin tests, tests sin assertions, tests que solo verifican tipos.
- **Tipo:** CLI / script Dart
- **Cómo se usa:** `dart run scripts/test_coverage_report.dart`
- **Output:**
  📊 VRM Test Coverage Report
  ────────────────────────────
  Features: 8 | Con tests: 2 | Sin tests: 6
  Test files: 5 | Tests totales: 18
  Widget tests: 1 | Unit tests: 17

  ⚠️ Features sin test:
    - recording (0 tests)
    - settings (0 tests)
    - onboarding (0 tests)
    - new_project (0 tests)
    - assistant (0 tests)
    - social_accounts (mock only)

  ✅ Features con tests:
    - core/data (repository_test: 6 tests)
    - core/pipeline (pipeline_test: 4 tests)
- **Impacto para el usuario final:** Visibilidad de cobertura en ~1s. Detecta regresiones de cobertura cuando se agregan features. Roadmap de tests faltantes auto-generado.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] widget_test.dart compila sin errores
✅ [CODE] widget_test.dart contiene ≥3 testWidgets verificando funcionalidad real de VRMApp
✅ [CODE] 0 referencias a "counter", "increment", "+1" u otros artefactos de template Flutter
✅ [CODE] Tests usan `group('VRMApp Widget Tests', ...)` para organización
✅ [FULLSTACK] `flutter test` pasa 20/20 (18 existentes + 2 nuevos mínimo) o 17/17 si se elimina
✅ [FULLSTACK] `flutter analyze` 0 errores
✅ [DX] test_coverage_report.dart ejecuta sin errores y reporta cobertura por feature
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `SettingsService.instance.getThemeMode()` requiere SharedPreferences mock en tests | Media | Widget test con `pumpWidget` no tiene binding real para SharedPreferences → posible crash o hang | Usar `SharedPreferences.setMockInitialValues({})` en setUp. Patrón: `repository_test.dart` usa `FakePathProviderPlatform`. |
| `VRMApp._loadThemeMode()` async → test ve solo loading state | Media | `tester.pump()` no resuelve Future de SharedPreferences → test verifica MaterialApp vacío | Usar `tester.pumpAndSettle()` o mock SettingsService con valor inmediato |
| Tests nuevos pueden importar deps que requieren plugins nativos | Baja | `DashboardPage` usa `ProjectRepository` → `path_provider` → plugin nativo | Mantener tests ligeros: verificar solo render, no funcionalidad completa. Usar `FakePathProviderPlatform` como patrón existente. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: test_coverage_report.dart | `scripts/test_coverage_report.dart` | `void main(List<String> args)` con subcomandos: (sin args) = report completo. Escanea `test/*.dart` → cuenta `test(` y `testWidgets(`. Escanea `lib/features/*/` → lista features. Cruza y reporta cobertura. | `scripts/debugprint_scanner.dart` (276L) — mismo patrón CLI scan + report | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/test_coverage_report.dart` ejecuta sin errores y muestra report |
| 1 | Reemplazar widget_test.dart con tests útiles | `test/widget_test.dart` | **Test 1:** `testWidgets('App renders MaterialApp without crash', (tester) async { SharedPreferences.setMockInitialValues({}); await tester.pumpWidget(const VRMApp(startWithOnboarding: false)); await tester.pump(); expect(find.byType(MaterialApp), findsOneWidget); })` **Test 2:** `testWidgets('App shows OnboardingFlow when startWithOnboarding=true', (tester) async { SharedPreferences.setMockInitialValues({}); await tester.pumpWidget(const VRMApp(startWithOnboarding: true)); await tester.pumpAndSettle(); expect(find.byType(OnboardingFlow), findsOneWidget); })` **Test 3:** `testWidgets('App shows DashboardPage when startWithOnboarding=false', (tester) async { SharedPreferences.setMockInitialValues({}); await tester.pumpWidget(const VRMApp(startWithOnboarding: false)); await tester.pumpAndSettle(); expect(find.byType(DashboardPage), findsOneWidget); })` | `test/widget_test.dart` actual (14L) — expandir, no reescribir desde cero | CODE | Baja | 0.5h | Tarea 0 | → verificar: `flutter test test/widget_test.dart` pasa 3/3 |
| 2 | Validar suite completa post-cambio | — | — | — | FULLSTACK | Baja | 0.25h | Tarea 1 | → verificar: `flutter test` pasa 20/20 (17 existentes + 3 nuevos) + `flutter analyze` 0 errores |

> **Nota Tarea 1:** Si `pumpAndSettle()` no resuelve `_loadThemeMode()` (SharedPreferences async) → usar `tester.pump(Duration(seconds: 1))` como fallback. Si DashboardPage/OnboardingFlow requieren plugins nativos no mockeados → simplificar a verificar solo que no crashea con `tester.pumpWidget()` + `tester.pump()` sin `pumpAndSettle`.

**Tiempo total estimado:** 1.75h

---

## 🔮 Roadmap (NO implementar ahora)

- **Widget tests por feature:** DashboardPage, RecordingPage, ScriptStudioPage → cada uno con ≥2 tests de renderizado
- **Golden tests:** Capturas de referencia visual para regresión de UI
- **Integration tests:** Flujo completo Idea→Script→Record con mocks
- **CI pipeline:** `flutter test` automático en push via GitHub Actions
- **Cobertura con `--coverage`:** Integrar `lcov` report en test_coverage_report.dart

---

## Notas

**Hallazgo crítico:** Plan desactualizado. widget_test.dart ya fue reparado en Paso 05 (confirmado por phase-state L84, L316). 0 refs a "counter". Test pasa 18/18. Tarea real = mejorar test existente de mínimo a útil, no "reparar" algo que ya funciona.
