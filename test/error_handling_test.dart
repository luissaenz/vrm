import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/core/exceptions/pipeline_exceptions.dart';
import 'package:vrm_app/core/pipeline/pipeline_factory.dart';

void main() {
  group('Pipeline Error Handling Tests', () {
    test('Pipeline throws PluginException on plugin failure', () async {
      final pipeline = PipelineFactory.createDefaultPipeline();

      // Invalid params should cause plugin to fail
      expect(
        () => pipeline.executeScriptOnly({}),
        throwsA(isA<PluginException>()),
      );
    });

    test('PluginException contains plugin metadata', () async {
      final pipeline = PipelineFactory.createDefaultPipeline();

      try {
        await pipeline.executeScriptOnly({});
        fail('Should have thrown PluginException');
      } catch (e) {
        expect(e, isA<PluginException>());
        final pluginError = e as PluginException;
        expect(pluginError.pluginId, isNotEmpty);
        expect(pluginError.stage, equals('idea_ingestion'));
      }
    });

    test('executeScriptOnly succeeds with valid params', () async {
      final pipeline = PipelineFactory.createDefaultPipeline();

      final result = await pipeline.executeScriptOnly({
        'topic': 'Test Topic',
        'context': 'Test context',
      });

      expect(result.chunks, isNotEmpty);
    });
  });

  group('Exception Hierarchy Tests', () {
    test('PipelineException formats message with cause', () {
      final exception = PipelineException(
        'Test failed',
        cause: Exception('Original error'),
      );

      expect(exception.toString(), contains('Test failed'));
      expect(exception.toString(), contains('Original error'));
    });

    test('ValidationException includes error list', () {
      final exception = ValidationException(
        message: 'Invalid input',
        errors: ['Field required', 'Invalid format'],
      );

      final message = exception.toString();
      expect(message, contains('Invalid input'));
      expect(message, contains('Field required'));
      expect(message, contains('Invalid format'));
    });

    test('ConfigurationException includes config key', () {
      final exception = ConfigurationException(
        configKey: 'script_processor',
        message: 'Unknown processor type',
      );

      expect(exception.toString(), contains('script_processor'));
      expect(exception.toString(), contains('Unknown processor type'));
    });
  });
}
