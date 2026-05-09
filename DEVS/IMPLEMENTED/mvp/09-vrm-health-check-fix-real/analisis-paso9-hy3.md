# analisis-paso9-hy3

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | vrm_health_check.dart existe | ls scripts/ | ✅ | scripts/vrm_health_check.dart |
| 2 | --fix flag soportado | grep 'fix' | ✅ | L20, L36, L156 |
| 3 | _runFixCleanup() existe | grep '_runFixCleanup' | ✅ | L175 |
| 4 | Limpieza vrm_data/tmp/ | lectura código | ✅ | L178-188 |
| 5 | Limpieza sesiones huerfanas | lectura código | ✅ | L190-220 |
| 6 | No borra proyectos validos | lógica sesión | ✅ | L199: borra session solo si no hay project.json |
| 7 | Patrón store_prep_cli.dart | comparar subcomandos | ✅ | ambos ejecutan acciones reales |
| 8 | Plan L120-122 coinciden | grep L120-122 | ❌ | Plan dice L120-122, fix en L175-223 |
| 9 | store_prep_cli.dart existe | ls scripts/ | ✅ | scripts/store_prep_cli.dart |
| 10 | store_prep_cli.dart acciones reales | lectura código | ✅ | _runCheck() ejecuta validaciones |

### Discrepancias
1. Plan L120-122 → fix en L175-223. Resolución: actualizar plan.md.

## 1️⃣ Análisis de Datos (ETAPA 1)
- ✅ Schema: vrm_data/ (filesystem JSON), tmp/ (temp files), projects/ (session_data.json + project.json)
- ✅ Integridad: session_data.json depende de project.json (padre)
- ✅ RLS: no aplica (filesystem)
- ✅ Índices: no aplica
- ✅ Tipos: JSON, binary/video

## 2️⃣ Análisis de Código (ETAPA 2)
- ✅ Función: _runFixCleanup() → Future<void>, sin params
- ✅ Patrón: igual a store_prep_cli.dart (subcomandos acciones reales)
- ✅ Modularidad: cohesivo (solo cleanup)
- ✅ Imports: dart:io, dart:convert → correctos
- ⚠️ Calidad: sin try/catch en borrado de archivos

## 3️⃣ Análisis de Backend (ETAPA 3)
- ✅ No aplica: paso es CLI Dart, no backend FastAPI

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)
- ✅ Flujo: CLI → --fix → limpieza → output documentado
- ❌ Discrepancia: plan L120-122 no coinciden
- ✅ DX: vrm_health_check.dart ya es herramienta DX
- ### Herramienta Propuesta: --dry-run flag para --fix
  - **Qué automatiza:** lista acciones de limpieza sin ejecutarlas → evita borrados accidentales
  - **Tipo:** flag CLI
  - **Cómo se usa:** dart run scripts/vrm_health_check.dart check --fix --dry-run
  - **Impacto:** usuario ve qué se borrará antes de ejecutar
  - **Prioridad:** Tarea 0

## 5️⃣ Criterios de Aceptación
✅ [DATA] vrm_data/tmp/ limpia correctamente
✅ [CODE] _runFixCleanup() existe
✅ [FULLSTACK] --fix ejecuta acciones reales
✅ [FULLSTACK] Acciones documentadas en output
✅ [FULLSTACK] No borra proyectos validos
✅ [DX] --dry-run flag disponible

## 6️⃣ Riesgos
| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Borrar tmp/ en uso | Media | App grabando clips | Skip archivos bloqueados |
| Borrar session errónea | Alta | project.json corrupto | Validar JSON antes de borrar |
| Crash por permisos | Media | Sin try/catch | Añadir try/catch por archivo |

## 7️⃣ Plan de Implementación
| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: --dry-run flag | scripts/vrm_health_check.dart | flag --dry-run en subcomando check | store_prep_cli.dart flags | DX | Baja | 0.5h | Ninguna | → dart run scripts/vrm_health_check.dart check --fix --dry-run lista acciones |
| 1 | Corregir plan L120-122 | DEVS/plan.md | actualizar paso 9 tareas L120-122 → L175-223 | — | DATA | Baja | 0.5h | Ninguna | → plan.md paso 9 tiene líneas correctas |
| 2 | Try/catch en _runFixCleanup | scripts/vrm_health_check.dart | try/catch en bucles de borrado | store_prep_cli.dart error handling | CODE | Media | 1h | Tarea 0 | → --fix no crashea por permisos |
| 3 | Validar project.json | scripts/vrm_health_check.dart | verificar project.json válido antes de borrar session | store_prep_cli.dart JSON validation | CODE | Media | 1h | Tarea 2 | → no borra sesiones de proyectos corruptos |

**Tiempo total:** 3h

## 🔮 Roadmap (NO implementar ahora)
- Añadir --verbose flag para más detalles de limpieza
- Integrar vrm_health_check.dart en CI para limpieza automática de tmp/

## 🚫 Reglas de Oro
- ✅ Análisis accionable, verificado contra código
- ✅ Discrepancia plan L120-122 documentada
- ✅ Tareas atómicas, 1 artefacto por tarea
- ✅ Interfaz exacta por tarea
- ✅ Patrón store_prep_cli.dart explícito
