# 📅 Día 6 - Exportación: Análisis Técnico Completo

**Agente:** qwen  
**Fecha:** 8 de abril de 2026  
**Documento de Referencia:** `docs/mvp-Definition.md`  
**Estado Actual:** 🔴 20% Implementado (solo existe botón sin funcionalidad)

---

## 1. Comprensión del Paso

### Qué Problema Resuelve
El usuario ha completado el pipeline `Idea → Guion → Grabar Clips → Auto-Stitch` y tiene un archivo `final.mp4` en el sistema de archivos privado de la app. **Sin exportación, el video queda atrapado** dentro de `/vrm_data/projects/{project_id}/final.mp4`, inaccesible para:
- Compartir en redes sociales (TikTok, Instagram, WhatsApp, etc.)
- Ver en la galería del teléfono
- Enviar por mensajería
- Editar en otras aplicaciones

### Inputs que Recibe
1. **`final.mp4`** - Archivo de video stitchado ubicado en `/vrm_data/projects/{project_id}/final.mp4`
2. **Project ID** - Identificador del proyecto activo
3. **Preferencias de usuario** - Configuración de calidad/formato (si aplica)

### Outputs que Debe Generar
1. **Video guardado en galería nativa** (iOS Photos / Android Gallery)
2. **Share Sheet nativo desplegado** con el video como contenido a compartir
3. **Estado de persistencia actualizado** - El proyecto debe marcar como "exportado"
4. **Feedback visual al usuario** - Confirmación de éxito o error detallado

### Rol Dentro del Sistema
Es el **último eslabón del core value proposition** del MVP. Sin exportación, el sistema completo (grabación + stitching) no genera valor utilizable. Es la "puerta de salida" que convierte el trabajo del usuario en un activo real.

---

## 2. Supuestos y Ambigüedades

### ⚠️ CRÍTICO - No Definido

1. **Formato de exportación**
   - ¿Solo `final.mp4` o también permitir exportar clips individuales?
   - ¿Misma calidad que el original o permitir downsampling (720p, 480p)?
   - **Pregunta:** ¿El MVP debe exportar SOLO el video stitchado final o también permitir seleccionar clips individuales?

2. **Duplicación vs. Referencia**
   - `photo_manager` copia el archivo a la galería. ¿Se mantiene el original en `/vrm_data/`?
   - **Pregunta:** ¿Se debe dar opción de borrar el proyecto original tras exportar (liberar espacio)?

3. **Comportamiento Post-Export**
   - ¿El usuario vuelve al dashboard, se queda en una pantalla de confirmación, o va directamente al share sheet?
   - **Pregunta:** ¿Cuál es el flujo UX esperado tras guardar en galería?

4. **Manejo de Errores en Export**
   - ¿Qué pasa si no hay espacio en el dispositivo para la copia?
   - ¿Qué pasa si el usuario deniega permisos de galería?
   - **Pregunta:** ¿Debe existir un reintento automático o solo notificar el error?

5. **Compatibilidad con iOS Photos vs. Android Gallery**
   - `photo_manager` abstrae ambos, pero iOS puede pedir permisos de "Add Only" vs "Full Access".
   - **Pregunta:** ¿Cómo manejar el caso donde iOS solo permite "Add Only" y el usuario luego no puede ver el video en la app Photos?

### Preguntas Críticas Pre-Implementación

- [ ] ¿Se debe exportar automáticamente tras el stitching o solo bajo demanda del usuario (botón en `recording_end_page.dart`)?
- [ ] ¿El share sheet se muestra automáticamente tras guardar, o el usuario debe activarlo manualmente?
- [ ] ¿Se debe registrar en `session_data.json` que el video fue exportado (timestamp, destino)?
- [ ] ¿Qué hacer si el archivo `final.mp4` no existe o está corrupto al momento de exportar?

---

## 3. Diseño Funcional

### Flujo Completo (Pipeline de Exportación)

