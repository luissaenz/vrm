# 🏛️ BLUEPRINT DEFINITIVO: Día 6 — Exportación (Galería + Share Sheet)

**Estado:** CONSOLIDADO / PARA IMPLEMENTACIÓN
**Versión:** 1.0

---

## 1. Resumen Ejecutivo

El Día 6 cierra el flujo principal de la Fase 1: **sacar el `final.mp4` del sandbox privado de la app y ponerlo en manos del usuario**. Tras completar stitching (Día 4-5), el video reside en `vrm_data/projects/{id}/final.mp4` — un directorio inaccesible fuera de la app. Este paso construye el puente hacia el ecosistema del dispositivo: guardar en la galería nativa (Fotos / Google Photos) y abrir el share sheet para distribución.

El punto de partida es `RecordingEndPage`, que ya tiene un botón "Export Video" con `onPressed: () {}` (vacío). No hay `ExportService`, no hay `photo_manager`, no hay `share_plus` declarados en `pubspec.yaml`. Los permisos de galería no están configurados en Android ni iOS.

**Alcance estricto del MVP:** Dos acciones secuenciales — (1) guardar en galería, (2) abrir share sheet — disparadas desde un solo botón, con feedback visual claro y manejo de errores accionable.

---

## 2. Diseño Funcional Consolidado

### 2.1 Happy Path (paso a paso)

1. **Precondición:** `StitchProgressPage` completa el stitching → navega a `RecordingEndPage` pasando `finalVideoPath` como argumento (ya implementado en `stitch_progress_page.dart` línea ~52: `Navigator.pushReplacementNamed('/recording-end', arguments: {'finalVideoPath': finalVideoPath})`).
2. **Visualización:** `RecordingEndPage` muestra preview del video con el botón "Export Video" en la barra inferior (ya existe en la UI, línea ~394).
3. **Trigger:** Usuario pulsa "Export Video".
4. **Permiso:** El sistema verifica permisos de galería. Si no están concedidos, los solicita. Si son denegados permanentemente, muestra diálogo con botón "Ir a Configuración".
5. **Guardado en galería:** `ExportService.saveToGallery()` copia `final.mp4` al álbum de fotos nativo. El botón muestra `CircularProgressIndicator` durante la operación.
6. **Confirmación visual:** `SnackBar` de éxito: *"Video guardado en tu galería"*.
7. **Share Sheet:** Inmediatamente después, `ExportService.shareVideo()` abre el share sheet nativo con el archivo adjunto.
8. **Estado final:** El botón cambia a un ícono de check y se deshabilita para evitar doble exportación. El video permanece en galería independientemente de lo que el usuario haga en el share sheet.

### 2.2 Edge Cases (MVP)

| Caso | Comportamiento Esperado |
|------|------------------------|
| `finalVideoPath` es `null` | Botón deshabilitado, texto: "Sin video disponible". |
| El archivo no existe en disco (`!File(path).existsSync()`) | Botón deshabilitado. SnackBar rojo: *"El archivo de video no fue encontrado. Vuelve a procesar."* |
| Permiso de galería denegado (primera vez) | El SO muestra el diálogo estándar. Si el usuario rechaza → diálogo in-app con "Ir a Configuración". |
| Permiso denegado permanentemente | Diálogo in-app con botón "Ir a Configuración" (reutiliza patrón existente en `PermissionService.handleDenied()`). El guardado se omite pero el **share sheet SÍ se abre** (compartir no requiere permisos de galería). |
| Guardado falla (espacio insuficiente u otro error) | SnackBar de error. El share sheet se abre igualmente — el video sigue disponible en el sandbox para compartir directamente. |
| Usuario cancela el share sheet | Sin acción requerida. Permanece en `RecordingEndPage`. El video ya fue guardado en galería si el paso anterior fue exitoso. |
| Usuario navega fuera de la página durante exportación | Verificación `if (mounted)` antes de cualquier `setState`. No crashes. |

