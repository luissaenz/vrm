# 🧠 Análisis Técnico — Paso 11: Reparar-widget-test-roto

**Agente:** Lm1  
**Fecha:** 2026-05-09  
**Paso:** 11  
**Fase:** mvp  
**Prioridad:** Baja

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `test/widget_test.dart` existe | ls test/widget_test.dart | ✅ | Archivo presente, 13 líneas |
| 2 | Referencia "counter" en widget_test | grep counter | ✅ AUSENTE | 0 resultados |
| 3 | Test = `'App renders without crash'` | widget_test.dart:7 | ✅ | Ya modificado, no es template Flutter |
| 4 | `VRMApp(startWithOnboarding: false)` válido | lib/main.dart:28-29 | ✅ | Constructor existe con parámetro requerido |
| 5 | `MaterialApp` widget buscado | widget_test.dart:11 | ✅ | `expect(find.byType(MaterialApp), findsOneWidget)` |
| 6 | `flutter test` pasa | ejecución | ✅ | 18/18 tests pasan |
| 7 | phase-state registra widget_test reparado | phase-state.md:84,316 | ✅ | Confirmado |
| 8 | `DashboardPage` existe | lib/features/dashboard/dashboard_page.dart | ✅ | Import en main.dart:5 |
| 9 | `OnboardingFlow` existe | lib/features/onboarding/pages/onboarding_flow.dart | ✅ | Import en main.dart:6 |
| 10 | `SettingsService.getThemeMode()` usa SharedPreferences | lib/features/settings/services/settings_service.dart | ⚠️ | Puede romper test sin mock |
| 11 | Patrones test existentes | repository_test.dart | ✅ | Usa group(), setUp, FakePathProvider |
| 12 | Test único widget test | glob test/**/*_test.dart | ⚠️ | Solo 1 widget test en proyecto |

### Discrepancias encontradas:

| # | Plan dice | Código real | Resolución |
|---|---|---|---|
| D1 | "Eliminar o reparar widget_test.dart que falla por referencia a widget counter inexistente" | widget_test.dart YA REPARADO. 0 refs a "counter". Test pasa 18/18. | **Plan desactualizado.** Acción: marcar completado + decidir si mejorar test. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**N/A.** Paso 11 = test puro. 0 tablas, 0 schema, 0 persistencia.

- ✅ Schema: Sin cambios
- ✅ Integridad referencial: N/A
- ✅ RLS policies: N/A
- ✅ Índices: N/A
- ✅ Tipos de datos: N/A

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Estado actual widget_test.dart (14L):
```dart
testWidgets('App renders without crash', (WidgetTester tester) async {
  await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
  await tester.pump();
  expect(find.byType(MaterialApp), findsOneWidget);
});
```

### Evaluación:

| Aspecto | Veredicto |
|---|---|
| ¿Compila? | ✅ Sí |
| ¿Pasa? | ✅ Sí (18/18) |
| ¿Cubre VRM? | ⚠️ MÍNIMO — solo verifica MaterialApp existe |
| ¿Template Flutter? | ❌ NO — ya fue reparado |
| ¿Valor regresión? | 🟡 Bajo — detecta solo crash de VRMApp |

### Opciones:

- **Opción A: Eliminar** → 17/17 tests. Pierde smoke test.
- **Opción B: Mejorar** → Verificar DashboardPage/OnboardingFlow. 18+ tests.

**Recomendación → Opción B.** Test actual trivial. Agregar verificaciones de pantallas reales.

### Patrones referencia:

| Patrón | Archivo | Uso |
|---|---|---|
| Unit test con fake | repository_test.dart | setUp, tearDown, FakePathProvider |
| Exception test | error_handling_test.dart | throwsA(isA<>()) |
| Widget test actual | widget_test.dart | testWidgets + pumpWidget |

### Test propuesto:
```dart
group('VRMApp Widget Tests', () {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  
  testWidgets('renders DashboardPage when startWithOnboarding=false', ...);
  testWidgets('renders OnboardingFlow when startWithOnboarding=true', ...);
});
```

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**N/A.** 0 APIs, 0 middleware, 0 backend afectado.

