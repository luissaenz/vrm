# VRM Skills Architecture

Guía visual y técnica de la arquitectura de skills para el pipeline de VRM.

---

## 🏛️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENTE IA (Cualquiera)                    │
│         Claude Code | Antigravity IDE | Otros               │
└────────────────────────┬────────────────────────────────────┘
                         │ (invoca skill)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                 SKILL ORCHESTRATOR LAYER                      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ vrm-quality-pipeline-skill.md                         │   │
│  │ ✓ Define los 5 roles                                 │   │
│  │ ✓ Define el flujo de ejecución                       │   │
│  │ ✓ Define entradas/salidas esperadas                 │   │
│  │ ✓ Define criterios de calidad                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                         │                                    │
│                         ├──→ vrm-quality-pipeline-config.json│
│                         │    (configuración ejecutable)      │
│                         │                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ROLES INDEPENDIENTES (Pueden executarse por cualquier │   │
│  │                     agente IA)                        │   │
│  │                                                        │   │
│  │ [ANALIZAR] → [IMPLEMENTAR] → [VALIDAR] → [CORREGIR] │   │
│  │                                    ↑                   │   │
│  │                                    └─ Loop max 3 veces│   │
│  │                                                        │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ (retorna resultados)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    FILESYSTEM / GIT                          │
│                                                               │
│  INPUT:  docs/mvp-Definition.md                             │
│          (documento técnico)                                │
│                                                               │
│  OUTPUT: FASE_1/Dia4-5/implementacion/                      │
│          ├── codigo/                                        │
│          ├── logs/                                          │
│          ├── reports/                                       │
│          └── README.md                                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Ejecución Detallado

### Pipeline Principal

```
┌─────────────────┐
│  DOCUMENTO      │
│  TÉCNICO (.md)  │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 1: ANALIZADOR                                       │
│ ─────────────────────────────────────────────────────  │
│                                                          │
│ Input:   Documento técnico completo                     │
│ Proceso: Validar completitud y consistencia             │
│ Output:  ✓ VÁLIDO | ❌ INVÁLIDO                         │
│                                                          │
│ Si VÁLIDO → continúa                                    │
│ Si INVÁLIDO → ESCALADA (requiere clarificación)         │
└────────┬────────────────────────────────────────────────┘
         │ (documento validado)
         ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 2: IMPLEMENTADOR                                    │
│ ────────────────────────────────────────────────────── │
│                                                          │
│ Input:   Documento técnico validado                     │
│ Proceso: Generar código funcional completo              │
│          - Dividir en componentes                       │
│          - Crear estructura de carpetas                 │
│          - Implementar cada módulo                      │
│          - Manejo de errores básico                     │
│ Output:  Código compilable/ejecutable                   │
│                                                          │
└────────┬────────────────────────────────────────────────┘
         │ (código generado)
         ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 3: VALIDADOR                                        │
│ ────────────────────────────────────────────────────── │
│                                                          │
│ Input:   Código + Documento original                    │
│ Proceso: Code review exhaustivo contra spec             │
│          - Cumplimiento funcional                       │
│          - Respeto a arquitectura                       │
│          - Calidad de código                            │
│          - Edge cases                                   │
│          - Integraciones                                │
│ Output:  Issues detectados + Decisión                   │
│          {                                               │
│            "decision": "aprobado|rechazado",             │
│            "issues": [{...}, ...]                       │
│          }                                               │
│                                                          │
└────────┬────────────────────────────────────────────────┘
         │
         ↓
    ¿APROBADO?
      /     \
    SÍ      NO
    /         \
   ↓           ↓
  FIN    ┌──────────────────────────────────┐
         │ FASE 4: CORRECTOR                │
         │ ──────────────────────────────  │
         │                                  │
         │ Input:  Issues + Código          │
         │ Proceso: Fijar issues por orden │
         │          - CRÍTICOS first        │
         │          - Luego IMPORTANTES     │
         │          - MEJORAS opcionales    │
         │ Output: Código actualizado       │
         │                                  │
         └────────┬─────────────────────────┘
                  │ (código corregido)
                  ↓
            [Vuelve a VALIDADOR]
                  │
                  ├─→ Loop counter++
                  │
                  └─→ Si loops >= max → ESCALADA
```