```
[Usuario presiona "Exportar Video"]
        ↓
[1] VALIDACIÓN INICIAL
   ├─ Verificar que `/vrm_data/projects/{id}/final.mp4` existe
   ├─ Verificar tamaño > 0 bytes
   ├─ Si NO existe → mostrar error: "Video no disponible. Reintenta la grabación."
   └─ Si existe → continuar
        ↓
[2] SOLICITUD DE PERMISOS
   ├─ Verificar permisos de galería (`photo_manager`)
   ├─ Si NO concedido → solicitar permiso nativo
   ├─ Si denegado permanentemente → mostrar dialog:
   │     "VRM necesita acceso a tu galería para guardar el video.
   │      Ve a Configuración > VRM > Fotos y habilita el acceso."
   │     [Cancelar] [Abrir Configuración]
   └─ Si concedido → continuar
        ↓
[3] GUARDADO EN GALERÍA
   ├─ Mostrar overlay: "Guardando video en galería..."
   ├─ Ejecutar `photo_manager.saveFile()` con el `final.mp4`
   ├─ Si éxito → continuar a [4]
   └─ Si falla → mostrar error específico:
        ├─ "Espacio insuficiente" → sugerir liberar espacio
        ├─ "Error de escritura" → sugerir reiniciar app
        └─ "Permiso revocado" → volver a [2]
        ↓
[4] CONFIRMACIÓN DE GUARDADO
   ├─ Mostrar snackbar/toast: "✅ Video guardado en tu galería"
   ├─ Actualizar estado del proyecto en `project_state.json`:
   │     `"exportedAt": "2026-04-08T15:30:00Z"`
   │     `"exportPath": "<gallery_asset_id>"`
   └─ Log interno para debugging
        ↓
[5] OFRECER COMPARTIR (Share Sheet)
   ├─ Mostrar dialog: "¿Quieres compartir tu video?"
   │     [Más tarde] [Compartir ahora]
   ├─ Si "Compartir ahora" → [6]
   └─ Si "Más tarde" → navegar al Dashboard
        ↓
[6] SHARE SHEET NATIVO
   ├─ Ejecutar `share_plus.shareFile()` con `final.mp4`
   ├─ Usuario selecciona app destino (WhatsApp, Instagram, etc.)
   ├─ Si compartió → registrar en log: `"sharedAt": "..."`
   └─ Si canceló → no registrar, volver al Dashboard
        ↓
[7] NAVEGACIÓN FINAL
   └─ Regresar al Dashboard con proyecto actualizado
```

### Casos Normales

| Escenario | Comportamiento Esperado |
|-----------|------------------------|
| Exportación exitosa | Video en galería + share sheet opcional |
| Usuario cancela share sheet | Regresa al dashboard sin registrar "sharedAt" |
| Video ya exportado previamente | Permitir re-exportar sin restricciones |

### Edge Cases

| Escenario | Manejo |
|-----------|--------|
| `final.mp4` no existe | Error claro: "Video no encontrado. Vuelve a grabar." + botón para volver a Dashboard |
| `final.mp4` corrupto (0 bytes) | Error: "Video dañado. Reintenta el proceso de stitching." |
| Espacio insuficiente en galería | Error: "No hay espacio suficiente. Libera ~{tamaño} MB e intenta de nuevo." |
| Permiso de galería denegado | Dialog educativo + botón para abrir configuración del OS |
| App en background durante export | Cancelar operación, guardar estado parcial, notificar al reabrir |
| iOS "Add Only" permission | Informar al usuario que debe cambiar a "Full Access" para ver el video |
| Archivo > 1GB (video muy largo) | Advertencia previa: "El video es grande, la exportación puede tardar ~X seg." |

### Manejo de Errores

```dart
enum ExportError {
  fileNotFound,
  fileCorrupted,
  insufficientStorage,
  permissionDenied,
  permissionPermanentlyDenied,
  writeError,
  unknownError,
}

Map<ExportError, ExportErrorMessage> errorMessages = {
  ExportError.fileNotFound: "No se encontró el video finalizado.",
  ExportError.fileCorrupted: "El video está dañado. Vuelve a grabar los clips.",
  ExportError.insufficientStorage: "Espacio insuficiente en tu dispositivo.",
  ExportError.permissionDenied: "VRM necesita acceso a tu galería.",
  ExportError.permissionPermanentlyDenied: "El permiso fue denegado. Actívalo en Configuración > VRM.",
  ExportError.writeError: "Error al guardar. Reinicia la app e intenta de nuevo.",
  ExportError.unknownError: "Error inesperado. Reintenta o contacta soporte.",
};
```

---

## 4. Diseño Técnico

### Arquitectura Sugerida

```
lib/features/export/
├── services/
│   ├── export_service.dart           # Orquestador principal
│   ├── gallery_export_service.dart   # Integración con photo_manager
│   └── share_service.dart            # Integración con share_plus
├── widgets/
│   ├── export_progress_overlay.dart  # UI de progreso
│   └── export_confirmation_dialog.dart
└── export_controller.dart            # State management (si aplica)
```

### Componentes Involucrados

#### 4.1. `ExportService` (Orquestador)

**Responsabilidad:** Coordinar validación, permisos, guardado en galería y share sheet.

