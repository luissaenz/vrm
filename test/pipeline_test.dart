import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/core/pipeline/pipeline_factory.dart';

void main() {
  group('VRM Pipeline Integration Tests', () {
    test('Default pipeline executes script processing successfully', () async {
      // Arrange
      final pipeline = PipelineFactory.createDefaultPipeline();
      final params = {
        'topic': 'Cómo crear contenido viral en 2026',
        'context':
            'En este video voy a enseñarte las mejores estrategias para crear contenido que realmente funcione en redes sociales.',
      };

      // Act
      final scriptBundle = await pipeline.executeScriptOnly(params);

      // Assert
      expect(scriptBundle.chunks, isNotEmpty);
      expect(scriptBundle.totalChunks, equals(scriptBundle.chunks.length));
      expect(scriptBundle.chunks.first.order, equals(1));
      expect(scriptBundle.chunks.first.text, isNotEmpty);
    });

    test('Pipeline factory creates different configurations', () {
      // Arrange & Act
      final defaultPipeline = PipelineFactory.createDefaultPipeline();
      final backendPipeline = PipelineFactory.createBackendPipeline();

      // Assert
      expect(
        defaultPipeline.scriptProcessor.pluginId,
        equals('template_script_v1'),
      );
      expect(
        backendPipeline.scriptProcessor.pluginId,
        equals('backend_api_v1'),
      );
    });

    test('Pipeline from config allows runtime plugin selection', () {
      // Arrange
      final configDefault = {'script_processor': 'template_script_v1'};
      final configBackend = {'script_processor': 'backend_api_v1'};

      // Act
      final pipelineDefault = PipelineFactory.createFromConfig(configDefault);
      final pipelineBackend = PipelineFactory.createFromConfig(configBackend);

      // Assert
      expect(
        pipelineDefault.scriptProcessor.pluginId,
        equals('template_script_v1'),
      );
      expect(
        pipelineBackend.scriptProcessor.pluginId,
        equals('backend_api_v1'),
      );
    });

    test('Manual input plugin validates params correctly', () async {
      // Arrange
      final pipeline = PipelineFactory.createDefaultPipeline();

      // Act & Assert - Valid params
      final validParams = {'topic': 'Test topic'};
      expect(pipeline.ideaSource.validateParams(validParams), isTrue);

      // Act & Assert - Invalid params (missing topic)
      final invalidParams = {'context': 'Some context'};
      expect(pipeline.ideaSource.validateParams(invalidParams), isFalse);

      // Act & Assert - Invalid params (empty topic)
      final emptyParams = {'topic': ''};
      expect(pipeline.ideaSource.validateParams(emptyParams), isFalse);
    });
  });
}
