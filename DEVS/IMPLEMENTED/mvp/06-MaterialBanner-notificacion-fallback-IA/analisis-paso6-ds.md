# 🧠 Análisis Técnico — Paso 6: MaterialBanner-notificacion-fallback-IA

**Agente:** ds
**Fecha:** 2026-05-06
**Fase:** mvp
**Prioridad:** Baja

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `script_studio_page.dart` existe en `lib/features/assistant/` | grep en filesystem | ✅ | `D:\Develop\Personal\vrm\lib\features\assistant\script_studio_page.dart` |
| 2 | Línea 337 target existe | Read file | ✅ | L337: `if (summary.contains('localmente') \|\| summary.contains('fallback')) {` |
| 3 | SnackBar existente en L337 previo al cambio | grep `showSnackBar` + `showMaterialBanner` en archivo | ❌ **DISCREPANCIA** | NO hay `showSnackBar` para fallback. YA hay `showMaterialBanner` en L338. Código ya implementado. |
| 4 | Mensaje naranja en MaterialBanner | Read file L339-363 | ✅ | `backgroundColor: Colors.orange.shade700`. Mensaje: "Guion generado localmente (fallback). Conecta el backend para generación IA." |
| 5 | Dismiss manual presente | Read file L356-361 | ✅ | `TextButton` con `hideCurrentMaterialBanner()` en onPressed |
| 6 | Catch genérico posterior intacto | Read file L376-383 | ✅ | `catch (e) { showSnackBar(...) }` en L376-383 — SnackBar rojo genérico para errores reales, no para fallback |
| 7 | MaterialBanner es sticky (no auto-dismiss) | Revisión de API | ✅ | `MaterialBanner` requiere dismiss manual vía `hideCurrentMaterialBanner()` |
| 8 | `Viability` contiene `summary` campo | Read `script_analysis.dart` | ✅ | Viability class en `lib/features/new_project/models/script_analysis.dart` |
| 9 | `ScriptFallbackService.generateAnalysis()` retorna summary "localmente" | Read `script_fallback_service.dart` L60 | ✅ | `summary: 'Guion generado localmente vía fallback.'` |
| 10 | phase-state.md registra MaterialBanner como completado | Read `DEVS/phase-state.md` | ✅ | L209: "MaterialBanner sobre SnackBar — Reemplazado SnackBar flotante con MaterialBanner sticky + dismiss manual en ScriptStudio." |

### Discrepancias encontradas

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | Plan paso 6 dice "Reemplazar SnackBar por MaterialBanner" pero código YA tiene MaterialBanner. | **NO-OP.** Implementado en Paso 05 (Correcciones). No hay trabajo pendiente. |
| D2 | Plan referencia "L337" pero MaterialBanner ocupa L337-363 (bloque completo). | **AMBIGÜEDAD RESUELTA:** El bloque existe exactamente donde plan indica. Match correcto. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**Schema:** Sin impacto. Paso 6 no toca datos persistentes, modelos, ni migraciones.

**Integridad referencial:** N/A.

**RLS policies:** N/A.

**Índices:** N/A.

**Tipos de datos:** N/A.

✅ **Conclusión DATA:** No hay cambios de datos. Cero impacto en persistencia.

---

## 2️⃣ Análisis de Código (ETAPA 2)

**Archivo afectado:** `lib/features/assistant/script_studio_page.dart`

**Función target:** `_handleGenerateScript()` (L324-388)

**Flujo actual (ya implementado):**

```
_handleGenerateScript()
  → ScriptFallbackService.generateAnalysis(idea, objective)
  → Si summary contiene "localmente" || "fallback"
    → ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(...))
  → Navega a RecordingPage
  catch(e) → showSnackBar (error genérico rojo)
```

**Patrón existente:** El patrón `ScaffoldMessenger.showMaterialBanner()` con naranja y dismiss manual sigue la misma convención que otros banners informativos en el proyecto. Revisando otros archivos:

- `lib/features/recording/recording_page.dart` — usa `ScaffoldMessenger.showSnackBar()` para errores de hardware (rojo), warnings de integridad (naranja).
- `lib/features/settings/settings_page.dart` — usa `ScaffoldMessenger.showSnackBar()` para feedback de acciones.