### 2.3 Manejo de Errores — Feedback al Usuario

| Escenario | Componente | Mensaje / Acción |
|---|---|---|
| Permiso denegado | `AlertDialog` (modal) | *"Se necesita acceso a la galería para guardar el video."* — Botones: "Ahora no" / "Ir a Configuración" |
| Error al guardar | `SnackBar` (rojo) | *"Error al guardar el video. Intenta de nuevo."* — El botón se re-habilita para reintentar |
| Archivo inexistente | `SnackBar` (rojo) | *"El archivo de video no fue encontrado. Vuelve a procesar."* |
| Share sheet cancelado | Ninguno (comportamiento esperado) | El video ya está en galería |

---

## 3. Diseño Técnico Definitivo

### 3.1 Evaluación Comparativa de los Análisis

| Aspecto | agt | cla | kl | oc | qwen | **Decisión Final** |
|---|---|---|---|---|---|---|
| Librería galería | `gal` | `photo_manager` | `photo_manager` | `photo_manager` | `photo_manager` | **`photo_manager`** — ya prevista en `mvp-Definition.md`, más control sobre permisos `addOnly` |
| Librería share | `share_plus` | `share_plus` | `share_plus` | `share_plus` | `share_plus` | **`share_plus`** — consenso total |
| Servicio | `ExportService` | `ExportService` | `ExportService` | `ExportService` + `ShareService` | `ExportService` | **`ExportService` único** — separar en dos servicios es overkill para MVP |
| Permisos | `permission_handler` + `gal` | `photo_manager` nativo | `photo_manager` | `PermissionService` existente | `permission_handler` | **`permission_handler`** (ya instalado) + `photo_manager` para verificación granular |
| Modelo extendido | Sin cambios | Sin cambios | `SessionData` + campos | `ExportRecord` en session_data | `SessionData` + `exportedAt` + `galleryAssetId` | **Sin cambios a SessionData** — no aporta valor al MVP, el usuario puede exportar múltiples veces |
| UI | `RecordingEndPage` | `RecordingEndPage` | `RecordingEndPage` | `StitchProgressPage` | `RecordingEndPage` | **`RecordingEndPage`** — es donde ya existe el botón. `StitchProgressPage` navega allí automáticamente |
| Share desde documents directo | — | Copia a temp | Directo | Directo | Directo | **Copia a temp** — Android `FileProvider` de `share_plus` solo tiene acceso a `cache_dir` por defecto. Compartir desde `documents/` lanza `FileProviderPathNotHandledException` |

### 3.2 Arquitectura de Componentes

#### NUEVO: `ExportService` — `lib/core/services/export_service.dart`

Servicio singleton, stateless. Encapsula toda la lógica de exportación.

**Métodos:**

```
saveToGallery(String filePath) → Future<ExportResult>
shareVideo(String filePath, {String? subject}) → Future<void>
```

**`ExportResult`** (Dart record):
```
({bool success, String? assetId, String? error})
```

**Responsabilidades internas de `saveToGallery`:**
1. Verificar existencia del archivo: `File(filePath).existsSync()`.
2. Verificar permisos vía `permission_handler`: `Permission.photos.status`.
3. Si no concedido → `Permission.photos.request()`.
4. Si `permanentlyDenied` → retorna `ExportResult(success: false, error: 'permanently_denied')`.
5. Llamar `PhotoManager.editor.saveVideo(File(filePath))`.
6. Retornar `ExportResult` con `assetId` del resultado.

**Responsabilidades internas de `shareVideo`:**
1. Copiar `File(filePath)` a `getTemporaryDirectory()/vrm_final.mp4`.
2. Llamar `Share.shareXFiles([XFile(cachePath)])`.
3. Limpiar archivo temporal tras el share (en `finally` block).

