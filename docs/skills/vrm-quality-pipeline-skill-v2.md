---
name: VRM Quality Pipeline Skill v2
description: Skill agnóstico de archivos - Ejecuta ciclo de análisis, implementación y validación basado en contenido
version: 2.0.0
type: orchestration
target_agents: ["Claude Code", "Antigravity IDE", "Other AI Agents"]
compatible_ides: ["VS Code", "Antigravity", "Claude Code"]
---

# 🎯 VRM Quality Pipeline Skill v2.0 (Agnóstico de Archivos)

## 🔄 Cambios Principales v2.0

- ✅ **Agnóstico de rutas de archivos** - Funciona con cualquier documento
- ✅ **Agnóstico de estructura de proyecto** - No depende de carpetas específicas
- ✅ **Reporte final consolidado** - Salida única con todo lo necesario
- ✅ **Sin guardado de intermedios** - Solo entrada y salida final
- ✅ **Contenido-céntrico** - Solo importa qué contiene el documento

---

## 📋 Propósito

Transformar un **documento técnico con especificación** en:
1. **Código compilable y validado**
2. **Reporte final** con todo el proceso documentado
3. **Sin dependencias** a rutas o estructura específicas

**Entrada:** Documento técnico (cualquier ruta, cualquier nombre)
**Salida:** Código + Reporte Final (un solo archivo consolidado)

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────┐
│  DOCUMENTO DE ENTRADA (Cualquier)   │
│  Contenido:                         │
│  • Descripción del problema         │
│  • Diseño funcional                 │
│  • Diseño técnico                   │
│  • Plan de implementación           │
│  • Riesgos                          │
└────────────┬────────────────────────┘
             │
             ↓
    ┌────────────────┐
    │ ANALIZAR       │ ← Valida que contenido sea completo
    │ (5-10 min)     │   Sin referencias a archivos
    └────────┬───────┘
             │
             ↓ (si VÁLIDO)
    ┌────────────────┐
    │ IMPLEMENTAR    │ ← Lee plan, genera código
    │ (60-90 min)    │   Sin references hardcodeadas
    └────────┬───────┘
             │
             ↓
    ┌────────────────┐
    │ VALIDAR        │ ← Code review contra spec
    │ (30-45 min)    │   Genera lista de issues
    └────────┬───────┘
             │
        ¿APROBADO?
        /         \
      SÍ           NO
      │             │
      │             └──→ ┌──────────────┐
      │                  │ CORRECTOR    │
      │                  │ (30-60 min)  │
      │                  │ Max 3 loops  │
      │                  └──────┬───────┘
      │                         │
      │                  [Vuelve a VALIDAR]
      │
      ↓
┌──────────────────────────────────┐
│ GENERAR REPORTE FINAL            │
│ • Resumen ejecutivo              │
│ • Código generado (completo)     │
│ • Issues detectados/corregidos   │
│ • Logs de ejecución              │
│ • Métricas                       │
│ • Próximos pasos                 │
└──────────┬───────────────────────┘
           │
           ↓
    [FIN - REPORTE LISTO] ✅
```

---

## 📥 Input: Especificación del Documento

El documento debe ser **texto estructurado** con:

```
1. DESCRIPCIÓN DEL PROBLEMA
   - Qué se va a construir
   - Por qué
   - A quién le sirve

2. DISEÑO FUNCIONAL
   - Objetivo
   - Entrada/salida
   - Flujo paso a paso
   - Edge cases

3. DISEÑO TÉCNICO
   - Arquitectura
   - Componentes
   - APIs/interfaces
   - Modelos de datos
   - Integraciones

4. PLAN DE IMPLEMENTACIÓN
   - Tareas desglosadas
   - Orden recomendado
   - Dependencias
   - Estimaciones

5. RIESGOS Y MITIGACIONES
   - Problemas potenciales
   - Estrategias de manejo
```

**No importa:**
- ❌ Ruta del archivo
- ❌ Nombre del archivo
- ❌ Ubicación en carpetas
- ❌ Formato exacto
- ❌ Lenguaje de markup

**Solo importa:**
- ✅ Contenido presente
- ✅ Información completa
- ✅ Claridad de instrucciones

---

## 📤 Output: Reporte Final Consolidado

**Salida única (todo en un archivo):**

```
REPORTE_IMPLEMENTACION_[timestamp].md

