---
name: VRM Quality Pipeline Skill
description: Skill autónomo para ejecutar ciclo completo de análisis, implementación y validación de especificaciones con loops de corrección
version: 1.0.0
type: orchestration
target_agents: ["Claude Code", "Antigravity IDE", "Other AI Agents"]
compatible_ides: ["VS Code", "Antigravity", "Claude Code"]
---

# 🎯 VRM Quality Pipeline Skill

## Propósito
Ejecutar un **ciclo completamente autónomo** que transforma una especificación técnica en código implementado y validado, con loops de corrección automáticos hasta alcanzar calidad de producción.

**Entrada:** Documento técnico consolidado (análisis final)  
**Salida:** Código validado y listo para producción  
**Autonomía:** Ciclos automáticos sin intervención hasta fase de aprobación final

---

## 🏗️ Arquitectura del Pipeline

```
[INICIO] 
  ↓
┌─────────────────────────────────┐
│ FASE 1: ANALIZAR ESPECIFICACIÓN │
│ (Validar completitud)           │
└─────────────────────────────────┘
  ↓
┌─────────────────────────────────┐
│ FASE 2: IMPLEMENTAR             │
│ (Código base funcional)         │
└─────────────────────────────────┘
  ↓
┌─────────────────────────────────┐
│ FASE 3: VALIDAR                 │
│ (Code review de calidad)        │
└─────────────────────────────────┘
  ↓
  ¿APROBADO?
  │         │
  SÍ        NO
  │         │
  │         └──→ ┌──────────────────────┐
  │              │ FASE 4: CORREGIR     │
  │              │ (Fix issues críticos)│
  │              └──────────────────────┘
  │                    ↓
  │              [Vuelve a VALIDAR]
  │                    ↓
  │              (Max 2-3 loops)
  │
  ↓
[FIN - CÓDIGO VALIDADO] ✅
```

---

## 📋 Roles y Responsabilidades

### FASE 1: ANALIZADOR
**Input:** Documento técnico consolidado (`.md`)  
**Output:** Validación de completitud, lista de ambigüedades

**Tareas:**
1. Leer documento técnico completo
2. Validar que tenga todas las secciones requeridas:
   - Diseño funcional ✓
   - Diseño técnico ✓
   - Decisiones tecnológicas ✓
   - Plan de implementación ✓
   - Riesgos y mitigaciones ✓
3. Detectar ambigüedades o inconsistencias
4. Decidir: ¿Continuar o requiere clarificación?

**Criterios de Aprobación:**
- ✅ Todas las secciones presentes
- ✅ Sin contradicciones técnicas
- ✅ Plan es accionable (tareas atómicas)
- ✅ Arquitectura es clara

---

### FASE 2: IMPLEMENTADOR
**Input:** Documento técnico validado  
**Output:** Código completo, estructurado, listo para testing

**Tareas:**
1. Dividir el plan en módulos/componentes implementables
2. Crear estructura de carpetas y archivos
3. Implementar cada componente siguiendo:
   - La arquitectura especificada (sin reinterpretaciones)
   - Patrones del proyecto existente
   - Naming conventions claros
4. Incluir:
   - Manejo de errores básico
   - Validaciones en límites (inputs)
   - Comentarios en lógica no-obvia
5. Generar código ejecutable o fácilmente compilable

**Reglas Estrictas:**
- ❌ NO redeseñar arquitectura
- ❌ NO agregar features extra
- ✅ TODO debe ser específico, no pseudocódigo
- ✅ Código debe poder ejecutarse/compilarse

**Estructura Esperada:**
```
proyecto/
├── componente_1/
│   ├── archivo_principal.dart
│   ├── modelos.dart
│   └── servicios.dart
├── componente_2/
│   └── ...
└── tests/
    ├── componente_1_test.dart
    └── ...
```

---

### FASE 3: VALIDADOR
**Input:** Implementación completa + Documento técnico original  
**Output:** Lista de issues (críticos, importantes, mejoras) + Decisión

**Tareas:**
1. **Validación Estricta** contra documento:
   - ¿Está TODO implementado?
   - ¿Se respeta la arquitectura?
   - ¿Hay desviaciones injustificadas?

