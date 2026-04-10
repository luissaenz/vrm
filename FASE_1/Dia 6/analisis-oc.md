# 📋 ANÁLISIS TÉCNICO - Día 6: Exportación (Galería y Share Sheet)

**Paso:** Día 6 - Exportación (Galería y Share Sheet)  
**Agente:** oc  
**Estado:** PENDIENTE (próximo hito)

---

## 1. Diseño Funcional

### 1.1 Happy Path

1. **El usuario completa el Auto-Stitch** → tiene `final.mp4` generado en `vrm_data/projects/{projectId}/`
2. **El usuario toca botón "Exportar"** en la UI de Stitch Progress o desde Review
3. **El sistema verifica permisos de Photos** (iOS: PHPhotoLibrary, Android: WRITE_EXTERNAL_STORAGE)
   - Si no hay permiso: solicitar permisos nativos → si se deniega, mostrar error accionable
4. **El sistema copy `final.mp4` a galería del dispositivo** mediante `photo_manager`:
   - iOS: Se guarda en Photos library (categoría Video)
   - Android: Se guarda en DCIM/VRM o Movies/
5. **El sistema dispara Share Sheet nativo** con el video ya guardado o con el archivo directo
6. **El usuario ve toast/feedback: "Video guardado en Galería"** + opciones de-compartir activas

### 1.2 Edge Cases para MVP

| Escenario | Comportamiento |
|-----------|----------------|
| **No hay `final.mp4`** (stitch incompleto) | Bloquear exportación, mostrar mensaje "Debes completar la unión primero" |
| **Permiso de galería denegado** | Mostrar diálogo con botón "Abrir Settings" y opción de-share alternativo |
| **Dispositivo sin espacio** | Mostrar error "Espacio insuficiente en dispositivo" |
| **Archivo corrupto o missing** | Reconstruir desde clips aprobados si existen, o mostrar error con opción de-reintentar stitch |
| **Share Sheet cancelado por usuario** | No mostrar error, simplemente cerrar modal |

---

## 2. Diseño Técnico

### 2.1 Componentes Nuevos

#### 2.1.1 ExportService (nuevo)
**Ubicación:** `lib/core/services/export_service.dart`

```dart
class ExportService {
  /// Guarda final.mp4 en galería y opcionalmente abre share sheet
  Future<ExportResult> exportToGallery({
    required String projectId,
    required String finalVideoPath,
    bool openShareSheet = true,
  });
}

class ExportResult {
  final bool success;
  final String? galleryPath; // Path donde se guardó en galería
  final String? errorMessage;
}
```

**Responsabilidades:**
- Verificar permisos de Photos
- Guardar video en galería usando `photo_manager`
- Limpiar archivos temporales si corresponde
- callbacks de progreso

#### 2.1.2 ShareService (nuevo)
**Ubicación:** `lib/core/services/share_service.dart`

```dart
class ShareService {
  /// Comparte archivo de video vía Share Sheet nativo
  Future<void> shareVideo({
    required String videoPath,
    String? text,
  });
}
```

**Responsabilidades:**
- Usar `share_plus` para abrir share sheet del OS
- Soportar texto descriptivo opcional (ej: "Mira mi video VRM")

### 2.2 Extensiones a Componentes Existentes

#### 2.2.1 RecordingManager
- Añadir método `exportFinalVideo()` que orchestina: Stitch → Export → Share
- O integrarlo como acción en `StitchProgressPage`

#### 2.2.2 StitchProgressPage
- Añadir botón "Exportar a Galería" (icono: download_alt)
- Añadir botón "Compartir" (icono: share)
- Estados: idle → exporting → sharing → complete/error

### 2.3 Modelos de Datos

#### 2.3.1 ExportRecord (nuevo en session_data.json)
```json
{
  "exportedAt": "2026-04-09T15:30:00Z",
  "galleryPath": "/Photos/VRM/final_20260409.mp4",
  "appVersion": "1.0.0"
}
```

### 2.4 Integración con Permisos

**PermissionService modificaciones:**
- Añadir `requestPhotosPermission()` usando `photo_manager`:
  - iOS: `PhotoManager.requestExtendAuthApproval()`
  - Android: Verificar `StoragePermission` o permiso de gerente de fotos

### 2.5 APIs/Contratos

| Método | Input | Output |
|--------|-------|--------|
| `ExportService.exportToGallery()` | `projectId`, `finalVideoPath` | `ExportResult` |
| `ShareService.shareVideo()` | `videoPath`, `text?` | `void` (dispara OS share sheet) |
| `PermissionService.requestPhotosPermission()` | - | `bool` (aprobado/denegado) |

---

## 3. Decisiones

### 3.1 Dependencias Seleccionadas

