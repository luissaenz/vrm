# 🧠 ANÁLISIS TÉCNICO: Día 6 - Exportación (Galería y Share Sheet)

**Agente:** agt
**Fase:** FASE 1 - Core de Grabación
**Alcance:** Implementación del flujo de salida del video final (`final.mp4`) hacia el ecosistema del dispositivo.

---

## 1. Diseño Funcional

El usuario, tras completar el proceso de grabación y stitching (Día 4-5), es dirigido a la pantalla de **Resumen de Performance** (`RecordingEndPage`). 

### Flujo Principal (Happy Path)
1.  **Visualización:** El usuario previsualiza el video final generado.
2.  **Acción de Guardado:** El usuario pulsa "Guardar en Galería".
    - El sistema solicita permisos si no los tiene.
    - Se muestra un indicador de carga (spinner) sobre el botón o un overlay.
    - Success: Mensaje de confirmación ("Video guardado en fotos").
3.  **Acción de Compartir:** El usuario pulsa el icono de "Compartir" (Share Sheet).
    - Se abre la interfaz nativa de compartición del OS con el archivo adjunto.

### Edge Cases (MVP)
- **Permisos Denegados:** Si el usuario niega el acceso a la galería, se muestra un diálogo explicativo con un link a los ajustes del sistema.
- **Espacio Insuficiente:** Si el guardado falla por falta de almacenamiento, se informa al usuario.
- **Cancelación de Share:** Si el usuario cierra el share sheet sin compartir, no ocurre nada (flujo normal de Android/iOS).

### Manejo de Errores
- **Error de Exportación:** Si la librería de guardado falla, se muestra un SnackBar con el error y la opción de reintentar.
- **Archivo no encontrado:** Si por alguna razón el `final.mp4` fue eliminado, se bloquea el botón de exportación y se muestra un mensaje de advertencia.

---

## 2. Diseño Técnico

### Componentes y Servicios
- **`ExportService` (Nuevo):** Servicio core que encapsula la interacción con plugins nativos.
  - `Future<bool> saveToGallery(String path)`: Copia el archivo a la galería.
  - `Future<void> shareVideo(String path, {String? text})`: Abre el share sheet.
- **`RecordingEndPage` (Modificación):** 
  - Integrar `ExportService`.
  - Añadir soporte para estados de carga (`isExporting`).
  - Dividir el botón inferior en dos acciones claras o un botón primario (Guardar) y una acción secundaria (Compartir).

### Interfaces
```dart
abstract class IExportService {
  Future<bool> saveVideoToGallery(String filePath);
  Future<void> shareVideo(String filePath, {String? message});
  Future<bool> hasGalleryPermission();
  Future<bool> requestGalleryPermission();
}
```

### Modelos de Datos
No se requieren nuevos modelos. Se utiliza el `finalVideoPath` persistido en `SessionData`.

---

## 3. Decisiones

1.  **Librería de Galería: `gal`**
    - **Justificación:** A diferencia de `photo_manager` (excelente para navegar galerías), `gal` es una librería moderna y mínima optimizada exclusivamente para *guardar* contenido en la galería con un manejo de permisos muy simplificado.
2.  **Librería de Compartido: `share_plus`**
    - **Justificación:** Es el estándar de la comunidad (Flutter Favorite) para invocar el Share Sheet nativo en Android e iOS.
3.  **Localización:** 
    - Se deben añadir las llaves `saveToGallery`, `videoSavedSuccess`, `videoSavedError` y `galleryPermissionRequired` a `app_localizations.dart` y sus archivos `.arb`.

---

## 4. Criterios de Aceptación (NUEVO)

- [ ] El video `final.mp4` se guarda en el álbum de fotos predeterminado del sistema.
- [ ] El nombre del archivo exportado sigue un patrón reconocible (ej: `VRM_VIDEO_2024...mp4`).
- [ ] El Share Sheet muestra la miniatura del video (si el OS lo soporta) y el archivo adjunto correctamente.
- [ ] En Android 13+, se solicita correctamente el permiso selectivo de medios.
- [ ] En iOS, se incluye la descripción de privacidad `NSPhotoLibraryAddUsageDescription` en el `Info.plist`.
- [ ] El usuario recibe feedback visual claro (loading -> success) durante todo el proceso.

---

## 5. Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| **Cambios en permisos Android 10-13** | Alto | Usar `permission_handler` junto con `gal` para manejar los diferentes niveles de acceso a almacenamiento/medios. |
| **Rechazo de App Store (iOS)** | Medio | Asegurar que los mensajes de `Info.plist` (Usage Descriptions) sean claros y no genéricos. |
| **Tamaño del archivo** | Bajo | Los videos de VRM son cortos (clips de ~10s x 10 chunks), pero se debe validar que el video no esté corrupto antes de exportar. |

---

## 6. Plan

1.  **Configuración de Dependencias (Complejidad Baja):**
    - Añadir `gal: ^2.4.0` y `share_plus: ^10.1.0` a `pubspec.yaml`.
    - `flutter pub get`.
2.  **Configuración Nativa (Complejidad Media):**
    - Android: Añadir permisos en `AndroidManifest.xml` (especialmente para legacy storage si aplica).
    - iOS: Añadir `NSPhotoLibraryAddUsageDescription` en `Info.plist`.
3.  **Implementación del Core (Complejidad Media):**
    - Crear `lib/core/services/export_service.dart`.
    - Implementar lógica de permisos y wrappers de plugins.
4.  **Actualización de UI (Complejidad Baja):**
    - Modificar `RecordingEndPage` para inyectar el servicio.
    - Implementar botones de acción y snacks de feedback.
5.  **Validación (Complejidad Baja):**
    - Testear en físico (Android/iOS) para confirmar persistencia real en galería.

---

### 🔮 Roadmap (No implementar ahora)
- Exportación a carpetas personalizadas.
- Transcodificación a diferentes calidades antes de exportar.
- Integración directa con Google Drive / Dropbox previa autenticación.
- Generación automática de miniaturas para el momento de compartir.
