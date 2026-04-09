# Análisis Día 9-10 - Agente Oc

## Diseño funcional

### Flujo completo (pipeline)

1. **Detección de fallo**: El pipeline de generación captura cualquier excepción del backend IA (timeout, 500, network error, null response)
2. **Activación de fallback**: Se invoca automáticamente `FallbackGenerator` como estrategia alternativa
3. **Selección de template**: Se carga template según intención del usuario (informar, convencer, narrar) desde assets
4. **Inyección de idea**: El texto raw del usuario se inyecta en la estructura del template (placeholder `{{idea}}`)
5. **Parsing con regex**: Se segmenta el texto combinado usando delimitadores `. ` y `,` como puntos de corte
6. **Validación de estructura**: Se verifica que el resultado tenga mínimo 3 frases válidas
7. **Formateo final**: Se estructura el script_bundle.json con array de líneas numeradas

### Casos normales

- **Timeout (30s)**: Fallback invocado, template seleccionado, parsing exitoso
- **Error HTTP 500**: Fallback invocado, template por defecto usado
- **Network unavailable**: Fallback invocado, idea particionada correctamente
- **Generación exitosa**: No se usa fallback, flujo normal continúa

### Edge cases

- **Ideas sin puntuación**: El regex no encuentra delimitadores, se devuelve la idea completa como una sola línea
- **Ideas muy cortas (<10 chars)**: Se procesan igual, resultado puede ser 1 línea
- **Ideas muy largas (>5000 chars)**: Truncamiento antes del parsing para evitar memory issues
- **Parsing produce <3 frases**: Se notifica al usuario que su idea es muy breve para un guion estructurado
- **Template no encontrado**: Se usa template genérico "estructura_básica.json"

### Manejo de errores

- Fallback falla completamente → Notificación UI "No se pudo generar guion. Intenta de nuevo."
- Template corrupt JSON → Fallback al template hardcodeado en memoria
- Regex exception → Wrapping en try-catch, devolver texto original formateado

---

## Diseño técnico

### Arquitectura sugerida

Patrón **Strategy** con fallback chaining:

```
IGenerator (interfaz abstracta)
  ├── AIGenerator (primary, falla si no hay backend)
  └── FallbackGenerator (secondary, activo si AIGenerator falla)
```

Componentes del FallbackGenerator:

- `TemplateLoader`: Carga JSON desde assets/templates/
- `RegexParser`: Segmenta texto usando `RegExp(r'[.,]\s*')`
- `ScriptFormatter`: Construye script_bundle.json
- `FallbackOrchestrator`: Coordina el flujo completo

### Componentes involucrados

- `lib/generators/fallback_generator.dart` - Clase principal
- `lib/generators/template_loader.dart` - Carga de assets
- `lib/parsers/regex_parser.dart` - Parsing de texto
- `lib/models/script_bundle.dart` - Modelo de datos
- `lib/pipelines/generation_pipeline.dart` - Integración

### APIs/Endpoints

**NINGUNO** - Este módulo es completamente offline.

### Modelos de datos (schemas)

**Template JSON (assets/templates/pas.json):**
```json
{
  "id": "pas",
  "name": "Problema-Solución-Beneficio",
  "structure": [
    "Comienza con un problema o dolor que tu audiencia experimenta: {{idea}}",
    "Explica por qué ocurre y cómo lo has resuelto: {{idea}}",
    "Muestra el beneficio claro y medible: {{idea}}"
  ],
  "intention": ["informar", "convencer"]
}
```

**ScriptBundle JSON (output):**
```json
{
  "id": "uuid",
  "source": "fallback",
  "template_id": "pas",
  "generated_at": "ISO8601",
  "lines": [
    {"order": 1, "text": "Tu idea segmentada...", "type": "problem"},
    {"order": 2, "text": "...continúa aquí", "type": "solution"}
  ]
}
```

### Integraciones externas

**NINGUNA** - Todo funciona sin red.

---

## Decisiones

### Lenguajes/Frameworks

**Dart 3.x con Flutter** - Consistencia total con el codebase existente.

### Librerías/Herramientas

- **RegExp nativo de Dart** - Suficiente para splitting simple
- **dart:convert** - Parsing JSON nativo
- **flutter/services** - Carga de assets (rootBundle)
- **json_serializable** - Generación de modelos type-safe

### Justificación técnica

1. **No dependencias externas**: Mantiene el bundle small y zero network dependency
2. **Regex nativo**: Puntuación básica (. y ,) es 100% funcional sin librerías extra
3. **rootBundle**: Forma estándar de Flutter para cargar assets en tiempo de compilación
4. **json_serializable**: Genera código type-safe para mantenimiento largo

---