2. **Evaluación de Calidad:**
   - Claridad del código
   - Modularidad
   - Manejo de errores
   - Edge cases contemplados
   - Integraciones correctas

3. **Triage de Issues:**
   Para cada problema encontrado:
   ```json
   {
     "id": "ISSUE_001",
     "descripción": "Descripción clara del problema",
     "severidad": "crítico|importante|mejora",
     "tipo": "arquitectura|lógica|código|integración|performance",
     "recomendación": "Cómo corregirlo"
   }
   ```

4. **Decisión Final:**
   - **✅ APROBADO** si:
     - 0 issues críticos
     - Implementación cumple lo esencial del documento
   - **❌ RECHAZADO** si:
     - 1+ issues críticos
     - Múltiples importantes que comprometen el sistema

**Nivel de Exigencia:**
Evalúa como si esto fuera a producción con usuarios reales. Un error aquí es inaceptable si era detectable.

---

### FASE 4: CORRECTOR
**Input:** Implementación + Lista de issues del validador  
**Output:** Código actualizado, fix log

**Tareas:**
1. Recibir lista de issues del VALIDADOR
2. Corregir en este orden:
   - ✅ CRÍTICOS (obligatorio)
   - ✅ IMPORTANTES (deben corregirse)
   - ⚠️ MEJORAS (solo si no introducen complejidad)
3. Mantener consistencia con arquitectura original
4. NO refactorizar partes no-relacionadas
5. Generar log de cambios

**Formato de Salida:**
```json
{
  "status": "fixed|partial",
  "changes": [
    {
      "issue_id": "ISSUE_001",
      "action": "fixed|skipped|partial",
      "descripción": "Qué se hizo"
    }
  ],
  "código_actualizado": "...",
  "notas": "Decisiones técnicas relevantes"
}
```

---

## 🔄 Loop de Corrección

El sistema itera automáticamente:

```
IMPLEMENTADOR → VALIDADOR → ¿APROBADO?
                    ↑           │
                    │       NO  │
                    └───────────┘
                        │
                    CORRECTOR
                        │
                        ↓
                [Vuelve a VALIDADOR]
                        │
                        ↓
                   (Max 3 loops)
```

**Máximo de loops:** 2-3  
**Condición de salida:**
- ✅ APROBADO (0 críticos) → FIN
- ❌ Críticos sin resolver después de 3 intentos → ESCALADA

---

## 📥 Entrada Requerida

### Documento Técnico Consolidado

Debe contener **obligatoriamente**:

```markdown
# [Nombre del Componente]

## 1. Diseño Funcional
- Objetivo central
- Componentes entrada/salida
- Pipeline de ejecución
- Edge cases
- Métricas de éxito

## 2. Diseño Técnico
- Arquitectura sugerida
- Componentes implicados
- APIs / endpoints
- Modelos de datos
- Integraciones

## 3. Decisiones Tecnológicas
- Stack elegido
- Justificación
- Librerías clave

## 4. Plan de Implementación
- Tareas desglosadas
- Orden recomendado
- Dependencias

## 5. Riesgos y Cuellos de Botella
- Técnicos
- Operativos
- Escalabilidad

## 6. Estrategia de Testing
- Unit tests
- Integration tests
- Casos críticos

## 7. Consideraciones de Escalabilidad
- Problemas al crecer
- Preparación para escala
```

---

## 📤 Salida Esperada

### Al Completar ✅

```
✅ CALIDAD GARANTIZADA:
├── Código implementado
├── 0 issues críticos
├── Tests definidos
├── Documentación actualizada
└── Listo para producción

LOGS:
├── issues_detectados.json
├── issues_corregidos.json
├── cambios_implementados.md
└── validacion_final.md
```

---

## 🚀 Cómo Invocar Este Skill

### En Claude Code / Antigravity IDE

```bash
# Opción 1: Directa
@skill vrm-quality-pipeline
input: D:\Develop\Personal\vrm\FASE_1\Dia4-5\analisis-FINAL.md
output_dir: D:\Develop\Personal\vrm\FASE_1\Dia4-5\implementacion

# Opción 2: Con configuración
@skill vrm-quality-pipeline
{
  "documento": "D:\Develop\Personal\vrm\FASE_1\Dia4-5\analisis-FINAL.md",
  "max_loops": 3,
  "output_dir": "D:\Develop\Personal\vrm\FASE_1\Dia4-5\",
  "lenguaje": "dart",
  "proyecto": "flutter"
}
```

