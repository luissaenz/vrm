# Contratos Técnicos y Schemas (VRM App)

## 1. Micro-Fragmento (Cámara Atómica)
Define la estructura de datos para cada clip de 2-4 segundos capturado localmente.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MicroFragment",
  "description": "Definición de un fragmento de video capturado (2-4 segundos)",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "timestamp": { "type": "string", "format": "date-time" },
    "duration": { "type": "number", "minimum": 2, "maximum": 5 },
    "fileUri": { "type": "string" },
    "metadata": {
      "type": "object",
      "properties": {
        "eyeGazeSuccess": { "type": "boolean" },
        "noiseLevelDb": { "type": "number" },
        "transcription": { "type": "string" }
      }
    }
  },
  "required": ["id", "timestamp", "duration", "fileUri"]
}
```

## 2. Contrato de Plugin de IA (Cloud/Local)
Define cómo se comunican los plugins externos con el núcleo de VRM.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AIPluginContract",
  "description": "Contrato para plugins de IA (Generación de guiones, Lip-sync, Mejora de audio)",
  "type": "object",
  "properties": {
    "pluginId": { "type": "string" },
    "inputType": { "enum": ["micro-fragment", "full-video", "audio-only", "text"] },
    "operation": { "type": "string", "example": "lip-sync-translation" },
    "parameters": {
      "type": "object",
      "additionalProperties": true
    },
    "output": {
      "type": "object",
      "properties": {
        "status": { "enum": ["success", "processing", "error"] },
        "resultUri": { "type": "string", "format": "uri" },
        "metadata": { "type": "object" }
      },
      "required": ["status"]
    }
  },
  "required": ["pluginId", "inputType", "operation"]
}
```