## Riesgos

### Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Regex no maneja puntuación no-latina (¡¿;) | MEDIA | BAJO | Añadir chars al pattern `r'[.,;!?¡¿]\s*'` |
| Templates corruptos | BAJA | ALTO | Try-catch + template hardcoded in-memory como backup |
| Memory con textos enormes | BAJA | MEDIA | Truncamiento a 5000 chars antes de parsing |

### Operativos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Templates limitados en variedad | ALTA | BAJO | Crear 5-7 templates covering intentions comunes |
| Calidad inferior a IA real | MEDIA | MEDIO | Notificar al usuario que es modo fallback |

### Escalabilidad

- **Si se agregan miles de templates**: Implementar lazy loading o index por intención
- **Si regex es insuficiente**: Migrar a sentence-splitting library (no ahora)

### Costos

- Desarrollo inicial: ~8 horas (bajo)
- Mantenimiento templates: ~2 horas/mes (crecimiento lineal)

---

## Plan

### Backlog técnico (ordenado)

1. **T1**: Crear directorio `assets/templates/` y definir 5 templates JSON (PAS, AIDA, Storytelling, List, Problem-Agitate-Solve)
2. **T2**: Implementar `TemplateLoader` con rootBundle.loadString() y cache in-memory
3. **T3**: Implementar `RegexParser` con función `List<String> splitText(String input)`
4. **T4**: Crear modelo `ScriptBundle` con json_serializable
5. **T5**: Implementar `FallbackGenerator` integrando T2+T3+T4
6. **T6**: Modificar `GenerationPipeline` para capturar exceptions de AIGenerator y invocar fallback
7. **T7**: Añadir logging con debug print para troubleshooting
8. **T8**: Crear UI fallback notification (Snackbar "Modo offline activado")

### Dependencias entre tareas

```
T1 (independiente)
T2 (depende de T1)
T3 (independiente)
T4 (independiente)
T5 (depende de T2, T3, T4)
T6 (depende de T5)
T7 (independiente, puede paralelizarse)
T8 (independiente)
```

---

## Métricas de éxito

### KPIs técnicos

| Métrica | Target | Cómo medir |
|---------|--------|-------------|
| Tiempo fallback < 500ms | 100% | Stopwatch en FallbackGenerator |
| Fallback成功率 (sin crash) | >99% | Crashlytics analytics |
| Líneas generadas por idea | ≥3 | Count en ScriptBundle.lines |

### KPIs de negocio

| Métrica | Target | Cómo medir |
|---------|--------|-------------|
| Usuarios que usan fallback | <20% de total | Analytics event: fallback_activated |
| Completan pipeline con fallback | >80% | Funnel analytics |

### Validación de implementación

1. Unit tests cubriendo parsing con 10+ inputs edge
2. Integration test del pipeline completo con mock AIGenerator throw
3. Test manual con 5 ideas largas/cortas/sin puntuación

---

## Estrategia de testing

### Unit tests (obligatorios)

- `RegexParser.splitText()` con: texto normal, sin puntuación, con comas, vacío, un char
- `TemplateLoader.load()` con: template existente, template faltante, JSON inválido
- `FallbackGenerator.generate()` con: idea válida, idea vacía, idea >5000 chars

### Integration tests

- Pipeline con AIGenerator throwing → Fallback invoked → ScriptBundle returned
- Pipeline con AIGenerator success → Fallback NOT invoked (verify mock called 0 times)

### Casos críticos a validar

1. Idea "Hola" → genera al menos 1 línea (no crash)
2. Idea con 10000 chars → truncamiento a 5000 sin exception
3. Template faltante → usa template por defecto sin crash
4. Fallback activo → UI muestra snackbar "Modo offline"

---

## Optimización y escalabilidad futura

### Problemas que aparecerán al escalar

1. **Variedad de templates**: Si hay 50+ templates, carga lenta en inicio
2. **Calidad del output**: Regex splitting es muy básico, no captura semántica
3. **Mantenimiento de templates**: JSON hardcodeado es difícil de editar sin recompilar

### Cómo dejar preparado el diseño desde ahora

1. **TemplateLoader con cache**: Ya implementado, permite lazy load futuro
2. **Interfaz IGenerator**: Facilita migrar a modelos locales (TensorFlow Lite) sin refactor
3. **Separación Parser/Formatter**: Permite mejorar lógica de segmentación independientemente
4. **Analytics hooks**: Ya incluidos en pipeline, permite decidir何时usar fallback real

### Roadmap post-MVP

- V2: Agregar 10+ templates más específicos por nicho
- V2: Reemplazar regex con sentence-transformers local
- V3: Integrar modelo LLM pequeño ( Gemma 2B) on-device