```dart
class ExportService {
  final GalleryExportService _galleryExport;
  final ShareService _share;
  final ProjectRepository _projectRepo;

  ExportService({
    required GalleryExportService galleryExport,
    required ShareService share,
    required ProjectRepository projectRepo,
  });

  /// Flujo completo de exportación
  Future<ExportResult> exportProject(String projectId) async {
    // 1. Validar archivo
    final videoFile = await _validateVideoFile(projectId);
    if (videoFile == null) return ExportResult.error(ExportError.fileNotFound);

    // 2. Verificar permisos
    final hasPermission = await _galleryExport.checkPermission();
    if (!hasPermission) {
      final granted = await _galleryExport.requestPermission();
      if (!granted) return ExportResult.error(ExportError.permissionDenied);
    }

    // 3. Guardar en galería
    final galleryAsset = await _galleryExport.saveToGallery(videoFile);
    if (galleryAsset == null) return ExportResult.error(ExportError.writeError);

    // 4. Actualizar proyecto
    await _projectRepo.markAsExported(projectId, galleryAsset.id);

    return ExportResult.success(galleryAsset);
  }

  /// Compartir video
  Future<void> shareVideo(File videoFile, {String? text}) async {
    await _share.shareFile(videoFile, text: text);
  }
}
```

#### 4.2. `GalleryExportService` (photo_manager)

**Responsabilidad:** Abstraer la escritura en galería nativa.

```dart
class GalleryExportService {
  /// Verificar si tenemos permisos de galería
  Future<bool> checkPermission() async {
    final status = await PhotoManager.requestPermissionExtend();
    return status.isAuth;
  }

  /// Solicitar permiso nativo
  Future<bool> requestPermission() async {
    final status = await PhotoManager.requestPermissionExtend();
    
    if (status.isLimited) {
      // iOS: permisos limitados, puede que no vea el video
      return true; // pero advertir al usuario
    }
    
    if (status.isDenied) {
      // Usuario denegó, ofrecer abrir configuración
      return false;
    }
    
    return status.isAuth;
  }

  /// Guardar archivo en galería
  Future<AssetEntity?> saveToGallery(File videoFile) async {
    final entity = await PhotoManager.editor.saveVideoWithPath(
      videoFile.path,
      title: 'VRM_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    return entity;
  }

  /// Abrir configuración del OS (para permisos denegados)
  Future<void> openSettings() async {
    await openAppSettings(); // de permission_handler
  }
}
```

#### 4.3. `ShareService` (share_plus)

**Responsabilidad:** Desplegar share sheet nativo.

```dart
class ShareService {
  /// Compartir archivo con texto opcional
  Future<void> shareFile(File file, {String? text}) async {
    final xFile = XFile(file.path);
    
    await Share.shareXFiles(
      [xFile],
      text: text ?? '🎬 Creado con VRM - Tu asistente de video personal',
      subject: 'Mi video VRM',
    );
  }
}
```

### APIs / Endpoints Necesarios

**NO se requieren APIs externos.** Todo es local al dispositivo.

### Modelos de Datos (Schemas Sugeridos)

#### Actualización a `project_state.json`

```json
{
  "projectId": "proj_abc123",
  "input": { ... },
  "script": { ... },
  "assets": {
    "videoId": "vid_xyz789",
    "filePath": "/vrm_data/projects/proj_abc123/final.mp4",
    "status": "processed",
    "metadata": {
      "durationMs": 45000,
      "resolution": "1080x1920",
      "fileSizeBytes": 15728640,
      "exportedAt": "2026-04-08T15:30:00Z",
      "exportedGalleryAssetId": "ios_photo_asset_12345",
      "sharedAt": null
    }
  },
  "createdAt": "2026-04-08T14:00:00Z",
  "updatedAt": "2026-04-08T15:30:00Z"
}
```

#### Nuevo Enum: `ExportStatus`

```dart
enum ExportStatus {
  notExported,
  exporting,
  exported,
  exportFailed,
  shared,
}
```

### Integraciones Externas

| Integración | Propósito | Librería |
|-------------|-----------|----------|
| **Galería nativa (iOS Photos / Android Gallery)** | Guardar video para acceso del usuario | `photo_manager: ^3.0.0` |
| **Share Sheet nativo** | Compartir video en apps externas | `share_plus: ^7.0.0` |
| **Configuración del OS** | Abrir settings para permisos | `permission_handler: ^11.3.0` (ya existe) |

---

## 5. Decisiones Tecnológicas

### Dependencias a Agregar

```yaml
dependencies:
  photo_manager: ^3.0.0
  share_plus: ^7.0.0
```

### Justificación Técnica

#### `photo_manager` vs. Alternativas

