# Analisis Paso 11 — Reparar-widget-test-roto

**Agente:** glm  
**Paso:** 11 — Reparar-widget-test-roto  
**Origen:** Sugerencia 🔵 de validacion — Paso 04  
**Prioridad:** Baja  
**Fase:** mvp  

---

## §0 — Verificacion contra Codigo Fuente

| # | Elemento | Verificacion | Estado | Evidencia |
|---|----------|-------------|--------|-----------|
| 1 | `test/widget_test.dart` existe | `ls test/widget_test.dart` | ✅ EXISTE | Archivo presente, 13 lineas |
| 2 | Referencia a counter widget | Busqueda de "counter" en archivo | ✅ NO EXISTE | Plan dice "falla por referencia a widget counter inexistente" pero archivo YA NO referencia counter |
| 3 | `VRMApp` clase existe | `lib/main.dart:27-29` | ✅ EXISTE | `class VRMApp extends StatefulWidget`, constructor `VRMApp({super.key, required this.startWithOnboarding})` |
| 4 | `VRMApp.startWithOnboarding` parametro | `lib/main.dart:28-29` | ✅ EXISTE | `final bool startWithOnboarding; required` |
| 5 | `MaterialApp` render en VRMApp | `lib/main.dart:65-115` | ✅ EXISTE | Widget build retorna `MaterialApp(...)` |
| 6 | `SettingsService.instance.getThemeMode()` | `lib/features/settings/services/settings_service.dart:40-45` | ✅ EXISTE | Usa `SharedPreferences.getInstance()` → fragile en test sin mock |
| 7 | `flutter test` ejecucion actual | `flutter test` output | ✅ PASA 18/18 | Todos los tests pasan, incluido widget_test.dart |
| 8 | `DashboardPage` existe | Import en `lib/main.dart:5` | ✅ EXISTE | `import package:vrm_app/features/dashboard/dashboard_page.dart` |
| 9 | `OnboardingFlow` existe | Import en `lib/main.dart:6` | ✅ EXISTE | `import package:vrm_app/features/onboarding/pages/onboarding_flow.dart` |
| 10 | Patrones de test existentes | `test/repository_test.dart` | ✅ VERIFICADO | Usa `group()`, `test()`, Arrange-Act-Assert, fake para path_provider |
| 11 | Patrones de test unitarios | `test/pipeline_test.dart`, `test/error_handling_test.dart` | ✅ VERIFICADO | Tests unitarios puros sin widgets |
| 12 | `AppLocalizations` dependencia | `lib/main.dart:3` | ✅ EXISTE | `import 'package:vrm_app/l10n/app_localizations.dart'` — puede fallar en test si no generate |
| 13 | Otros tests widget | Busqueda en `test/` | ❌ NO EXISTE | widget_test.dart es el UNICO widget test del proyecto |
| 14 | Test directory subestructura | `test/features/export/services/` y `test/recording/models/` | ⚠️ VACIOS | Directorios existen pero SIN archivos de test |

### Discrepancias Encontradas

1. **❌ DISCREPANCIA MAYOR:** Plan afirma que widget_test.dart "falla por referencia a widget counter inexistente" pero el archivo ACTUAL no referencia counter alguno. El test YA FUE MODIFICADO para instanciar `VRMApp(startWithOnboarding: false)` y verificar `MaterialApp`. **Pasa 18/18.** El plan queda desactualizado en este punto.

2. **⚠️ DISCREPANCIA MENOR:** Plan dice "Eliminar o reparar" asumiendo que el test esta roto. No esta roto — pero su valor es minimo: solo verifica que `MaterialApp` se renderiza, no ningun comportamiento VRM.

3. **⚠️ FRAGILIDAD:** `VRMApp.initState()` llama `SettingsService.instance.getThemeMode()` que usa `SharedPreferences`. Funciona en test porque `flutter_test` inyecta mock implicito, pero es dependencia oculta y fragile.

4. **⚠️ DIRECTORIOS VACIOS:** `test/features/export/services/` y `test/recording/models/` existen vacios — indican tests planificados pero nunca implementados.

---

## §1 — Analisis de Datos (ETAPA 1)

Este paso NO involucra schema de DB, migraciones ni datos persistentes. No aplica.

- ✅ Schema: Sin cambios
- ✅ Integridad referencial: N/A
- ✅ RLS policies: N/A
- ✅ Indices: N/A
- ✅ Tipos de datos: N/A

---

## §2 — Analisis de Codigo (ETAPA 2)

### Funciones/Clases Actuales en `widget_test.dart`

