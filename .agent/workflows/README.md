# 🚀 VRM Commands - Custom Slash Commands

Colección de custom slash commands para ejecutar el VRM Quality Pipeline de forma interactiva.

---

## 📦 Comandos Disponibles

### `/Analizador` 🔍 (Nuevo)
**Descripción:** Análisis exhaustivo de especificaciones técnicas siguiendo ANALISIS.txt

**Uso:**
```
/Analizador
```

**Flujo:**
```
/Analizador
  ↓
[Pide documento]
  ↓
[Pide sección]
  ↓
[Ejecuta análisis - 10 secciones]
  ↓
[Guarda en carpeta original: [seccion]-analisis-[agente].md]
  ↓
[Versionado automático si existe: (1), (2), ...]
```

**Características:**
- ✅ Guarda en carpeta original del documento
- ✅ Versionado automático (no sobrescribe)
- ✅ 10 secciones de análisis exhaustivo
- ✅ Sigue exactamente ANALISIS.txt

---

### `/Implementador` ⭐ (Principal)
**Descripción:** Inicia el pipeline completo con entrada interactiva

**Uso:**
```
/Implementador
```

**Flujo:**
```
/Implementador
  ↓
[Pide ubicación del documento]
  ↓
[Pide lenguaje]
  ↓
[Pide tipo de proyecto]
  ↓
[Pide máximo de loops]
  ↓
[Pide si generar tests]
  ↓
[Confirma todo]
  ↓
[Ejecuta skill automáticamente]
```

---

## 🔧 Instalación

### Opción A: Auto-detect en Claude Code

1. Abre VS Code
2. Abre extensión Claude Code
3. El sistema debería detectar esta carpeta automáticamente
4. Los comandos estarán disponibles vía `/`

### Opción B: Registro Manual

En la paleta de comandos de Claude Code:

```
Ctrl+Shift+P → "Register Custom Command"
Path: .agent/workflows/implementador-config.json
```

### Opción C: Via Keybinding

Agrega a `.claude/keybindings.json`:

```json
{
  "keybindings": [
    {
      "key": "ctrl+shift+i",
      "command": "vrm.implementador",
      "when": "editorFocus"
    }
  ]
}
```

---

## 📋 Estructura de Archivos

```
.agent/workflows/
├── README.md (este archivo)
├── implementador.md                ← Especificación del comando
├── implementador-config.json       ← Configuración JSON
├── IMPLEMENTADOR-PROMPT.txt        ← Prompt interactivo
└── [otros comandos futuros]
```

---

## 💻 Cómo Usar `/Implementador`

### Forma 1: Directa en Claude Code

```
Escribe en el chat:
/Implementador

El sistema te pedirá:
1. Tu especificación (contenido o ruta)
2. Lenguaje (Dart, Python, JS, TS)
3. Tipo de proyecto (Flutter, Web, Backend)
4. Máximo de loops (1-5)
5. Generar tests (Sí/No)
6. Nivel de estrictez (strict/normal/lenient)

NOTA: Funciona con cualquier archivo, en cualquier ruta.
El sistema es agnóstico de la ubicación.
```

### Forma 2: Con Argumentos

```
/Implementador --document docs/mvp-Definition.md --language dart --project flutter
```

### Forma 3: Con Defaults

```
/Implementador --defaults

Usa:
  • Documento: docs/mvp-Definition.md
  • Lenguaje: Dart
  • Proyecto: Flutter
  • Loops: 3
  • Tests: Sí
  • Estrictez: strict
```

### Forma 4: Solo Validación

```
/Implementador --analyze-only

Solo ejecuta ANALIZADOR, no implementa nada
```

---

## 🎯 Flujo Interactivo Detallado

