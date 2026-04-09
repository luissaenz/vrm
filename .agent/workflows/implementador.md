---
name: Implementador
alias: /Implementador
description: Inicia el pipeline de calidad VRM (Analizar → Implementar → Validar → Corregir)
version: 1.0.0
category: VRM Pipeline
---

# /Implementador - VRM Quality Pipeline Interactive

## Descripción
Slash command que inicia el flujo completo de **análisis, implementación y validación** de forma interactiva.

Pide la ubicación del documento técnico y ejecuta automáticamente el pipeline VRM Quality Pipeline.

---

## Cómo Usar

### En Claude Code
```
/Implementador
```

El comando te pedirá:
1. **Ubicación del documento** (ej: docs/mvp-Definition.md)
2. **Lenguaje** (Dart, Python, JavaScript, TypeScript)
3. **Tipo de proyecto** (Flutter, Web, Backend)
4. **Máximo de loops** (1-5)
5. **Generar tests** (sí/no)

---

## Flujo Interactivo

```
Usuario: /Implementador
    │
    ↓
¿Dónde está el documento técnico?
[📄] Selecciona archivo o escribe ruta
    │
    ↓
¿Lenguaje? (Dart / Python / JavaScript / TypeScript)
[Dart ▼]
    │
    ↓
¿Tipo de proyecto? (Flutter / Web / Backend / Generic)
[Flutter ▼]
    │
    ↓
¿Máximo de loops? (1-5)
[3]
    │
    ↓
¿Generar tests? (sí / no)
[Sí]
    │
    ↓
[EJECUTAR]
    │
    ↓
┌──────────────────────────────────────┐
│ Iniciando VRM Quality Pipeline...    │
│ ✓ ANALIZAR documento                 │
│ ✓ IMPLEMENTAR código                 │
│ ✓ VALIDAR contra especificación      │
│ ✓ CORRECTOR (si necesario)           │
│ ✓ REPORTES generados                 │
└──────────────────────────────────────┘
```

---

## Ejemplos

### Ejemplo 1: Uso Básico
```
Usuario: /Implementador

Sistema: ¿Ubicación del documento?
Usuario: docs/mvp-Definition.md

Sistema: ¿Lenguaje?
Usuario: Dart

Sistema: ¿Tipo de proyecto?
Usuario: Flutter

Sistema: ¿Máximo de loops?
Usuario: 3

Sistema: ¿Generar tests?
Usuario: Sí

[Ejecuta automáticamente]
```

### Ejemplo 2: Con Archivo Abierto
```
Usuario: [Abre docs/mvp-Definition.md en editor]
Usuario: /Implementador

Sistema: ¿Usar documento actual (docs/mvp-Definition.md)?
Usuario: Sí

[Continúa con preguntas de lenguaje, tipo, etc.]
```

### Ejemplo 3: Con Defaults
```
Usuario: /Implementador --defaults

Sistema: Usando configuración por defecto:
  • Documento: docs/mvp-Definition.md
  • Lenguaje: Dart
  • Tipo: Flutter
  • Loops: 3
  • Tests: Sí

[Ejecuta automáticamente sin más preguntas]
```

---

## Workflow Completo

```
┌─────────────────────────────────────────────────────┐
│ /Implementador                                       │
│ (Usuario invoca comando)                             │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ ENTRADA INTERACTIVA                                 │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ¿Ubicación del documento técnico?               │ │
│ │ [Seleccionar / Escribir ruta]                   │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ¿Lenguaje?                                      │ │
│ │ [Dart ▼ / Python / JavaScript / TypeScript]    │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ¿Tipo de proyecto?                              │ │
│ │ [Flutter ▼ / Web / Backend / Generic]          │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ¿Máximo de loops? (1-5)                         │ │
│ │ [3]                                             │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ¿Generar tests?                                 │ │
│ │ [Sí ▼ / No]                                     │ │
│ └─────────────────────────────────────────────────┘ │
└────────┬────────────────────────────────────────────┘
         │
         ↓ (todas las respuestas recopiladas)
┌─────────────────────────────────────────────────────┐
│ VALIDACIÓN PREVIA                                   │
│ ✓ Archivo existe: docs/mvp-Definition.md           │
│ ✓ Formato: Markdown                                │
│ ✓ Tamaño: OK                                       │
│ ✓ Proyecto inicializado: Sí                        │
│ → Proceder: ✓                                       │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ EJECUTAR SKILL                                      │
│                                                      │
│ @skill vrm-quality-pipeline                        │
│ input: docs/mvp-Definition.md                       │
│ lenguaje: dart                                      │
│ proyecto_tipo: flutter                             │
│ max_loops: 3                                        │
│ generar_tests: true                                │
│                                                      │
└────────┬────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│ PIPELINE VRM QUALITY EJECUTÁNDOSE...                │
│                                                      │
│ [████░░░░] 40% - ANALIZANDO documento              │
│ [████████░] 80% - IMPLEMENTANDO código             │
│ [██████████] 100% - VALIDANDO                      │
│                                                      │
│ ✅ COMPLETADO: FASE_1/Dia4-5/implementacion/      │
│                                                      │
│ Resultados:                                         │
│ • Código: 450 líneas                               │
│ • Issues detectados: 3                             │
│ • Issues corregidos: 3                             │
│ • Loops usados: 2/3                                │
│ • Status: APROBADO ✓                               │
│                                                      │
│ Archivos generados:                                │
│ ├── codigo/                                        │
│ ├── logs/execution.log.json                        │
│ ├── reports/validacion_final.md                    │
│ └── README.md                                      │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Opciones Disponibles

### Flags Opcionales

```bash
# Usar defaults sin preguntar
/Implementador --defaults