> **Justificación de la copia temporal:** En Android, `share_plus` usa un `FileProvider` que por defecto solo expone `cache_dir` y `external_cache_dir`. Intentar compartir desde `getApplicationDocumentsDirectory()` lanza excepción. La copia al directorio temporal es el patrón documentado y funciona en ambas plataformas.

#### MODIFICADO: `RecordingEndPage` — `lib/features/recording/recording_end_page.dart`

Cambios localizados y mínimos:

1. Agregar estados: `bool _isExporting = false`, `bool _exportDone = false`.
2. Conectar `_buildBottomAction()` → método `_exportVideo()`.
3. `_exportVideo()`:
   - `setState(() => _isExporting = true)`
   - Llamar `ExportService.saveToGallery(widget.finalVideoPath!)`
   - Si éxito → `SnackBar` confirmación → `ExportService.shareVideo(...)`
   - Si error de permiso permanente → mostrar diálogo → si guarda falla, abrir share de todos modos
   - `setState(() => _isExporting = false; _exportDone = true)`
   - Verificar `if (mounted)` antes de cada `setState`.
4. El botón muestra `CircularProgressIndicator` mientras `_isExporting`.
5. El botón muestra ícono check y deshabilitado cuando `_exportDone`.
6. El botón está deshabilitado si `widget.finalVideoPath == null`.

#### NO se modifican:
- `RecordingManager` — la exportación es post-pipeline.
- `FFmpegStitcherService` — ya genera `final.mp4` correctamente.
- `SessionData` — no se requiere persistir estado de exportación en MVP.
- `PermissionService` — se usa `permission_handler` directamente en `ExportService` para permisos de fotos (no es responsabilidad de `PermissionService` que está enfocado en cámara/micrófono).
- `StitchProgressPage` — ya navega correctamente a `RecordingEndPage`.

### 3.3 Configuración de Plataforma

#### Android — `android/app/src/main/AndroidManifest.xml`

Agregar dentro de `<manifest>` (antes de `<application>`):

```xml
<!-- Para Android 13+ (API 33+): acceso a video -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<!-- Para Android 9 y anterior (API < 29): escritura externa -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

> `photo_manager` 3.x gestiona internamente los permisos correctos por API level. Estas declaraciones son necesarias para que el SO las presente al usuario. Se añade también el `<intent>` para `Intent.ACTION_SEND` en el bloque `<queries>` para que `share_plus` pueda resolver actividades de sharing:

```xml
<intent>
    <action android:name="android.intent.action.SEND" />
    <data android:mimeType="video/*" />
</intent>
```

#### iOS — `ios/Runner/Info.plist`

Ya existe `NSPhotoLibraryUsageDescription` (línea actual del archivo). Se necesita agregar:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>VRM necesita acceso a tu galería para guardar el video final de tu proyecto.</string>
```

> `NSPhotoLibraryUsageDescription` ya existe con: *"Esta aplicación necesita acceso a la biblioteca de fotos para guardar y seleccionar videos."* — Es suficiente. `NSPhotoLibraryAddUsageDescription` es requerida adicionalmente en iOS 11+ para el modo "add-only" (escritura sin lectura completa).

### 3.4 Flujo de Datos

```
RecordingEndPage (widget.finalVideoPath)
    │
    └── _exportVideo()
            │
            ├── [guard] finalVideoPath == null || !File.existsSync()
            │       → SnackBar error, return
            │
            ├── ExportService.saveToGallery(finalVideoPath)
            │       ├── Permission.photos.status
            │       │       → permanentlyDenied → showDialog → ExportResult(error: 'permanently_denied')
            │       │       → not granted → Permission.photos.request()
            │       ├── PhotoManager.editor.saveVideo(File(finalVideoPath))
            │       └── ExportResult({success, assetId, error})
            │
            ├── [si éxito o perm denial] ExportService.shareVideo(finalVideoPath)
            │       ├── File(finalVideoPath).copy(tempDir/vrm_final.mp4)
            │       ├── Share.shareXFiles([XFile(cachePath)])
            │       └── File(cachePath).delete()   // cleanup en finally
            │
            └── setState(() => _isExporting = false; _exportDone = true)
                └── SnackBar confirmación
```

