# 🏛️ BLUEPRINT MAESTRO: Exportación (Día 6)
**Estado:** DEFINITIVO / PARA IMPLEMENTACIÓN
**Versión:** 1.0 (Consonancia con `estado-fase.md`)

## 1. Resumen Ejecutivo
El Día 6 cierra el flujo principal de la Fase 1. Dado que el `final.mp4` ya existe en el sandbox privado de la app (`vrm_data/projects/{id}/final.mp4`), el objetivo es **sacarlo** del sandbox y ponerlo en manos del usuario: primero persistiéndolo en la galería del dispositivo (donde sobrevive aunque se desinstale la app), y luego abriendo el share sheet nativo para que el usuario lo distribuya a donde quiera. Ambas acciones se disparan desde el botón "Export Video" que ya existe en `RecordingEndPage` pero está desconectado.

---

## 2. Diseño Funcional

### 2.1 Happy Path Detallado
1. **Precondición:** `RecordingEndPage` recibe `finalVideoPath` no nulo (flujo estándar desde `StitchProgressPage`).
2. **Trigger:** El usuario pulsa "Export Video".
3. **Permiso:** El sistema solicita permiso de escritura a la galería vía `photo_manager`. Si ya está concedido, se omite el diálogo del SO.
4. **Guardado en Galería:** `ExportService.saveToGallery()` copia `final.mp4` al álbum de fotos nativo. El usuario ve un `LinearProgressIndicator` en el botón durante la operación (~1-3s para un video típico).
5. **Confirmación:** Al completar el guardado, se muestra un `SnackBar` de éxito: _"Video guardado en tu galería"_.
6. **Share Sheet:** Inmediatamente después, `ExportService.shareVideo()` abre el share sheet nativo con el archivo. El usuario puede compartir a cualquier app instalada o descartar.
7. **Estado Final:** `RecordingEndPage` queda en estado "exportado" — el botón cambia a ícono de check y se deshabilita para evitar doble exportación.

### 2.2 Edge Cases (MVP)

| Caso | Comportamiento Esperado |
|------|------------------------|
| `finalVideoPath` es `null` | Botón deshabilitado con texto "Sin video disponible". No puede suceder en el flujo normal, pero protege accesos directos a la ruta. |
| El archivo no existe en disco | Antes de cualquier operación, se verifica `File(path).existsSync()`. Si falla, SnackBar de error: _"El archivo de video no fue encontrado. Vuelve a procesar."_ |
| Permiso de galería denegado (primera vez) | El SO muestra el diálogo estándar de permiso. Si el usuario rechaza, se muestra un diálogo in-app con botón "Ir a Configuración" que abre `AppSettings.openAppSettings()`. |
| Permiso denegado permanentemente | Mismo diálogo de "Ir a Configuración". El guardado en galería se omite pero el share sheet SÍ se abre (compartir no requiere permisos de galería). |
| Guardado en galería falla (espacio insuficiente u otro error de `photo_manager`) | SnackBar de error con el mensaje del SO. El share sheet se abre igualmente — el video sigue disponible para compartir aunque no se haya guardado. |
| Usuario cancela el share sheet | No hay acción requerida. La app permanece en `RecordingEndPage`. El video ya fue guardado en galería si el paso anterior fue exitoso. |

### 2.3 Manejo de Errores (UX)
- **Permiso denegado:** Diálogo modal con título _"Acceso a Galería Requerido"_, mensaje explicativo y dos botones: "Ahora no" (cierra el diálogo) y "Abrir Configuración".
- **Archivo faltante / error crítico:** `SnackBar` rojo con mensaje descriptivo. El botón vuelve a habilitarse para reintentar.
- **Error de `photo_manager` no fatal:** `SnackBar` naranja + el share sheet se abre de todos modos con el archivo de caché temporal.

---

## 3. Diseño Técnico

### 3.1 Componentes

#### NUEVO: `ExportService` — `lib/core/services/export_service.dart`
Servicio singleton que encapsula toda la lógica de exportación. No tiene estado propio.

**Interfaz:**
```
saveToGallery(String filePath) → Future<ExportResult>
shareVideo(String filePath, {String? subject}) → Future<void>
```

Donde `ExportResult` es un record:
```
({bool success, String? assetId, String? error})
```

**Responsabilidades internas:**
1. `saveToGallery`: Verifica existencia de archivo → solicita permiso → llama `PhotoManager.editor.saveVideo()` → devuelve `ExportResult`.
2. `shareVideo`: Copia `final.mp4` al directorio de caché (`getTemporaryDirectory()`) → llama `Share.shareXFiles([XFile(cachePath)])` → limpia el archivo de caché tras compartir.

> **Por qué copiar a caché antes de compartir:** En Android, `getApplicationDocumentsDirectory()` es un directorio privado del sandbox. El `FileProvider` de `share_plus` solo tiene acceso declarado a `cache_dir` y `external_cache_dir` por defecto. Intentar compartir directamente desde `documents/` lanzaría un `FileProviderPathNotHandledException` en Android. La copia al directorio temporal (`getTemporaryDirectory()`) es el patrón establecido.

