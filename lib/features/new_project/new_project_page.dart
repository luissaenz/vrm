import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../../shared/widgets/script_editor.dart';
import '../fragments/fragment_organization_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../onboarding/data/onboarding_repository.dart';
import './models/script_analysis.dart';
import '../../shared/widgets/widget_progress.dart';
import '../../shared/widgets/widget_estimation.dart';
import '../assistant/script_studio_page.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  final TextEditingController _scriptController = TextEditingController();
  final OnboardingRepository _repository = OnboardingRepository();
  bool _isLoading = false;

  // Parámetros de ritmo dinámicos
  double _segmentRateWpm = 160.0;

  @override
  void initState() {
    super.initState();
    _scriptController.addListener(() => setState(() {}));
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final profile = await _repository.getUserProfile();
    if (mounted) {
      setState(() {
        _segmentRateWpm = profile.segmentRateWpm;
      });
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _optimizeScript() async {
    if (_scriptController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Obtener la identidad del usuario (para uso futuro con API)
      // final profile = await _repository.getUserProfile();
      // final profileId = ApiService.mapIdentityToProfileId(profile.identity);

      /* 
      // 2. Llamar API Real
      final response = await ApiService.post(
        'script/analyze-and-segment',
        payload: {
          "profile_id": profileId,
          "SCRIPT": _scriptController.text,
          "segment_minTime": _segmentMinTime,
          "segment_maxTime": _segmentMaxTime,
          "segment_RateWpm": _segmentRateWpm,
          "send_to_ai": true,
        },
      );

      // 3. Procesar respuesta
      if (response['ai_response'] != null &&
          response['ai_response']['content'] != null) {
        final analysisJson = response['ai_response']['content'];
        final decodedAnalysis = analysisJson is String
            ? Map<String, dynamic>.from(jsonDecode(analysisJson))
            : Map<String, dynamic>.from(analysisJson);

        final analysis = ScriptAnalysis.fromJson(decodedAnalysis);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FragmentOrganizationPage(analysis: analysis),
            ),
          );
        }
      }
      */

      // MOCK PARA DESARROLLO RÁPIDO
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simular latencia mínima

      final mockResponse = {
        "meta": {
          "language": "es",
          "total_segments": 8,
          "estimated_duration_seconds": 39.75,
        },
        "segments": [
          {
            "id": 1,
            "type": "hook",
            "text":
                "Hay una estrategia para adquirir clientes que pocos usan y se llama Content Pillars.",
            "direction": {
              "tone": "intrigante, confidencial",
              "pauses": "'clientes','Content Pillars'",
              "emphasis": "'pocos usan','Content Pillars'",
            },
            "subtitles":
                "Hay una estrategia para adquirir clientes\nque POCOS USAN\n\nSe llama CONTENT PILLARS",
            "edit_metadata": {"duration_seconds": 4.125, "wpm": 160},
          },
          {
            "id": 2,
            "type": "context",
            "text": "Se basa en dividir tu contenido en tres pilares claros.",
            "direction": {
              "tone": "explicativo, claro",
              "pauses": "'contenido'",
              "emphasis": "'tres pilares claros'",
            },
            "subtitles":
                "Se basa en DIVIDIR tu contenido\nen TRES PILARES CLAROS",
            "edit_metadata": {"duration_seconds": 3.75, "wpm": 160},
          },
          {
            "id": 3,
            "type": "development",
            "text":
                "El primero es Atracción. Acá no hablás de vos. Hablás de los objetivos, miedos y obstáculos de tu audiencia.",
            "direction": {
              "tone": "directo, empático",
              "pauses": "'Atracción','vos'",
              "emphasis": "'no hablás de vos','objetivos, miedos y obstáculos'",
            },
            "subtitles":
                "El primero es ATRACCIÓN\n\nAcá NO HABLÁS DE VOS\n\nHablás de los OBJETIVOS, MIEDOS\ny OBSTÁCULOS de tu audiencia",
            "edit_metadata": {"duration_seconds": 6.0, "wpm": 160},
          },
          {
            "id": 4,
            "type": "development",
            "text": "Este contenido no vende, trae a la gente correcta.",
            "direction": {
              "tone": "convincente, afirmativo",
              "pauses": "'vende'",
              "emphasis": "'no vende','gente correcta'",
            },
            "subtitles": "Este contenido NO VENDE\n\nTrae a la GENTE CORRECTA",
            "edit_metadata": {"duration_seconds": 3.75, "wpm": 160},
          },
          {
            "id": 5,
            "type": "development",
            "text":
                "El segundo pilar es Nutrición. Y esto es clave: repetir tips, repetir ideas, repetir mensajes.",
            "direction": {
              "tone": "enfático, revelador",
              "pauses": "'Nutrición','clave'",
              "emphasis": "'clave','repetir'",
            },
            "subtitles":
                "El segundo pilar es NUTRICIÓN\n\nY esto es CLAVE:\n\nREPETIR tips, REPETIR ideas,\nREPETIR mensajes",
            "edit_metadata": {"duration_seconds": 5.625, "wpm": 160},
          },
          {
            "id": 6,
            "type": "development",
            "text":
                "La repetición genera posicionamiento. Y el posicionamiento genera confianza.",
            "direction": {
              "tone": "lógico, persuasivo",
              "pauses": "'posicionamiento'",
              "emphasis": "'genera posicionamiento','genera confianza'",
            },
            "subtitles":
                "La REPETICIÓN genera POSICIONAMIENTO\n\nY el POSICIONAMIENTO genera CONFIANZA",
            "edit_metadata": {"duration_seconds": 4.5, "wpm": 160},
          },
          {
            "id": 7,
            "type": "development",
            "text":
                "Ahora, el tercer pilar es el que paga las cuentas: Venta. Acá el contenido no vende en el post. El contenido lleva la conversación al inbox o a WhatsApp.",
            "direction": {
              "tone": "directo, práctico",
              "pauses": "'cuentas','Venta','post'",
              "emphasis":
                  "'paga las cuentas','no vende en el post','inbox o WhatsApp'",
            },
            "subtitles":
                "Ahora, el tercer pilar es el que\nPAGA LAS CUENTAS: VENTA\n\nAcá el contenido NO VENDE en el post\n\nLleva la conversación al INBOX\n o a WHATSAPP",
            "edit_metadata": {"duration_seconds": 7.125, "wpm": 160},
          },
          {
            "id": 8,
            "type": "cta",
            "text":
                "Y ahí es donde se crea la oportunidad de venta. Si querés ideas de contenido para cada pilar, escribime “PILARES” en los comentarios.",
            "direction": {
              "tone": "conclusivo, llamativo",
              "pauses": "'venta','pilar'",
              "emphasis": "'oportunidad de venta','“PILARES”'",
            },
            "subtitles":
                "Y ahí es donde se crea la\nOPORTUNIDAD DE VENTA\n\nSi querés ideas de contenido\npara cada pilar\n\nESCRIBIME “PILARES”\n en los comentarios",
            "edit_metadata": {"duration_seconds": 5.625, "wpm": 160},
          },
        ],
      };

      final analysis = ScriptAnalysis.fromJson(mockResponse);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FragmentOrganizationPage(analysis: analysis),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al optimizar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                VRMHeader(
                  title: l10n.newProjectTitle,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VRMStepIndicator(
                          stepNumber: '1',
                          title: l10n.step1Title,
                        ),
                        const SizedBox(height: 20),
                        _buildScriptInput(l10n),
                        const SizedBox(height: 16),
                        _buildStatsRow(l10n),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            WidgetProgress(
              title: "Dividiendo en fragmentos",
              subtitle: "El agente IA está procesando el guión.",
              description:
                  "Dividir el guión en bloques facilitará la retencion de los mismos mejorando la expresividad y la calidad del video generado.",
              progress:
                  0.0, // Podemos hacerlo dinámico si el backend enviara progreso
              duration: const Duration(seconds: 40),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.backgroundLight.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: _scriptController.text.trim().isEmpty || _isLoading
              ? null
              : () => _optimizeScript(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.forestDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: AppTheme.forest.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.content_cut, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.splitIntoFragments.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScriptInput(AppLocalizations l10n) {
    return VRMScriptEditor(
      controller: _scriptController,
      hintText:
          'Pega o escribe aquí tu guion para dividirlo en fragmentos de grabación...',
      actions: [
        VRMScriptEditor.actionButton(
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _scriptController.text = data!.text!;
            }
          },
          icon: Icons.paste_outlined,
          label: "Pegar",
          backgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: const Color(0xFF64748B),
        ),
        VRMScriptEditor.actionIcon(
          onPressed: () {},
          icon: Icons.mic_none_outlined,
        ),
      ],
      trailing: VRMScriptEditor.actionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScriptStudioPage()),
          );
        },
        icon: Icons.auto_awesome,
        label: "Asistente AI",
        foregroundColor: AppTheme.forest,
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final words = _scriptController.text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    final seconds = words / _segmentRateWpm * 60;

    return Estimation(
      speedPpm: _segmentRateWpm,
      durationSeconds: seconds,
      tolerance: 5,
    );
  }
}
