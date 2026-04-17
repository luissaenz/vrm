import 'package:uuid/uuid.dart';
import '../../../core/models/script_bundle.dart';
import '../../new_project/models/script_analysis.dart';

/// Servicio encargado de generar guiones basados en plantillas (fallback)
/// cuando la IA no está disponible o falla. Implementa el flujo del Día 9-10.
class ScriptFallbackService {
  static final ScriptFallbackService _instance =
      ScriptFallbackService._internal();
  factory ScriptFallbackService() => _instance;
  ScriptFallbackService._internal();

  final _uuid = const Uuid();

  /// Diccionario de plantillas por objetivo.
  /// placeholders soportados: {{idea}}
  final Map<String, List<String>> _templates = {
    'conectar': [
      '¿Alguna vez has sentido que {{idea}} es todo un reto? Te entiendo perfectamente. Lo cierto es que no estás solo en esto. Al final del día, lo más importante es cómo enfrentamos {{idea}} con una sonrisa y determinación.',
      'Hablemos con el corazón sobre {{idea}}. Es un tema que nos toca a todos de cerca. Quiero que sepas que compartir esto sobre {{idea}} me hace sentir más cerca de ti.',
    ],
    'educar': [
      'Hoy vamos a desglosar qué es {{idea}} y por qué debería importarte. Primero, entendamos la base. Luego, veremos cómo aplicar {{idea}} en tres pasos sencillos. En conclusión, dominar esto te dará una ventaja enorme.',
      '¿Quieres aprender sobre {{idea}}? Aquí tienes la guía rápida. El concepto fundamental de {{idea}} se resume en buscar la eficiencia. Recuerda que la práctica constante de {{idea}} es la clave del maestro.',
    ],
    'vender': [
      '¿Estás cansado de luchar con los resultados de {{idea}}? Tenemos la solución definitiva que estabas buscando. Imagina lo que podrías lograr si {{idea}} dejara de ser un problema. ¡Haz clic ahora y transforma tu experiencia con {{idea}}!',
      'Atención: El secreto de {{idea}} ha sido revelado. No dejes pasar esta oportunidad única de mejorar en {{idea}}. El éxito te espera, solo tienes que dar el paso hoy con nuestro método de {{idea}}.',
    ],
  };

  /// Genera un [ScriptAnalysis] basado en la idea y el objetivo.
  /// Se usa [ScriptAnalysis] para compatibilidad directa con [RecordingPage].
  Future<ScriptAnalysis> generateAnalysis(String idea, String objective) async {
    // Simular latencia de "procesamiento"
    await Future.delayed(const Duration(milliseconds: 1500));

    final templateList =
        _templates[objective.toLowerCase()] ?? _templates['educar']!;
    
    // Selección aleatoria de plantilla
    final template = (List<String>.from(templateList)..shuffle()).first;
    
    final fullText = template.replaceAll('{{idea}}', idea);
    final segments = _segmentToAnalysis(fullText);

    return ScriptAnalysis(
      meta: Meta(
        language: 'es',
        totalSegments: segments.length,
        estimatedDurationSeconds: segments.fold(
            0.0, (sum, item) => sum + item.editMetadata.durationSeconds),
      ),
      segments: segments,
      viability: Viability(
        verdict: 'Alta',
        retentionScore: 0.85,
        summary: 'Guion generado localmente vía fallback.',
      ),
    );
  }

  /// Segmenta el texto en [ScriptSegment] para el teleprompter.
  List<ScriptSegment> _segmentToAnalysis(String text) {
    final regex = RegExp(r'(?<=[.!?])\s+');
    final rawSegments = text.split(regex);
    
    final List<ScriptSegment> finalSegments = [];
    int currentId = 0;

    for (var segment in rawSegments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.length > 120) {
        final subSegments = _splitLongText(trimmed);
        for (var sub in subSegments) {
          finalSegments.add(_buildSegment(currentId++, sub));
        }
      } else {
        finalSegments.add(_buildSegment(currentId++, trimmed));
      }
    }

    return finalSegments;
  }

  ScriptSegment _buildSegment(int id, String text) {
    final duration = _estimateDuration(text);
    return ScriptSegment(
      id: id,
      type: 'content',
      text: text,
      direction: SegmentDirection(
        tone: 'Neutral',
        pauses: '',
        emphasis: '',
      ),
      subtitles: text,
      editMetadata: EditMetadata(
        durationSeconds: duration,
        wpm: (text.split(' ').length / (duration / 60)).roundToDouble(),
      ),
    );
  }

  List<String> _splitLongText(String text) {
    if (text.contains(',')) {
      final parts = text.split(RegExp(r',\s*'));
      return parts.where((p) => p.trim().isNotEmpty).toList();
    }
    final words = text.split(' ');
    final mid = (words.length / 2).floor();
    return [
      words.sublist(0, mid).join(' '),
      words.sublist(mid).join(' '),
    ];
  }

  double _estimateDuration(String text) {
    final wordCount = text.split(' ').length;
    final estimated = wordCount / 2.5;
    return estimated < 3.0 ? 3.0 : estimated;
  }

  /// Helper para convertir un [ScriptAnalysis] a [ScriptBundle] para el Pipeline.
  ScriptBundle toBundle(ScriptAnalysis analysis) {
    return ScriptBundle(
      scriptId: _uuid.v4(),
      totalChunks: analysis.segments.length,
      chunks: analysis.segments.map((s) {
        return ScriptChunk(
          order: s.id,
          text: s.text,
          estimatedDurationSec: s.editMetadata.durationSeconds,
          emotionalTone: s.direction.tone,
        );
      }).toList(),
    );
  }
}
