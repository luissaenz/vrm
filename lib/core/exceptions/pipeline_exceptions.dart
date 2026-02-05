/// Base exception for pipeline-related errors
class PipelineException implements Exception {
  final String message;
  final dynamic cause;
  final StackTrace? stackTrace;

  PipelineException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    if (cause != null) {
      return 'PipelineException: $message\nCaused by: $cause';
    }
    return 'PipelineException: $message';
  }
}

/// Exception thrown when a plugin fails during execution
class PluginException extends PipelineException {
  final String pluginId;
  final String stage;

  PluginException({
    required this.pluginId,
    required this.stage,
    required String message,
    dynamic cause,
    StackTrace? stackTrace,
  }) : super(
         'Plugin "$pluginId" failed at stage "$stage": $message',
         cause: cause,
         stackTrace: stackTrace,
       );
}

/// Exception thrown when input validation fails
class ValidationException extends PipelineException {
  final Map<String, dynamic>? invalidData;
  final List<String>? errors;

  ValidationException({required String message, this.invalidData, this.errors})
    : super(message);

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (errors != null && errors!.isNotEmpty) {
      buffer.write('\nValidation errors:\n');
      for (final error in errors!) {
        buffer.write('  - $error\n');
      }
    }
    return buffer.toString();
  }
}

/// Exception thrown when configuration is invalid
class ConfigurationException extends PipelineException {
  final String configKey;

  ConfigurationException({required this.configKey, required String message})
    : super('Invalid configuration for "$configKey": $message');
}

/// Exception thrown when persistence operations fail
class PersistenceException extends PipelineException {
  final String operation;
  final String? projectId;

  PersistenceException({
    required this.operation,
    this.projectId,
    required String message,
    dynamic cause,
  }) : super(
         'Persistence operation "$operation" failed${projectId != null ? ' for project $projectId' : ''}: $message',
         cause: cause,
       );
}