| Librería | Versión | Justificación |
|----------|---------|----------------|
| `photo_manager` | ^3.0.0 | API unificado para iOS/Android, estándar en Flutter |
| `share_plus` | ^7.0.0 | Wrapper multiplataforma del native share sheet |

**Justificación técnica:**
- Ambas son dependencias declaradas en `mvp-Definition.md` y ya previstas en la arquitectura Fase 1.
- `photo_manager` tiene mejor soporte en Android 13+ (Scoped Storage) que alternativas.
- `share_plus` es mantenida por Flutter team (canonical).

### 3.2 Flujo de Permisos

**Decisión:** Verificar permisos ANTES de copiar a galería.

1. Verificar `PermissionService.isPhotosPermissionGranted()`
2. Si no → request → si deniega → mostrar UI de settings
3. Si approve → proceder a copy

**Alternativa considerada:** Copiar primero y catch permission error. Descartado porque genera用户体验 roto (archivo copiado parcialmente o perdido).

### 3.3 Manejo de Errores

- Cualquier error de export → no guardar en `session_data` como "exportado" (para permitir reintento)
- Si el video ya existe en galería (mismo hash) → skip copy, usar existentes

---

## 4. Criterios de Aceptación

| # | Criterio | Verificable vía |
|---|----------|-----------------|
| 1 | El botón "Exportar" visible tras completar stitch | UI test |
| 2 | Si no hay permiso, aparece diálogo nativo de permisos | Manual |
| 3 | Video se guarda en Photos (iOS) o Galería (Android) | Explorador archivos |
| 4 | Share Sheet nativo se abre tras exportar | Manual |
| 5 | Si share cancela, no hay error/crash | Manual |
| 6 | Si storage lleno, muestra error claro | Manual |
| 7 | Spinner muestra durante exportación (>200ms) | UI test |
| 8 | `session_data.json` actualiza tras export exitoso | JSON check |

---

## 5. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|-------|-------------|--------|------------|
| **photo_manager no autoriza en iOS 14+** | Media | Alto | Test temprano en dispositivo, tener fallback de-share directo |
| **Scattered Storage deniega en Android 13+** | Media | Medio | Usar MediaStore API (photo_manager lo abstrae), test en Android 13 physical |
| **Video grande (>1GB) agota memoria** | Baja | Alto | Chunked copy o streaming; para MVP: warn >500MB |
| **Share Sheet no está disponible (app sandbox)** | Baja | Medio | Fallback: Guardar a Downloads, notificar usuario |

---

## 6. Plan de Implementación

### Tarea 1: Añadir dependencias
- [ ] Añadir `photo_manager: ^3.0.0` y `share_plus: ^7.0.0` en `pubspec.yaml`
- [ ] flutter pub get

### Tarea 2: Crear ExportService
- [ ] Crear `lib/core/services/export_service.dart`
- [ ] Implementar `exportToGallery()` con `photo_manager`
- [ ] Implementar `_saveToGallery()` con AssetEntity
- [ ] Testing: unit test con archivo mock

### Tarea 3: Crear ShareService
- [ ] Crear `lib/core/services/share_service.dart`
- [ ] Implementar `shareVideo()` con `share_plus`

### Tarefa 4: Extender PermissionService
- [ ] Añadir `requestPhotosPermission()`
- [ ] Añadir `isPhotosPermissionGranted()`

### Tarea 5: Integrar en UI (StitchProgressPage)
- [ ] Añadir botones "Exportar" y "Compartir"
- [ ] Conectar a ExportService
- [ ] Añadir estados de loading

### Tarea 6: Testing QA
- [ ] Test en iOS físico: permisos, gallery, share
- [ ] Test en Android físico: permisos, gallery, share

**Complejidad relativa:** Media (mayormente integración de libs existentes)

**Dependencias:** 
- Requiere `final.mp4` disponible (Día 4-5 completado)
- Requiere `PermissionService` existente

---

## 🔮 Roadmap (NO implementar ahora)

1. **Export múltiples:** Batch export de todas las tomas a zip
2. **Export a nube personal:** iCloud, Google Drive, Dropbox
3. **Compresión configurable:**Antes de guardar, permitir reducir calidad/size
4. **Auto-export post-stitch:** Opción de auto-exportar al completar stitch
5. **Metadata EXIF:** Inyectar tags (title, description) en el video guardado
6. **Historial de exports:** Ver qué se ha exportado y cuándo

**Decisiones tomadas para no bloquear roadmap:**
- ExportService separado de RecordingManager (facilita extensión)
- ExportResult incluye galleryPath para tracking futuro
- SessionData extensible con campo `exportRecords[]`

---

**Idioma:** Español 🇪🇸  
**Documento generado:** 2026-04-09