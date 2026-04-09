# VRM Quality Pipeline - Ejemplos de Invocación

Guía práctica con ejemplos reales para invocar la skill desde diferentes contextos.

---

## 🎯 Ejemplo 1: Claude Code (Invocación Directa)

### Setup Inicial
```bash
# En terminal VS Code
git clone [repo] vrm
cd vrm
code .
```

### Opción A: Comando Simple
```
# Abrir Claude Code en VS Code (Extensión)
Ctrl + Shift + P → "Open Claude Code"

# Pedir al agente:
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md
output_dir: FASE_1/Dia4-5/implementacion
lenguaje: dart
proyecto_tipo: flutter
```

### Opción B: Configuración Completa
```
Tengo un documento técnico en:
docs/mvp-Definition.md

Quiero que ejecutes el skill VRM Quality Pipeline:
- Input: docs/mvp-Definition.md
- Lenguaje: Dart
- Tipo: Flutter
- Max loops: 3
- Generar tests: sí
- Salida: FASE_1/Dia4-5/implementacion/
```

### Output Esperado
```
✅ SKILL COMPLETADO

Análisis: ✓ Documento válido
Implementación: ✓ 450 líneas de código
Validación: ✓ 3 issues detectados
Corrección: ✓ 2 loops de corrección
Status Final: APROBADO

Archivos generados en: FASE_1/Dia4-5/implementacion/
├── codigo/
├── logs/
├── reports/
└── README.md
```

---

## 🎯 Ejemplo 2: Antigravity IDE

### Setup
```bash
# Abrir Antigravity
antigravity open ~/Develop/Personal/vrm
```

### Invocación vía UI
```
Menú: Skills → VRM Quality Pipeline

Dialog que aparece:
┌──────────────────────────────────────┐
│ VRM Quality Pipeline                 │
├──────────────────────────────────────┤
│                                      │
│ Input Document:                      │
│ [📄] docs/mvp-Definition.md          │
│                                      │
│ Language: [Dart ▼]                   │
│ Project Type: [Flutter ▼]            │
│ Max Loops: [3]                       │
│ Generate Tests: [✓]                  │
│ Output Dir: [FASE_1/Dia4-5/...▼]     │
│                                      │
│ [Cancel] [Execute]                   │
└──────────────────────────────────────┘
```

### Invocación vía Command Palette
```
Ctrl + Shift + P (o Cmd + Shift + P)
> Execute Skill: VRM Quality Pipeline

Input: docs/mvp-Definition.md
Config: vrm-quality-pipeline-config.json
```

---

## 🎯 Ejemplo 3: Invocación Programática (Python)

### Script para ejecutar skill
```python
# execute_vrm_skill.py
import json
import subprocess
from pathlib import Path

# Configuración
config = {
    "documento": "docs/mvp-Definition.md",
    "lenguaje": "dart",
    "proyecto_tipo": "flutter",
    "max_loops": 3,
    "generar_tests": True,
    "output_dir": "FASE_1/Dia4-5/implementacion"
}

# Ejecutar skill
def execute_vrm_skill(config):
    payload = {
        "skill": "vrm-quality-pipeline",
        "config": config
    }
    
    # Guardar config temporal
    with open("temp_config.json", "w") as f:
        json.dump(payload, f)
    
    # Ejecutar (depende del agente)
    result = subprocess.run([
        "claude-code",
        "execute-skill",
        "vrm-quality-pipeline",
        "--config", "temp_config.json"
    ])
    
    return result.returncode == 0

if __name__ == "__main__":
    success = execute_vrm_skill(config)
    if success:
        print("✅ Skill ejecutado correctamente")
    else:
        print("❌ Error en ejecución del skill")
```

### Ejecutar
```bash
python execute_vrm_skill.py
```

---

## 🎯 Ejemplo 4: Invocación Manual (Paso a Paso)

### Cuando no tienes acceso a skill automatizado

#### Paso 1: Leer la skill
```
Lee estos archivos:
- docs/skills/vrm-quality-pipeline-skill.md
- docs/skills/vrm-quality-pipeline-config.json

Entiende la arquitectura y los roles.
```

#### Paso 2: Ejecutar ANALIZAR
```
Rol: ANALIZADOR
Documento: docs/mvp-Definition.md

Tu tarea:
1. Leer documento completo
2. Verificar que tiene estas secciones:
   - Diseño Funcional ✓
   - Diseño Técnico ✓
   - Decisiones ✓
   - Plan ✓
   - Riesgos ✓
   - Testing ✓
3. Detectar ambigüedades
4. Decidir: ¿VÁLIDO o INVÁLIDO?

Salida esperada: JSON con análisis
```

#### Paso 3: Ejecutar IMPLEMENTADOR
```
Rol: IMPLEMENTADOR
Entrada: [Resultado del ANALIZADOR]

Tu tarea:
1. Leer documento técnico
2. Dividir en módulos
3. Crear estructura de carpetas
4. Implementar cada componente en Dart
5. Incluir manejo de errores
6. Generar código ejecutable

Salida esperada: Carpeta /codigo/ con .dart files
```