### 3.5 Dependencias Nuevas (`pubspec.yaml`)

```yaml
  # Exportación (Día 6)
  photo_manager: ^3.5.0       # Guardado en galería nativa
  share_plus: ^10.1.0         # Share sheet nativo
```

> Se usan versiones recientes para garantizar compatibilidad con SDK 3.10.7 del proyecto. Ejecutar `flutter pub get` tras agregar.

---

## 4. Decisiones Tecnológicas

| # | Decisión | Justificación | Alternativa Descartada |
|---|---------|--------------|----------------------|
| D1 | `photo_manager` para guardado en galería | Ya prevista en `mvp-Definition.md`, soporte robusto iOS+Android, API `addOnly` menos invasiva | `gal` — más simple pero menos control sobre permisos granulares y manejo de errores |
| D2 | `share_plus` para share sheet | Estándar Flutter, abstrae `UIActivityViewController` (iOS) e `Intent.ACTION_SEND` (Android) | Platform channels directos — innecesario para MVP |
| D3 | Secuencia save → share (no paralelo) | Garantiza persistencia local incluso si el usuario cancela el share | Share primero — si falla, el usuario pierde la acción sin video en galería |
| D4 | Copia a `getTemporaryDirectory()` antes de compartir | Android `FileProvider` de `share_plus` solo expone `cache_dir`. Sin esto, crash en Android | Compartir directo desde `documents/` — funciona en iOS pero crash en Android |
| D5 | `ExportService` como único servicio (no separar en `ShareService`) | Para MVP, un solo servicio con 2 métodos es suficiente y más mantenible | Separar en dos servicios — over-engineering para 2 métodos |
| D6 | **No** extender `SessionData` con estado de exportación | El usuario puede exportar múltiples veces sin consecuencia. No aporta valor al MVP | Agregar `exportedAt`, `galleryAssetId` — complejidad sin retorno en MVP |
| D7 | `permission_handler` directo en `ExportService` (no extender `PermissionService`) | `PermissionService` existente está enfocado en cámara/micrófono. Los permisos de fotos son específicos de exportación y no se reusan en otro lugar | Extender `PermissionService` — acopla lógica no relacionada |

**No hay decisiones tecnológicas nuevas respecto a `estado-fase.md`** que contradigan lo vigente. Las dependencias `photo_manager` y `share_plus` ya están listadas como prioritarias en `mvp-Definition.md` Sección 3.

---

## 5. Criterios de Aceptación MVP ✅

### Funcionales
- [ ] Al pulsar "Export Video" con un `finalVideoPath` válido y archivo existente, el video aparece en la galería nativa del dispositivo (app Fotos en iOS, Google Photos en Android).
- [ ] Tras el guardado exitoso en galería, se abre automáticamente el share sheet nativo con el video como archivo adjunto.
- [ ] Si el permiso de galería es denegado permanentemente, se muestra un diálogo con mensaje explicativo y botón "Ir a Configuración" que abre `openAppSettings()`.
- [ ] Si el guardado en galería falla por cualquier motivo, el share sheet se abre de todos modos (degradación elegante — el video se puede compartir aunque no se guarde en galería).
- [ ] Si el usuario cancela el share sheet, no hay crash ni mensaje de error. El video permanece en galería si el guardado fue exitoso.

