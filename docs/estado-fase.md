# 📊 ESTADO DE LA FASE: FASE 1 - Core de Grabación

## 1. Resumen de Fase
**Objetivo:** Permitir el flujo completo desde la captura de fragmentos individuales hasta la generación de un video final mediante concatenación (stitching) y exportación a galería.

**Pasos de la Fase:**
1.  **Día 1-2: Grabación Crítica** (Captura de clips .mp4 en disco) -> ✅ COMPLETADO
2.  **Día 3: Revisión Visual** (Validación de clips post-grabación) -> ✅ COMPLETADO
3.  **Día 4-5: Auto-Stitch** (Concatenación vía FFmpeg) -> ✅ COMPLETADO
4.  **Día 6: Exportación** (Galería y Share Sheet) -> ⏳ PENDIENTE (**PRÓXIMO HITO**)
5.  **Día 7-8: Persistencia Local Offline** (Gestión de proyectos/sesiones) -> ✅ COMPLETADO
6.  **Día 9-10: IA Offline / Fallback** (Generación de guiones local) -> ⏳ PENDIENTE

**Dependencias Críticas:**
- La Revisión (Día 3) depende de que los archivos se graben correctamente (Día 1-2).
- El Auto-Stitch (Día 4-5) depende de tener una lista de `approvedClips` generada en la Revisión.
- La Exportación (Día 6) depende de tener el `finalVideoPath` generado por el Auto-Stitch.

---

## 2. Estado Actual del Proyecto

### ✅ Implementado y Funcional
- **Grabación (F8):** `recording_page.dart` maneja la interfaz de cámara y el flujo de grabación por fragmentos.
- **Revisión (F9):** `clip_review_page.dart` permite previsualizar clips, aceptarlos o repetirlos.
- **Motor de Stitching (F10):** `FFmpegStitcherService` implementado con soporte para *stream copy* (rápido) y *re-encoding* (fallback).
- **Persistencia de Sesión (F7-8):** `RecordingManager` guarda automáticamente `session_data.json` en disco ante cada cambio (clips aprobados, progreso de grabación).
- **Servicios Core:** `RecordingManager`, `ClipStorageService`, `CameraService` y `PermissionService` estabilizados.
- **Modelos de Datos:** `ProjectState`, `SessionData`, `AssetManifest` y `ScriptBundle` definidos y con soporte JSON.

### ⚠️ Parcialmente Implementado
- **Plugin Architecture:** `StitcherPlugin` existe como wrapper pero la integración directa en `RecordingManager` es la que se usa actualmente para el MVP.
- **Teleprompter (F6-F7):** Integrado en la grabación pero pendiente de refinamientos finales de sincronización con la voz.

### 🔴 No existe aún
- **Exportación (F11):** No hay integración con `photo_manager` ni `share_plus`.
- **IA Fallback (F4-F5):** Pendiente implementar la generación de guiones basada en templates locales.

---

## 3. Contratos Técnicos Vigentes

### Estructura de Carpetas
- `lib/features/recording/`: Lógica central de captura, revisión y orquestación de sesión.
- `lib/core/services/`: Servicios globales como `FFmpegStitcherService`.
- `lib/core/models/`: Definición de los estados persistentes del sistema.
- `vrm_data/projects/{id}/`: Estructura en disco para clips, sesión y video final.

### Convenciones de Naming
- Archivos de UI: `snake_case_page.dart`.
- Servicios: `PascalCaseService`.
- Clips: `chunk_{index}_take_{attempt}.mp4`.
- Video Final: `final.mp4`.

### Dependencias Instaladas
- `camera`: ^0.11.0+4
- `video_player`: ^2.9.1
- `ffmpeg_kit_flutter`: ^6.0.3
- `path_provider`, `path`, `sqflite`, `shared_preferences`.
- `permission_handler`, `intl`, `uuid`.

---

## 4. Decisiones de Arquitectura Tomadas
- **FFmpeg como Motor Único:** Se decidió usar FFmpeg para asegurar compatibilidad de codecs al unir clips de diferentes sesiones o cámaras.
- **Persistencia "Hot":** La sesión se guarda en cada "Accept" de clip para prevenir pérdida de progreso por crash o salida accidental.
- **Desacoplamiento de Hardware:** El `CameraService` abstrae la complejidad de la cámara nativa, permitiendo al `RecordingManager` centrarse en el flujo de negocio.
- **Fallback de Re-encoding:** Si la unión rápida de streams falla, se intenta un re-encodificado ultra-rápido para asegurar que el video final siempre se genere.

---

## 5. Registro de Pasos Completados

| Paso | Estado | Archivos Modificados | Decisiones Tomadas | Notas |
|------|--------|---------------------|-------------------|-------|
| Día 1-2 | ✅ | `recording_page.dart`, `camera_service.dart` | Captura de fragmentos secuenciales en disco. | Estabilizado en físico. |
| Día 3 | ✅ | `clip_review_page.dart`, `recording_manager.dart` | Implementación de revisión obligatoria post-toma. | Soporta auto-accept de 3s. |
| Día 4-5 | ✅ | `ffmpeg_stitcher_service.dart`, `stitcher_plugin.dart` | Uso de FFmpeg para unión de clips. | Soporta re-encoding fallback. |
| Día 7-8 | ✅ | `session_data.dart`, `recording_manager.dart` | Persistencia JSON automática en disco. | Adelantado para mayor robustez. |

---

## 6. Criterios Generales de Aceptación Fase 1 (Actualizado)
- [x] El usuario puede grabar clips MP4 reales que persisten en caché.
- [x] La pantalla de revisión reproduce el video grabado inmediatamente.
- [x] La unión de clips genera un video único `final.mp4` reproducible.
- [x] El proceso de sesión se recupera tras cerrar y abrir la app (vía `session_data.json`).
- [ ] El video final se guarda en la galería de fotos del dispositivo (Día 6).
- [ ] No hay fugas de memoria (leaks) tras múltiples ciclos de grabación/revisión.

---
**Idioma de respuesta:** Español 🇪🇸
