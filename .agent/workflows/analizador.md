---
name: Analizador
alias: /Analizador
description: Ejecuta análisis exhaustivo de secciones de documentos técnicos
version: 1.0.0
category: VRM Analysis
---

# /Analizador - VRM Analysis Command

## Descripción

Comando interactivo que ejecuta un **análisis exhaustivo y accionable** de cualquier sección de un documento técnico, guardando el resultado automáticamente en la **misma carpeta del documento original** con versionado automático.

---

## 🚀 Uso Rápido

```
/Analizador
```

El sistema te pedirá:
1. **Documento a analizar** (ruta o contenido)
2. **Sección específica** (Fase, Día, Componente, Feature)
3. **Confirmación**

**Resultado:** Archivo guardado automáticamente

```
[carpeta-original]/[seccion]-analisis-[agente]([N]).md
```

---

## 📋 Flujo Interactivo

```
┌────────────────────────────────────────┐
│ Usuario: /Analizador                   │
└────────┬─────────────────────────────┬─┘
         │                             │
         ↓                             ↓
    ¿Documento?              ¿Sección a analizar?
    docs/mvp.md              FASE 1
         │                             │
         └────────────┬────────────────┘
                      │
                      ↓
              ┌──────────────────┐
              │ Validaciones     │
              │ ✓ Archivo existe │
              │ ✓ Permisos OK    │
              │ ✓ Sección existe │
              └────────┬─────────┘
                       │
                       ↓
              ┌──────────────────┐
              │ Ejecuta ANÁLISIS │
              │ (10 secciones)   │
              └────────┬─────────┘
                       │
                       ↓
         ┌─────────────────────────────┐
         │ Guarda resultado:           │
         │ /docs/FASE_1-analisis-claude.md    │
         │                             │
         │ Si existe:                  │
         │ → FASE_1-analisis-claude(1).md ✓   │
         │ → claude-analisis(2).md ✓   │
         │ → automático                │
         └────────┬────────────────────┘
                  │
                  ↓
          [✅ ANÁLISIS GUARDADO]
```

---

## 💻 Ejemplos de Uso

### Ejemplo 1: Analizar Primera Fase

```
/Analizador

¿Qué documento quieres analizar?
→ docs/mvp-Definition.md

¿Qué sección específica?
→ FASE 1

¿Confirmas? (SÍ/No)
→ SÍ

[Sistema ejecuta análisis...]

✅ Análisis guardado: docs/FASE_1-analisis-claude.md
```

### Ejemplo 2: Reanálisis (Versionado Automático)

```
/Analizador
Documento: docs/mvp-Definition.md
Sección: FASE 1
Confirma: SÍ

✅ Primera vez: docs/FASE_1-analisis-claude.md

/Analizador
Documento: docs/mvp-Definition.md
Sección: FASE 1 (actualizado)
Confirma: SÍ

✅ Segunda vez: docs/FASE_1-analisis-claude(1).md (automático)
✓ NO sobrescribe
✓ Nueva versión
```

### Ejemplo 3: Analizar Componente Específico

```
/Analizador

¿Documento?
→ FASE_1/Dia4-5/especificacion.md

¿Sección?
→ Grabación de Video - Captura de Frames

¿Confirmas?
→ SÍ

✅ Guardado: FASE_1/Dia4-5/Grabacion_Video_Captura-analisis-claude.md
```

### Ejemplo 4: Analizar Feature Completa

```
/Analizador

¿Documento?
→ docs/features/recording.md

¿Sección?
→ Feature: Auto-Stitch (Día 4-5)

¿Confirmas?
→ SÍ

✅ Guardado: docs/features/Feature_AutoStitch-analisis-antigravity.md
```

---

## 📊 Salida: Archivo Generado

### Ubicación y Nombre

```
Documento original: docs/mvp-Definition.md
             ↓
Archivo análisis: docs/FASE_1-analisis-claude.md

Patrón: [seccion]-analisis-[agente].md

Donde:
  [seccion] = nombre de la sección analizada
  [agente] = nombre del agente IA
    • claude  (si usa Claude)
    • antigravity (si usa Antigravity IDE)
    • openai (si usa OpenAI)
```

### Contenido del Archivo

```markdown
# 📊 Análisis: [Sección]

**Documento:** docs/mvp-Definition.md
**Sección:** FASE 1
**Agente:** claude
**Fecha:** 2026-04-08T14:30:15Z

---

## 1. Comprensión del Paso
[Análisis detallado]

## 2. Supuestos y Ambigüedades
[Ambigüedades encontradas]

## 3. Diseño Funcional
[Flujo, casos normales, edge cases]

## 4. Diseño Técnico
[Arquitectura, componentes, APIs]

## 5. Decisiones Tecnológicas
[Stack y justificación]

## 6. Plan de Implementación
[Tareas desglosadas]

## 7. Riesgos y Cuellos de Botella
[Análisis de riesgos]

## 8. Métricas de Éxito
[KPIs y validación]

## 9. Estrategia de Testing
[Tests recomendados]

## 10. Optimización y Escalabilidad Futura
[Preparación para escala]

---

✅ Análisis completado exitosamente
```

---

## 🔄 Versionado Automático

```
Primera ejecución:
  /Analizador
  → docs/FASE_1-analisis-claude.md

Segunda ejecución (misma sección):
  /Analizador
  → docs/FASE_1-analisis-claude(1).md ✓ (automático, no sobrescribe)

Tercera ejecución:
  /Analizador
  → docs/FASE_1-analisis-claude(2).md ✓ (automático)

Sistema detecta automáticamente:
  ✓ Archivo base existe
  ✓ Incrementa número
  ✓ No sobrescribe
  ✓ Mantiene historial
```