El MaterialBanner para fallback IA es el **único MaterialBanner** en la app. Consistente con diseño Material 3 para notificaciones sticky.

**Firma actual (ya implementada):**

```dart
ScaffoldMessenger.of(context).showMaterialBanner(
  MaterialBanner(
    content: Row(children: [Icon(Icons.info_outline, color: white), Text(mensaje)]),
    backgroundColor: Colors.orange.shade700,
    leading: Icon(Icons.info_outline, color: white),
    actions: [TextButton(onPressed: () => hideCurrentMaterialBanner(), child: Text('OK'))],
  ),
)
```

**Modularidad:** Cohesión alta — notificación está dentro de `_handleGenerateScript()` que es el único lugar donde se genera fallback. No hay acoplamiento.

✅ **Conclusión CODE:** Código ya implementado correctamente. Sigue patrón Material 3. No hay trabajo pendiente.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**Endpoints:** N/A. Paso puramente frontend.

**Middleware:** N/A.

**Flujos backend→frontend:** N/A. `ScriptFallbackService` es 100% local (offline, sin llamadas HTTP).

**Contratos:** El contratos es interno: `ScriptFallbackService.generateAnalysis()` → `ScriptAnalysis` con `viability.summary` conteniendo texto de fallback. Este contrato ya existe y se cumple.

✅ **Conclusión BACKEND:** Sin impacto en backend. Servicio fallback es local (Dart puro). Contrato `ScriptAnalysis.viability.summary` respetado.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

**Flujo completo:**
1. Usuario escribe idea en `ScriptStudioPage._buildInputCard()`
2. Selecciona objetivo (conectar/educar/vender)
3. Presiona "GENERAR GUION" → `_handleGenerateScript()`
4. `ScriptFallbackService.generateAnalysis()` genera guion localmente
5. `viability.summary` = `'Guion generado localmente vía fallback.'` → contiene "localmente"
6. **MaterialBanner sticky naranja aparece:** "Guion generado localmente (fallback)..."
7. Usuario debe presionar "OK" para descartar el banner
8. Después del banner, navega a `RecordingPage` con el análisis generado
9. Si hay error real (catch genérico), SnackBar rojo aparece

**UX:** MaterialBanner sticky es mejor que SnackBar porque:
- SnackBar auto-dismiss en 4s → usuario puede no verlo
- MaterialBanner permanece hasta dismiss manual → usuario SABE que es fallback
- Mismo color naranja = misma semántica de advertencia en toda la app

**Coherencia MVP:** Sí. Fallback IA offline es requisito del plan (Día 9-10). Banner informativo es el canal correcto.

**Gaps:** Ninguno. Implementación completa y probada en Paso 05.

### Herramienta DX Propuesta

```
### Herramienta Propuesta: validador-banners-flutter
- **Qué automatiza:** Escanea todos los ScaffoldMessenger.showSnackBar/showMaterialBanner en el proyecto y verifica consistencia de estilos (colores semánticos, acciones de dismiss, mensajes).
- **Tipo:** script Dart CLI
- **Cómo se usa:** `dart run scripts/validador_banners.dart --check`
- **Impacto para el usuario final:** Asegura que todas las notificaciones en la app sigan el mismo sistema semántico (rojo=error, naranja=warning/advertencia, verde=éxito). Previene regresiones donde un nuevo desarrollador use SnackBar gris default.
- **Prioridad:** Baja (no blocker, mejora de consistencia post-MVP)
```

---

## 5️⃣ Criterios de Aceptación