| Opción | Pros | Contras | Decisión |
|--------|------|---------|----------|
| **photo_manager** | - Abstrae iOS/Android nativamente<br>- Soporte write-only en iOS<br>- Retorna AssetEntity con metadatos<br>- Mantenimiento activo | - Requiere configuración de permisos en Info.plist<br>- En iOS 14+ puede retornar status "limited" | ✅ **SELECCIONADO** |
| `image_gallery_saver` | - API simple | - Obsoleto, sin mantenimiento desde 2021<br>- Problemas con iOS 14+<br>- No soporta Android 13+ scoped storage | ❌ Descartado |
| `gallery_saver` | - Soporta video + imagen | - Múltiples issues abiertos sin resolver<br>- No funciona bien con Flutter 3.x | ❌ Descartado |

**Por qué `photo_manager`:** Es el estándar de la industria para acceso a galería en Flutter. La alternativa `image_gallery_saver` está abandonada. `photo_manager` tiene mantenimiento activo de `fluttercandies` y soporta correctamente Android 13+ scoped storage + iOS 14+ photo permissions.

#### `share_plus` vs. Alternativas

| Opción | Pros | Contras | Decisión |
|--------|------|---------|----------|
| **share_plus** | - Fork mantenido de `share`<br>- Soporte nativo a archivos + texto<br>- API simple (1 línea)<br>- Funciona en iOS + Android | - No permite compartir directo a una app específica (esto es intencional) | ✅ **SELECCIONADO** |
| `esys_flutter_share` | - Similar a share_plus | - Sin mantenimiento desde 2020<br>- Issues con Android 11+ package visibility | ❌ Descartado |
| Implementación manual (MethodChannel) | - Control total | - Requiere código nativo iOS/Android<br>- Overkill para un share sheet | ❌ Descartado |

**Por qué `share_plus`:** Es el fork oficial y mantenido del plugin `share` original. API extremadamente simple, sin dependencias nativas complejas, y resuelve exactamente el caso de uso: abrir el share sheet nativo con un archivo adjunto.

### Configuración de Plataformas Requerida

#### Android (`android/app/src/main/AndroidManifest.xml`)

**NO se requiere configuración especial** para `photo_manager` en Android. La librería maneja scoped storage automáticamente.

Para `share_plus`, puede ser necesario agregar (Android 11+):

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.SEND" />
    <data android:mimeType="*/*" />
  </intent>
</queries>
```

#### iOS (`ios/Runner/Info.plist`)

**OBLIGATORIO** para `photo_manager`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>VRM necesita acceso a tu galería para guardar los videos que creas.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>VRM necesita permiso para guardar videos en tu galería.</string>
```

**OBLIGATORIO** para `share_plus` (si se comparten archivos):

```xml
<key>UIFileSharingEnabled</key>
<true/>
```

---

## 6. Plan de Implementación

### Desglose en Tareas (Backlog Técnico)

| # | Tarea | Descripción | Dependencias | Prioridad | Estimación |
|---|-------|-------------|--------------|-----------|------------|
| **6.1** | Agregar dependencias al `pubspec.yaml` | Añadir `photo_manager` y `share_plus` + `flutter pub get` | Ninguna | 🔴 Crítica | 5 min |
| **6.2** | Configurar `Info.plist` (iOS) | Agregar keys de Photo Library usage description | 6.1 | 🔴 Crítica | 10 min |
| **6.3** | Configurar `AndroidManifest.xml` | Agregar `<queries>` para share_plus (Android 11+) | 6.1 | 🟡 Media | 5 min |
| **6.4** | Crear `GalleryExportService` | Implementar chequeo de permisos, solicitud, y `saveToGallery()` | 6.1, 6.2, 6.3 | 🔴 Crítica | 1.5 horas |
| **6.5** | Crear `ShareService` | Implementar `shareFile()` con `share_plus` | 6.1 | 🔴 Crítica | 30 min |
| **6.6** | Crear `ExportService` (orquestador) | Implementar flujo completo: validar → permisos → guardar → actualizar proyecto | 6.4, 6.5 | 🔴 Crítica | 2 horas |
| **6.7** | Crear `ExportProgressOverlay` | Widget de feedback visual durante exportación | Ninguna | 🟡 Media | 1 hora |
| **6.8** | Crear `ExportConfirmationDialog` | Dialog post-guardado para ofrecer compartir | Ninguna | 🟡 Media | 45 min |
| **6.9** | Conectar botón en `recording_end_page.dart` | Wireframear `ExportService` al botón "Exportar Video" existente | 6.6, 6.7, 6.8 | 🔴 Crítica | 1 hora |
| **6.10** | Actualizar modelo `ProjectState` | Agregar campos `exportedAt`, `exportedGalleryAssetId`, `sharedAt` | 6.6 | 🟡 Media | 30 min |
| **6.11** | Actualizar `ProjectRepository` | Agregar método `markAsExported(projectId, assetId)` | 6.10 | 🟡 Media | 30 min |
| **6.12** | Manejo de errores edge cases | Implementar dialogs de error para cada `ExportError` | 6.6 | 🟡 Media | 1 hora |
| **6.13** | Testing manual en dispositivos físicos | Probar export en Android + iOS reales | Todas | 🔴 Crítica | 2 horas |