```dart
// test/widget_test.dart — estado actual
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

### Evaluacion

| Aspecto | Valoracion |
|---------|-----------|
| **Cobertura real** | Minima — solo verifica que MaterialApp existe, no comportamiento VRM |
| **Patron seguido** | Ninguno — test aislado sin group, sin setup/teardown, sin mock explicito |
| **Fragilidad** | Alta — depende de `SharedPreferences` implicito via `SettingsService` |
| **Utilidad para regression** | Nula — cualquier app Flutter con MaterialApp pasaria este test |
| **Alineacion con convencion** | Parcial — nombre `{name}_test.dart` OK, pero contenido no sigue patron de otros tests |

### Patrones Existentes Relevantes

**Patron de test con fake/mocks** (`test/repository_test.dart:142-156`):
```dart
class FakePathProviderPlatform extends PathProviderPlatform {
  final String basePath;
  FakePathProviderPlatform(this.basePath);
  @override
  Future<String?> getApplicationDocumentsPath() async => basePath;
  @override
  Future<String?> getTemporaryPath() async => basePath;
  @override
  Future<String?> getApplicationSupportPath() async => basePath;
}
```

**Patron de test unitario con `group()`** (`test/pipeline_test.dart:4-6`):
```dart
group('VRM Pipeline Integration Tests', () {
  test('Default pipeline executes script processing successfully', () async { ... });
});
```

### Opciones de Modificacion

**Opcion A — Eliminar** (`test/widget_test.dart` eliminado):
- Pros: Remueve test sin valor real, elimina falsa sensacion de cobertura
- Contras: Pierde humo de humo minimo; `flutter test` baja a 17/17
- Veredicto: **No recomendado** — humo de humo es baseline util

**Opcion B — Reemplazar con test significativo** (RECOMENDADO):
- Nuevo test verifica renderizado de pantalla principal (`DashboardPage`)
- Usa patron de `group()` + `setUp()` consistente con otros tests
- Mock explicito de `SharedPreferences` para eliminar fragilidad
- Mantiene cuenta en 18/18 (reemplaza 1 test por ≥1 mejores)

### Funciones/Clases Nuevas Propuestas

```dart
// test/widget_test.dart — propuesta
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() async {
    // Mock explicito de SharedPreferences para SettingsService
    SharedPreferences.setMockInitialValues({});
  });

  group('VRMApp Widget Tests', () {
    testWidgets('renders DashboardPage when startWithOnboarding is false', ...);
    testWidgets('renders OnboardingFlow when startWithOnboarding is true', ...);
  });
}
```

- ✅ Modularidad: Mismo archivo, tests separados por comportamiento
- ✅ Calidad: Verifica widgets VRM reales, no solo MaterialApp generico
- ✅ Cohesion: Cada test verifica un comportamiento especifico
- ✅ Patrones: Sigue convencion de `group()` + `test()` del proyecto

---

## §3 — Analisis de Backend (ETAPA 3)

Este paso NO involucra APIs, endpoints, middleware ni servicios backend. No aplica.

- ✅ APIs: N/A
- ✅ Middleware: N/A
- ✅ Flujos: N/A
- ✅ Contratos: N/A
- ✅ Error handling: N/A

---

## §4 — Analisis de Fullstack + DX (ETAPA 4)

### Flujo Completo

```
flutter test → widget_test.dart → VRMApp(startWithOnboarding: false)
  → SettingsService.instance.getThemeMode() → SharedPreferences (mock implicito)
  → MaterialApp → DashboardPage (verificar renderizado)
```

### Coherencia con MVP

El test actual es un humo de humo generico. Para MVP, reemplazar con test que verifique pantallas reales (Dashboard) tiene mas valor que eliminarlo.

**Gaps detectados:**
1. Test actual no verifica ninguna pantalla VRM especifica
2. Dependencia implicita de `SharedPreferences` sin mock explicito → puede romperse
3. `startWithOnboarding: true` no esta testeado (ruta de onboarding)
4. Directorios de test vacios (`test/features/export/services/`, `test/recording/models/`) sugieren estructura futura pero sin implementacion

### DX & Tooling (OBLIGATORIO)

```
### Herramienta Propuesta: vrm_test_runner
- **Que automatiza:** Verificacion de suite de tests completa con conteo y reporte de cobertura por modulo
- **Tipo:** Script CLI
- **Como se usa:** `dart run scripts/vrm_test_runner.dart` — ejecuta `flutter test`, cuenta resultados por archivo, reporta modulos sin tests (como test/features/export/services/ vacio)
- **Impacto para el usuario final:** Visibilidad inmediata de cobertura de tests por modulo, detecta directorios vacios que sugieren tests faltantes
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## §5 — Criterios de Aceptacion