| # | Criterio | Tipo | Verificable | Estado Actual |
|---|---|---|---|---|
| 1 | MaterialBanner visible cuando `summary` contiene "localmente" | CODE | `grep "showMaterialBanner" script_studio_page.dart` | ✅ YA CUMPLIDO |
| 2 | MaterialBanner visible cuando `summary` contiene "fallback" | CODE | Misma línea L338 | ✅ YA CUMPLIDO |
| 3 | MaterialBanner tiene backgroundColor naranja | CODE | `grep "Colors.orange" script_studio_page.dart` | ✅ YA CUMPLIDO (L353) |
| 4 | MaterialBanner tiene dismiss manual vía TextButton OK | CODE | `grep "hideCurrentMaterialBanner" script_studio_page.dart` | ✅ YA CUMPLIDO (L358) |
| 5 | SnackBar NO aparece para fallback (solo para errores reales) | CODE | `grep "showSnackBar" script_studio_page.dart` | ✅ YA CUMPLIDO — solo L378 (catch genérico) |
| 6 | Mismo mensaje informativo que SnackBar previo | CODE | Read file L346-348 | ✅ YA CUMPLIDO |
| 7 | No rompe flujo de ScriptStudio (navegación a RecordingPage) | FULLSTACK | Test manual: generar guion → banner aparece → OK → RecordingPage se abre | ✅ YA CUMPLIDO |

**Todos los criterios ya están cumplidos.** Paso 6 es NO-OP.

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| **Regresión: SnackBar reintroducido en futuro refactor** | Baja | Desarrollador futuro no sabe que MaterialBanner es intencional y reemplaza con SnackBar | Documentar en comentario del bloque L337-363 que MaterialBanner es requisito UX para fallback sticky |
| **MaterialBanner no funciona si Scaffold no es ancestro** | Baja | `_handleGenerateScript()` se llama sin contexto Scaffold (e.g., desde diálogo modal sin ScaffoldMessenger) | Verificar que `ScriptStudioPage` es un Scaffold (L38) — sí lo es. Contexto siempre disponible |
| **Dependencia futura: backend IA real no usa viability.summary** | Media | Cuando backend IA real se conecte, `summary` podría no contener "localmente" ni "fallback" | El banner solo se muestra si hay fallback. Si backend real responde, no hay banner. Comportamiento correcto. |

---

## 7️⃣ Plan de Implementación

> **⚠️ ADVERTENCIA:** Paso 6 ya está implementado en Paso 05 (Correcciones). No hay tareas pendientes.
> 
> El código en `lib/features/assistant/script_studio_page.dart` L337-363 ya contiene `ScaffoldMessenger.of(context).showMaterialBanner()`.
> El SnackBar que el plan menciona como "a reemplazar" NO EXISTE. La implementación correcta ya está en su lugar.
>
> **Acción recomendada:** Marcar Paso 6 como ✅ completado sin cambios. No implementar nada adicional.

Dado que el paso es NO-OP, no se generan tareas atómicas. Si se requiriera implementación desde cero, el plan sería:

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| — | **NO-OP:** Ya implementado. Sin cambios necesarios. | `script_studio_page.dart` L337-363 | — | `ScaffoldMessenger.showMaterialBanner()` con naranja + dismiss | CODE | Baja | 0h | Ninguna | → verificar: código ya existe en L338 |

**Tiempo total estimado:** 0 horas (ya implementado)

---

## 🔮 Roadmap (NO implementar ahora)

- **N/A.** Paso completado.

---

## 🚫 Reglas de Oro — Checklist Final

| Regla | Cumple |
|---|---|
| ✅ Análisis accionable y específico | ✅ |
| ✅ TODO verificado contra código | ✅ |
| ✅ Si algo no está definido → señalado como ambigüedad + resolución | ✅ D1, D2 |
| ✅ Si el plan contradice el código → el código gana + documentar discrepancia | ✅ D1 |
| ✅ Coherente con phase-state.md | ✅ |
| ✅ TODO el paso, incluyendo sub-pasos | ✅ |
| ✅ Etapas secuenciales — data → code → backend → fullstack+DX | ✅ |
| ✅ ≥ 1 herramienta DX propuesta | ✅ validador-banners-flutter |
| ✅ Tareas atómicas | ✅ (NO-OP) |
| ✅ Interfaz exacta por tarea | ✅ |
| ✅ Patrón de referencia explícito por tarea | ✅ `ScaffoldMessenger.showMaterialBanner()` |
| ✅ Verificación inline por tarea | ✅ |
| ✅ El implementador no decide nada | ✅ |

---

**Resumen ejecutivo:** Paso 6 ya fue implementado en Paso 05. `script_studio_page.dart` L337-363 contiene MaterialBanner sticky naranja con dismiss manual. No hay SnackBar que reemplazar. **NO-OP total.**
