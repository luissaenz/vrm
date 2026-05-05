# Validación de Memory Leaks — 10 min Grabación Continua

## Prerrequisitos
- Dispositivo físico Android/iOS (emulador no detecta leaks reales)
- Flutter DevTools instalado (`flutter pub global activate devtools`)
- App compilada en profile mode: `flutter run --profile`

## Procedimiento

### 1. Iniciar sesión de prueba
```bash
flutter run --profile
```

### 2. Abrir DevTools
```bash
flutter pub global run devtools
```
Conectar al puerto del dispositivo (ej: `http://127.0.0.1:9100`).

### 3. Iniciar monitoreo
- En DevTools: ir a **Memory** tab
- Click **Record** (grabar línea de tiempo)
- Anotar heap usage inicial

### 4. Ejecutar grabación de 10 minutos
1. En la app: crear nuevo proyecto → generar guion
2. Iniciar grabación (grabar fragmento completo)
3. Dejar grabando durante 10 min continuos
4. Opcional: alternar entre menú de ajustes durante la grabación

### 5. Detener y revisar
- Detener grabación en app
- En DevTools: detener grabación de memoria
- Revisar línea de tiempo:
  - **Heap creciendo constantemente** → posible leak
  - **GC no recupera memoria después de detener** → leak confirmado
  - **Samples > 50MB sin liberar** → investigar

### 6. Criterios de Aprobación
- [ ] Sin crashes durante 10 min continuos
- [ ] Heap usage no crece >30% entre inicio y fin (misma operación)
- [ ] GC reduce heap después de detener grabación
- [ ] MemoryMonitor genera reporte sin warnings de leak
- [ ] LoggerService captura eventos de memoria si ocurren

### 7. Reporte
```bash
dart run scripts/vrm_health_check.dart memory
```
Esto verifica estáticamente que los patrones de dispose estén presentes.
Para detección dinámica, seguir el procedimiento arriba con DevTools.

## Notas
- Si se detectan leaks: revisar `dispose()` en `RecordingPage`, `CameraService`, `RecordingManager`
- `MemoryMonitor` en `lib/features/recording/services/memory_monitor.dart` ayuda en debug
- `didHaveMemoryPressure()` en `RecordingPage` limpia temp automáticamente
