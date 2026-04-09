# Análisis Técnico: Día 6 — Exportación (Galería + Share Sheet)

## 1. Diseño Funcional

### Happy Path Detallado
1. El usuario completa el stitching → `RecordingManager` retorna `finalVideoPath` → navega a `RecordingEndPage`.
2. `RecordingEndPage` recibe `finalVideoPath` y muestra preview del video con botón "Exportar Video" (ya existe, `onPressed` vacío).
3. Usuario toca "Exportar Video".
4. El sistema verifica permisos de almacenamiento/galería. Si no están concedidos, muestra diálogo nativo de solicitud.
5. El video `final.mp4` se guarda en la galería nativa del dispositivo (app Fotos / Google Photos).
6. Inmediatamente después del guardado exitoso, se abre el modal nativo de compartir del OS (`share_plus`) con el archivo como adjunto.
7. El usuario elige destino o cierra el share sheet.
8. Se marca la exportación como completada en `session_data.json` y se muestra confirmación visual breve ("Guardado ✓").

### Edge Cases que Afectan al MVP
- **`finalVideoPath` es null o archivo no existe:** El stitching pudo haber fallado silenciosamente o el archivo fue borrado. El botón debe estar deshabilitado y mostrar tooltip "Video no disponible".
- **Permisos de galería denegados permanentmente:** El usuario rechazó permisos anteriormente y seleccionó "no volver a preguntar". Se muestra diálogo explicativo con botón "Abrir Configuración" para ir a settings del OS.
- **Espacio insuficiente en galería:** `photo_manager` puede fallar si el almacenamiento está lleno. Se captura el error y se muestra mensaje específico con opción de reintentar.
- **Video > formato/galería incompatibilidad:** Algunos dispositivos pueden rechazar ciertos codecs. Si `photo_manager` falla, se intenta fallback con `share_plus` directamente desde la ruta temporal del archivo (sin copiar a galería).

### Manejo de Errores — Qué Ve el Usuario
| Escenario | Feedback Visual | Acción Disponible |
|---|---|---|
| Permisos denegados | SnackBar: "Se necesitan permisos de galería para guardar" + botón "Ir a Ajustes" | Botón que abre `AppSettings.openAppSettings()` |
| Error al guardar | SnackBar: "Error al guardar el video. Intenta de nuevo." | Botón "Reintentar" re-ejecuta el flujo |
| Share sheet cancelado por usuario | Sin mensaje (comportamiento esperado — el video ya está en galería) | Ninguna, el video ya se guardó |
| Archivo corrupto/inexistente | Botón deshabilitado con texto "Video no disponible" | Ninguno, el usuario debe rehacer el stitching |

---

## 2. Diseño Técnico

### Componente Nuevo: `ExportService`
**Archivo:** `lib/core/services/export_service.dart`

Servicio stateless que encapsula las operaciones de exportación. No depende de `RecordingManager` ni de ningún estado de UI.

```
class ExportService {
  // Guarda el video en la galería del dispositivo
  Future<GallerySaveResult> saveToGallery(String videoPath)

  // Abre el share sheet nativo con el video
  Future<void> shareVideo(String videoPath)
}

class GallerySaveResult {
  final bool success;
  final String? assetId;  // ID del asset en galería (iOS) / path (Android)
  final String? errorMessage;
}
```

**Responsabilidades:**
- Solicitar y verificar permisos de galería vía `permission_handler` (ya instalado).
- Usar `photo_manager` para escribir el video en la galería.
- Usar `share_plus` para abrir el share sheet.
- Retornar resultados tipados para que la UI reaccione apropiadamente.

### Modificación: `RecordingEndPage`
**Archivo:** `lib/features/recording/recording_end_page.dart`

Cambios mínimos y localizados:
1. Agregar estado `_isExporting` (bool) para controlar spinner durante exportación.
2. Conectar el `onPressed` del botón "Export Video" (línea ~394) a `_handleExport()`.
3. `_handleExport()` llama a `ExportService.saveToGallery()` → luego `ExportService.shareVideo()`.
4. Mostrar `CircularProgressIndicator` overlay durante el proceso.
5. Mostrar `SnackBar` de éxito/error según resultado.

### Modificación: `SessionData`
**Archivo:** `lib/features/recording/models/session_data.dart`

Agregar campos:
- `exportedAt: DateTime?` — marca cuando se exportó exitosamente.
- `galleryAssetId: String?` — identificador del asset en galería (opcional, útil para futuras referencias).

Estos campos son opcionales (`?`) para mantener compatibilidad con sesiones existentes que no tienen exportación. No rompen JSON parsing de sesiones previas.