- ✅ APIs: N/A
- ✅ Middleware: N/A
- ✅ Flujos: N/A
- ✅ Contratos: N/A
- ✅ Error handling: N/A

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end:
```
flutter test → widget_test.dart → VRMApp(startWithOnboarding: false)
  → SettingsService.getThemeMode() → SharedPreferences (fragile)
  → MaterialApp → DashboardPage (si pumpAndSettle)
```

### Gaps:
- Test no espera `_loadThemeMode()` async → ve only loading state
- 0 tests widget para features (recording, dashboard, settings)
- Dependencia SharedPreferences sin mock explícito

### DX & Tooling (OBLIGATORIO):
```
### Herramienta Propuesta: test_suite_validator.dart
- Qué automatiza: Valida que suite de tests pasa y reporta features sin tests.
- Tipo: CLI / script Dart
- Cómo se usa: dart run scripts/test_suite_validator.dart
- Output:
  📊 VRM Test Coverage Report
  Features: 8 | Con tests: 2 | Sin tests: 6
  ⚠️ Features sin test: recording, settings, onboarding, new_project, assistant
- Impacto: Visibilidad de cobertura en ~1s. Roadmap tests faltantes auto-generado.
- Prioridad: Tarea 0 — implementar antes que el resto
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] widget_test.dart compila sin errores
✅ [CODE] widget_test.dart contiene ≥2 testWidgets verificando VRMApp/DashboardPage/OnboardingFlow
✅ [CODE] 0 referencias a "counter", "increment" u otros artefactos template Flutter
✅ [CODE] Tests usan group('VRMApp Widget Tests', ...) para organización
✅ [FULLSTACK] flutter test pasa 19/19 (17 existentes + 2 nuevos)
✅ [FULLSTACK] flutter analyze 0 errores
✅ [DX] test_suite_validator.dart ejecuta sin errores y reporta cobertura por feature
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| SharedPreferences sin mock rompe test | Media | SettingsService.instance.getThemeMode() usa SharedPreferences | Agregar SharedPreferences.setMockInitialValues({}) en setUp |
| pumpAndSettle timeout en CI | Media | _loadThemeMode() async en initState | Usar pump(Duration) como fallback |
| OnboardingFlow requiere state complejo | Media | Puede fallar sin providers mockeados | Simplificar a verificar no-crash |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón | Etapa | Complejidad | Tiempo | Verificación |
|---|---|---|---|---|---|---|---|---|
| 0 | **DX: test_suite_validator.dart** | scripts/test_suite_validator.dart | `void main(List<String> args)` — escanea test/*.dart + lib/features/*/, reporta coverage | scripts/debugprint_scanner.dart | DX | Media | 1h | → verificar: `dart run scripts/test_suite_validator.dart` |
| 1 | Reemplazar widget_test.dart con tests útiles | test/widget_test.dart | Test 1: renders DashboardPage. Test 2: renders OnboardingFlow. setUp con SharedPreferences mock | widget_test.dart actual | CODE | Baja | 0.5h | → verificar: `flutter test` pasa |
| 2 | Validar suite completa | — | — | — | FULLSTACK | Baja | 0.25h | → verificar: `flutter test` pasa 19/19 |

**Tiempo total:** 1.75h

---

## 🔮 Roadmap (NO implementar ahora)

- Widget tests por feature: DashboardPage, RecordingPage, ScriptStudioPage
- Golden tests para regresión visual
- Integration tests: flujo Idea→Script→Record
- CI pipeline: flutter test automático
- Coverage con --coverage + lcov

---

## 🚫 Reglas de Oro

- ✅ Todo verificado contra código
- ✅ Discrepancia identificada (plan desactualizado)
- ✅ ≥1 herramienta DX propuesta
- ✅ Tareas atómicas: 1 artefacto/tarea
- ✅ Interfaz exacta por tarea
- ✅ Patrón explícito
- ✅ Verificación inline
- ✅ Estimación tiempo