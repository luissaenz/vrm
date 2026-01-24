// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'VRM App';

  @override
  String get goodMorning => 'BUENOS DÍAS,';

  @override
  String get creator => 'Alex Rivera';

  @override
  String get streak => 'Racha';

  @override
  String days(String count) {
    return '$count Días';
  }

  @override
  String get clips => 'Clips';

  @override
  String get newProject => 'Nuevo Proyecto';

  @override
  String get voiceControlActive => 'Control por voz activado';

  @override
  String get recentProjects => 'Proyectos Recientes';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get readyToCreate => '¿Listo para crear?';

  @override
  String get captureIdeas => 'Captura tus ideas, un fragmento a la vez.';

  @override
  String get streakLabel => 'RACHA DE\nGRABACIÓN';

  @override
  String get fragments => 'FRAGMENTOS';

  @override
  String get calendar => 'Calendario';

  @override
  String get panel => 'PANEL';

  @override
  String get videos => 'VIDEOS';

  @override
  String get script => 'SCRIPT';

  @override
  String get profile => 'PERFIL';

  @override
  String get draft => 'BORRADOR';

  @override
  String get ready => 'LISTO';

  @override
  String get wed => 'MIE';

  @override
  String get thu => 'JUE';

  @override
  String get fri => 'VIE';

  @override
  String get sat => 'SAB';

  @override
  String get progressLabel => 'PROGRESO';

  @override
  String get editedYesterday => 'Editado ayer';

  @override
  String editedHoursAgo(String count) {
    return 'Editado hace $count horas';
  }

  @override
  String fragmentCount(String current, String total) {
    return '$current/$total Fragmentos';
  }

  @override
  String get newProjectTitle => 'Nuevo Proyecto';

  @override
  String get step1Title => 'PASO 1: ESCRIBE O PEGA TU GUION';

  @override
  String charactersCount(String count) {
    return '$count caracteres';
  }

  @override
  String secondsAbbreviation(String seconds) {
    return '${seconds}s';
  }

  @override
  String totalTimeEstimate(String seconds) {
    return 'duración aproximada $seconds';
  }

  @override
  String get assistant => 'ASISTENTE';

  @override
  String get optimize => 'OPTIMIZAR CON IA';

  @override
  String get fragmentPreview => 'VISTA PREVIA DE FRAGMENTOS';

  @override
  String blocksCount(int count) {
    return '$count BLOQUES';
  }

  @override
  String get splitIntoFragments => 'Dividir en Fragmentos';

  @override
  String get paste => 'Pegar';

  @override
  String get segment => 'SEGMENTAR';

  @override
  String get scriptAssistantTitle => 'Asistente de Guion';

  @override
  String get defineIdea => 'Define tu Idea';

  @override
  String get iaHelperText =>
      'La IA te ayudará a estructurar el contenido perfecto.';

  @override
  String get videoIdeaLabel => 'IDEA DEL VIDEO';

  @override
  String get videoIdeaPlaceholder =>
      'Ej: Un video sobre cómo organizar tu escritorio para ser más productivo en 5 pasos...';

  @override
  String get suggestedStructures => 'Estructuras sugeridas';

  @override
  String get premiumAi => 'PREMIUM AI';

  @override
  String get hookTitle => 'Introducción / Hook';

  @override
  String get hookDesc =>
      'Engancha a tu audiencia en los primeros 3 segundos con un problema común.';

  @override
  String get valueTitle => 'Desarrollo de Valor';

  @override
  String get valueDesc =>
      'Divide tu explicación en 3 puntos clave accionables y fáciles de seguir.';

  @override
  String get ctaTitle => 'Cierre (CTA)';

  @override
  String get ctaDesc =>
      'Pide a tus seguidores que den like y compartan el contenido.';

  @override
  String get generateFullScript => 'Generar Guion Completo';

  @override
  String get poweredByAi => 'POTENCIADO POR IA DE ÚLTIMA GENERACIÓN';
}
