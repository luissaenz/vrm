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

  @override
  String get step2Title => 'PASO 2: VALIDA LOS FRAGMENTOS';

  @override
  String get next => 'SIGUIENTE';

  @override
  String get reRecord => 'REGRABAR';

  @override
  String get preparation => 'PREPARACIÓN';

  @override
  String get listening => 'ESCUCHANDO...';

  @override
  String get systemReads => 'EL SISTEMA LEE EL GUION:';

  @override
  String get getReady => 'PREPÁRATE';

  @override
  String get repeat => 'REPETIR';

  @override
  String get record => 'GRABAR';

  @override
  String get waiting => 'ESPERANDO...';

  @override
  String get voiceControlDisabled => 'Control por voz desactivado';

  @override
  String get recordingStatus => 'GRABANDO';

  @override
  String get listeningToAdvance => 'Escuchando voz para avanzar...';

  @override
  String get gridLabel => 'GRID';

  @override
  String get ghostLabel => 'GHOST';

  @override
  String get welcomeTitle => 'BIENVENIDA';

  @override
  String get welcomeHeadline => '¿Cuál es tu mayor obstáculo hoy?';

  @override
  String get welcomeCta => 'COMENZAR';

  @override
  String get identityHeadline => 'Elige tu Identidad';

  @override
  String get identitySubheadline =>
      'Toca el espejo que mejor refleje tu propósito hoy';

  @override
  String get identityConfirm => 'CONFIRMAR IDENTIDAD';

  @override
  String get configTitle => 'Configuración Personalizada';

  @override
  String get configGreetingLeader =>
      '\"Bienvenido. He configurado la app en Modo Eficiencia. Tus guiones serán concisos y la IA eliminará tus silencios automáticamente.\"';

  @override
  String get configGreetingInfluencer =>
      '\"¡Hola! He activado el Modo Flow. La app te avisará si tu sonrisa o contacto visual caen. Vamos a hacer que se enamoren de tu contenido.\"';

  @override
  String get configGreetingSeller =>
      '\"Listo. He cargado plantillas de Elevator Pitch y guiones de ventas probados. Tu objetivo es la claridad.\"';

  @override
  String get configGreetingDefault => '\"Estamos listos para empezar.\"';

  @override
  String get configSummaryLabel => 'RESUMEN DE CONFIGURACIÓN';

  @override
  String get configTeleprompterLabel => 'Velocidad sugerida para tu perfil';

  @override
  String get configCta => 'CREAR MI PRIMER VIDEO';

  @override
  String get configFooterLabel => 'PULSA PARA INICIAR TU EXPERIENCIA';

  @override
  String get profileLeaderTitle => 'Líder';

  @override
  String get profileLeaderTag => 'EFICACIA';

  @override
  String get profileLeaderQuote => '\"Tengo poco tiempo\"';

  @override
  String get profileInfluencerTitle => 'Influencer';

  @override
  String get profileInfluencerTag => 'ENERGÍA';

  @override
  String get profileInfluencerQuote => '\"Quiero conectar\"';

  @override
  String get profileSellerTitle => 'Vendedor';

  @override
  String get profileSellerTag => 'CONFIANZA';

  @override
  String get profileSellerQuote => '\"Necesito vender\"';

  @override
  String get configSolutionLeaderTitle => 'Toma 1 Minuto';

  @override
  String get configSolutionLeaderSubtitle => 'Grabaciones rápidas y perfectas';

  @override
  String get configSolutionInfluencerTitle => 'Encuentra tu Voz';

  @override
  String get configSolutionInfluencerSubtitle =>
      'Crea una comunidad que te ame';

  @override
  String get configSolutionSellerTitle => 'Claridad Absoluta';

  @override
  String get configSolutionSellerSubtitle =>
      'Convierte espectadores en clientes';

  @override
  String get configSolutionDefaultTitle => 'Solución Optimizada';

  @override
  String get configSolutionDefaultSubtitle => 'Configuración personalizada';

  @override
  String get configPremiumLeaderTitle => 'Modo \"Magic Edit\"';

  @override
  String get configPremiumLeaderSubtitle => 'Video listo en 30 segundos';

  @override
  String get configPremiumInfluencerTitle => 'Filtros de \"Carisma\"';

  @override
  String get configPremiumInfluencerSubtitle => 'Análisis de tono emocional';

  @override
  String get configPremiumSellerTitle => 'Teleprompter de Venta';

  @override
  String get configPremiumSellerSubtitle => 'Scripts premium incluidos';

  @override
  String get configPremiumDefaultTitle => 'Funciones Premium';

  @override
  String get configPremiumDefaultSubtitle => 'Desbloquea todo el potencial';

  @override
  String profileTeleprompterLeader(String ppm) {
    return 'Teleprompter Rápido ($ppm ppm)';
  }

  @override
  String profileTeleprompterInfluencer(String ppm) {
    return 'Teleprompter Dinámico ($ppm ppm)';
  }

  @override
  String profileTeleprompterSeller(String ppm) {
    return 'Teleprompter Persuasivo ($ppm ppm)';
  }

  @override
  String get welcomeCoachImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDtnj9X_8A4fpoltWeeCfJjOfdRir4lvqGiqtmMoT9Hvmws0Aq5DKAZCFTa9kXP_wgcDvg8PTDqEzCFC3zFii1Veuisu0XyAs9IOo0zP1n_QGqG1XnhUWb56CkgWZFSuxlcpsJtwkYwOP5ge53hCLRFqDiuBvmfFjY0vE1fNtLvZx3ZRMPsDPqcISCDlgnLfuVNNvfOC-Xo2Avc5bsJ4x6WTihF_dDNwh_ZMzgcGLr31IjmjExdO2MegRAE0LM3QxLehYpyI7bLo8dl';

  @override
  String get profileLeaderImage =>
      'https://images.unsplash.com/photo-1519085185750-7697655d7e74?q=80&w=1000&auto=format&fit=crop';

  @override
  String get profileInfluencerImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfHM-MBerpZJQCw1G3xkyUzZFtWHm1-mXt_BzAN78Zz5-iUC5HLbaQ6Hsf0u8oYKDUVO__A18MIz3ySJH3ssZ1G17Z5raOAK1hVKQNdfj8_ei7kjmmWZ_lDM2t3nzH5wHp8JrcbyyoH_1IGK7erPct4eaNzbgBsqenPoZe2CZi63PE8ftlb6WRkOIA8OKzqKwVeUwL-S_7Rl7pV0666CS5a1g1zTZAWo6DpQ6i06jyEngNHa-BVG39DOOc1Eq6XNMsziDBwVAn3qZ';

  @override
  String get profileSellerImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAbHlQa2OUJlKn6gBpuhTPrs-Q0_qAIgIDsINsGm2LfDF76YoL3utRhVCQZBt6pFvVeMUMvQuAg_7-LwLeCMFJnJQ4l18fMu-jUX1w15MZt7mxklAwpcg1L6vUWXRZn2xc81UNL7g2IqMrNhBTCXDe9Y18yO1iYbt8tc8jU4KDoFeLKt5_qsgWKoGerm2puw0hCjNqb0TfvxixhDpay7OjTLm-u4IRnf_IbJ-Ezo-hvh5e4YPu2lHJS9o03e05lK4IxuPyCXfoCCU4d';
}