#### MODIFICADO: `RecordingEndPage` — `lib/features/recording/recording_end_page.dart`
- El widget se convierte en `StatefulWidget` (ya lo es).
- Se añade estado: `_isExporting = false`, `_exportDone = false`.
- `_buildBottomAction()` se conecta a un nuevo método `_exportVideo()`.
- El botón muestra `CircularProgressIndicator` cuando `_isExporting == true`.
- El botón muestra ícono de check y está deshabilitado cuando `_exportDone == true`.

### 3.2 Configuración de Plataforma

#### Android — `android/app/src/main/AndroidManifest.xml`
Añadir dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```
> `photo_manager` 3.x gestiona los permisos internamente usando `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` en API 33+ y `READ_EXTERNAL_STORAGE` en API < 33. `WRITE_EXTERNAL_STORAGE` solo es necesario hasta API 28 (Android 9). El `minSdk = 24` ya está configurado en `build.gradle.kts`.

#### iOS — `ios/Runner/Info.plist`
Añadir las dos claves requeridas por Apple para acceso a galería:
```
NSPhotoLibraryAddUsageDescription → "VRM necesita acceso a tu galería para guardar el video final."
NSPhotoLibraryUsageDescription → "VRM necesita acceso a tu galería para guardar el video final."
```
> `NSPhotoLibraryAddUsageDescription` es suficiente para escritura (iOS 11+). `NSPhotoLibraryUsageDescription` es requerida por `photo_manager` para acceso de lectura opcional. Sin ambas, la app crashea en iOS al solicitar el permiso.

### 3.3 Modelo de Datos
No se extiende `SessionData`. El `finalVideoPath` ya está en `SessionData.finalVideoPath` (implementado en Día 4-5). No se requiere persistir el estado de exportación en el MVP — si el usuario cierra y vuelve, puede exportar de nuevo.

### 3.4 Flujo de Datos
```
RecordingEndPage (finalVideoPath)
    └── _exportVideo()
            ├── ExportService.saveToGallery(finalVideoPath)
            │       ├── File.existsSync() → guard
            │       ├── PhotoManager.requestPermissionExtend()
            │       └── PhotoManager.editor.saveVideo(File(finalVideoPath))
            │               → ExportResult({success, assetId, error})
            │
            └── ExportService.shareVideo(finalVideoPath)
                    ├── File(finalVideoPath).copy(temporaryDir/vrm_final.mp4)
                    ├── Share.shareXFiles([XFile(cachePath)], subject: ...)
                    └── File(cachePath).delete()  // cleanup post-share