### Orden Recomendado de Desarrollo

```
FASE 1: Infraestructura (30 min)
  6.1 → 6.2 → 6.3 (dependencias + configs)

FASE 2: Servicios Core (4 horas)
  6.4 → 6.5 → 6.6 (GalleryExport + Share + Export orchestrator)

FASE 3: UI Components (2 horas)
  6.7 → 6.8 → 6.9 (overlays + dialogs + wiring)

FASE 4: Persistencia (1 hora)
  6.10 → 6.11 (model updates + repo methods)

FASE 5: Robustez (1 hora)
  6.12 (error handling)

FASE 6: Validación (2 horas)
  6.13 (testing manual en dispositivos)
```

**Total estimado: ~10.5 horas** (1 día de trabajo concentrado, como especifica el plan MVP).

### Dependencias entre Tareas

```
6.1 (deps)
  └─ 6.2 (iOS config)
  └─ 6.3 (Android config)
       └─ 6.4 (GalleryExportService) ─┐
       └─ 6.5 (ShareService) ─────────┼─ 6.6 (ExportService orchestrator)
                                       └─ 6.9 (wiring en recording_end_page)
  6.7 (overlay) ──────────────────────┘
  6.8 (dialog) ───────────────────────┘
  6.10 (model) ── 6.11 (repo) ───────── 6.6
  6.12 (error handling) ──────────────── 6.6
  6.13 (testing) ─────────────────────── TODAS las anteriores
```

---

## 7. Riesgos y Cuellos de Botella

### Riesgos Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **`photo_manager` falla en iOS 14+ con permisos "limited"** | Media | 🟡 Medio | Detectar `isLimited` y advertir al usuario que cambie a "Full Access" |
| **Scoped Storage en Android 13+ bloquea escritura** | Baja | 🔴 Alto | `photo_manager` ya lo maneja, pero verificar en testing |
| **Video > 1GB causa timeout en guardado** | Media | 🟡 Medio | Implementar progress indicator + timeout de 60s con retry |
| **`share_plus` no reconoce el formato del archivo** | Baja | 🟡 Medio | Validar que el archivo sea `.mp4` válido antes de compartir |
| **Crash en app al abrir share sheet en iOS simulator** | Alta | 🟢 Bajo | Share sheet no funciona en simulator; testear solo en device físico |

### Riesgos Operativos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **Usuario deniega permisos y no sabe cómo reactivarlos** | Alta | 🟡 Medio | Dialog educativo con botón directo a configuración |
| **Usuario cree que el video no se guardó (no lo ve en galería)** | Media | 🟡 Medio | Mensaje explícito: "Video guardado ✅. Abre tu app de Fotos para verlo." |
| **Exportación interrumpe grabación en progreso** | Baja | 🔴 Alto | Aislar export de la lógica de grabación (diferentes servicios) |

### Escalabilidad

| Riesgo | Descripción | Solución Futura |
|--------|-------------|-----------------|
| **Videos de larga duración (10+ min)** | Exportar archivos grandes consume tiempo y memoria | Implementar exportación en background con isolate |
| **Múltiples formatos de exportación** | Usuarios pueden querer 720p, 480p para compartir más rápido | Integrar `ffmpeg_kit` para transcodificación previa |
| **Compartir a múltiples plataformas simultáneamente** | Share sheet solo permite una app a la vez | Si en el futuro se quiere compartir en masa, implementar con APIs directas de cada red social |

### Costos

**NO hay costos directos.** Las librerías son open-source y gratuitas. El único "costo" es:
- Tiempo de desarrollo: ~10.5 horas (1 día)
- Testing en dispositivos físicos: necesidad de tener un iOS y un Android real disponible

---

## 8. Métricas de Éxito

### KPIs Técnicos

| Métrica | Target | Cómo Medir |
|---------|--------|------------|
| **Tasa de éxito de exportación** | > 95% | `(exports exitosos / exports intentados) * 100` |
| **Tiempo promedio de exportación** | < 5 segundos para videos < 100MB | Log de timestamps: inicio → fin de `saveVideoWithPath` |
| **Tasa de permisos concedidos** | > 80% | `(permisos concedidos / permisos solicitados) * 100` |
| **Tasa de uso de share sheet** | > 60% | `(veces que se abrió share sheet / exports exitosos) * 100` |
| **Crash rate durante export** | 0% | Firebase Crashlytics o logs de errores no manejados |