---

## ⚙️ Opciones Avanzadas

### Opción 1: Skip Confirmación

```
/Analizador --auto

Usa valores por defecto:
  • Documento: [actual abierto en editor]
  • Sección: [detectada automáticamente]
  • Ejecuta: sin confirmación
```

### Opción 2: Especificar Agente

```
/Analizador --agent "custom-agente"

Nombre archivo:
  → docs/custom-agente-analisis.md
```

### Opción 3: Salida Personalizada

```
/Analizador --output "docs/analisis-custom/"

Guarda:
  → docs/analisis-custom/claude-analisis.md
```

---

## ✅ Validaciones Previas

Sistema verifica automáticamente:

```
✓ Documento existe y es accesible
✓ Formato es texto/markdown
✓ Carpeta tiene permisos de escritura
✓ Sección existe en el documento
✓ No hay caracteres inválidos en nombres
✓ Espacio en disco suficiente
```

Si algo falla → Reporta error específico

---

## 📊 Proceso de Análisis

Sigue exactamente el proceso definido en `docs/process/ANALISIS.txt`:

```
1. Comprensión del Paso
   ├─ ¿Qué problema resuelve?
   ├─ ¿Qué inputs recibe?
   ├─ ¿Qué outputs debe generar?
   └─ ¿Qué rol cumple?

2. Supuestos y Ambigüedades
   ├─ TODO lo no definido
   ├─ Preguntas críticas
   └─ Marca lo que debe resolverse

3. Diseño Funcional
   ├─ Flujo paso a paso
   ├─ Casos normales
   ├─ Edge cases
   └─ Manejo de errores

4. Diseño Técnico
   ├─ Arquitectura
   ├─ Componentes
   ├─ APIs/endpoints
   └─ Modelos de datos

5. Decisiones Tecnológicas
   ├─ Frameworks
   ├─ Librerías
   └─ Justificación técnica

6. Plan de Implementación
   ├─ Tareas pequeñas
   ├─ Orden de desarrollo
   └─ Dependencias

7. Riesgos y Cuellos de Botella
   ├─ Técnicos
   ├─ Operativos
   ├─ Escalabilidad
   └─ Costos

8. Métricas de Éxito
   ├─ Validación
   └─ KPIs

9. Estrategia de Testing
   ├─ Unit tests
   ├─ Integration tests
   └─ Casos críticos

10. Optimización y Escalabilidad
    ├─ Problemas al escalar
    └─ Preparación desde ahora
```

---

## 🎯 Diferencia vs Skill Implementador

| Aspecto | /Analizador | /Implementador |
|---------|-----------|----------------|
| **Función** | Analizar especificación | Analizar + Implementar + Validar |
| **Salida** | Análisis (`-analisis.md`) | Reporte final (`REPORTE_*.md`) |
| **Ubicación** | Carpeta del documento | Mismo lugar o custom |
| **Versionado** | `(1)`, `(2)`, ... | Timestamp |
| **Tiempo** | 10-15 min | 2-4 horas |
| **Complejidad** | Análisis puro | Análisis + Código + Validación |

---

## 💡 Tips y Tricks

### Tip 1: Archivo Abierto Automáticamente

```
1. Abre documento en editor
2. /Analizador
3. Sistema sugiere: ¿Usar documento actual? → SÍ
```

### Tip 2: Historial de Análisis

Todos los análisis se guardan:
```
docs/FASE_1-analisis-claude.md
docs/FASE_1-analisis-claude(1).md
docs/claude-analisis(2).md
...
→ Puedes compararlos para ver cambios/mejoras
```

### Tip 3: Batch Analysis

```
/Analizador --batch config.json

Analiza múltiples secciones automáticamente
Genera múltiples archivos
Sin interacción
```

---

## 🔗 Documentación Relacionada

- [Skill Analizador](../skills/skill-analizador.md)
- [Proceso ANALISIS](../process/ANALISIS.txt)
- [Skill Implementador v2.0](../skills/vrm-quality-pipeline-skill-v2.md)

---

## 🚀 Próximos Pasos

1. Ejecuta: `/Analizador`
2. Proporciona documento
3. Especifica sección
4. Confirma
5. Archivo se guarda automáticamente
6. Revisa: `[carpeta-original]/[seccion]-analisis-[agente]([N]).md`

---

## 📝 Ejemplo de Flujo Completo

```
/Analizador

¿Documento a analizar?
docs/mvp-Definition.md

¿Sección específica?
FASE 1 - Día 1 a 10: Core de Grabación

¿Confirmas?
SÍ

[Sistema ejecuta análisis exhaustivo...]

✅ Análisis guardado exitosamente

Archivo: docs/FASE_1-analisis-claude.md

Contiene:
  ✓ Comprensión del paso
  ✓ Supuestos y ambigüedades identificadas
  ✓ Diseño funcional completo
  ✓ Diseño técnico detallado
  ✓ Decisiones y justificaciones
  ✓ Plan de implementación
  ✓ Análisis de riesgos
  ✓ Métricas de éxito
  ✓ Estrategia de testing
  ✓ Optimización futura

[Ahora puedes:]
  1. Revisar el análisis
  2. Hacer cambios si es necesario
  3. Usar /Implementador con el documento
  4. O analizar otra sección
```

---

**Versión:** 1.0.0  
**Status:** 🟢 Production Ready  
**Fecha:** 2026-04-08
