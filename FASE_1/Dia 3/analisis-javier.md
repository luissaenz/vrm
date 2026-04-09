# Análisis Técnico: FASE 1 - Día 3 (Revisión Visual de Clips)

## 1. Comprensión del Paso

### Problema que resuelve
Permitir al usuario validar visualmente el clip grabado antes de proceder al siguiente fragmento del guion. Es un "feedback loop" crítico donde el creador decide: aprobar (avanzar) o re-grabar (repetir).

### Inputs
- `clipPath`: Ruta absoluta del archivo `.mp4` generado (`.../clips/chunk_X_take_Y.mp4`)
- `chunkIndex`: Índice actual del fragmento en el guion
- `totalChunks`: Total de fragmentos a grabar
- `scriptAnalysis`: Objeto con el guion analizado (para mostrar contexto)

### Outputs
- **Aprobado**: Navegación al siguiente chunk (o a Stitcher si es el último)
- **Re-grabar**: Retorno a `RecordingPage` con el mismo `chunkIndex`, eliminando el clip defectuoso

### Rol en el sistema
Es el punto de bifurcación después de cada grabación. Conecta la fase de grabación (Día 1-2) con la fase de stitching (Día 4-5).

---

## 2. Supuestos y Ambigüedades

### Críticas
1. **¿El VideoPlayer reproduce automáticamente?** El documento menciona "auto-play en loop", pero no especifica el comportamiento inicial (mute por defecto, primeras pruebas de audio, etc.)
2. **¿Qué sucede si el clip está corrupto o tiene 0 bytes?** El análisis existente sugiere forzar retorno a cámara, pero no define el mensaje de error al usuario
3. **¿Cómo se maneja el silencio forzado de iOS?** El switch Ring/Silent puede silenciar el VideoPlayer - ¿se implementa `audio_session` para forzar audio?
4. **¿Navegación o reinstanciación?** ¿Se usa `Navigator.pushReplacement` o se reinstancia `RecordingPage` completamente?
5. **¿Cuántas re-grabaciones permite el usuario?** ¿Hay un límite o es ilimitado?

### Preguntas de diseño
- ¿El usuario puede reproducir el clip manualmente, o solo hay loop automático?
- ¿Hay controles de scrub (barra de progreso) para revisar segmentos específicos?
- ¿Se muestra el texto del guion debajo del video para contexto?

---

## 3. Diseño Funcional

### Flujo Principal (Pipeline)

```
[RecordingPage] → graba clip → stopRecording() → saveClip()
        ↓
   ClipReviewScreen (auto-instanciada post-stop)
        ↓
   ┌────┴────┐
   ↓          ↓
[Repetir]  [Aprobar]
   ↓          ↓
Delete clip  Guardar path en script_bundle
Return to    Advance to next chunk
RecordingPage
```

### Casos Normales
1. **Aprobación directa**: Usuario ve el loop 1-2 veces → toca "Aprobar" → siguiente fragmento
2. **Re-grabación**: Usuario toca "Repetir" → clip se elimina → retorna a cámara con mismo índice

### Edge Cases
| Escenario | Comportamiento |
|-----------|-----------------|
| Archivo corrupto (0 bytes) | Mostrar mensaje de error, botar automáticamente a re-grabación |
| VideoPlayer falla al inicializar | Pantalla de error con opción de re-grabar |
| storage lleno | Prevenir grabación, mostrar alerta antes de llegar a review |
| Usuario cierra la app durante review | Persistir estado en session_data.json |
| Último chunk aprobado | Redirigir a pantalla de stitching o fin |

### Manejo de Errores
- **Inicialización fallida del VideoPlayer**: Mostrar UI de error con "Regrabar" como única opción
- **Archivo no encontrado**: same as corrupt - redirigir a re-grabación
- **Fallo al eliminar archivo en Retake**: Log warning, continuar navegación de todas formas

---

## 4. Diseño Técnico

### Arquitectura
- **Widget**: `ClipReviewScreen` (nueva página)
- **State Management**: Provider/ChangeNotifier (`ClipReviewNotifier`)
- **Navegación**: GoRouter o `Navigator.pushReplacement` (eliminar stack de review)

