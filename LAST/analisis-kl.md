# Análisis Técnico: Día 6 - Exportación (Galería y Share Sheet)

## 1. Diseño Funcional

### Happy Path Detallado
1. Usuario completa el stitching y llega a la pantalla de exportación.
2. Toca el botón "Exportar y Compartir".
3. El sistema solicita permisos de galería si no están concedidos.
4. El video `final.mp4` se copia a la galería nativa del dispositivo.
5. Se abre automáticamente el modal nativo de compartir del sistema operativo, permitiendo al usuario elegir destino (WhatsApp, Instagram, etc.) o guardar localmente.
6. El usuario ve una confirmación visual de éxito.

### Edge Cases Relevantes para MVP
- **Archivo final.mp4 no existe:** Si el stitching falló, mostrar mensaje "No hay video para exportar" y redirigir a grabación.
- **Permisos denegados:** Mostrar diálogo explicativo y opción para ir a ajustes del sistema.
- **Espacio insuficiente en galería:** Notificar error y sugerir liberar espacio.
- **Video corrupto:** Durante el guardado, validar que el archivo sea reproducible antes de confirmar.

### Manejo de Errores
- **Falla en guardado:** Mensaje "Error al guardar en galería. Revisa permisos y espacio disponible."
- **Falla en compartir:** Mensaje "No se pudo abrir el compartidor. Intenta guardar manualmente."
- En todos los casos, permitir al usuario reintentar la acción sin perder progreso.

## 2. Diseño Técnico

### Componentes Nuevos o Modificaciones
- **Nuevo servicio:** `ExportService` en `lib/core/services/export_service.dart` para encapsular lógica de exportación.
- **Modificación:** Actualizar `RecordingManager` para integrar el flujo de exportación al final del pipeline.
- **UI:** Agregar botón "Exportar" en la pantalla post-stitching (probablemente `recording_page.dart` o nueva pantalla de resultados).

### Interfaces (Inputs/Outputs)
- **ExportService.exportFinalVideo(String finalVideoPath): Future<bool>**
  - Input: Ruta absoluta del `final.mp4`
  - Output: `true` si exitoso, `false` si falló
  - Lanza excepciones específicas: `PermissionDeniedException`, `StorageFullException`, `FileCorruptException`

### Modelos de Datos Nuevos o Extensiones
- Extender `ProjectState` con campo `exportedAt: DateTime?` para marcar cuando se exportó exitosamente.
- Actualizar `session_data.json` para incluir estado de exportación.

Debe ser coherente con contratos existentes: estructura de carpetas `vrm_data/projects/{id}/final.mp4`, convenciones de naming.

## 3. Decisiones

- **Uso de photo_manager sobre métodos nativos:** Proporciona abstracción cross-platform robusta para escritura en galería, manejando iCloud en iOS automáticamente. Evita código nativo personalizado.
- **Integración secuencial save + share:** Primero guardar para obtener URI válida, luego compartir. Evita compartir archivos temporales que puedan desaparecer.
- **No pre-validar permisos exhaustivamente:** Confiar en las librerías para manejar prompts nativos, reduciendo complejidad inicial.

## 4. Criterios de Aceptación
- El archivo `final.mp4` se copia correctamente a la galería del dispositivo (visible en app Fotos/iCloud).
- La pantalla muestra spinner durante el guardado y confirmación al finalizar.
- Si falla el guardado por permisos, el usuario ve un mensaje explicativo y botón para ir a ajustes.
- Si falla el guardado por espacio, el usuario ve un mensaje específico y sugerencia de acción.
- El modal nativo de compartir se abre automáticamente después del guardado exitoso.
- El estado de la sesión se marca como exportado en `session_data.json`.
- No se pierden datos si el usuario cancela durante el proceso.

## 5. Riesgos
- **Incompatibilidad de photo_manager en versiones antiguas de Android:** Mitigación: Implementar fallback usando `MediaStore` nativo si falla.
- **Bloqueo de share_plus en ciertos dispositivos jailbroken/rooted:** Mitigación: Atrapar excepciones y mostrar opción alternativa de "Guardar solo".
- **Latencia en dispositivos lentos durante copia de video:** Mitigación: Mostrar progreso estimado y permitir cancelación.

## 6. Plan
1. **Crear ExportService básico** (Baja): Definir clase con método skeleton y dependencias.
2. **Implementar guardado con photo_manager** (Media): Integrar copia a galería, manejo de permisos.
3. **Agregar validación de archivo** (Baja): Verificar integridad del video antes de exportar.
4. **Integrar share_plus** (Media): Abrir modal después de guardado exitoso.
5. **Actualizar RecordingManager** (Media): Conectar flujo de exportación al final del pipeline. Depende de tarea 1-4.
6. **Modificar UI de resultados** (Baja): Agregar botón y estados visuales. Depende de tarea 5.
7. **Testing en dispositivos físicos** (Media): Validar en iOS y Android reales. Depende de todas las tareas anteriores.

## 🔮 Roadmap
- Integración con cloud storage (Google Drive, iCloud Drive) para backup automático.
- Compresión automática del video antes de compartir para reducir tamaño.
- Opciones avanzadas de exportación (calidad, formato alternativo).
- Análisis de uso post-exportación para métricas de engagement.</content>
<parameter name="filePath">D:\Develop\Personal\vrm\LAST\analisis-kl.md