```
┌─────────────────────────────────────────────────────┐
│ Usuario escribe: /Implementador                      │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ¿Ubicación del documento?                  │
│ Ejemplo: docs/mvp-Definition.md                     │
│                                                      │
│ Usuario: docs/mvp-Definition.md                    │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ✓ Documento validado                       │
│ Sistema: ¿Lenguaje?                                 │
│          [Dart] / Python / JavaScript / TypeScript  │
│                                                      │
│ Usuario: Dart                                       │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ¿Tipo de proyecto?                         │
│          [Flutter] / Web / Backend / Generic        │
│                                                      │
│ Usuario: Flutter                                    │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ¿Máximo de loops? (1-5)                    │
│          [3 - Recomendado]                          │
│                                                      │
│ Usuario: 3                                          │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ¿Generar tests?                            │
│          [Sí] / No                                  │
│                                                      │
│ Usuario: Sí                                         │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: Resumen de configuración:                  │
│ • Documento:    docs/mvp-Definition.md             │
│ • Lenguaje:     Dart                               │
│ • Proyecto:     Flutter                            │
│ • Loops:        3                                  │
│ • Tests:        Sí                                 │
│ • Estrictez:    strict                             │
│                                                      │
│ ¿Confirmas? [CONFIRMAR] / Cambiar                  │
│                                                      │
│ Usuario: CONFIRMAR                                  │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Sistema: ✓ Validaciones previas:                    │
│ ✓ Documento existe                                  │
│ ✓ Es Markdown válido                               │
│ ✓ Tiene secciones requeridas                       │
│ ✓ Proyecto inicializado                            │
│ ✓ Permisos OK                                      │
│                                                      │
│ → Procediendo...                                    │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ Ejecutando:                                         │
│                                                      │
│ @skill vrm-quality-pipeline                        │
│ input: docs/mvp-Definition.md                       │
│ lenguaje: dart                                      │
│ proyecto_tipo: flutter                             │
│ max_loops: 3                                        │
│ generar_tests: true                                │
│ nivel_estrictez: strict                            │
│                                                      │
│ [█████████░░░░░░░░░] 50% - ANALIZANDO...           │
│ [██████████░░░░░░░░] 55% - IMPLEMENTANDO...        │
│ [███████████░░░░░░░] 60% - VALIDANDO...            │
│ ...                                                 │
│                                                      │
│ ✅ COMPLETADO                                       │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ 📊 Resultados:                                      │
│                                                      │
│ ✓ Código generado: 450 líneas                      │
│ ✓ Issues corregidos: 3                             │
│ ✓ Loops usados: 2/3                                │
│ ✓ Status: APROBADO                                 │
│                                                      │
│ 📁 Output:                                          │
│ FASE_1/Dia4-5/implementacion/                      │
│ ├── codigo/                                        │
│ ├── logs/                                          │
│ ├── reports/                                       │
│ └── README.md                                      │
│                                                      │
│ 🚀 Próximos pasos:                                 │
│ 1. flutter test                                    │
│ 2. flutter build apk                               │
│ 3. Deploy                                          │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Troubleshooting

### Problema: Comando no aparece

**Solución:**
```
1. Recarga VS Code: Ctrl+R
2. Abre paleta de comandos: Ctrl+Shift+P
3. Busca: "Reload Custom Commands"
4. Intenta nuevamente: /Implementador
```

### Problema: "Documento no existe"

**Solución:**
```
1. Verifica la ruta
2. El archivo debe ser .md (Markdown)
3. Intenta: /Implementador --browse
4. Selecciona el archivo del file picker
```

### Problema: "Proyecto no inicializado"

**Solución:**
```
1. Asegúrate que pubspec.yaml existe
2. Corre: flutter pub get
3. Intenta nuevamente: /Implementador
```

### Problema: Error en validación

**Solución:**
```
1. Ejecuta con debug: /Implementador --debug
2. Revisa los logs
3. Verifica que el documento tiene secciones requeridas
4. Lee: docs/skills/ARCHITECTURE.md
```

---

## 📚 Comandos Relacionados

```bash
# Validar código generado
/Validador

# Arreglar issues específicos
/Corrector

# Generar documentación
/Documentador

# Ejecutar tests
/Tester

# Todas las opciones
/Ayuda vrm
```

---

## 🔗 Documentación Relacionada

- [Skill Principal](../skills/vrm-quality-pipeline-skill.md)
- [Ejemplos de Invocación](../skills/INVOCATION_EXAMPLES.md)
- [Arquitectura](../skills/ARCHITECTURE.md)
- [Configuración JSON](implementador-config.json)

---

## 📝 Atributos del Comando

| Atributo | Valor |
|----------|-------|
| **ID** | `vrm.implementador` |
| **Nombre** | Implementador |
| **Versión** | 1.0.0 |
| **Tipo** | Interactive |
| **Status** | 🟢 Production Ready |
| **Plataformas** | Claude Code, Antigravity IDE |
| **Shortcut** | Ctrl+Shift+I (opcional) |

---

## 💡 Tips y Tricks

### Tip 1: Usar Archivo Abierto Automáticamente

```
1. Abre el documento en editor
2. /Implementador
3. Sistema sugiere: "¿Usar docs/mvp-Definition.md?" → Sí
```

### Tip 2: Reutilizar Configuración Anterior

```
1. Primera ejecución: /Implementador
2. Segunda ejecución: /Implementador
3. Sistema recuerda configuración anterior → Solo confirma
```

### Tip 3: Ejecutar en Batch Mode

```
/Implementador --batch --config batch-config.json

Ejecuta múltiples componentes sin input interactivo
```

---

## 🎓 Guía de Lectura

**Si eres nuevo:**
```
1. Este README.md (5 min)
2. implementador.md (10 min)
3. Ejecuta: /Implementador
4. Sigue las preguntas
```

**Si necesitas entender cómo funciona:**
```
1. implementador-config.json (5 min)
2. IMPLEMENTADOR-PROMPT.txt (15 min)
3. ../skills/ARCHITECTURE.md (20 min)
```

---

## 🚀 Próximos Pasos

```
1. Escribe: /Implementador
2. Responde las preguntas
3. Confirma
4. Espera a que termine
5. Revisa los resultados en FASE_1/Dia4-5/implementacion/
```

---

**Última actualización:** 2026-04-08  
**Status:** 🟢 Production Ready  
**Mantenedor:** VRM Development Team

---

**¡Listo para comenzar?** Escribe en Claude Code:

```
/Implementador
```

🎉