#### Paso 4: Ejecutar VALIDADOR
```
Rol: VALIDADOR
Entrada: 
  - Código generado
  - Documento original

Tu tarea:
1. Validar que TODO está implementado
2. Revisar arquitectura
3. Revisar calidad de código
4. Buscar issues (críticos, importantes, mejoras)
5. Decidir: APROBADO o RECHAZADO

Salida esperada: JSON con issues + decisión
```

#### Paso 5: Si necesita corrección
```
Rol: CORRECTOR
Entrada:
  - Código
  - Issues del VALIDADOR

Tu tarea:
1. Leer issues por severidad
2. Fijar CRÍTICOS primero
3. Fijar IMPORTANTES
4. MEJORAS solo si no añaden complejidad
5. Mantener arquitectura

Salida esperada: Código actualizado + changelog
```

---

## 🎯 Ejemplo 5: Invocación en CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/vrm-quality-pipeline.yml
name: VRM Quality Pipeline

on:
  push:
    paths:
      - 'docs/**'
      - 'FASE_*/**'
      - '.github/workflows/vrm-quality-pipeline.yml'

jobs:
  vrm-quality-pipeline:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Execute VRM Quality Pipeline
        run: |
          python -m pip install requests
          python execute_vrm_skill.py --document docs/mvp-Definition.md
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: vrm-quality-report
          path: FASE_1/Dia4-5/implementacion/reports/
      
      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('FASE_1/Dia4-5/implementacion/reports/validacion_final.json'));
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ VRM Quality Pipeline Resultado: ${report.decision}`
            })
```

### Ejecutar Skill en CI
```bash
# Trigger automático
git push → GitHub Actions ejecuta skill → Genera reporte → Comenta en PR
```

---

## 🎯 Ejemplo 6: Invocación Interactiva (Chat)

### Claude Code Web (claude.ai/code)
```
Usuario: Quiero implementar la fase de grabación del VRM

Claude: Entendido. Tenemos el documento técnico en docs/mvp-Definition.md

¿Quieres que ejecute el skill VRM Quality Pipeline?

[Usuario: Sí]

Claude ejecuta internamente:
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md

[Muestra progreso]
Fase 1: Analizando... ✓
Fase 2: Implementando... ✓
Fase 3: Validando... ✓
Resultado: APROBADO ✓

Aquí está el código generado:
[Muestra archivos]
```

---

## 🎯 Ejemplo 7: Invocación con Customización

### Config Personalizada
```bash
# Por defecto
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md

# Con opciones personalizadas
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md
config: {
  "lenguaje": "dart",
  "proyecto_tipo": "flutter",
  "max_loops": 2,
  "generar_tests": true,
  "nivel_estrictez": "strict",
  "output_dir": "custom_output/"
}
```

### Variables de Entorno
```bash
export VRM_SKILL_INPUT="docs/mvp-Definition.md"
export VRM_SKILL_OUTPUT="FASE_1/Dia4-5/"
export VRM_SKILL_LANGUAGE="dart"
export VRM_SKILL_MAX_LOOPS=3

# Ejecutar con vars
@skill vrm-quality-pipeline --env-vars
```

---

## 📊 Matriz de Invocación

| Contexto | Método | Complejidad | Tiempo |
|----------|--------|-------------|--------|
| Claude Code | Comando directo | Baja | 5 min |
| Antigravity IDE | UI/Dialog | Baja | 5 min |
| Terminal | Script Python | Media | 10 min |
| Manual paso a paso | Instrucciones | Alta | 60+ min |
| CI/CD | GitHub Actions | Media | 15 min |
| Interactivo | Chat Claude | Baja | 10 min |

---

## ✅ Checklist Post-Ejecución

Después de invocar, verifica:

- [ ] Skill completó todas las fases
- [ ] 0 issues críticos
- [ ] Código en carpeta output
- [ ] Reportes generados
- [ ] Tests pasaron (si aplica)
- [ ] Logs disponibles para review

---

## 🔍 Debugging Invocación

### Problema: Skill no se encuentra
```bash
# Verificar que archivo existe
ls docs/skills/vrm-quality-pipeline-skill.md

# Registrar skill en el agente
claude-code register-skill docs/skills/vrm-quality-pipeline-skill.md
```

### Problema: Configuración inválida
```bash
# Validar JSON config
python -m json.tool docs/skills/vrm-quality-pipeline-config.json

# Usar config por defecto
@skill vrm-quality-pipeline input: docs/mvp-Definition.md
```

### Problema: Output no se genera
```bash
# Verificar permisos
chmod 755 FASE_1/Dia4-5/

# Crear directorio si no existe
mkdir -p FASE_1/Dia4-5/implementacion
```

---

## 📝 Resumen Rápido

### TL;DR - La forma más rápida

**Con Claude Code:**
```
@skill vrm-quality-pipeline
input: docs/mvp-Definition.md
```

**Con Antigravity:**
```
Skills → VRM Quality Pipeline → Click Execute
```

**Manual:**
```
Leer: docs/skills/vrm-quality-pipeline-skill.md
Seguir roles: ANALIZAR → IMPLEMENTAR → VALIDAR → CORREGIR
```

---

**Última actualización:** 2026-04-08  
**Versión del Skill:** 1.0.0
