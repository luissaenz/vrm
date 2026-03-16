# Arquitectura de Pipeline Modular VRM

## 📐 Estructura General

La aplicación VRM sigue una **arquitectura de pipeline lineal modular** basada en el patrón Strategy Pattern, donde cada fase del procesamiento está desacoplada mediante interfaces abstractas.

```
[Ingesta] → [Procesamiento] → [Grabación*] → [Post-Proceso] → [Analytics]
     ↓              ↓              ↓                ↓                ↓
IIdeaSource   IScriptProcessor  (Recording)  IPostProcessor  IAnalyticsProvider
```

*La grabación ocurre entre el procesamiento de script y el post-procesamiento, pero no es un plugin sino parte del core de la app.

---

## 🎯 Principios Arquitectónicos

### 1. **Single Source of Truth (SSoT)**
Todos los contratos de datos están definidos como **JSON Schemas** en [`lib/core/schemas/`](file:///d:/Develop/Personal/vrm/lib/core/schemas/):

- [`input_schema.json`](file:///d:/Develop/Personal/vrm/lib/core/schemas/input_schema.json) - Ingesta normalizada
- [`script_bundle.json`](file:///d:/Develop/Personal/vrm/lib/core/schemas/script_bundle.json) - Guion micro-fragmentado
- [`asset_manifest.json`](file:///d:/Develop/Personal/vrm/lib/core/schemas/asset_manifest.json) - Paquete de video
- [`project_state.json`](file:///d:/Develop/Personal/vrm/lib/core/schemas/project_state.json) - Estado completo del proyecto

### 2. **Strategy Pattern (Plugins Intercambiables)**
Ninguna lógica está hard-coded. Todo se procesa mediante plugins que implementan interfaces:

```dart
// Ejemplo: cambiar de plugin local a backend API
final pipeline = PipelineFactory.createFromConfig({
  'script_processor': 'backend_api_v1' // o 'template_script_v1'
});
```

### 3. **Determinístico y Lineal**
El pipeline es **explícito y predecible**. No hay agentes autónomos ni orquestadores de IA.

---

## 📦 Componentes

### Contratos de Datos (Models)
Ubicación: [`lib/core/models/`](file:///d:/Develop/Personal/vrm/lib/core/models/)

- [`input_schema.dart`](file:///d:/Develop/Personal/vrm/lib/core/models/input_schema.dart)
- [`script_bundle.dart`](file:///d:/Develop/Personal/vrm/lib/core/models/script_bundle.dart)
- [`asset_manifest.dart`](file:///d:/Develop/Personal/vrm/lib/core/models/asset_manifest.dart)
- [`project_state.dart`](file:///d:/Develop/Personal/vrm/lib/core/models/project_state.dart)

### Interfaces de Plugins
Ubicación: [`lib/core/plugins/`](file:///d:/Develop/Personal/vrm/lib/core/plugins/)

- [`i_idea_source.dart`](file:///d:/Develop/Personal/vrm/lib/core/plugins/i_idea_source.dart)
- [`i_script_processor.dart`](file:///d:/Develop/Personal/vrm/lib/core/plugins/i_script_processor.dart)
- [`i_post_processor.dart`](file:///d:/Develop/Personal/vrm/lib/core/plugins/i_post_processor.dart)
- [`i_analytics_provider.dart`](file:///d:/Develop/Personal/vrm/lib/core/plugins/i_analytics_provider.dart)

### Plugins Default (MVP)
Ubicación: [`lib/core/plugins/default/`](file:///d:/Develop/Personal/vrm/lib/core/plugins/default/)

| Plugin | Interfaz | Descripción |
|--------|----------|-------------|
| [`ManualInputPlugin`](file:///d:/Develop/Personal/vrm/lib/core/plugins/default/manual_input_plugin.dart) | IIdeaSource | Ingesta manual desde campo de texto |
| [`TemplateScriptPlugin`](file:///d:/Develop/Personal/vrm/lib/core/plugins/default/template_script_plugin.dart) | IScriptProcessor | Fragmentación basada en plantillas locales |
| [`StitcherPlugin`](file:///d:/Develop/Personal/vrm/lib/core/plugins/default/stitcher_plugin.dart) | IPostProcessor | Unión nativa de clips (AVFoundation/MediaCodec) |
| [`LocalSessionStats`](file:///d:/Develop/Personal/vrm/lib/core/plugins/default/local_session_stats.dart) | IAnalyticsProvider | Métricas básicas de sesión |

### Plugins Externos (Opcionales)
Ubicación: [`lib/core/plugins/external/`](file:///d:/Develop/Personal/vrm/lib/core/plugins/external/)

- [`BackendScriptPlugin`](file:///d:/Develop/Personal/vrm/lib/core/plugins/external/backend_script_plugin.dart) - Adaptador para el backend FastAPI existente

### Pipeline Central
Ubicación: [`lib/core/pipeline/`](file:///d:/Develop/Personal/vrm/lib/core/pipeline/)

- [`vrm_pipeline.dart`](file:///d:/Develop/Personal/vrm/lib/core/pipeline/vrm_pipeline.dart) - Orquestador principal
- [`pipeline_factory.dart`](file:///d:/Develop/Personal/vrm/lib/core/pipeline/pipeline_factory.dart) - Factory para inyección de dependencias

---

## 🚀 Uso del Pipeline

### Ejemplo Básico (100% Local)

```dart
import 'package:vrm_app/core/pipeline/pipeline_factory.dart';

// Crear pipeline con plugins default
final pipeline = PipelineFactory.createDefaultPipeline();

// Ejecutar solo procesamiento de script
final script = await pipeline.executeScriptOnly({
  'topic': 'Cómo crear contenido viral',
  'context': 'En este video veremos las mejores estrategias...',
});

print('Total de fragmentos: ${script.totalChunks}');
for (var chunk in script.chunks) {
  print('${chunk.order}. ${chunk.text}');
}
```

### Usando Backend API

```dart
// Crear pipeline que usa backend para script processing
final pipeline = PipelineFactory.createBackendPipeline();

final script = await pipeline.executeScriptOnly({
  'topic': 'Tutorial de Flutter',
  'context': 'Aprende a crear apps móviles desde cero...',
});
```

### Configuración Runtime

```dart
// Cargar configuración desde SharedPreferences o archivo
final config = {
  'script_processor': 'backend_api_v1', // o 'template_script_v1'
};

final pipeline = PipelineFactory.createFromConfig(config);
```

---

## 🔄 Flujo Completo

```mermaid
graph LR
    A[UI: New Project] --> B[IIdeaSource]
    B --> C[InputSchema]
    C --> D[IScriptProcessor]
    D --> E[ScriptBundle]
    E --> F[Recording UI]
    F --> G[AssetManifest raw]
    G --> H[IPostProcessor]
    H --> I[AssetManifest processed]
    I --> J[IAnalyticsProvider]
    J --> K[Metrics Report]
```

---

## 📝 Persistencia (JSON Local)

Los proyectos se guardan como archivos JSON individuales:

```
/documents/projects/
  ├── uuid-1234.json  (ProjectState completo)
  ├── uuid-5678.json
  └── ...
```

**Ejemplo de Project State:**
```json
{
  "project_id": "uuid-1234",
  "created_at": "2026-02-05T10:00:00Z",
  "updated_at": "2026-02-05T11:00:00Z",
  "input": { "idea_id": "...", "raw_topic": "...", ... },
  "script": { "script_id": "...", "chunks": [...] },
  "assets": [
    { "video_id": "...", "file_path": "...", "status": "processed" }
  ]
}
```

---

## ✅ Cumplimiento de Especificaciones

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| Pipeline modular (Strategy Pattern) | ✅ | 4 interfaces + Factory |
| Contratos JSON (SSoT) | ✅ | 4 JSON Schemas validados |
| Inyección de dependencias | ✅ | PipelineFactory |
| Sistema determinista | ✅ | Flujo lineal explícito |
| Persistencia JSON | ✅ | ProjectState en archivos locales |
| NO agentes autónomos | ✅ | Pipeline invocador simple |
| Backend como plugin opcional | ✅ | BackendScriptPlugin |

---

## 🔧 Próximos Pasos

1. **Refactorizar UI existente** para usar el pipeline
2. **Implementar grabación real** que genere `AssetManifest`
3. **Implementar stitching nativo** (AVFoundation/MediaCodec)
4. **Crear sistema de configuración** para selección de plugins en UI

---

## 📚 Referencias

- [Especificaciones Maestras](file:///C:/Users/ld_sa/.gemini/antigravity/brain/35f10135-ae97-42d2-8b99-813545babc30/implementation_plan.md)
- [Tests de Integración](file:///d:/Develop/Personal/vrm/test/pipeline_test.dart)