```

---

## 4. Decisiones Tecnológicas

**1. Guardar en galería ANTES de abrir share sheet (no en paralelo):**
Garantiza que el video quede persistido localmente incluso si el usuario cancela el share. El share sheet es una operación no bloqueante desde la perspectiva del usuario.

**2. `photo_manager` en modo `addOnly` (no `readWrite`):**
Solo necesitamos escribir el video. Solicitar acceso completo de lectura es innecesario, más invasivo para el usuario y puede ser rechazado más frecuentemente. `PhotoManager.requestPermissionExtend(requestOption: PermissionRequestOption(iosAccessLevel: IosAccessLevel.addOnly))`.

**3. Copia a directorio temporal antes de compartir:**
Necesario en Android por restricciones de `FileProvider` de `share_plus`. En iOS no es estrictamente necesario, pero se aplica la misma lógica para consistencia entre plataformas y para evitar que `share_plus` intente acceder a un path dentro del sandbox de documents que en algunos contextos iOS también puede ser problemático.

**4. `share_plus` como única dependencia de sharing (no usar `platform_channel` directo):**
`share_plus` abstrae la diferencia entre `UIActivityViewController` (iOS) y `Intent.ACTION_SEND` (Android). La alternativa nativa requeriría platform channels propios, innecesario para MVP.

**5. No persistir estado "exportado" en `SessionData`:**
El Día 7-8 ya implementó la persistencia de sesión. Guardar el flag "ya exportado" en JSON crea complejidad sin valor real para el MVP — el usuario puede exportar múltiples veces sin consecuencias.

---

## 5. Criterios de Aceptación MVP ✅

### Funcionales:
- [ ] Al pulsar "Export Video" con `finalVideoPath` válido, el video aparece en la galería nativa del dispositivo (Fotos / Google Photos).
- [ ] El share sheet nativo se abre automáticamente después del guardado en galería.
- [ ] Si el permiso de galería es denegado, se muestra un diálogo con opción de ir a Configuración del sistema.
- [ ] Si `finalVideoPath` es `null` o el archivo no existe, el botón está deshabilitado o muestra un error antes de intentar cualquier operación.

### Técnicos:
- [ ] `photo_manager` y `share_plus` están declarados en `pubspec.yaml`.
- [ ] `NSPhotoLibraryAddUsageDescription` y `NSPhotoLibraryUsageDescription` están en `ios/Runner/Info.plist`.
- [ ] Los permisos de Android (`READ_MEDIA_VIDEO`, `WRITE_EXTERNAL_STORAGE` maxSdk 28) están declarados en `AndroidManifest.xml`.
- [ ] La lógica de exportación está encapsulada en `ExportService` — `RecordingEndPage` no llama directamente a `photo_manager` ni `share_plus`.
- [ ] El archivo temporal en `getTemporaryDirectory()` se elimina tras el share (éxito o cancelación).

### Robustez:
- [ ] El botón muestra un estado de carga (`CircularProgressIndicator`) durante la exportación, evitando doble pulsación.
- [ ] Si el guardado en galería falla, el share sheet se abre igualmente (degradación elegante).
- [ ] La app no crashea si el usuario navega fuera de `RecordingEndPage` durante la exportación (verificación `mounted` antes de `setState`).

---

## 6. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| `share_plus` falla en Android por `FileProvider` al usar path de documents | Alta | 🔴 Bloqueante | Copiar a `getTemporaryDirectory()` antes de compartir. Es el patrón documentado por `share_plus`. |
| iOS rechaza la app en review por `NSPhotoLibraryUsageDescription` ausente o vaga | Media | 🔴 Bloqueante en producción | Redactar el string de uso de forma explícita: mencionar "guardar el video final del proyecto". |
| `photo_manager` v3.x rompe la API respecto a v2.x (cambio en `saveVideo`) | Media | 🟡 Medio | Revisar el CHANGELOG de `photo_manager` al momento de instalar. La API actual es `PhotoManager.editor.saveVideo(File(...), title: ...)`. |
| iOS "Limited Photos Access" (acceso parcial, iOS 14+) | Media | 🟡 Medio | Usar `IosAccessLevel.addOnly` evita este problema — el usuario no necesita conceder acceso a fotos existentes, solo a guardar nuevas. |
| Video muy grande (>500MB) causa timeout en share sheet o UI freeze | Baja | 🟡 Medio | La copia al directorio temporal es rápida (mismo filesystem). El share sheet en iOS/Android gestiona files grandes sin bloquear el hilo principal. |

---

## 7. Plan de Implementación

| # | Tarea | Complejidad | Dependencia |
|---|-------|-------------|-------------|
| 1 | Agregar `photo_manager: ^3.3.0` y `share_plus: ^10.3.4` a `pubspec.yaml`; ejecutar `flutter pub get` | Baja | Ninguna |
| 2 | Añadir permisos en `android/app/src/main/AndroidManifest.xml` | Baja | Tarea 1 |
| 3 | Añadir `NSPhotoLibraryAddUsageDescription` y `NSPhotoLibraryUsageDescription` en `ios/Runner/Info.plist` | Baja | Tarea 1 |
| 4 | Implementar `ExportService` en `lib/core/services/export_service.dart` con `saveToGallery()` y `shareVideo()` | Media | Tareas 1-3 |
| 5 | Modificar `RecordingEndPage`: añadir `_isExporting`, `_exportDone`, método `_exportVideo()`, estado de loading en botón, diálogo de permiso denegado | Media | Tarea 4 |
| 6 | Prueba en dispositivo físico Android (guardado en galería + share a WhatsApp) | Alta | Tarea 5 |
| 7 | Prueba en dispositivo físico iOS (guardado en Fotos + share a Files/iMessage) | Alta | Tarea 5 |

---

## 8. Testing Mínimo Viable
1. **Test funcional Android:** Video de 3 clips (~30s) → Export → Verificar en "Google Photos" que aparece → Share a WhatsApp → Verificar que se puede reproducir.
2. **Test funcional iOS:** Mismo video → Export → Verificar en "Fotos" → Share a Archivos.
3. **Test de permiso denegado:** Denegar acceso a galería en Configuración del SO → Pulsar Export → Verificar diálogo + link a Configuración.
4. **Test de archivo faltante:** Eliminar manualmente el `final.mp4` del filesystem → Navegar a RecordingEndPage con path inválido → Verificar error amigable.

---

## 9. 🔮 Roadmap (Post-MVP)
- **Guardado con metadatos:** Añadir álbum personalizado "VRM" en iOS/Android para organizar todos los videos exportados.
- **Export Progress con porcentaje:** Para videos largos (>2 min), mostrar progreso real de la copia/guardado.
- **Generación de thumbnail:** Usar FFmpeg para extraer el primer frame de `final.mp4` y mostrarlo en la pantalla de exportación.
- **Export como GIF/MP3:** Opciones alternativas de formato desde el share sheet extendido.
- **Share directo a plataformas (OAuth):** TikTok, Instagram, YouTube — explícitamente excluido del MVP per `mvp-Definition.md`.