### Invocación Programática

```python
# Pseudocódigo agnóstico
skill = VRMQualityPipelineSkill(
    documento_técnico="path/to/spec.md",
    max_loops=3,
    output_dir="path/to/output"
)

resultado = skill.ejecutar()
# Returns:
# {
#   "status": "completed",
#   "código": "...",
#   "validación": "aprobado",
#   "logs": {...}
# }
```

---

## 🎓 Guía de Uso por Rol

### Si Eres ESPECIFICADOR (PM/Architect)
1. Generá el documento técnico consolidado
2. Invocá: `@skill vrm-quality-pipeline input: tu_documento.md`
3. Revisá los logs y el código generado
4. Si hay escaladas → Clarificá ambigüedades

### Si Eres IMPLEMENTADOR
1. Recibís el skill invocado con documento
2. El sistema te pide input si falta claridad
3. Implementás siguiendo el documento EXACTAMENTE
4. El VALIDADOR revisa automáticamente

### Si Eres VALIDADOR
1. Recibís código del IMPLEMENTADOR
2. Hacés code review contra documento
3. Generás lista de issues con severidad
4. Decidís: APROBADO o RECHAZADO

### Si Eres CORRECTOR
1. Recibís issues del VALIDADOR
2. Arreglás en orden: críticos → importantes → mejoras
3. Explicás decisiones técnicas
4. El sistema vuelve a VALIDAR

---

## 📊 Métricas y KPIs

**Después de ejecutar el skill, debería tener:**

| Métrica | Target | Cómo Validar |
|---------|--------|-------------|
| Issues Críticos | 0 | review issues_corregidos.json |
| Cobertura Código | 80%+ | analysis del código |
| Desviaciones Spec | 0 | comparar código con documento |
| Loops de Corrección | ≤ 3 | revisar loop_history.json |
| Tiempo Ejecución | ≤ 2-3h | timestamp inicio-fin |

---

## 🛠️ Troubleshooting

### Problema: Documento incompleto
**Solución:** Ejecutá ANALISIS para completarlo antes de llamar al skill

### Problema: Demasiados loops (>3)
**Solución:** Escalá → Clarificá documento técnico con PM

### Problema: Implementación no respeta arquitectura
**Solución:** CORRECTOR debe leer documento antes de arreglar

### Problema: VALIDADOR detecta ambigüedades
**Solución:** Return to ANALIZER para clarificar, luego restart

---

## 📚 Referencias

### Archivos de Sistema VRM
- Instrucciones ANALISIS: `docs/process/ANALISIS.txt`
- Instrucciones UNIFICACION: `docs/process/UNIFICACION.txt`
- Instrucciones IMPLEMENTACION: `docs/process/IMPLEMENTADOR.txt`
- Instrucciones VALIDACION: `docs/process/VALIDADOR.txt`
- Instrucciones CORRECTOR: `docs/process/CORRECTOR.txt`

### Documentos de Ejemplo
- Spec completo: `docs/mvp-Definition.md`
- Análisis Dia 1-2: `FASE_1/Dia1-2/analisis-FINAL.md`

---

## ✅ Checklist Pre-Ejecución

Antes de invocar este skill, verificá:

- [ ] Documento técnico existe y es completo
- [ ] Documento tiene todas las secciones requeridas
- [ ] Proyecto Flutter/Dart está configurado
- [ ] Dependencies en pubspec.yaml están actualizadas
- [ ] Proyecto compila sin errores
- [ ] No hay merge conflicts pendientes

---

## 🎯 Conclusión

Este skill **automatiza completamente** el flujo de análisis → implementación → validación → corrección, garantizando que el código resultante:

✅ Cumple la especificación  
✅ Tiene calidad de producción  
✅ Está listo para deploy  
✅ Es repetible y auditable  

**Tiempo estimado:** 2-4 horas por componente  
**Autonomía:** 100% hasta aprobación final

---

**Última actualización:** 2026-04-08  
**Status:** Production Ready  
**Mantenedor:** VRM Development Team