### KPIs de Negocio (UX)

| Métrica | Target | Cómo Medir |
|---------|--------|------------|
| **Satisfacción post-export** | > 4/5 estrellas | Encuesta opcional post-export: "¿Pudiste compartir tu video?" |
| **Tasa de proyectos completados** | > 70% llegan a export | `(proyectos exportados / proyectos iniciados) * 100` |
| **Compartir en redes** | > 50% de usuarios comparten al menos 1 video | Log de `sharedAt` en project metadata |

### Cómo Validar que Está Bien Implementado

1. **Test de Humo:** Grabar 3 clips → stitch → exportar → verificar que el video aparezca en la galería del teléfono.
2. **Test de Compartir:** Exportar → abrir share sheet → seleccionar WhatsApp/Telegram → verificar que el archivo adjunto sea el video correcto.
3. **Test de Permisos:** Denegar permisos → intentar exportar → verificar que se muestre dialog educativo → abrir configuración → conceder → reintentar export.
4. **Test de Error:** Renombrar `final.mp4` a otro nombre → intentar exportar → verificar que se muestre error "video no encontrado".
5. **Test de Persistencia:** Exportar → cerrar app → reopen → verificar que `project_state.json` tenga `exportedAt` con timestamp válido.

---

## 9. Estrategia de Testing

### Unit Tests

```dart
// test/features/export/services/gallery_export_service_test.dart

group('GalleryExportService', () {
  late GalleryExportService service;
  late MockPhotoManager mockPhotoManager;

  setUp(() {
    mockPhotoManager = MockPhotoManager();
    service = GalleryExportService(photoManager: mockPhotoManager);
  });

  test('checkPermission returns true when status is authorized', () async {
    when(mockPhotoManager.requestPermissionExtend())
        .thenAnswer((_) async => PermissionStatus.authorized);
    
    final result = await service.checkPermission();
    expect(result, isTrue);
  });

  test('saveToGallery returns AssetEntity when file exists', () async {
    final testFile = File('/tmp/test_video.mp4');
    when(mockPhotoManager.saveVideoWithPath(any))
        .thenAnswer((_) async => AssetEntity(id: 'test_123'));
    
    final result = await service.saveToGallery(testFile);
    expect(result, isNotNull);
    expect(result!.id, 'test_123');
  });

  test('saveToGallery throws when file does not exist', () async {
    final nonExistentFile = File('/tmp/nonexistent.mp4');
    // Simular comportamiento de photo_manager con archivo inexistente
    when(mockPhotoManager.saveVideoWithPath(any))
        .thenThrow(Exception('File not found'));
    
    expect(() => service.saveToGallery(nonExistentFile), throwsException);
  });
});
```

```dart
// test/features/export/services/export_service_test.dart

group('ExportService', () {
  late ExportService service;
  late MockGalleryExportService mockGalleryExport;
  late MockShareService mockShare;
  late MockProjectRepository mockProjectRepo;

  setUp(() {
    mockGalleryExport = MockGalleryExportService();
    mockShare = MockShareService();
    mockProjectRepo = MockProjectRepository();
    service = ExportService(
      galleryExport: mockGalleryExport,
      share: mockShare,
      projectRepo: mockProjectRepo,
    );
  });

  test('exportProject fails when video file does not exist', () async {
    final result = await service.exportProject('nonexistent_project');
    expect(result.error, ExportError.fileNotFound);
  });

  test('exportProject fails when permission is denied', () async {
    // Setup: archivo existe
    setupMockVideoFile('proj_123');
    
    // Permiso denegado
    when(mockGalleryExport.requestPermission())
        .thenAnswer((_) async => false);
    
    final result = await service.exportProject('proj_123');
    expect(result.error, ExportError.permissionDenied);
  });

  test('exportProject succeeds when all steps complete', () async {
    setupMockVideoFile('proj_123');
    when(mockGalleryExport.requestPermission())
        .thenAnswer((_) async => true);
    when(mockGalleryExport.saveToGallery(any))
        .thenAnswer((_) async => MockAssetEntity(id: 'asset_456'));
    when(mockProjectRepo.markAsExported(any, any))
        .thenAnswer((_) async => true);
    
    final result = await service.exportProject('proj_123');
    expect(result.isSuccess, isTrue);
    expect(result.assetId, 'asset_456');
    
    // Verificar que se marcó como exportado
    verify(mockProjectRepo.markAsExported('proj_123', 'asset_456')).called(1);
  });
});
```

### Integration Tests