Contenidos:
├── 1. RESUMEN EJECUTIVO
│   ├── Entrada: [Descripción del documento]
│   ├── Salida: [Qué se generó]
│   ├── Resultado: APROBADO/RECHAZADO
│   └── Métricas: líneas, componentes, issues
│
├── 2. ESPECIFICACIÓN PROCESADA
│   ├── Plan de implementación (extraído del documento)
│   ├── Componentes identificados
│   └── Arquitectura entendida
│
├── 3. CÓDIGO GENERADO
│   ├── Estructura de carpetas
│   ├── Código completo de cada componente
│   ├── Interfaces y contratos
│   └── Tests definidos
│
├── 4. VALIDACIÓN Y ISSUES
│   ├── Issues detectados (críticos, importantes, mejoras)
│   ├── Issues corregidos
│   ├── Loops de corrección usados
│   └── Justificaciones técnicas
│
├── 5. MÉTRICAS Y ESTADÍSTICAS
│   ├── Líneas de código
│   ├── Componentes generados
│   ├── Tiempo total
│   ├── Coverage de especificación
│   └── Quality score
│
├── 6. DECISIONES TÉCNICAS
│   ├── Patrones elegidos
│   ├── Justificaciones
│   └── Alternativas consideradas
│
├── 7. PRÓXIMOS PASOS
│   ├── Build y deploy
│   ├── Testing recomendado
│   ├── Optimizaciones futuras
│   └── Escalabilidad
│
└── 8. LOGS Y DEBUG
    ├── Timeline de ejecución
    ├── Decisiones en cada fase
    └── Errors encontrados y resueltos
```

---

## 🔄 Fases (Sin Referencias a Archivos)

### FASE 1: ANALIZADOR (Agnóstico)

**Input:** Contenido del documento (lo que el usuario pase)

**Análisis:**
```
1. ¿Tiene descripción del problema?
2. ¿Tiene diseño funcional?
3. ¿Tiene diseño técnico?
4. ¿Tiene plan de implementación?
5. ¿Tiene riesgos identificados?
6. ¿Plan es accionable?
7. ¿Arquitectura es clara?
```

**Output:** `valid | invalid` + detalles

**Nota:** No importa si viene de `docs/mvp.md` o `FASE_1/Dia4-5/analisis.md`

---

### FASE 2: IMPLEMENTADOR (Agnóstico)

**Input:** Contenido del plan (extraído del documento)

**Proceso:**
```
1. Lee PLAN DE IMPLEMENTACIÓN del documento
2. Identifica COMPONENTES y MÓDULOS
3. Genera CÓDIGO para cada uno
4. NO referencia rutas específicas
5. Código es PORTABLE (no depende de estructura)
```

**Output:** Código estructurado (no en carpetas, en el reporte)

**Nota:** El código generado es agnóstico de dónde se colocará

---

### FASE 3: VALIDADOR (Agnóstico)

**Input:** Código + Contenido original del documento

**Validación:**
```
1. Compara código contra ESPECIFICACIÓN (contenido)
2. Revisa que cubra TODO el PLAN
3. Identifica ISSUES (críticos, importantes, mejoras)
4. NO valida contra rutas o estructura
```

**Output:** Lista de issues + decisión

---

### FASE 4: CORRECTOR (Agnóstico)

**Input:** Issues detectados + Código

**Corrección:**
```
1. Arregla CRÍTICOS (obligatorio)
2. Arregla IMPORTANTES (recomendado)
3. Arregla MEJORAS (opcional)
4. NO añade complejidad innecesaria
```

**Output:** Código actualizado + changelog

**Loop:** Máximo 3 iteraciones

---

## 📊 Datos que Fluyen (No Archivos)

```
FLUJO DE DATOS (No archivos):

Documento (texto)
    │
    ├─→ ANALIZADOR
    │   └─→ {valid: true, issues: [...]}
    │
    ├─→ IMPLEMENTADOR
    │   └─→ {codigo: "...", componentes: [...]}
    │
    ├─→ VALIDADOR
    │   └─→ {issues: [...], decision: "aprobado"}
    │
    └─→ REPORTE FINAL (uno solo)
        {
          especificacion: "...",
          codigo: "...",
          validacion: "...",
          metricas: "..."
        }
```

**Nota:** Todo se mantiene en memoria, no en archivos intermedios

---

## 📥 Cómo Invocar (Agnóstico)

### Opción 1: Contenido Directo

```
/Implementador
Pega el contenido de tu especificación aquí:

## Mi Especificación

### Descripción
Necesito una función que...

### Diseño Funcional
Input: ...
Output: ...

### Diseño Técnico
Arquitectura: ...

### Plan
1. Crear componente X
2. Implementar Y
3. ...
```

### Opción 2: Archivo (Pero agnóstico)

```
/Implementador
input: [cualquier ruta]/[cualquier nombre].md
```

El sistema NO asume dónde está. Solo lee.

### Opción 3: URL o Contenido Remoto

```
/Implementador --url https://raw.githubusercontent.com/.../spec.md
```

---

## 📋 No Necesita Guardar Intermedios

**Respuesta a tu pregunta:**

**❌ NO se necesita guardar análisis intermedios** porque:

1. **El reporte final contiene TODO**
   - Especificación procesada
   - Plan entendido
   - Issues detectados
   - Decisiones tomadas

2. **La traza está en los logs**
   - Timeline de ejecución
   - Decisiones en cada fase
   - Errores y resoluciones

3. **El código está completo**
   - Código final en el reporte
   - Copiar-pegar directamente
   - Sin dependencias de archivos

**Ejemplo de salida:**
```
REPORTE_IMPLEMENTACION_20260408_143015.md
  ├── Especificación original (en el reporte)
  ├── Código generado (en el reporte)
  ├── Issues log (en el reporte)
  ├── Métricas (en el reporte)
  └── Próximos pasos (en el reporte)