### Flujo de Integración
```
RecordingEndPage._handleExport()
  ├── setState(() => _isExporting = true)
  ├── ExportService.saveToGallery(widget.finalVideoPath!)
  │   ├── permission_handler.check(Permission.photos)  // iOS
  │   ├── permission_handler.check(Permission.storage) // Android < 13
  │   ├── PhotoManager.editor.saveVideoWithPath(videoPath)
  │   └── Retorna GallerySaveResult
  ├── [Si éxito] ExportService.shareVideo(widget.finalVideoPath!)
  │   └── Share.shareXFiles([XFile(videoPath)])
  ├── setState(() => _isExporting = false)
  ├── [Opcional] RecordingManager actualiza sessionData con exportedAt
  └── SnackBar de confirmación
```

### No se Modifican
- `RecordingManager` — la exportación es un paso posterior al stitching, no necesita cambios en el manager. Se maneja puramente en la UI layer + `ExportService`.
- `FFmpegStitcherService` — ya genera `final.mp4` correctamente.
- `CameraService`, `ClipStorageService` — no involucrados.

---

## 3. Decisiones

### D1: `photo_manager` como mecanismo principal de guardado
**Justificación:** `photo_manager` tiene soporte nativo para escribir videos en la galería tanto en iOS (Photos framework) como en Android (MediaStore). Maneja automáticamente las diferencias de API levels y el caso especial de iCloud en iOS. Alternativas como `image_gallery_saver` son menos mantenidas y no soportan iOS tan robustamente.

### D2: `permission_handler` para permisos (ya instalado) en lugar de dejar que `photo_manager` maneje permisos implícitamente
**Justificación:** `photo_manager` puede solicitar permisos internamente, pero no expone buen control para detectar "permanently denied". Usar `permission_handler` (que ya es dependencia del proyecto) permite verificar el estado `PermissionStatus.permanentlyDenied` y ofrecer al usuario ir directamente a settings, mejorando la UX.

### D3: Secuencia save → share (no al revés ni en paralelo)
**Justificación:** Si compartimos primero y el share sheet falla, el usuario pierde la acción sin tener el video en galería. Guardando primero, incluso si el share falla, el video ya está disponible en la app Fotos. El usuario puede compartir manualmente después.

### D4: No agregar `ExportService` como método dentro de `RecordingManager`
**Justificación:** `RecordingManager` orquesta grabación → revisión → stitching. La exportación es un paso post-pipeline que no afecta el estado de la sesión de grabación. Mantenerlo separado reduce acoplamiento y facilita testing individual. La UI (`RecordingEndPage`) orquesta la secuencia.

### D5: No usar `share_plus` como mecanismo de guardado a galería
**Justificación:** `share_plus` solo abre el share sheet. En iOS, el usuario podría elegir "Save Video" pero no es guaranteed. Necesitamos `photo_manager` para asegurar que el video se escribe directamente en la galería sin depender de la acción del usuario en el share sheet.

---

## 4. Criterios de Aceptación

- [ ] Las dependencias `photo_manager` y `share_plus` están declaradas en `pubspec.yaml` con versiones compatibles.
- [ ] `ExportService` existe en `lib/core/services/export_service.dart` con métodos `saveToGallery()` y `shareVideo()`.
- [ ] El botón "Export Video" en `RecordingEndPage` llama a `ExportService` y muestra un indicador de carga mientras procesa.
- [ ] Al guardar exitosamente en galería, el video es visible en la app nativa de Fotos/Google Photos del dispositivo.
- [ ] Después de guardar en galería, se abre automáticamente el share sheet nativo con el video adjunto.
- [ ] Si los permisos de galería están denegados permanentemente, se muestra un mensaje explicativo con un botón que abre la configuración del sistema.
- [ ] Si el guardado falla por espacio insuficiente, se muestra un mensaje de error específico (genérico, no stack trace).
- [ ] Si `finalVideoPath` es null o el archivo no existe, el botón "Export Video" aparece deshabilitado.
- [ ] `SessionData` incluye campos opcionales `exportedAt` y `galleryAssetId` que se serializan/deserializan correctamente en JSON.
- [ ] Tras una exportación exitosa, se muestra un `SnackBar` o indicador breve de confirmación ("Guardado ✓").
- [ ] El usuario puede cancelar el share sheet sin afectar el video ya guardado en galería.
- [ ] No hay memory leaks: tras navegar away de `RecordingEndPage`, los controladores de video y referencias al archivo se liberan correctamente.

---