# Solo analizar (no implementar)
/Implementador --analyze-only

# Solo validar código existente
/Implementador --validate-only

# Debug mode (más logs)
/Implementador --debug

# Configuración personalizada
/Implementador --config configs/custom.json

# No generar tests
/Implementador --no-tests

# Nivel máximo de estrictez
/Implementador --strict
```

---

## Variables de Configuración Soportadas

El comando detecta automáticamente:

```
✓ Archivo abierto en editor actual → usa como input
✓ Última ruta usada → sugiere por defecto
✓ Lenguaje del proyecto → detecta (Dart/Flutter)
✓ Estructura del proyecto → detecta tipo
✓ Variables de entorno → usa si existen
```

---

## Validaciones Pre-Ejecución

Antes de ejecutar, verifica:

```
✓ Documento existe
✓ Documento es Markdown válido
✓ Documento contiene secciones requeridas
✓ Proyecto existe
✓ pubspec.yaml/package.json existe
✓ No hay merge conflicts
✓ Permisos de escritura en output dir
```

Si algo falla → Reporta error específico

---

## Salida Esperada

Después de `/Implementador`:

```
✅ IMPLEMENTACIÓN COMPLETADA

Input:
  • Documento: docs/mvp-Definition.md
  • Lenguaje: Dart
  • Tipo: Flutter

Output:
  • Código: FASE_1/Dia4-5/implementacion/codigo/
  • Logs: FASE_1/Dia4-5/implementacion/logs/
  • Reportes: FASE_1/Dia4-5/implementacion/reports/

Resultados:
  • Líneas de código: 450
  • Componentes: 5
  • Issues corregidos: 3
  • Loops usados: 2/3
  • Status: APROBADO ✓
  • Tiempo: 2h 15min

Próximos pasos:
  1. Revisar: FASE_1/Dia4-5/implementacion/README.md
  2. Tests: flutter test
  3. Build: flutter build apk
```

---

## Atajos de Teclado (Opcional)

Si configurado en keybindings:

```
Ctrl+Shift+I    → /Implementador (quick)
Ctrl+Alt+I      → /Implementador --defaults
```

---

## Troubleshooting

### Problema: "Documento no existe"
```
/Implementador --browse

Sistema: Abre file picker para seleccionar
```

### Problema: "Proyecto no inicializado"
```
/Implementador --init

Sistema: Inicializa estructura VRM antes de continuar
```

### Problema: "Error en validación"
```
/Implementador --verbose

Sistema: Muestra logs detallados del error
```

---

## Integración con Otros Comandos

```bash
# Después de /Implementador, puedes usar:
/Validador        # Revalidar el código generado
/Corrector        # Arreglar issues específicos
/Tester           # Generar tests automáticamente
/Documentador     # Generar documentación
```

---

## Notas Importantes

- ✅ El comando es **completamente interactivo**
- ✅ **Detecta contexto** (archivo abierto, proyecto actual)
- ✅ **Valida antes de ejecutar** (previene errores)
- ✅ **Reutilizable** (puedes ejecutarlo múltiples veces)
- ✅ **No destructivo** (no borra código existente)
- ✅ **Con rollback** (logs permiten deshacer si necesario)

---

## Versión

- **v1.0.0** (2026-04-08)
- Compatible con: Claude Code, Antigravity IDE
- Requiere: docs/skills/vrm-quality-pipeline-skill.md

---

**¿Listo para comenzar?**

```
/Implementador
```

¡El sistema te guiará paso a paso! 🚀
