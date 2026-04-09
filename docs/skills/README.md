# VRM Skills Library

Colección de skills autónomos para ejecutar flujos de desarrollo en VRM usando cualquier agente IA compatible con VS Code.

---

## 📚 Skills Disponibles

### 1. VRM Quality Pipeline ⭐
**Archivo:** [`vrm-quality-pipeline-skill.md`](vrm-quality-pipeline-skill.md)  
**Configuración:** [`vrm-quality-pipeline-config.json`](vrm-quality-pipeline-config.json)

#### Propósito
Ejecutar un ciclo **completamente autónomo** que transforma una especificación técnica en código implementado, validado y listo para producción.

#### Flujo
```
ESPECIFICACIÓN → ANALIZAR → IMPLEMENTAR → VALIDAR → ¿APROBADO? → CORREGIR (si falta) → FIN
```

#### Entrada
- Documento técnico consolidado (análisis final en Markdown)

#### Salida
- Código implementado
- Issues detectados y corregidos
- Reportes de validación
- Logs de ejecución

#### Autonomía
- ✅ Automático hasta loops máximos (2-3)
- ✅ Sin intervención humana en ciclos de corrección
- ✅ Escalada automática si se exceden loops

---

## 🚀 Cómo Usar

### Opción 1: Claude Code (Recomendado)

#### Setup
1. Clona/actualiza el repo VRM
2. Abre VS Code en la carpeta del proyecto
3. Abre Claude Code extension

#### Uso Directo
```bash
# Invocación simple
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md
output_dir: FASE_1/Dia4-5/implementacion

# Con configuración detallada
@skill vrm-quality-pipeline
config: docs/skills/vrm-quality-pipeline-config.json
lenguaje: dart
proyecto_tipo: flutter
max_loops: 3
```

---

### Opción 2: Antigravity IDE

#### Setup
1. Abre Antigravity IDE
2. Abre el proyecto VRM
3. Registra la skill

#### Uso
```
CMD + Shift + P (paleta de comandos)
> Ejecutar Skill: VRM Quality Pipeline

# O vía barra de herramientas:
Skills → VRM Quality Pipeline
```

---

### Opción 3: Invocación Manual (Cualquier Agente IA)

#### Paso 1: Leer la Skill
```python
# Pedir al agente que lea:
leer: docs/skills/vrm-quality-pipeline-skill.md
leer: docs/skills/vrm-quality-pipeline-config.json
```

#### Paso 2: Ejecutar Fase por Fase
```bash
# 1. ANALIZADOR
Ejecuta la FASE 1: ANALIZADOR
Documento: docs/mvp-Definition.md
Objetivo: Validar completitud y detectar ambigüedades

# 2. IMPLEMENTADOR (si FASE 1 pasó)
Ejecuta la FASE 2: IMPLEMENTADOR
Documento: [resultado del ANALIZADOR]
Objetivo: Generar código completo

# 3. VALIDADOR
Ejecuta la FASE 3: VALIDADOR
Código: [resultado del IMPLEMENTADOR]
Documento original: [spec original]
Objetivo: Code review contra especificación

# 4. CORRECTOR (si necesario)
Si VALIDADOR rechazó:
Ejecuta la FASE 4: CORRECTOR
Issues: [lista del VALIDADOR]
Código: [código original]
Objetivo: Arreglar issues críticos
```

---

## 📋 Estructura de Archivos

```
docs/skills/
├── README.md (este archivo)
├── vrm-quality-pipeline-skill.md ← SKILL PRINCIPAL
├── vrm-quality-pipeline-config.json ← CONFIGURACIÓN
└── [otros skills futuros]

Salida (después de ejecutar):
├── FASE_X/DiaX-Y/implementacion/
│   ├── logs/
│   │   ├── execution.log.json
│   │   └── loop_history.json
│   ├── codigo/
│   │   ├── componente_1/
│   │   ├── componente_2/
│   │   └── ...
│   ├── reports/
│   │   ├── issues_detectados.json
│   │   ├── issues_corregidos.json
│   │   ├── cambios_implementados.md
│   │   └── validacion_final.md
│   └── README.md (documentación generada)
```

---

## ⚙️ Configuración

### Archivo `vrm-quality-pipeline-config.json`

Controla:
- Lenguaje de programación
- Tipo de proyecto
- Máximo de loops de corrección
- Generación de tests y documentación
- Nivel de estrictez en validación

