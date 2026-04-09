# Análisis Día 7-8: Persistencia Local Offline

## Diseño funcional

### Flujo completo paso a paso (tipo pipeline)
1. Al iniciar un nuevo proyecto, crear directorio `/vrm_data/projects/{project_id}/` y archivos base (input_schema.json, script_bundle.json).
2. Durante la grabación, salvar estado incremental en session_data.json cada vez que se completa un clip o bloque.
3. Si el pipeline se cancela (usuario sale, app crashea), el estado queda persistido.
4. Al reanudar, desde Dashboard, detectar proyectos incompletos y cargar session_data.json para continuar desde el último checkpoint.
5. Al completar el proyecto, marcar como finalizado y generar final.mp4 si no existe.

### Casos normales
- Usuario graba varios clips, app se cierra inesperadamente, al reabrir puede continuar grabando los clips faltantes.
- Pipeline llega a stitching, falla en medio, reanuda desde stitching con clips existentes.

### Edge cases
- Proyecto sin clips grabados: reanudar desde generación de guion.
- Clips faltantes: notificar al usuario y permitir re-grabar.
- JSON corrupto: fallback a estado inicial, con warning.
- Dispositivo sin espacio: manejar error y sugerir liberar espacio.

### Manejo de errores
- Si escritura falla (permisos, espacio), mostrar error al usuario y pausar pipeline.
- Si carga falla, ofrecer reset del proyecto.

## Diseño técnico

### Arquitectura sugerida
- Patrón Repository: Clase `PersistenceManager` encapsula toda lógica de I/O.
- Separación: Métodos `saveProjectState`, `loadProjectState`, `cleanupOldProjects`.

### Componentes involucrados
- `PersistenceManager`: Singleton para manejar archivos JSON.
- Modelos: Clases Dart serializables (usando json_serializable) para ProjectData, SessionData.
- Integración en `vrm_pipeline`: Llamadas a save en puntos críticos.

### APIs / endpoints necesarios
- No aplica (local offline).

### Modelos de datos (schemas sugeridos)
```json
// input_schema.json
{
  "project_id": "string",
  "idea": "string",
  "intention": "string",
  "created_at": "timestamp"
}

// session_data.json
{
  "current_step": "string", // e.g. "recording", "stitching"
  "recorded_clips": ["clip_1.mp4", "clip_2.mp4"],
  "script_blocks": [...],
  "last_saved": "timestamp"
}
```

### Integraciones externas (si aplica)
- path_provider para directorios.
- json para serialización.

## Decisiones

### Lenguajes / frameworks recomendados
- Dart/Flutter, existente en el proyecto.

### Librerías o herramientas clave
- path_provider: Para paths consistentes.
- json_serializable: Para modelos seguros.
- shared_preferences: Para metadatos simples si needed, pero usar files para datos grandes.

### Justificación técnica (no genérica)
- path_provider asegura compatibilidad cross-platform (iOS/Android).
- JSON simple evita complejidad de DB como SQLite, suficiente para MVP offline.
- Serialización automática reduce bugs en parsing.

## Riesgos

### Técnicos
- Archivos JSON grandes causan lag en carga: Mitigación - dividir en chunks o usar async loading.
- Corrupción de archivos: Mitigación - backups automáticos o checksums.

### Operativos
- Usuario borra archivos manualmente: Mitigación - warning en UI sobre importancia de no tocar /vrm_data.
- App updates rompen schemas: Mitigación - versionado en JSON.

### Escalabilidad
- Muchos proyectos: Mitigación - límite de 10 proyectos, auto-cleanup de antiguos.
- Espacio disco: Mitigación - checks de espacio antes de grabar.

### Costos
- Bajo: Solo CPU para serialización, no APIs externas.

## Plan

### Desglose en tareas pequeñas (tipo backlog técnico)
1. Definir modelos Dart para ProjectData y SessionData con json_serializable.
2. Implementar PersistenceManager con métodos save/load usando path_provider.
3. Integrar saves en vrm_pipeline en checkpoints (post-clip, pre-stitch).
4. Agregar lógica de reanudación en Dashboard: detectar proyectos incompletos.
5. Implementar cleanup: borrar proyectos completados antiguos.
6. Testing: Unit tests para save/load, integration para pipeline reanudado.

### Orden recomendado de desarrollo
- 1,2 (base), luego 3,4 (integración), 5 (cleanup), 6 (testing).

### Dependencias entre tareas
- 3 depende de 2.
- 4 depende de 3.
- 6 depende de 1-5.