---
name: Analizador - VRM Analysis Skill
description: Ejecuta análisis exhaustivo de especificaciones técnicas según proceso ANALISIS.txt
version: 1.0.0
type: analysis
target_agents: ["Claude Code", "Antigravity IDE", "Other AI Agents"]
compatible_ides: ["VS Code", "Antigravity", "Claude Code"]
---

# 🔍 /Analizador - VRM Analysis Skill

## Propósito

Ejecutar un **análisis exhaustivo y accionable** de una sección específica de un documento técnico, siguiendo el proceso definido en `ANALISIS.txt`.

**Entrada:** 
- Documento técnico (cualquier ruta)
- Sección a analizar (Fase, Día, Componente, etc.)

**Salida:**
- Archivo: `[agente]-analisis.md` (guardado en misma carpeta del documento original)
- Versionado automático si existe: `[agente]-analisis(1).md`, `[agente]-analisis(2).md`, etc.

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────┐
│ Usuario invoca:                 │
│ /Analizador                     │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│ Sistema pide:                   │
│ 1. ¿Documento a analizar?       │
│ 2. ¿Qué sección?                │
│ 3. Confirma                     │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│ Valida entrada                  │
│ • Archivo existe                │
│ • Contiene sección              │
│ • Permisos de escritura         │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│ Ejecuta ANÁLISIS                │
│ (siguiendo ANALISIS.txt)        │
│                                 │
│ 1. Comprensión del paso         │
│ 2. Supuestos y ambigüedades     │
│ 3. Diseño funcional             │
│ 4. Diseño técnico               │
│ 5. Decisiones tecnológicas      │
│ 6. Plan de implementación       │
│ 7. Riesgos y cuellos            │
│ 8. Métricas de éxito            │
│ 9. Estrategia de testing        │
│ 10. Optimización y escalabilidad│
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│ Guarda resultado:               │
│                                 │
│ Ubicación: [carpeta del doc]    │
│ Nombre: [agente]-analisis.md    │
│ Versioning: (1), (2), (3)...    │
│ Si existe: automático           │
└────────┬────────────────────────┘
         │
         ↓
    [FIN - ANÁLISIS GUARDADO] ✅
```

---

## 📥 Input Interactivo

### Pregunta 1: Documento

```
¿Qué documento quieres analizar?

Ejemplos:
  • docs/mvp-Definition.md
  • FASE_1/Dia4-5/especificacion.md
  • path/to/documento.md

Respuesta: [ruta o contenido]
```

### Pregunta 2: Sección a Analizar

```
¿Qué sección específica?

Ejemplos:
  • FASE 1
  • Dia 4-5
  • Componente: Grabación de Video
  • Feature: Auto-Stitch
  • [Descripción libre]

Respuesta: [nombre de sección]
```

### Pregunta 3: Confirmación

```
Resumen:
  • Documento: [archivo]
  • Sección: [sección]
  • Salida: [carpeta]/[agente]-analisis.md
  
¿Confirmas? [SÍ] / No
```

---

## 📋 Proceso de Análisis

Sigue exactamente el proceso de `ANALISIS.txt`:

### 1. Comprensión del Paso

- ¿Qué problema resuelve?
- ¿Qué inputs recibe?
- ¿Qué outputs debe generar?
- ¿Qué rol cumple en el sistema?

### 2. Supuestos y Ambigüedades

- Detecta TODO lo que no está definido
- Lista preguntas críticas
- Marca lo que debería resolverse antes de implementar

### 3. Diseño Funcional

- Flujo completo paso a paso (tipo pipeline)
- Casos normales
- Edge cases
- Manejo de errores

### 4. Diseño Técnico

- Arquitectura sugerida
- Componentes involucrados
- APIs / endpoints necesarios
- Modelos de datos (schemas sugeridos)
- Integraciones externas (si aplica)

### 5. Decisiones Tecnológicas

- Lenguajes / frameworks recomendados
- Librerías o herramientas clave
- Justificación técnica (no genérica)

### 6. Plan de Implementación

- Desglose en tareas pequeñas (tipo backlog técnico)
- Orden recomendado de desarrollo
- Dependencias entre tareas

### 7. Riesgos y Cuellos de Botella

- Técnicos
- Operativos
- Escalabilidad
- Costos

### 8. Métricas de Éxito

- Cómo validar que la sección está bien implementada
- KPIs técnicos y de negocio

### 9. Estrategia de Testing

- Unit tests
- Integration tests
- Casos críticos a validar

### 10. Optimización y Escalabilidad Futura

- Qué problemas aparecerán al escalar
- Cómo dejar preparado el diseño desde ahora

---

## 📤 Output: Archivo [agente]-analisis.md

### Ubicación

```
[Carpeta del documento original]
/[agente]-analisis.md

Ejemplos:
  docs/mvp-Definition.md
    → docs/[agente]-analisis.md
  
  FASE_1/Dia4-5/especificacion.md
    → FASE_1/Dia4-5/[agente]-analisis.md
  
  path/to/documento.md
    → path/to/[agente]-analisis.md
```

### Nombre del Archivo

```
Patrón: [seccion]-analisis-[agente].md

Ejemplos:
  • FASE_1-analisis-claude.md
  • Dia_4-5-analisis-claude.md
  • Grabacion_Video-analisis-antigravity.md
  • Feature_AutoStitch-analisis-openai.md
  
Donde:
  [seccion] = nombre de la sección analizada (sanitizado)
  [agente] = nombre del agente IA que ejecuta el skill
```

### Versionado Automático

Si el archivo ya existe:

```
Primera ejecución:
  → [seccion]-analisis-[agente].md

