# 📊 ESTADO DE LA FASE: FASE 1 - Core de Grabación

## 1. Resumen de Fase
**Objetivo:** Permitir el flujo completo desde la captura de fragmentos individuales hasta la generación de un video final mediante concatenación (stitching) y exportación a galería.

**Pasos de la Fase:**
1.  **Día 1-2: Grabación Crítica** (Captura de clips .mp4 en disco) -> ✅ COMPLETADO
2.  **Día 3: Revisión Visual** (Validación de clips post-grabación) -> ✅ COMPLETADO
3.  **Día 4-5: Auto-Stitch** (Concatenación vía FFmpeg) -> ⚙️ EN CURSO
4.  **Día 6: Exportación** (Galería y Share Sheet) -> ⏳ PENDIENTE
5.  **Día 7-8: Persistencia Local Offline** (Gestión de proyectos/sesiones) -> ⏳ PENDIENTE
6.  **Día 9-10: IA Offline / Fallback** (Generación de guiones local) -> ⏳ PENDIENTE

**Dependencias Críticas:**
- La Revisión (Día 3) depende de que los archivos se graben correctamente (Día 1-2).
- El Auto-Stitch (Día 4-5) depende de tener una lista de `approvedClips` generada en la Revisión.

---

## 2. Estado Actual del Proyecto

### ✅ Implementado y Funcional
- **Grabación (F8):** `recording_page.dart` maneja la interfaz de cámara y el flujo de grabación por fragmentos.
- **Revisión (F9):** `clip_review_page.dart` permite previsualizar clips, aceptarlos o repetirlos.
- **Servicios Core:** `RecordingManager`, `ClipStorageService` y `CameraService` orquestan el hardware y el sistema de archivos.
- **Onboarding & Ideas:** Flujos iniciales (F1-F3) y Dashboard (F12) operacionales al 90-100%.

### ⚠️ Parcialmente Implementado
- **Auto-Stitch (F10):** `stitcher_plugin.dart` existe como estructura en `lib/core/plugins/default/`, pero carece de la implementación de comandos `ffmpeg`.
- **Teleprompter (F6-F7):** Integrado en la grabación pero pendiente de refinamientos finales de sincronización.

### 🔴 No existe aún
- **Exportación (F11):** No hay integración con `photo_manager` ni `share_plus`.
- **Persistencia de Proyectos:** Los datos de sesión no se guardan formalmente en el `vrm_data` schema definido en el plan.

---

## 3. Contratos Técnicos Vigentes

### Estructura de Carpetas
- `lib/features/recording/`: Contiene la lógica principal de captura y revisión.
- `lib/features/recording/services/`: Services para cámara, almacenamiento de clips y gestión de grabación.
- `lib/core/plugins/`: Arquitectura de plugins para procesamiento (Stitcher).

### Convenciones de Naming
- Archivos de UI: `snake_case_page.dart` o `snake_case_screen.dart`.
- Componentes: `PascalCase`.
- Clips temporales: Preferencia por `chunk_{index}_take_{attempt}.mp4`.

### Dependencias Instaladas
- `camera`: ^0.11.0+4
- `video_player`: ^2.9.1
- `path_provider`, `path`, `sqflite`.
- *Nota: `ffmpeg_kit_flutter` aún no aparece en pubspec.yaml.*

---

## 4. Decisiones de Arquitectura Tomadas
- **Arquitectura Modular Determinista:** Uso del `RecordingManager` para desacoplar la UI de la lógica de hardware/archivos.
- **Validación Binaria:** El usuario debe aprobar cada clip antes de avanzar, asegurando que el stitch final siempre sea de calidad.
- **Manejo de Video Liviano:** Uso de `video_player` nativo sin wrappers pesados para optimizar el bundle.

---

## 5. Registro de Pasos Completados

| Paso | Estado | Archivos Modificados | Decisiones Tomadas | Notas |
|------|--------|---------------------|-------------------|-------|
| Día 1-2 | ✅ | `recording_page.dart`, `camera_service.dart` | Captura de fragmentos secuenciales en disco. | Estabilizado en físico. |
| Día 3 | ✅ | `clip_review_page.dart`, `recording_manager.dart` | Implementación de revisión obligatoria post-toma. | Soporta auto-accept de 3s. |
| Día 4-5 | ⚙️ | `stitcher_plugin.dart` | Planificada integración con FFmpeg. | **PRÓXIMO HITO.** |

---

## 6. Criterios Generales de Aceptación Fase 1
- [x] El usuario puede grabar clips MP4 reales que persisten en caché.
- [x] La pantalla de revisión reproduce el video grabado inmediatamente.
- [ ] La unión de clips genera un video único reproducible en la galería del sistema.
- [ ] El proceso de "unión" muestra feedback visual de progreso.
- [ ] No hay fugas de memoria (leaks) tras múltiples ciclos de grabación/revisión.

---
**Idioma de respuesta:** Español 🇪🇸