**Ejemplo de uso personalizado:**
```json
{
  "lenguaje": "dart",
  "proyecto_tipo": "flutter",
  "max_loops": 3,
  "generar_tests": true,
  "generar_documentación": true,
  "nivel_estrictez": "strict"
}
```

---

## 📊 Métricas Esperadas

Después de ejecutar el skill, esperás:

| Métrica | Target |
|---------|--------|
| **Issues Críticos** | 0 |
| **Issues Importantes Corregidos** | 100% |
| **Cobertura de Especificación** | 100% |
| **Loops de Corrección** | ≤ 3 |
| **Tiempo Total** | 2-4 horas |

---

## 🔍 Validación Previa (Checklist)

Antes de ejecutar el skill:

- [ ] Documento técnico existe y es completo
- [ ] Contiene todas las secciones requeridas
- [ ] Proyecto está inicializado
- [ ] Dependencies instaladas
- [ ] Proyecto compila sin errores
- [ ] No hay merge conflicts

---

## 🛠️ Troubleshooting

### Problema: "Documento incompleto"
**Solución:** Ejecutá ANALISIS.txt primero para generar documento completo

### Problema: "Demasiados loops"
**Solución:** Escalá → Clarificá ambigüedades con PM → Restart

### Problema: "Implementación no respeta arquitectura"
**Solución:** CORRECTOR debe releer documento antes de arreglar

### Problema: No compila el código generado
**Solución:** Revisar output del IMPLEMENTADOR en logs, ajustar especificación

---

## 📖 Documentación Relacionada

### Instrucciones Base (Roles)
- [`docs/process/ANALISIS.txt`](../process/ANALISIS.txt) - Cómo hacer análisis exhaustivo
- [`docs/process/UNIFICACION.txt`](../process/UNIFICACION.txt) - Cómo consolidar análisis
- [`docs/process/IMPLEMENTADOR.txt`](../process/IMPLEMENTADOR.txt) - Cómo implementar
- [`docs/process/VALIDADOR.txt`](../process/VALIDADOR.txt) - Cómo validar
- [`docs/process/CORRECTOR.txt`](../process/CORRECTOR.txt) - Cómo corregir

### Documentos del Proyecto
- [`docs/mvp-Definition.md`](../mvp-Definition.md) - Especificación MVP
- [`docs/definitions.md`](../definitions.md) - Definiciones del sistema
- [`docs/flows.md`](../flows.md) - Flujos de usuario

---

## 🎯 Casos de Uso

### Caso 1: Implementar una nueva feature
```bash
# 1. Generá especificación técnica (análisis + unificación)
# 2. Guardá en docs/
# 3. Ejecutá skill:
@skill vrm-quality-pipeline
input: tu_especificacion.md
```

### Caso 2: Code review automático
```bash
# Validá código existente contra especificación
@skill vrm-quality-pipeline
input: especificacion.md
validate_only: true
```

### Caso 3: Fix de bugs
```bash
# Ejecutá skill solo en CORRECTOR
@skill vrm-quality-pipeline
fase: corrector
issues: lista_de_issues.json
```

---

## 🔒 Restricciones y Garantías

### ✅ Garantizado
- Código cumple la especificación
- 0 issues críticos
- Manejo de errores básico
- Validaciones en límites del sistema
- Código compilable/ejecutable

### ❌ No Garantizado
- Performance óptima (primera pasada)
- UI/UX perfecto
- Optimización de assets
- Documentación exhaustiva

Estos son topics para mejora post-MVP.

---

## 📞 Soporte y Feedback

**Errores encontrados:**
1. Documentá el error en `docs/skills/ISSUES.md`
2. Incluí output del skill
3. Describí qué esperabas

**Mejoras sugeridas:**
Abrí un PR en `docs/skills/IMPROVEMENTS.md`

---

## 🔄 Versioning

- **v1.0.0** (2026-04-08) - Release inicial
- Cada skill versionado independientemente
- Compatible con: Claude Code, Antigravity IDE, y agentes IA genéricos

---

## 📝 Nota Final

Esta es una **colección extensible de skills**. Se pueden agregar más:
- Skill de refactoring
- Skill de testing
- Skill de performance optimization
- Skill de documentation generation
- etc.

Cada skill sigue el mismo patrón:
1. Definición en Markdown
2. Configuración en JSON
3. Documentación clara
4. Agnóstica del IDE/agente

---

**Última actualización:** 2026-04-08  
**Mantenedor:** VRM Development Team  
**Status:** 🟢 Production Ready
