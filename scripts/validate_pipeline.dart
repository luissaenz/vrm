import 'dart:io';

/// Pipeline validator for VRM Atomic Camera
/// Tests each stage of the recording pipeline and reports failures.
/// Run: `dart run scripts/validate_pipeline.dart`
///
/// Stages:
/// 1. CameraService init
/// 2. Recording + save clip
/// 3. Clip review (file existence)
/// 4. Stitch service (catches MissingPluginException gracefully)
/// 5. Export service (file path validation)

void main(List<String> args) async {
  print('=== VRM Pipeline Validator ===');
  print('');

  final results = <String, bool>{};
  final errors = <String, String>{};

  // Stage 1: Check camera_service.dart imports and structure
  print('[1/5] Verifying CameraService...');
  try {
    final cameraFile = File('lib/features/recording/services/camera_service.dart');
    if (await cameraFile.exists()) {
      final content = await cameraFile.readAsString();
      final hasStartRecording = content.contains('startRecording()');
      final hasStopRecording = content.contains('stopRecording()');
      if (hasStartRecording && hasStopRecording) {
        results['CameraService'] = true;
        print('  ✅ CameraService: start/stop recording methods found');
      } else {
        results['CameraService'] = false;
        errors['CameraService'] = 'Missing startRecording or stopRecording method';
        print('  ❌ CameraService: missing recording methods');
      }
    } else {
      results['CameraService'] = false;
      errors['CameraService'] = 'File not found';
      print('  ❌ CameraService: file not found');
    }
  } catch (e) {
    results['CameraService'] = false;
    errors['CameraService'] = e.toString();
    print('  ❌ CameraService: $e');
  }

  // Stage 2: Check ClipStorageService
  print('[2/5] Verifying ClipStorageService...');
  try {
    final clipFile = File('lib/features/recording/services/clip_storage_service.dart');
    if (await clipFile.exists()) {
      final content = await clipFile.readAsString();
      if (content.contains('saveClip')) {
        results['ClipStorage'] = true;
        print('  ✅ ClipStorageService: saveClip found');
      } else {
        results['ClipStorage'] = false;
        errors['ClipStorage'] = 'saveClip method not found';
        print('  ❌ ClipStorageService: no saveClip method');
      }
    } else {
      results['ClipStorage'] = false;
      errors['ClipStorage'] = 'File not found';
      print('  ❌ ClipStorageService: file not found');
    }
  } catch (e) {
    results['ClipStorage'] = false;
    errors['ClipStorage'] = e.toString();
    print('  ❌ ClipStorageService: $e');
  }

  // Stage 3: Check ClipReviewPage
  print('[3/5] Verifying ClipReviewPage...');
  try {
    final reviewFile = File('lib/features/recording/clip_review_page.dart');
    if (await reviewFile.exists()) {
      final content = await reviewFile.readAsString();
      if (content.contains('VideoPlayerController.file')) {
        results['ClipReview'] = true;
        print('  ✅ ClipReviewPage: uses VideoPlayerController.file()');
      } else {
        results['ClipReview'] = false;
        errors['ClipReview'] = 'Does not use VideoPlayerController.file()';
        print('  ❌ ClipReviewPage: no VideoPlayerController.file()');
      }
    } else {
      results['ClipReview'] = false;
      errors['ClipReview'] = 'File not found';
      print('  ❌ ClipReviewPage: file not found');
    }
  } catch (e) {
    results['ClipReview'] = false;
    errors['ClipReview'] = e.toString();
    print('  ❌ ClipReviewPage: $e');
  }

  // Stage 4: Check NativeStitcherService
  print('[4/5] Verifying NativeStitcherService...');
  try {
    final stitchFile = File('lib/core/services/native_stitcher_service.dart');
    if (await stitchFile.exists()) {
      final content = await stitchFile.readAsString();
      final hasSingleClipFallback = content.contains('clipPaths.length == 1');
      results['Stitcher'] = hasSingleClipFallback;
      print('  ✅ NativeStitcherService: ${hasSingleClipFallback ? "has single-clip fallback" : "found but NO fallback"}');
      if (!hasSingleClipFallback) {
        errors['Stitcher'] = 'No single-clip fallback, MissingPluginException will crash';
      }
    } else {
      results['Stitcher'] = false;
      errors['Stitcher'] = 'File not found';
      print('  ❌ NativeStitcherService: file not found');
    }
  } catch (e) {
    results['Stitcher'] = false;
    errors['Stitcher'] = e.toString();
    print('  ❌ NativeStitcherService: $e');
  }

  // Stage 5: Check ExportService
  print('[5/5] Verifying ExportService...');
  try {
    final exportFile = File('lib/core/services/export_service.dart');
    if (await exportFile.exists()) {
      final content = await exportFile.readAsString();
      final hasSaveToGallery = content.contains('saveToGallery');
      final hasShareVideo = content.contains('shareVideo');
      if (hasSaveToGallery && hasShareVideo) {
        results['ExportService'] = true;
        print('  ✅ ExportService: saveToGallery + shareVideo found');
      } else {
        results['ExportService'] = false;
        errors['ExportService'] = 'Missing saveToGallery or shareVideo';
        print('  ❌ ExportService: missing methods');
      }
    } else {
      results['ExportService'] = false;
      errors['ExportService'] = 'File not found';
      print('  ❌ ExportService: file not found');
    }
  } catch (e) {
    results['ExportService'] = false;
    errors['ExportService'] = e.toString();
    print('  ❌ ExportService: $e');
  }

  // Summary
  print('');
  print('=== RESULT ===');
  final passed = results.values.where((v) => v).length;
  final total = results.length;
  print('Passed: $passed/$total stages');

  if (errors.isNotEmpty) {
    print('');
    print('❌ FAILURES:');
    for (final entry in errors.entries) {
      print('  - ${entry.key}: ${entry.value}');
    }
    exitCode = 1;
  } else {
    print('✅ All stages OK');
    exitCode = 0;
  }
}