### Técnicos
- [ ] `photo_manager` y `share_plus` están declarados en `pubspec.yaml` y `flutter pub get` ejecuta sin errores.
- [ ] `NSPhotoLibraryAddUsageDescription` está presente en `ios/Runner/Info.plist` con un string descriptivo.
- [ ] `READ_MEDIA_VIDEO` y `WRITE_EXTERNAL_STORAGE` (maxSdk 28) están declarados en `android/app/src/main/AndroidManifest.xml`.
- [ ] El bloque `<queries>` de Android incluye `<intent>` para `ACTION_SEND` con mimeType `video/*`.
- [ ] La lógica de exportación está encapsulada en `ExportService` (`lib/core/services/export_service.dart`). `RecordingEndPage` no llama directamente a `photo_manager` ni `share_plus`.
- [ ] El archivo temporal creado en `getTemporaryDirectory()` se elimina tras el share (éxito o cancelación), verificado con `finally` block.

### Robustez
- [ ] El botón "Export Video" muestra un indicador de carga (`CircularProgressIndicator` o equivalente) durante la exportación, evitando doble pulsación.
- [ ] Si `finalVideoPath` es `null` o el archivo no existe, el botón está deshabilitado y el usuario ve un mensaje de error accionable.
- [ ] La app no crashea si el usuario navega fuera de `RecordingEndPage` durante la exportación (verificación `mounted` antes de cada `setState`).

---

## 6. Plan de Implementación

| # | Tarea | Complejidad | Dependencia | Archivos |
|---|-------|-------------|-------------|----------|
| 1 | Agregar `photo_manager` y `share_plus` a `pubspec.yaml`; ejecutar `flutter pub get` | Baja | Ninguna | `pubspec.yaml` |
| 2 | Agregar permisos Android: `READ_MEDIA_VIDEO`, `WRITE_EXTERNAL_STORAGE` (maxSdk 28), intent `SEND` en `<queries>` | Baja | Tarea 1 | `android/app/src/main/AndroidManifest.xml` |
| 3 | Agregar `NSPhotoLibraryAddUsageDescription` en iOS Info.plist | Baja | Tarea 1 | `ios/Runner/Info.plist` |
| 4 | Implementar `ExportService` con `saveToGallery()` y `shareVideo()` | Media | Tareas 1-3 | `lib/core/services/export_service.dart` |
| 5 | Modificar `RecordingEndPage`: estados `_isExporting`/`_exportDone`, método `_exportVideo()`, conectar botón, spinner, diálogo permisos denegados, SnackBar feedback | Media | Tarea 4 | `lib/features/recording/recording_end_page.dart` |
| 6 | Testing en dispositivo físico Android: permisos, guardado galería, share a WhatsApp | Alta | Tarea 5 | — |
| 7 | Testing en dispositivo físico iOS: permisos Photos, guardado en Fotos, share a iMessage/Files | Alta | Tarea 5 | — |

**Orden de ejecución recomendado:** 1 → 2 → 3 → 4 → 5 → 6+7 en paralelo.

---

## 7. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| `share_plus` falla en Android por `FileProvider` al compartir desde `documents/` | **Alta** | 🔴 Bloqueante | Copiar a `getTemporaryDirectory()` antes de compartir. Patrón documentado por `share_plus`. |
| iOS App Review rechaza por `NSPhotoLibraryAddUsageDescription` ausente | Media | 🔴 Bloqueante en producción | Agregar el key con string explícito mencionando "guardar el video final". |
| `photo_manager` 3.x cambia API de `saveVideo` respecto a versiones anteriores | Media | 🟡 Medio | Consultar CHANGELOG al instalar. La API actual es `PhotoManager.editor.saveVideo(File, title: ...)`. |
| iOS "Limited Photos Access" (iOS 14+) obliga a pedir acceso completo | Media | 🟡 Medio | Usar `IosAccessLevel.addOnly` en `requestPermissionExtend()` — el usuario solo concede escritura, no lectura de fotos existentes. |
| `photo_manager` no solicita permisos correctamente en Android 13+ (Scoped Storage) | Baja | 🟡 Medio | `permission_handler` verifica el estado antes de llamar a `photo_manager`. Si denegado, guiar a settings del SO. |
| Video muy grande (>500MB) causa lentitud en copia temporal | Baja | 🟡 Medio | Los clips típicos de VRM son cortos (~10s × ~10 chunks). Para MVP: si el archivo existe y el stitching completó, el tamaño es manejable. |
| Usuario cierra app durante `saveToGallery` | Baja | 🟢 Bajo | `PhotoManager.editor.saveVideo()` es atómico — o completa o falla limpiamente. El archivo original en `vrm_data/` permanece intacto. |