### Componentes Involucrados
```
ClipReviewScreen
├── VideoPlayer widget (video_player package)
├── Controls overlay (play/pause, scrub)
├── Decision buttons (Approve/Retake)
└── Script context (texto del chunk actual)

ClipReviewNotifier (State)
├── clipPath: String
├── chunkIndex: int
├── isPlaying: bool
├── position: Duration
└── métodos: approve(), retake(), togglePlay()
```

### APIs / Endpoints
No hay endpoints HTTP. Es 100% local.

### Modelos de Datos

```dart
// ClipReviewState
class ClipReviewState {
  final String clipPath;           // /path/to/chunk_0_take_1.mp4
  final int chunkIndex;            // 0-based
  final int totalChunks;           // e.g., 5
  final ScriptSegment currentSegment; // texto del chunk
  final ReviewDecision? decision;  // null hasta que usuario decide
  final bool isVideoInitialized;
  final String? errorMessage;
}

enum ReviewDecision { approved, retake }

// script_bundle.json (actualización post-aprobación)
{
  "chunks": [
    { "index": 0, "validTake": "/path/to/chunk_0_take_1.mp4" },
    { "index": 1, "validTake": null }  // pending
  ]
}
```

### Integraciones
- `video_player: ^2.8.0` - reproducción local
- `dart:io` - eliminación de archivos (File.deleteSync)
- `path_provider` - acceso a directorios

---

## 5. Decisiones Tecnológicas

### Librería Base
- **video_player: ^2.8.0** (oficial) - NO chewie ni paquetes terceros que agreguen weight innecesario
- **Justificación**: Botones custom son triviales de implementar, el wrapper de chewie añade ~500KB innecesarios

### Decisión Pendiente (requiere resolución antes de coding)
| Decisión | Opción 1 (Recomendada) | Opción 2 |
|----------|----------------------|----------|
| Audio forzado en iOS | Usar `audio_session` package | Ignorar - user ajusta volumen manualmente |
| Loop behavior | Auto-loop until interaction | One-shot + play button visible |
| Delete strategy | Hard delete inmediato | Soft delete (mover a .trash) |
| Navigation | pushReplacement | pop + push nuevo |

---

## 6. Plan de Implementación

### Backlog Técnico (orden recomendado)

#### Tarea 1: Estructura de ClipReviewScreen (0.5h)
- Crear archivo `lib/features/recording/clip_review_screen.dart`
- Definir constructor con params requeridos: clipPath, chunkIndex, totalChunks, scriptAnalysis
- Scaffold básico con fondo negro

#### Tarea 2: VideoPlayer Integration (1h)
- Inicializar `VideoPlayerController.file(File(clipPath))` en initState
- Mostrar `FutureBuilder` con indicador de carga hasta `controller.value.isInitialized`
- Widget `VideoPlayer(controller)` con AspectRatio

#### Tarea 3: UI de Controles (1h)
- Overlay con botones Approve (✓) y Retake (↻)
- Indicador de progreso "Fragmento X de Y"
- Texto del chunk actual (mini teleprompter)
- Auto-play loop con muted initial

#### Tarea 4: Lógica de Decisión (1h)
- Implementar `onApprove()`: guardar path en script_bundle.json, navegar siguiente
- Implementar `onRetake()`: eliminar archivo, navegar a RecordingPage con mismo índice
- Validar archivo existente antes de mostrar UI

#### Tarea 5: Cleanup y Edge Cases (0.5h)
- Override dispose() - dispose controller explícitamente
- Manejo de errores de inicialización (try/catch en initialize)
- Feedback visual durante procesamiento

#### Tarea 6: Integración con RecordingPage (0.5h)
- Modificar `_stopRecording()` en recording_page.dart para navegar a ClipReviewScreen automáticamente
- Pasar el path del clip guardado como argumento

### Dependencias entre tareas
- Tareas 1 → 2 → 3: Secuencial (UI depende de controller)
- Tarea 4 requiere Tareas 1-3 completas
- Tarea 5 es cross-cutting
- Tarea 6 depende de Tareas 1-5 (no puede integrar sin tener la screen)