→ UN ARCHIVO ÚNICO
→ CONTIENE TODO
→ LISTO PARA USAR
```

---

## 🎯 Ventajas de Esta Arquitectura

| Aspecto | Beneficio |
|---------|-----------|
| **Agnóstico** | Funciona con cualquier documento |
| **Portable** | Código generado no depende de rutas |
| **Simple** | Solo entrada → salida |
| **Auditable** | Reporte contiene todo |
| **Reproducible** | Misma entrada = mismo output |
| **Escalable** | Funciona para cualquier tamaño |

---

## 📤 Ejemplo de Reporte Final

```markdown
# 📊 Reporte de Implementación

**Generado:** 2026-04-08 14:30:15  
**Agente:** VRM Quality Pipeline v2.0  
**Status:** ✅ APROBADO

---

## 1. Resumen Ejecutivo

**Entrada:** Especificación de Grabación de Video  
**Salida:** Módulo de grabación compilable en Dart/Flutter

**Resultado:** APROBADO
- ✓ Especificación válida
- ✓ Código completo y compilable
- ✓ 0 issues críticos
- ✓ 100% de especificación cubierta

**Métricas:**
- Líneas de código: 450
- Componentes: 5
- Issues detectados: 3
- Issues corregidos: 3
- Loops usados: 2/3
- Tiempo total: 2h 15min

---

## 2. Especificación Procesada

[Extracción del plan del documento original]

Plan de Implementación Identificado:
1. Crear servicio de permisos
2. Implementar controller de cámara
3. Generar modelos de datos
4. Integrar storage
5. Tests unitarios

---

## 3. Código Generado

### Componente 1: PermissionService

```dart
class PermissionService {
  // Código completo aquí
}
```

### Componente 2: CameraController

```dart
class CameraController {
  // Código completo aquí
}
```

[... resto de componentes ...]

---

## 4. Validación y Issues

**Issues Detectados:**
- CRÍTICO: Falta manejo de error en X
- IMPORTANTE: Performance puede mejorar en Y
- MEJORA: Documentación en Z

**Issues Corregidos:**
- CRÍTICO: ✓ Resuelto (Razón: agregó try-catch)
- IMPORTANTE: ✓ Resuelto (Razón: optimizó loop)
- MEJORA: ✓ Resuelto (Razón: agregó comentarios)

---

## 5. Métricas

- Coverage de especificación: 100%
- Quality score: 9.2/10
- Compilable: ✓
- Tests viable: ✓

---

## 6. Próximos Pasos

1. Copiar código a `lib/features/recording/`
2. Ejecutar: `flutter pub get`
3. Compilar: `flutter build apk`
4. Tests: `flutter test`

---

## 7. Logs

[Timeline de ejecución con timestamps]
[Decisiones en cada fase]
[Cualquier issue encontrado y resuelto]

---

**Fin del reporte**
```

---

## 🔑 Principios de Diseño v2.0

1. **Contenido, no archivos**
   - Importa QUÉ dice el documento
   - No importa DÓNDE está

2. **Una salida consolidada**
   - Todo en un reporte
   - No carpetas ni intermedios

3. **Agnóstico de estructura**
   - Funciona en cualquier proyecto
   - Código es portable

4. **Trazabilidad completa**
   - Reporte contiene TODO
   - Auditable de principio a fin

5. **Sin dependencias**
   - No depende de rutas hardcodeadas
   - No depende de estructura específica

---

## 🚀 Cómo Usar

### Setup

```
1. Lee este documento
2. Invoca: /Implementador
3. Pega especificación (o archivo)
4. Sigue preguntas interactivas
5. Sistema genera reporte
```

### Resultado

```
REPORTE_IMPLEMENTACION_[timestamp].md
  ✓ Listo para copiar código
  ✓ Documentado completamente
  ✓ Auditable
  ✓ Reproducible
```

---

## 📝 Nota Final

**v2.0 es radicalmente más simple:**

- ❌ No maneja carpetas específicas
- ❌ No guarda intermedios
- ❌ No references a FASE_1/Dia4-5
- ✅ Solo contenido + salida
- ✅ Completamente agnóstico
- ✅ Reporte final único

**Es la versión de producción.**

---

**Versión:** 2.0.0  
**Fecha:** 2026-04-08  
**Status:** 🟢 Production Ready
