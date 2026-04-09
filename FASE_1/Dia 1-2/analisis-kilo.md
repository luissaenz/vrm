# Análisis: FASE 1 - Día 1-2 (Grabación Crítica)

**Objetivo:** Implementar el sistema de escritura de clips de video a disco físico.

---

## 1. Comprensión del Paso

### Problema que resuelve
El sistema actual tiene la interfaz de cámara y los estados de grabación definidos, pero **no existe implementación real de escritura a disco**. Los métodos `_startActualRecording()` (línea 277-284) y `_stopRecording()` (línea 286-291) en `recording_page.dart` contienen únicamente TODOs. El usuario no puede crear archivos `.mp4` persistentes.

### Inputs recibe
- `ScriptAnalysis` (del flujo anterior) - contiene los segmentos del guion
- `CameraController` ya inicializado con `ResolutionPreset.high`, `enableAudio: true`, `ImageFormatGroup.jpeg`
- Estado `RecordingState.recording` activo
- Índice de fragmento actual (`_activeFragmentIndex`)

### Outputs debe generar
- Archivos `.mp4` individuales命名为 `chunk_{fragmentIndex}_take_{takeNumber}.mp4`
- Ubicación: `/vrm_data/projects/{projectId}/clips/`
- Metadatos asociados al clip (duración, tamaño, timestamp)

### Rol en el sistema
Es el primer paso del pipeline VRM: `Idea → Guion → Grabar → Unir → Exportar`. Sin grabación persistida, no hay clip que revisar ni stitcher que ejecutar.

---

## 2. Supuestos y Ambigüedades

### Preguntas críticas a resolver antes de implementar

| # | Pregunta | Impacto | Responsable |
|---|---------|---------|-------------|
| 1 | ¿**Resolución de video** debe ser configurable o fija en `high`? | Storage/calidad | PO |
| 2 | ¿**Formato de video** es siempre `.mp4` o puede ser `.mov` en iOS? | Compatibilidad stitcher | Tech Lead |
| 3 | ¿Cuántos **takes** por fragmento se permiten? ¿3 máximo? | UX/Storage | PO |
| 4 | ¿El nombre del archivo debe incluir **timestamp** o solo序号? | Naming convention | Tech Lead |
| 5 | ¿Se implementa **grabación manual** (botón) o solo **voice command**? | UX completeness | PO |
| 6 | ¿Qué pasa si el usuario **cierra la app** durante grabación? | Recovery path | Tech Lead |
| 7 | ¿Se guarda **audio separado** del video? | Post-procesing | Tech Lead |
| 8 | ¿Necesita **feedback visual** de grabación (timer, duración)? | UX | PO |

### Definiciones faltantes detectadas

- **Directorio base de proyectos:** No existe variable `projectId` en `RecordingPage` - debe recibirse como input
- **Toma actual (take number):** No hay lógica para contar takes por fragmento
- **Recovery si grabación incompleta:** No hay mecanismo de checkpoint
- **Límite de storage:** No hay validación de espacio disponible

---

## 3. Diseño Funcional

### Flujo completo (Pipeline)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER PRESIONA BOTÓN GRABAR                                      │
│    ↓                                                             │
│ 2. COUNTDOWN (3s) - estado: countdown                           │
│    ↓                                                             │
│ 3. INICIAR GRABACIÓN real (camera.startVideoRecording())            │
│    ↓                                                             │
│ 4. DURANTE GRABACIÓN:                                            │
│    - Mostrar indicador REC en UI                                 │
│    - Updatear timer visual                                        │
│    - Monitorear storage disponible                              │
│    ↓                                                             │
│ 5. USER PRESIONA STOP / VOICE COMMAND "stop"                      │
│    ↓                                                             │
│ 6. DETENER GRABACIÓN (camera.stopVideoRecording())                 │
│    ↓                                                             │
│ 7. RECUPERAR ARCHIVO temporal del sistema                         │
│    ↓                                                             │
│ 8. MOVER a ruta definitiva:                                      │
│    /vrm_data/projects/{projectId}/clips/                          │
│    chunk_{fragmentIndex}_take_{n}.mp4                          │
│    ↓                                                             │
│ 9. GUARDAR metadata en session_data.json                       │
│    ↓                                                             │
│ 10. TRANSICIÓN a ClipReviewScreen                              │
└─────────────────────────────────────────────────────────────────┘
```

### Casos normales

| Escenario | Comportamiento esperado |
|----------|------------------------|
| Grabación exitosa | Archivo guardado, transición a revisión |
| Voce command "stop" | Detiene grabación equivalente a botón |
| Cambio de fragmento | Incrementa `_activeFragmentIndex`, resetea take counter |
| Regrabación | Incrementa take number, marca anterior como discarded |

### Edge cases

| Edge case | Manejo |
|----------|--------|
| Storage lleno durante grabación | Detener inmediatamente, mostrar error, guardar lo grabado (si playable) |
| Cámara desconectada (USB) | Mostrar overlay "Cámara no disponible", oferta retry |
| Llamada entrante durante grabación | Pausar grabación (Android), continuar en background (iOS requires background mode) |
| App killed por sistema | **CRÍTICO:** Implementar auto-save cada 10s o recuperar del temp |
| Video corrupto (no playable) | Descartar, mostrar "Clip corrupto", ofrecer retry |
| Permiso cámara revocados | Interceptar, mostrar settings nativo |

### Manejo de errores

```dart
// Niveles de error requeridos:
1. CATASTRÓFICO (sin grabación): Toast + retry button
2. ERROR PARCIAL (video corrupto): Toast + option retry  
3. WARNING (storage bajo <100MB): Banner + suggest cleanup
```

---

## 4. Diseño Técnico

### Arquitectura sugerida

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│  RecordingPage (UI)                                         │
│    - Estados: idle, countdown, recording, finished          │
│    - UI: CameraPreview, RecordButton, Timer                  │
└────────────────────────┬────────────────────────────────────┘
                           │
┌─────────────────────────▼────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                       │
│  RecordingController (NEW - Clase separada)                │
│    - startRecording()                                         │
│    - stopRecording()                                        │
│    - pauseRecording() / resumeRecording()                  │
│    - checkStorage()                                         │
│    - getRecordingStatus()                                   │
└────────────────────────┬��───────────────────────────────────┘
                           │
┌─────────────────────────▼────────────────────────────────────┐
│                    DATA/PLATFORM LAYER                        │
│  CameraService (wrapper de camera package)                      │
│    - initialize()                                           │
│    - startVideoRecording() → XFile                         │
│    - stopVideoRecording() → XFile path                     │
│                                                         │
│  FileStorageService (NEW)                                   │
│    - getProjectClipsPath(projectId)                      │
│    - saveClip(tempPath, finalPath)                       │
│    - getClipMetadata()                                    │
│    - checkAvailableStorage()                             │
│                                                         │
│  PermissionService (NEW)                                  │
│    - checkCameraPermission()                             │
│    - checkMicrophonePermission()                         │
│    - requestPermissions()                               │
└──────────────────────────────────────────────────────────┘
```

