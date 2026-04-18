# 📊 ESTADO DE LA FASE: FASE 2 - Interfaz y Refinamiento (Abril 2026)

## 1. Resumen de Fase
**Objetivo:** Completar la interfaz reactiva (Día 13) y refinamiento local (Días 14-18) para asegurar la estabilidad del MVP.

| Paso | Estado | Prioridad | Dependencia |
|------|--------|-----------|-------------|
| F1-F12: Fase 1 (Core) | ✅ COMPLETADO | Bloqueante | Ninguna |
| Día 11-12: Cámara Atómica | ✅ COMPLETADO | Crítica | F1-F2 |
| Día 13: Proyectos & Dashboard | 🏗️ EN DESARROLLO | Alta | F7-F8 |
| 3B_LIMPIEZA: Calidad | ✅ COMPLETADO | Media | Todas |

---

## 2. Estado Actual del Proyecto (Verificado contra Código)

### ✅ Implementado y Funcional
- **Grabación Fragmentada (Atom):** `RecordingManager` orquesta `CameraService` y `ClipStorageService`. Soporta inicio/parada por fragmentos.
- **Review de Clips:** `ClipReviewPage` permite previsualizar, aceptar o rechazar tomas de un fragmento.
- **Stitching de Video:** `FFmpegStitcherService` une los clips aprobados en un único video MP4.
- **Localización:** Soporte completo en ES/EN mediante ARB files y `AppLocalizations`.
- **Persistencia de Sesión:** `RecordingManager` guarda automáticamente `session_data.json` con el estado de la sesión (clips aprobados, tomas por fragmento, etc.).
- **Laboratorio de Ideas (Assistant):** `ScriptStudioPage` y `ScriptFallbackService` proporcionan la UI y generación de guiones offline mediante plantillas profesionales.
- **Diseño Visual:** Implementación fiel al tema "Forest" (oscuros profundos, verde vibrante, tipografía Inter/Google Fonts).
- **IA Offline / Fallback:** Generación local de guiones basada en objetivos (Conectar, Educar, Vender) operativa.
- **Cámara Atómica (Hardware & Modos):** Control manual de foco, exposición bloqueada (**Street Mode**) y flash (Torch) funcional en `CameraService`.
- **Teleprompter Avanzado:** Sistema de scroll fluido basado en PPM (Palabras Por Minuto) integrado en `RecordingPage`.
- **Efecto Fantasma (Ghost Mode):** Superposición de video (opacidad 0.2) para alineación de tomas consecutivas.

- **Dashboard (Proyectos):** 🏗️ EN DESARROLLO. Se ha iniciado la conexión con `ProjectRepository` para reemplazar los mocks por proyectos reales persistidos en disco.
- **Limpieza de Código (Linting):** Proceso 3B finalizado. Código libre de warnings `avoid_print` y otros diagnósticos menores.

### ⏳ No Existe Aún / Pendiente
- **Exportación con `gal`:** ⚠️ El plan menciona que se usa `gal`, pero el código real (`ExportService`) sigue utilizando `photo_manager`. La dependencia `gal` NO está en `pubspec.yaml`.

### ⚠️ Discrepancias Plan vs Código
1. **Librería de Exportación:** El documento previo afirmaba que `gal` estaba instalado y en uso. Verificado que no existe en `pubspec.yaml`.
2. **Assets:** `pubspec.yaml` referencia carpetas `assets/images/`, `assets/models/`, etc., pero no se detectaron en la raíz del proyecto (se encuentran en `docsx/assets` pero no en `assets/`).

---

## 3. Contratos Técnicos Vigentes

### Modelos de Datos (`lib/core/models/`)
- **`ScriptBundle`:** Estructura fragmentada del guion (chunks).
- **`SessionData`:** Estado persistente de la sesión de grabación.
- **`ClipMetadata`:** Metadatos técnicos de cada toma.

### Navegación (`lib/main.dart`)
- `/dashboard`: Panel principal.
- `/stitch-progress`: Pantalla de renderizado (paso de argumentos vía `onGenerateRoute`).
- `/recording-end`: Resumen final y exportación.

### Patrones de Código
- **Servicios:** Clases asíncronas para hardware e I/O. Se introdujo `ScriptFallbackService` como Singleton para lógica offline.
- **Managers:** Lógica de orquestación de flujo (ej. `RecordingManager`).
- **Persistence:** Archivos JSON en el directorio de documentos de la aplicación.
- **Hardware Abstraction:** `CameraService` expone métodos para mutar parámetros de hardware (`setFlashMode`, `setFocusMode`, `setExposureMode`) de forma segura.

### Dependencias Críticas (`pubspec.yaml`)
- `camera`: ^0.11.0+4
- `ffmpeg_kit_flutter`: ^6.0.3
- `photo_manager`: ^3.5.0 (Actual para Galería)
- `shared_preferences`: ^2.2.3
- `permission_handler`: ^11.3.0

---

## 4. Decisiones de Arquitectura Tomadas
- **Atomicidad Visual:** Cada fragmento de guion tiene su propio ciclo de grabación para maximizar la calidad por toma.
- **FFmpeg para Stitching:** Motor robusto para asegurar que los clips de diferentes resoluciones/frames se unan correctamente.
- **Hot-Save:** Guardado automático de `session_data.json` en cada cambio de estado para evitar pérdida de progreso.
- **Protocolo de Exteriores:** Bloqueo de exposición y foco para evitar "hunting" visual en modo CALLE.
- **Sincronización de Prompter:** Scroll basado en tiempo (`Timer.periodic`) para evitar lag visual independientemente del framerate de la cámara.

---

## 5. Registro de Pasos Completados

| Paso | Estado | Archivos Modificados | Notas |
|------|--------|---------------------|-------|
| F1-F5 | ✅ | `recording_page.dart`, `telepronter.dart` | Teleprompter y cámara integrados. |
| F11 | ✅ | `export_service.dart`, `ffmpeg_stitcher_service.dart` | Exportación funcional vía photo_manager. |
| Día 9-10 | ✅ | `script_fallback_service.dart`, `script_studio_page.dart` | Generación de guiones local funcional. |
| Día 11-12 | ✅ | `camera_service.dart`, `recording_page.dart` | Atomic Camera: Modos Street, Ghost Mode y Teleprompter Pro. |
| 3B_LIMPIEZA | ✅ | `camera_service.dart`, `telepronter.dart` | Eliminación de prints y lints en el flujo de grabación. |

---

## 6. Criterios de Aceptación Fase 1
- [x] Grabación y unión de clips funcional.
- [x] Persistencia de progreso contra cierres accidentales.
- [x] UI temática "Forest" aplicada.
- [x] Refactorización a `gal` (PENDIENTE).
- [x] Fallback de IA Offline (COMPLETADO).
- [x] Cámara Atómica: Modos Calle, Enfoque y Fantasma (COMPLETADO).

---
**Idioma de respuesta:** Español 🇪🇸sión.
- [ ] El video exportado sigue un patrón de nombre consistente (`VRM_VIDEO_...`).

---
**Idioma de respuesta:** Español 🇪🇸