```dart
// integration_test/export_flow_test.dart

testWidgets('Export flow: valid video file to gallery', (tester) async {
  // 1. Crear proyecto de prueba con final.mp4 dummy
  final testProject = await createTestProjectWithVideo();
  
  // 2. Navegar a recording_end_page
  await tester.pumpWidget(MaterialApp(home: RecordingEndPage(projectId: testProject.id)));
  await tester.pumpAndSettle();
  
  // 3. Tocar botón "Exportar Video"
  await tester.tap(find.text('Exportar Video'));
  await tester.pumpAndSettle();
  
  // 4. Verificar que aparece overlay de progreso
  expect(find.text('Guardando video en galería...'), findsOneWidget);
  
  // 5. Esperar a que termine (mock de photo_manager)
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  
  // 6. Verificar mensaje de éxito
  expect(find.text('✅ Video guardado en tu galería'), findsOneWidget);
  
  // 7. Verificar que proyecto se marcó como exportado
  final updatedProject = await loadProject(testProject.id);
  expect(updatedProject.assets.metadata.exportedAt, isNotNull);
});
```

### Casos Críticos a Validar (Manual Testing)

| # | Caso | Resultado Esperado |
|---|------|-------------------|
| M1 | Exportar video válido en Android físico | Video aparece en Google Photos |
| M2 | Exportar video válido en iOS físico | Video aparece en Photos.app |
| M3 | Permiso de galería denegado (primera vez) | Aparece dialog solicitando permiso |
| M4 | Permiso de galería denegado permanentemente | Aparece dialog con botón a Configuración |
| M5 | Intentar exportar sin `final.mp4` | Error: "Video no encontrado" |
| M6 | Exportar video de 500MB | Exportación exitosa, puede tardar > 10s |
| M7 | Abrir share sheet y cancelar | No registra `sharedAt`, regresa al dashboard |
| M8 | Abrir share sheet y compartir a WhatsApp | Video adjunto en WhatsApp correctamente |
| M9 | Exportar, cerrar app, reopen | Proyecto muestra estado "exportado" |
| M10 | Re-exportar mismo proyecto | Permite sin errores, actualiza `exportedAt` |

---

## 10. Optimización y Escalabilidad Futura

### Qué Problemas Aparecerán al Escalar

| Escala | Problema | Solución |
|--------|----------|----------|
| **Videos > 500MB** | `photo_manager.saveVideoWithPath()` puede bloquear el main thread > 10s | Mover a un **Isolate** separado con `compute()` |
| **Múltiples exportaciones simultáneas** | Cola de escritura en galería puede causar race conditions | Implementar **ExportQueue** con procesamiento secuencial |
| **Usuarios con galerías de 10,000+ videos** | iOS "limited" permission se vuelve impráctico | Educar al usuario para cambiar a "Full Access" o implementar export a carpeta custom |
| **Necesidad de diferentes calidades** | `final.mp4` en 1080p es muy pesado para WhatsApp (límite 16MB) | Integrar **ffmpeg_kit** para crear versiones downscaled (720p, 480p) |
| **Compartir a plataformas específicas sin share sheet** | Share sheet no permite publicar directamente a TikTok/Instagram | En V2, integrar **APIs nativas** de cada red social (requiere OAuth) |

### Cómo Dejar Preparado el Diseño Desde Ahora

#### 1. Arquitectura Extensible con Abstract Factory

```dart
/// Interfaz para diferentes estrategias de exportación
abstract class ExportStrategy {
  Future<ExportResult> export(File videoFile, ExportConfig config);
}

/// Implementación actual (galería nativa)
class GalleryExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> export(File videoFile, ExportConfig config) {
    return PhotoManager.editor.saveVideoWithPath(videoFile.path);
  }
}

/// Estrategia futura: exportación con compresión
class CompressedExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> export(File videoFile, ExportConfig config) async {
    // Futuro: usar ffmpeg_kit para crear versión comprimida
    // final compressedPath = await FFmpegKit.execute('-i ${videoFile.path} -vf scale=-2:720 output_720.mp4');
    // return PhotoManager.editor.saveVideoWithPath(compressedPath);
    throw UnimplementedError('Compressed export not yet implemented');
  }
}

/// Estrategia futura: export directo a cloud
class CloudExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> export(File videoFile, ExportConfig config) {
    // Futuro: subir a Firebase Storage, AWS S3, etc.
    throw UnimplementedError('Cloud export not yet implemented');
  }
}
```

#### 2. Configuración de Exportación Flexible