### Componentes a modificar

| Archivo | Cambios |
|---------|---------|
| `recording_page.dart` | Implementar `_startActualRecording()`, `_stopRecording()` - integrar con nuevo RecordingController |
| `models/recording_state.dart` | Añadir estados: `paused`, `error`, `saving` |
| `services/recording_controller.dart` | **NUEVO** - lógica de grabación |
| `services/file_storage_service.dart` | **NUEVO** - persistencia de clips |

### APIs / Endpoints necesarios

**Externos:** Ninguno (todo local)

**Internos (nuevos):**

```dart
// RecordingController
class RecordingController {
  Future<void> startRecording();              // Inicia video
  Future<XFile> stopRecording();             // Detiene y retorna archivo
  Future<void> pauseRecording();            // Pausa (si hw soporta)
  Future<void> resumeRecording();            // Resume
  bool get isRecording;
  Duration get recordingDuration;
  RecordingStatus get status;
}

// FileStorageService  
class FileStorageService {
  String getClipsDirectory(String projectId);
  Future<File> saveClip(File tempFile, String finalPath);
  Future<Map<String, dynamic>> getClipMetadata(File file);
  Future<bool> hasAvailableStorage(int requiredMB);
}
```

### Modelos de datos (schemas sugeridos)

**session_data.json** (aextendir):
```json
{
  "projectId": "uuid",
  "currentFragmentIndex": 0,
  "clips": [
    {
      "fragmentIndex": 0,
      "take": 1,
      "filename": "chunk_0_take_1.mp4",
      "path": "/vrm_data/projects/{id}/clips/chunk_0_take_1.mp4",
      "durationMs": 45000,
      "fileSizeBytes": 12500000,
      "createdAt": "2024-01-15T10:30:00Z",
      "isValid": true,
      "isRetake": false
    }
  ],
  "lastRecordedAt": "2024-01-15T10:30:00Z",
  "totalRecordingMs": 45000
}
```

### Integraciones externas

| Librería | Propósito | Versión recomendada |
|---------|----------|----------------------|
| `camera` | Camera API de Flutter | `^0.11.0+4` (ya en pubspec) |
| `path_provider` | Rutas de archivo | `^2.1.3` (ya en pubspec) |
| `permission_handler` | Permisos runtime | `^6.0.0` |

---

## 5. Decisiones Tecnológicas

### Frameworks
- **Flutter** con `camera` package - mantener consistencia con codebase existente

### Librerías clave

| Librería | Justificación |
|----------|---------------|
| `camera` (v0.11.0+) | Ya utilizada en codebase, soporta `startVideoRecording()` en iOS/Android |
| `path_provider` (v2.1.3) | Ya en dependencies, acceso a temp directories cross-platform |
| `permission_handler` | Necesario para-request permisos en Android 13+ y iOS 11+ |

### Decisiones de implementación

1. **Grabar a tempfirst, luego mover** - Evita corrupción si app crash durante escritura
2. **Filename: `chunk_{idx}_take_{n}.mp4`** - Escalable, trazable, ordered
3. **Timer basado en Duration** - No依赖 sistema, más preciso
4. **Auto-checkpoint cada 10s** - Si app killed, recuperación parcial
5. **UI State Machine** - estados explícitos para cada fase