---

## 📦 Componentes del Sistema

### 1. Skill Definition Layer (`vrm-quality-pipeline-skill.md`)
```
└── Skill Principal
    ├── Propósito
    ├── Roles (5 funciones independientes)
    │   ├── ANALIZADOR
    │   ├── IMPLEMENTADOR
    │   ├── VALIDADOR
    │   ├── CORRECTOR
    │   └── ORQUESTADOR (coordina el flujo)
    ├── Entradas esperadas
    ├── Salidas esperadas
    ├── Flujo paso a paso
    └── Reglas de ejecución
```

### 2. Configuration Layer (`vrm-quality-pipeline-config.json`)
```
└── Configuración
    ├── Metadata (versión, descripción)
    ├── Pipeline stages (definición de fases)
    ├── Loop control (max iteraciones, condiciones)
    ├── Execution (timeouts, output dirs)
    ├── Configuration options (lenguaje, tipo, etc.)
    └── Error handling (estrategias de fallo)
```

### 3. Invocation Layer (README, INVOCATION_EXAMPLES)
```
└── Documentación
    ├── Cómo invocar desde Claude Code
    ├── Cómo invocar desde Antigravity
    ├── Ejemplos de invocación
    ├── Troubleshooting
    └── API de invocación
```

---

## 🔌 Puntos de Integración

### Integraciones Soportadas

```
┌──────────────────┐
│  VS Code        │
│  + Extensiones  │
│  ├─ Claude Code │
│  └─ [Otros]     │
└─────────┬────────┘
          │
      ┌───┴────────────┐
      │                │
      ↓                ↓
  Claude Code      Antigravity IDE
  (OpenAI/           (Custom)
   Anthropic)
      │                │
      └───┬────────────┘
          │ (ejecutan skill)
          ↓
┌─────────────────────────┐
│ VRM Quality Pipeline    │
│ Skill                   │
└────────────┬────────────┘
             │
      ┌──────┴──────┐
      │             │
      ↓             ↓
  Filesystem    Git / GitHub
  /vrm_data/    (push results)
```

---

## 🎯 Modelo de Roles

### Independencia y Composición

```
Cada ROLE es independiente:
┌────────────────┐
│   ANALIZADOR   │ ← Puede ejecutarse solo
│                │ ← Puede reutilizarse
│  Input:  .md   │ ← Agnóstico del previo
│  Output: JSON  │
└────────────────┘

         +

┌────────────────┐
│ IMPLEMENTADOR  │ ← Puede ejecutarse solo
│                │ ← Puede reutilizarse
│  Input:  JSON  │ ← Agnóstico del previo
│  Output: CODE  │
└────────────────┘

         +

┌────────────────┐
│  VALIDADOR     │ ← Puede ejecutarse solo
│                │ ← Puede reutilizarse
│  Input:  CODE  │ ← Agnóstico del previo
│  Output: JSON  │
└────────────────┘

         +

┌────────────────┐
│  CORRECTOR     │ ← Puede ejecutarse solo
│                │ ← Puede reutilizarse
│  Input:  JSON  │ ← Agnóstico del previo
│  Output: CODE  │
└────────────────┘

RESULTADO: Composable, reusable, testeable
```

---

## 🔐 Garantías de Arquitectura

### Safety Guarantees
- ✅ Cada rol tiene responsabilidad atómica
- ✅ No modificación de inputs
- ✅ Determinismo (misma entrada = misma salida)
- ✅ Agnóstico del IDE/agente
- ✅ Escalable (agregar más roles sin romper)

### Quality Guarantees
- ✅ Código respeta especificación
- ✅ 0 issues críticos
- ✅ Manejo de errores básico
- ✅ Validaciones en límites
- ✅ Testing definido