**Total estimado: 4.5 horas**

---

## 7. Riesgos y Cuellos de Botella

### Técnicos
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Memory leak por VideoPlayer no dispose | ALTA | ALTO | Verificación obligatoria en code review |
| Navegación genera stack overflow | MEDIA | MEDIO | Usar pushReplacement siempre |
| Archivo corrupto no detectable | BAJA | ALTO | Verificar size > 0 en ClipStorageService (ya existe) |
| Black screen al cargar video | MEDIA | MEDIO | Mostrar loader hasta isInitialized true |

### Operativos
- El usuario no tiene forma de "ir hacia atrás" una vez aprobado un chunk - problema menor, flow es lineal
- No hay undo después de aprobar

### Escalabilidad
- Para clips > 30 segundos, el tiempo de carga aumenta - considerar pre-carga en background
- Videos 4K pueden ser problemáticos en reproducción - opcional: transcodificar a 1080p antes de guardar (postergación a V2)

### Costos
- Ninguno adicional - todo es local, no hay APIs externos

---

## 8. Métricas de Éxito

### KPIs Técnicos
- **Time-to-first-frame**: < 500ms desde que entra a la screen
- **Memoria**: No increment > 50MB entre grabaciones repetidas (test de stress)
- **Crash rate**: 0% en initialization de video

### KPIs de Negocio
- **Conversion**: % de usuarios que pasan de review a siguiente chunk en primer intento
- **Retake rate**: % de clips que requieren re-grabación (indicador de calidad de recording)

### Validación
- Ejecución manual: 10 grabaciones completas de 3-5 chunks cada una
- Validar que no haystack trace en logs después de 20 iteraciones recording→review→retake

---

## 9. Estrategia de Testing

### Unit Tests
```dart
// Test: Decision approve guarda path correctamente
test('approve saves clip path to script_bundle', () {
  final notifier = ClipReviewNotifier(...);
  await notifier.approve();
  expect(scriptBundle.chunks[0].validTake, isNotNull);
});

// Test: Retake elimina archivo físico
test('retake deletes physical file', () async {
  final notifier = ClipReviewNotifier(...);
  await notifier.retake();
  expect(File(clipPath).existsSync(), false);
});

// Test: Video initialization failure handling
test('shows error when video init fails', () async {
  final notifier = ClipReviewNotifier(clipPath: '/invalid/path.mp4');
  await notifier.initializeVideo();
  expect(notifier.errorMessage, isNotNull);
});
```

### Integration Tests
- **Flow completo**: Grabar → Review → Approve → Siguiente chunk → Final
- **Stress test**: 20 ciclos recording→review→retake sin memory leak

### Casos Críticos a Validar
1. Video corrupto (0 bytes) - debe mostrar error y permitir re-grabar
2. Usuario presiona Approve dos veces rápidamente - debe manejar idempotencia
3. Navegación hacia atrás desde review - debe mantener estado correcto
4. App matada durante review - al reopen debe poder continuar o estar en estado consistente

---

## 10. Optimización y Escalabilidad Futura

### Problemas que aparecerán al escalar
1. **Clips 4K**: Reproducción lenta en dispositivos low-end
   - Solución V2: Transcodificar a 1080p en segundo plano usando FFmpeg antes de guardar
2. **Videos largos (>1 min)**: Buffering visible
   - Solución V2: Pre-cargar próximo chunk mientras usuario revisa actual
3. **Edición de clip**: Usuario quiere cortar principio/fin
   - Solución V2: Agregar trim UI con range selector

### Preparación desde ahora
- Arquitectura permitiría inyección de diferentes video sources (no hardcodear File)
- El script_bundle.json ya soporta metadata extendida para agregar datos de trim en V2
- Evitar strongly coupled navigation - usar callback pattern o router para facilitar cambios

---

## Notas Adicionales

- El análisis existente (analisis-antigravity.md) ya capturó la mayoría de puntos técnicos correctos
- Este análisis añade: roadmap de implementación, métricas de éxito, estrategia de testing detallada
- La principal ambigüedad pendiente es el manejo del mute en iOS - resolver antes de coding