```dart
class ExportConfig {
  final ExportDestination destination;
  final VideoQuality? quality;
  final bool shareAfterExport;
  final String? shareText;

  const ExportConfig({
    this.destination = ExportDestination.gallery,
    this.quality,
    this.shareAfterExport = true,
    this.shareText,
  });
}

enum ExportDestination {
  gallery,
  cloud,
  customFolder,
}

enum VideoQuality {
  original,  // sin transcodificación
  hd1080p,
  hd720p,
  sd480p,
}
```

#### 3. Isolate-Ready Design

```dart
/// Preparado para mover a un Isolate en el futuro
class ExportWorker {
  /// Este método debe ser puro para poder usarse con compute()
  static Future<ExportResult> exportInIsolate(Map<String, dynamic> params) async {
    final videoPath = params['videoPath'] as String;
    final config = params['config'] as ExportConfig;
    
    // Toda la lógica de exportación aquí, sin depender de state management
    // Esto permitirá: compute(ExportWorker.exportInIsolate, params);
    
    return ExportResult.success(...);
  }
}
```

#### 4. Logging Estructurado para Analytics

```dart
class ExportAnalytics {
  final AnalyticsService _analytics;

  Future<void> logExportAttempt({
    required String projectId,
    required int videoSizeBytes,
    required Duration duration,
    required bool success,
    String? error,
  }) async {
    await _analytics.logEvent(
      name: 'video_export',
      parameters: {
        'project_id': projectId,
        'video_size_bytes': videoSizeBytes,
        'duration_ms': duration.inMilliseconds,
        'success': success,
        'error': error ?? '',
      },
    );
  }
}
```

### Decisiones que NO Tomar Ahora (Dejar para V2)

| Decisión | Por Qué Esperar |
|----------|----------------|
| Soporte para múltiples formatos (MOV, AVI, GIF) | MVP solo necesita MP4 |
| Exportación a cloud (Firebase, GDrive) | Complejidad alta, valor bajo para MVP |
| Transcodificación con ffmpeg (diferentes calidades) | Requiere ffmpeg_kit, que aún no está integrado |
| Publicación directa a redes sociales (APIs nativas) | Excluido definidamente del MVP |
| Batch export (múltiples proyectos a la vez) | UX prematura, primero validar flujo individual |

---

## 11. Resumen de Archivos a Crear/Modificar

### Crear (Nuevos)

| Archivo | Propósito |
|---------|-----------|
| `lib/features/export/services/export_service.dart` | Orquestador principal |
| `lib/features/export/services/gallery_export_service.dart` | Integración con photo_manager |
| `lib/features/export/services/share_service.dart` | Integración con share_plus |
| `lib/features/export/widgets/export_progress_overlay.dart` | UI de progreso |
| `lib/features/export/widgets/export_confirmation_dialog.dart` | Dialog post-guardado |
| `lib/features/export/models/export_result.dart` | Modelo de resultado |
| `lib/features/export/models/export_config.dart` | Configuración flexible |
| `test/features/export/services/gallery_export_service_test.dart` | Tests unitarios |
| `test/features/export/services/export_service_test.dart` | Tests unitarios |

### Modificar (Existentes)

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | Agregar `photo_manager` y `share_plus` |
| `lib/core/models/project_state.dart` | Agregar campos `exportedAt`, `exportedGalleryAssetId`, `sharedAt` |
| `lib/core/data/project_repository.dart` | Agregar método `markAsExported()` |
| `lib/features/recording/recording_end_page.dart` | Conectar botón "Exportar Video" al `ExportService` |
| `ios/Runner/Info.plist` | Agregar Photo Library usage descriptions |
| `android/app/src/main/AndroidManifest.xml` | Agregar `<queries>` para Android 11+ |

---

## 12. Checkpoint de Validación Final

Tras completar Día 6, el sistema debe pasar este checklist:

- [ ] `photo_manager` y `share_plus` agregados a `pubspec.yaml` y configurados
- [ ] `Info.plist` tiene las 2 keys de Photo Library
- [ ] `AndroidManifest.xml` tiene `<queries>` para share
- [ ] `ExportService` implementado con flujo completo
- [ ] Botón "Exportar Video" en `recording_end_page.dart` funcional
- [ ] Video aparece en galería nativa tras exportar
- [ ] Share sheet se abre al confirmar exportación
- [ ] Proyecto se marca como exportado en `project_state.json`
- [ ] Manejo de errores para: archivo no existe, permisos denegados, espacio insuficiente
- [ ] Tests unitarios pasando (> 80% coverage de servicios de export)
- [ ] Testing manual exitoso en al menos 1 dispositivo Android físico
- [ ] Testing manual exitoso en al menos 1 dispositivo iOS físico

---

**FIN DEL ANÁLISIS - DÍA 6**

*Documento generado para implementación inmediata por equipo de desarrollo.*
*Nivel de detalle: listo para codear sin ambigüedades críticas.*