### Portability Guarantees
- ✅ Funciona en VS Code + extensiones
- ✅ Funciona en Antigravity IDE
- ✅ Funciona con cualquier agente IA
- ✅ Invocable desde CLI, API, UI
- ✅ Output portable y documentado

---

## 📊 Matriz de Responsabilidades

```
TAREA                      ANALIZADOR  IMPLEMENTADOR  VALIDADOR  CORRECTOR
─────────────────────────────────────────────────────────────────────────
Validar completitud          ✓
Detectar ambigüedades        ✓
Generar código                          ✓
Validar contra spec                                    ✓
Buscar issues                                          ✓
Arreglar issues                                                      ✓
Mantener arquitectura                                                ✓
Generar reportes             ✓          ✓              ✓           ✓
Tomar decisiones             ✓                         ✓
```

---

## 🚀 Extensibilidad

### Agregar Nuevos Roles

```markdown
# Si necesitas un rol nuevo:

1. Leer vrm-quality-pipeline-skill.md
2. Entender patrón de Role
3. Crear nuevo role:
   - Input bien definido
   - Output bien definido
   - Responsabilidad atómica
   - Agnóstico del sistema
4. Integrarlo en pipeline
5. Documentar en README
```

### Ejemplo: Agregar rol "DOCUMENTADOR"

```
PIPELINE EXTENDIDO:

Analizar → Implementar → Validar → Corregir → DOCUMENTAR → Fin

Donde DOCUMENTADOR:
- Input: Código final + especificación
- Proceso: Generar documentación
- Output: Markdown + API docs
```

---

## 📈 Escalabilidad

### Escalable en:
- **Complejidad de componentes:** Skills para features grandes
- **Equipo:** Roles independientes = puede hacer cada uno distinto agente
- **Proyectos:** Reutilizable para otros proyecto que sigan mismo patrón
- **Versiones:** Múltiples versiones del skill en paralelo

### No escalable en:
- Componentes con ciclos complejos (rediseñar)
- Múltiples agentes simultáneos (requiere coordinación)
- Cambios frecuentes de especificación (mantener documento)

---

## 🔍 Validación de Arquitectura

### Cómo verificar que está bien implementado

```bash
# 1. Verificar que roles son independientes
[] Analizador puede ejecutarse sin el resto
[] Implementador puede correr solo si tiene input válido
[] Validador puede funcionar con cualquier código
[] Corrector maneja issues genéricos

# 2. Verificar que flujo es correcto
[] ANALIZAR valida → bloquea si falla
[] IMPLEMENTAR genera código → bloquea si ambiguo
[] VALIDAR decide → APROBADO o RECHAZADO
[] CORRECTOR hace loops → máximo 3

# 3. Verificar que output es portability
[] Código en carpeta output
[] Logs en JSON
[] Reportes descargables
[] Documentación actualizada
```

---

## 📝 Notas de Diseño

### Por qué esta arquitectura

1. **Separación de Responsabilidades**
   - Cada rol hace UNA cosa
   - Fácil de mantener, testear, escalar

2. **Determinismo**
   - Misma entrada → misma salida
   - Reproducible, auditable

3. **Agnóstico del IDE**
   - No depende de características del IDE
   - Portable a cualquier agente IA

4. **Loops de Corrección**
   - Máximo 3 iteraciones
   - Escalada si no converge
   - No loops infinitos

5. **Output Documentado**
   - JSON para máquinas
   - Markdown para humanos
   - Logs para debugging

---

## 🎓 Referencias

- [Skill Principal](vrm-quality-pipeline-skill.md)
- [Configuración](vrm-quality-pipeline-config.json)
- [Ejemplos de Invocación](INVOCATION_EXAMPLES.md)
- [Documentación General](README.md)

---

**Última actualización:** 2026-04-08  
**Versión:** 1.0.0  
**Status:** 🟢 Production Ready