---

## 6. Plan de Implementación

### Tareas (Backlog técnico)

| # | Tarea | Estimación | Dependencias |
|---|-------|------------|--------------|
| 1.1 | Añadir `projectId` como required prop en `RecordingPage` | 0.5d | Ninguna |
| 1.2 | Crear `RecordingController` con lógica de start/stop | 1d | Ninguna |
| 1.3 | Implementar `FileStorageService.saveClip()` | 0.5d | 1.1 |
| 1.4 | Conectar `_startActualRecording()` con controller | 0.5d | 1.2 |
| 1.5 | Conectar `_stopRecording()` con controller + save | 0.5d | 1.2, 1.3 |
| 1.6 | Añadir indicadores UI: Recording indicator + Timer | 0.5d | 1.4 |
| 1.7 | Implementar manejo de errores (storage, permissions) | 0.5d | 1.2 |
| 1.8 | Guardar metadata en session_data.json | 0.5d | 1.3 |
| 1.9 | Voice command "stop" integration | 0.25d | 1.5 |
| 1.10 | **INTEGRATION TEST** - Grabación completa y playback | 0.5d | 1.5, 1.8 |

**Total estimado:** 5 días (margen: +1 día)

### Orden recomendado

1. **Día 1:** Servicios base (Controller + FileStorage) + permisos
2. **Día 2:** Integración UI start/stop + loop básico
3. **Día 3:** UI indicadores + metadata
4. ** Día 4:** Edge cases + errores + voice commands
5. **Día 5:** Testing + polish

---

## 7. Riesgos y Cuellos de Botella

### Riesgos técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| `camera.startVideoRecording()` no funciona en release build | Media | Alto | Test inmediato en device físico con `--release` |
| Video corrupto al mover archivo (permission denied) | Baja | Alto | Usar copy+delete vs rename, con retry |
| Memory leak por CameraController no disposed | Media | Medio | Verificar dispose en todos los exit paths |

### Riesgos operativos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Storage llena sin warning | Baja | Alto | Check storage antes de cada grabación |
| Permisos denegados bloquean todo | Media | Alto | Graceful degradation, screen de settings |

### Costos

- **Storage por clip:** ~10-15MB por minuto en 1080p
- **I/O operations:** ~50ms por save en móvil

---

## 8. Métricas de Éxito

### KPIs técnicos

| Métrica | Target | Validación |
|--------|--------|-----------|
| Grabación de clip | Archivo .mp4 playable en <3s post-stop | Reproducir en video_player |
| Time to first clip | <30s desde start hasta archivo persisted | Log timestamps |
| Error rate | <5% de grabaciones fallen | Crashlytics |
| Memory ceiling | <200MB durante grabación | Native profiling |

### KPIs de negocio

| Métrica | Target |
|--------|-------|
| Usuario completa primera grabación | >80% usuarios que inician |
| Retake rate | <2 takes promedio por fragmento |
| Drop-off en grabación | <15% abandona durante primer take |

---

## 9. Estrategia de Testing

### Unit tests (RecordingController)

```
✓ startRecording() cambia estado a recording
✓ stopRecording() retorna XFile válido
✓ checkAvailableStorage() retorna true cuando >100MB
✓ Timer incrementa cada segundo
```

### Integration tests

```
✓ USER: Grabar → Stop → Clip existe en /clips/ → Playback OK
✓ USER: Grabar → Voice "stop" → Clip existe
✓ USER: Grabar → App killed → Recovery en restart
✓ USER: Storage lleno → Mostrar error → User puede grabar en otro proyecto
```

### Casos críticos a validar

| # | Caso | Esperado |
|---|------|----------|
| 1 | Grabación de 2+ minutos (stress test) | No memory leak, archivo playable |
| 2 | 10 takes consecutivos | Todos guardados con take N |
| 3 | Grabación con airplane mode | Sin efecto (todo local) |
| 4 | Grabación + cambio de app (background) | Continúa en Android, pausar en iOS |
| 5 | Retry después de error de escritura | Recupera correctamente |

---

## 10. Optimización y Escalabilidad Futura

### Problemas que aparecerán al escalar

| Problema |何时会出现 | Solución prep anticipada |
|----------|------------|------------------------|
| Storage lleno dispositivos 16GB | 50+ clips | Cloud sync (V2) |
| Grabación en background limitada | iOS strict mode | Implementar agora (V2) |
| Video stitch lento (>100 clips) | 20+ takes | Pre-allocation de paths |
| Fragmentos desalineados con audio | Latencia alta | Sync de timestamps en stitcher |

### Preparación desde ahora

1. **Namespacing consistente:** Siempre `chunk_{fragment}_take_{n}` - permite query agrupado
2. **Metadata centralizado:** session_data.json con clip references - permite resume
3. **Modular recording logic:** RecordingController aislable para reuse en otros flujos (V2 multi-take)
4. **Separación temp vs final paths:** Recovery de temp si proceso cortado
5. **Async I/O:** No block UI thread durante save - usar isolate o compute si archivo >10MB