## 5. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `photo_manager` falla en iOS 17+ por cambios en Photos API | Media | Alto | Usar la versión más reciente de `photo_manager` (^3.x). Si falla, capturar error y ofrecer fallback: share directo con `share_plus` sin guardar en galería. |
| `photo_manager` no solicita permisos correctamente en Android 13+ (permisos granulares de media) | Media | Medio | Usar `permission_handler` para verificar `Permission.photos` antes de llamar a `photo_manager`. Si denegado, guiar al usuario a settings. |
| Video demasiado grande para el share sheet (algunos OS limitan archivos adjuntos) | Baja | Medio | `share_plus` generalmente maneja archivos locales sin límite estricto. Si el problema ocurre, el share sheet nativo del OS lo maneja; no hay control directo. Documentar como limitación de plataforma. |
| El usuario cierra la app durante la exportación (a mitad de saveToGallery) | Baja | Medio | `photo_manager.editor.saveVideoWithPath()` es atómico — o completa o falla limpiamente. No deja archivos corruptos en galería. El video original en `vrm_data/` permanece intacto. |
| `share_plus` no encuentra el archivo por problemas de FileProvider (Android) | Baja | Alto | Asegurar que `android/app/src/main/AndroidManifest.xml` tenga el `<provider>` configurado para `file_paths.xml`. Esto es requerido por `share_plus` en Android. |

---

## 6. Plan

### Tareas Atómicas (ordenadas)

| # | Tarea | Complejidad | Dependencias |
|---|---|---|---|
| 1 | Agregar `photo_manager` y `share_plus` al `pubspec.yaml` y ejecutar `flutter pub get` | Baja | Ninguna |
| 2 | Crear `lib/core/services/export_service.dart` con la clase `ExportService` y el modelo `GallerySaveResult` | Baja | Tarea 1 |
| 3 | Implementar `saveToGallery()` en `ExportService`: verificación de permisos + llamada a `photo_manager` + manejo de errores | Media | Tarea 2 |
| 4 | Implementar `shareVideo()` en `ExportService`: llamada a `share_plus` + manejo de cancelación | Baja | Tarea 2 |
| 5 | Extender `SessionData` con campos `exportedAt` y `galleryAssetId` (modelo + JSON + copyWith) | Baja | Ninguna |
| 6 | Modificar `RecordingEndPage._buildBottomAction()`: conectar `onPressed` del botón a `_handleExport()`, agregar estado `_isExporting`, spinner overlay, SnackBar feedback | Media | Tareas 3, 4 |
| 7 | Verificar configuración de Android para `share_plus`: asegurarse de que `AndroidManifest.xml` tiene el provider de FileProvider configurado (generalmente `share_plus` lo agrega automáticamente, pero verificar) | Baja | Tarea 1 |
| 8 | Testing en dispositivo físico Android: permisos, guardado a galería, share sheet | Media | Tareas 1-7 |
| 9 | Testing en dispositivo físico iOS: permisos Photos, guardado, share sheet | Media | Tareas 1-7 |

### Dependencias Visuales
```
T1 (deps) → T2 (servicio) → T3 (saveToGallery) → T6 (UI)
                        → T4 (shareVideo)     → T6 (UI)
T5 (modelo) → T6 (UI)
T1 → T7 (Android config)
T6 → T8 (testing Android)
T6 → T9 (testing iOS)
```

---

## 🔮 Roadmap (NO implementar ahora)

- **Compresión pre-exportación:** Antes de guardar/compartir, ofrecer opción de comprimir el video para reducir tamaño (especialmente útil para compartir por WhatsApp/Telegram con límites de archivo).
- **Selección de calidad de exportación:** Permitir al usuario elegir resolución/bitrate del video final (720p, 1080p, original).
- **Exportación directa a cloud:** Integración con Google Drive, iCloud Drive, Dropbox para backup automático.
- **Re-exportación desde historial:** Si el usuario quiere re-exportar un proyecto antiguo, poder hacerlo sin re-grabar (requiere que `final.mp4` persista en disco).
- **Métricas de exportación:** Trackear cuántas veces se exporta, a qué plataformas, para analizar uso real de la feature (post-MVP, con consentimiento del usuario).
- **Watermark/Branding:** Opción de agregar watermark sutil de "Hecho con LUMIS" en la esquina del video exportado (para marketing orgánico).

### Decisiones de Diseño Pensando en el Futuro
- `ExportService` se diseñó como clase separada (no acoplada a `RecordingManager`) para que sea extensible: se pueden agregar métodos como `compressVideo()`, `exportToCloud()` sin tocar la lógica de grabación.
- Los campos `exportedAt` y `galleryAssetId` en `SessionData` son opcionales y extensibles: se pueden agregar `exportedPaths`, `shareDestinations`, etc. sin romper compatibilidad.
- El flujo save → share es secuencial pero cada paso retorna resultado independiente, lo que permite en el futuro hacer save sin share, o share sin save, según preferencia del usuario.