---

## 8. Testing Mínimo Viable

Los siguientes casos **DEBEN** probarse antes de considerar el paso completo:

| # | Test | Criterio de Aceptación Asociado | Resultado Esperado |
|---|------|-------------------------------|-------------------|
| T1 | **Guardado Android:** Video de 3 clips (~30s) → Export → Verificar en Google Photos | Funcional #1 | Video aparece en Google Photos, reproducible |
| T2 | **Guardado iOS:** Mismo flujo → Verificar en app Fotos | Funcional #1 | Video aparece en Fotos, reproducible |
| T3 | **Share Android:** Tras guardar, share sheet se abre → compartir a WhatsApp | Funcional #2 | WhatsApp recibe video, reproducible |
| T4 | **Share iOS:** Tras guardar, share sheet se abre → compartir a Archivos/iMessage | Funcional #2 | Archivo recibido correctamente |
| T5 | **Permiso denegado:** Negar acceso a galería en Settings → Pulsar Export | Funcional #3, Robustez #3 | Diálogo con "Ir a Configuración", sin crash |
| T6 | **Archivo faltante:** Eliminar `final.mp4` manualmente → Navegar a RecordingEndPage | Robustez #4 | Botón deshabilitado, mensaje de error |
| T7 | **Navegación durante export:** Pulsar Export → inmediatamente navegar back | Robustez #5 | Sin crash, sin leak de memoria |
| T8 | **Share cancelado:** Abrir share sheet → cancelar sin compartir | Funcional #5 | Sin error, video permanece en galería |

---

## 9. 🔮 Roadmap (Post-MVP)

| Feature | Descripción | Por qué no en MVP |
|---------|------------|------------------|
| Álbum personalizado "VRM" | Crear álbum dedicado en iOS/Android para organizar todos los videos exportados | Requiere lógica extra de gestión de álbumes, no esencial para el flujo principal |
| Compresión pre-exportación | Ofrecer opción de comprimir video antes de guardar/compartir | Agrega dependencia/FFmpeg extra; los clips MVP son cortos |
| Selección de calidad | Elegir resolución/bitrate del video exportado (720p, 1080p, original) | Complejidad de UI + re-encoding, fuera del scope del Día 6 |
| Export a cloud | Google Drive, iCloud Drive, Dropbox | Requiere OAuth, flujos de autenticación — explícitamente fuera del MVP |
| Watermark/Branding | Agregar "Hecho con LUMIS" al video exportado | Decision de producto, no técnica — post-MVP |
| Historial de exportaciones | Trackear qué proyectos se exportaron y cuándo | `SessionData` no se extiende en MVP; el usuario puede re-exportar sin límite |
| Share directo a redes (OAuth) | TikTok, Instagram, YouTube | **Explícitamente excluido** en `mvp-Definition.md` |

### Decisiones de Diseño que Facilitan el Roadmap
- `ExportService` es una clase separada y stateless: se pueden agregar métodos (`compressVideo()`, `exportToCloud()`, `saveToAlbum()`) sin tocar la UI ni otros servicios.
- El flujo save → share es secuencial pero cada paso retorna resultado independiente: en el futuro se puede hacer solo save, solo share, o ambos, según preferencia del usuario.
- La copia a directorio temporal se encapsula dentro de `shareVideo()`: si en el futuro se necesita compartir desde otra ubicación, el método se adapta sin afectar `saveToGallery()`.
- No se extiende `SessionData` con estado de exportación: esto evita tener que migrar datos de sesiones previas y mantiene el modelo limpio para cuando se implemente un historial de exportaciones con su propia estructura.