```
✅ [CODE] widget_test.dart NO contiene referencia a counter widget
✅ [CODE] widget_test.dart usa group() y patron consistente con otros tests
✅ [CODE] Mock explicito de SharedPreferences en setUp()
✅ [CODE] Test verifica DashboardPage se renderiza cuando startWithOnboarding=false
✅ [CODE] Test verifica OnboardingFlow se renderiza cuando startWithOnboarding=true
✅ [CODE] flutter test pasa 18/18 (o + si se agregan tests adicionales)
✅ [CODE] No se pierde cobertura de tests existentes (17 otros tests siguen pasando)
✅ [DX] Script vrm_test_runner ejecuta sin errores y reporta modulos sin tests
```

---

## §6 — Riesgos

| Riesgo | Severidad | Causa | Mitigacion |
|--------|-----------|-------|------------|
| AppLocalizations no generados en test | Media | `lib/main.dart:3` importa `app_localizations.dart` generado | Agregar `generate: true` en pubspec o mock de localizations en test |
| SharedPreferences mock no cubre SettingsService edge cases | Baja | Mock con valores vacios puede no reflejar estado real | Usar `SharedPreferences.setMockInitialValues({'theme_mode': 0})` para cubrir getThemeMode |
| VRMApp init async causa timing en test | Media | `_loadThemeMode()` es async en `initState` → race condition posible | Usar `await tester.pumpAndSettle()` en vez de solo `pump()` |
| Directorios de test vacios dan falsa sensacion de cobertura | Baja | `test/features/export/services/` y `test/recording/models/` existen vacios | Script DX los detecta y reporta |
| OnboardingFlow requiere state complejo para renderizar | Media | Puede depender de providers o controllers no mockeados | Si falla, usar `pumpAndSettle()` con timeout o mock providers especificos |

---

## §7 — Plan de Implementacion

| # | Tarea | Artefacto | Interfaz exacta | Patron a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificacion |
|---|-------|-----------|-----------------|-----------------|-------|-------------|-------------|--------------|-------------|
| 0 | **DX: vrm_test_runner** — Script CLI que ejecuta `flutter test`, cuenta resultados por archivo, reporta directorios vacios | `scripts/vrm_test_runner.dart` | `Future<void> main(List<String> args) async` — ejecuta `Process.run('flutter', ['test'])`, parsea output, cuenta passed/failed por archivo, escanea `test/` buscando directorios vacios, imprime reporte | `scripts/store_prep_cli.dart` (CLI con subcomandos) | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/vrm_test_runner.dart` ejecuta sin errores y muestra reporte |
| 1 | Agregar mock explicito de SharedPreferences en widget_test.dart | `test/widget_test.dart` | En `setUp()`: `SharedPreferences.setMockInitialValues({});` — elimina dependencia oculta de SettingsService | `test/repository_test.dart:142-156` (FakePathProviderPlatform) | CODE | Baja | 0.2h | Ninguna | → verificar: `flutter test test/widget_test.dart` pasa sin warnings |
| 2 | Reemplazar test generico por tests significativos con group() | `test/widget_test.dart` | `group('VRMApp Widget Tests', () { testWidgets('renders DashboardPage when startWithOnboarding is false', ...); testWidgets('renders OnboardingFlow when startWithOnboarding is true', ...); })` — usar `await tester.pumpAndSettle()` post `pumpWidget()` | `test/pipeline_test.dart:4-6` (group + test) | CODE | Media | 0.5h | Tarea 1 | → verificar: `flutter test test/widget_test.dart` pasa 2/2 tests y verifica tipos VRM especificos (no MaterialApp generico) |
| 3 | Validar suite completa + script DX | — | — | — | FULLSTACK | Baja | 0.2h | Tareas 0-2 | → verificar: `flutter test` pasa 18/18 (o mas) Y `dart run scripts/vrm_test_runner.dart` reporta todos los tests OK y detecta directorios vacios |

**Tiempo total estimado:** 1.4 horas

---

## 🔮 Roadmap (NO implementar ahora)

- **Test de OnboardingFlow completo**: Verificar transiciones entre pantallas de onboarding (requiere mock de controllers)
- **Test de navigacion entre rutas**: Verificar `/dashboard`, `/recording`, `/stitch-progress`, `/recording-end` (requiere mock de args)
- **Poblar `test/features/export/services/`**: Tests unitarios para export service
- **Poblar `test/recording/models/`**: Tests unitarios para modelos de sesion
- **Widget test por feature**: Dashboard, ScriptStudio, Recording, etc.
- **Integrar `vrm_test_runner` como CI step**: GitHub Actions o similar

---

## 📊 Notas Finales

**Estado real del paso:** DISCREPANCIA con plan. Plan dice "falla por referencia a widget counter inexistente" → archivo actual NO falla, NO referencia counter, PASA 18/18. El test ya fue reparado previamente pero sigue siendo un test generico sin valor VRM especifico.

**Recomendacion:** Reemplazar (Opcion B) en vez de eliminar. Un test que verifica `DashboardPage` y `OnboardingFlow` aporta valor real al MVP sin costo adicional significativo.