# Análisis: Día 6 - Exportación
**Documento:** docs\mvp-Definition.md  
**Paso:** día 6  
**Agente:** Kilo  

## Diseño funcional
### Flujo completo paso a paso
1. Usuario finaliza el stitching del video y llega a la pantalla de exportación.
2. Sistema verifica existencia del archivo `final.mp4` en el directorio del proyecto.
3. Llama a función de guardado utilizando `photo_manager` para insertar el video en la galería nativa del dispositivo.
4. Si guardado exitoso, obtiene la URI del asset guardado.
5. Despliega modal nativo de compartir usando `share_plus` con la URI del video.
6. Usuario selecciona plataforma de destino y comparte.

### Casos normales
- Video se guarda correctamente en galería y modal de compartir se muestra.
- Usuario puede seleccionar compartir vía WhatsApp, email, redes sociales, etc.

### Edge cases
- Archivo `final.mp4` no existe o está corrupto: mostrar error y permitir reintentar stitching.
- Permisos de galería denegados: solicitar permisos nuevamente o mostrar mensaje explicativo.
- Dispositivo sin espacio de almacenamiento: mostrar error de disco lleno.
- Video muy grande (>2GB): manejar límites de sistema de archivos.

### Manejo de errores
- Error en guardado: loggear y mostrar toast "Error al guardar video".
- Error en compartir: loggear y mostrar "Error al compartir".
- Timeout en operaciones: implementar timeouts de 30s para evitar UI congelada.

## Diseño técnico
### Arquitectura sugerida
- Crear servicio `ExportService` en `lib/services/export_service.dart`.
- Integrar en `recording_page.dart` o nueva pantalla `export_screen.dart`.
- Usar patrón Provider para estado de exportación.

### Componentes involucrados
- `ExportService`: Maneja lógica de guardado y compartir.
- `ExportScreen`: UI para mostrar progreso y botones de acción.
- `VideoPlayer`: Para preview opcional antes de exportar.

### APIs / endpoints necesarios
- `photo_manager`: `PhotoManager.editor.saveVideo()`
- `share_plus`: `Share.shareXFiles()`
- No se requieren APIs externas.

### Modelos de datos
```dart
class ExportResult {
  final bool success;
  final String? errorMessage;
  final String? assetId;
  final String? shareUrl;
}
```

### Integraciones externas
- iCloud/Fotos (iOS): `photo_manager` maneja automáticamente.
- Google Photos/Galería (Android): igual.

## Decisiones
### Lenguajes / frameworks recomendados
- Flutter/Dart: Consistente con el resto de la app.

### Librerías o herramientas clave
- `photo_manager: ^3.0.0`: Para guardado nativo en galería.
- `share_plus: ^7.0.0`: Para modal nativo de compartir.
- `path_provider`: Para acceder a rutas de archivos.

### Justificación técnica
- `photo_manager` es la librería estándar para gestión de fotos/videos en Flutter, maneja permisos y compatibilidad cross-platform.
- `share_plus` integra directamente con APIs nativas de compartir, evitando implementaciones custom que fallarían en updates de OS.
- Ambas son mantenidas activamente y tienen buena documentación.

## Riesgos
### Técnicos
- Compatibilidad con versiones antiguas de iOS/Android: `photo_manager` requiere min SDK 21+ para Android.
- Grandes archivos de video: Pueden causar OOM en dispositivos low-end.
- Concurrencia: Si múltiples exports simultáneos, race conditions en filesystem.

### Operativos
- Permisos denegados permanentemente: Usuario debe ir a settings manualmente.
- Fallos de red al compartir: Algunos shares requieren internet.

### Escalabilidad
- Múltiples videos: No impacta, pero UI debe manejar listas si se extiende.
- Almacenamiento: Videos grandes pueden llenar dispositivo rápidamente.

### Costos
- Ninguno adicional, librerías son gratis.

## Plan
### Desglose en tareas pequeñas
1. Agregar dependencias `photo_manager` y `share_plus` a `pubspec.yaml`.
2. Crear `ExportService` con método `exportVideo(String projectId)`.
3. Implementar guardado con `PhotoManager.editor.saveVideo()`.
4. Integrar compartir con `Share.shareXFiles()`.
5. Crear `ExportScreen` con UI de progreso y botones.
6. Agregar navegación desde `recording_page.dart` a `ExportScreen`.
7. Implementar manejo de errores y permisos.
8. Probar en dispositivos físicos iOS y Android.

### Orden recomendado de desarrollo
1. Dependencias y service base.
2. Guardado funcional.
3. Compartir funcional.
4. UI y navegación.
5. Error handling.
6. Testing.

### Dependencias entre tareas
- Service debe estar antes de UI.
- Testing requiere todo implementado.