Segunda ejecución:
  → [seccion]-analisis-[agente](1).md

Tercera ejecución:
  → [seccion]-analisis-[agente](2).md

Cuarta ejecución:
  → [seccion]-analisis-[agente](3).md

Sistema detecta automáticamente el número más alto y suma 1
```

### Contenido del Archivo

```markdown
# 📊 Análisis: [Sección]

**Documento:** [ruta del documento original]
**Sección analizada:** [nombre de sección]
**Agente:** [nombre del agente IA]
**Fecha:** [timestamp]
**Versión:** [1.0.0 o (1), (2), según versionado]

---

## 1. Comprensión del Paso

[Análisis detallado]

---

## 2. Supuestos y Ambigüedades

[Lista de ambigüedades detectadas]

---

## 3. Diseño Funcional

[Flujo completo, casos normales, edge cases]

---

## 4. Diseño Técnico

[Arquitectura, componentes, APIs, modelos]

---

## 5. Decisiones Tecnológicas

[Stack elegido y justificación]

---

## 6. Plan de Implementación

[Tareas desglosadas, orden, dependencias]

---

## 7. Riesgos y Cuellos de Botella

[Análisis de riesgos]

---

## 8. Métricas de Éxito

[KPIs y validación]

---

## 9. Estrategia de Testing

[Tests recomendados]

---

## 10. Optimización y Escalabilidad Futura

[Preparación para escala]

---

## 📝 Notas

[Cualquier otra nota relevante]

---

**Análisis completado exitosamente**
```

---

## 🔄 Invocación

### Opción 1: Comando Interactivo

```bash
/Analizador

¿Documento?
→ docs/mvp-Definition.md

¿Sección?
→ FASE 1

¿Confirmas?
→ SÍ

[Ejecuta análisis]

Resultado: docs/claude-analisis.md ✅
```

### Opción 2: Con Parámetros

```bash
/Analizador --document docs/mvp-Definition.md --section "FASE 1"
```

### Opción 3: Configuración

```bash
/Analizador --config analisis-config.json
```

---

## 🎯 Casos de Uso

### Caso 1: Analizar Primera Fase

```
/Analizador
Documento: docs/mvp-Definition.md
Sección: FASE 1

Output: docs/claude-analisis.md
```

### Caso 2: Reanálisis (Versioning Automático)

```
/Analizador
Documento: docs/mvp-Definition.md
Sección: FASE 1

Primer análisis:  docs/claude-analisis.md
Segundo análisis: docs/claude-analisis(1).md ← Automático
Tercer análisis:  docs/claude-analisis(2).md ← Automático
```

### Caso 3: Analizar Componente Específico

```
/Analizador
Documento: FASE_1/Dia4-5/especificacion.md
Sección: Grabación de Video - Captura

Output: FASE_1/Dia4-5/claude-analisis.md
```

---

## ✅ Validaciones

Antes de ejecutar, verifica:

- [ ] Documento existe
- [ ] Es archivo de texto/markdown
- [ ] Carpeta del documento tiene permisos de escritura
- [ ] Sección existe en el documento
- [ ] No hay conflictos de permisos

Si algo falla → Reporta error específico

---

## 🔐 Configuración Recomendada

En `.claude/commands/analizador-config.json`:

```json
{
  "command": {
    "id": "vrm.analizador",
    "name": "Analizador",
    "description": "Análisis exhaustivo de especificaciones técnicas"
  },
  "output": {
    "pattern": "[agente]-analisis.md",
    "location": "same_as_input",
    "versioning": "auto",
    "overwrite": false
  },
  "analysis_depth": "exhaustive",
  "follow_process": "ANALISIS.txt"
}
```

---

## 📊 Metadata del Análisis

El archivo generado incluye metadata:

```markdown
**Documento:** [ruta]
**Sección:** [nombre]
**Agente:** [nombre agente IA]
**Fecha:** [ISO 8601]
**Versión archivo:** [1.0 o (N)]
**Proceso:** ANALISIS.txt v1.0
**Status:** ✅ Completado
```

---

## 🚀 Cómo Usar

### Setup

```
1. Invoca: /Analizador
2. Proporciona documento
3. Especifica sección
4. Confirma
5. Sistema genera análisis
6. Archivo guardado en carpeta original
```

### Resultado

```
[carpeta-original]/[agente]-analisis.md
  ✓ Análisis completo
  ✓ 10 secciones
  ✓ Auditable
  ✓ Reproducible
```

---

## 📝 Notas Importantes

- ✅ Sigue exactamente proceso de `ANALISIS.txt`
- ✅ Guarda en misma carpeta del documento
- ✅ Versionado automático (no sobrescribe)
- ✅ Nombre agnóstico (depende del agente)
- ✅ Análisis exhaustivo y accionable
- ✅ No inventar nada (señalar explícitamente)

---

## 🔗 Referencias

- Proceso base: `docs/process/ANALISIS.txt`
- Skill relacionada: `vrm-quality-pipeline-skill-v2.md`
- Comando: `/Analizador`

---

**Versión:** 1.0.0  
**Fecha:** 2026-04-08  
**Status:** 🟢 Production Ready

---

## 🎓 Conclusión

Esta skill transforma el proceso manual de ANALISIS.txt en un comando automatizado que:

1. **Pide input** (documento + sección)
2. **Valida** (archivo existe, permisos OK)
3. **Ejecuta análisis** (siguiendo proceso exacto)
4. **Guarda resultado** (carpeta original, versionado automático)
5. **Entrega archivo listo** (auditable y reproducible)

**Un comando. Análisis exhaustivo. Archivo guardado automáticamente.**
