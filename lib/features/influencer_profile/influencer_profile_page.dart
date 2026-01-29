import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/script_editor.dart';

class InfluencerProfilePage extends StatefulWidget {
  const InfluencerProfilePage({super.key});

  @override
  State<InfluencerProfilePage> createState() => _InfluencerProfilePageState();
}

class _InfluencerProfilePageState extends State<InfluencerProfilePage> {
  int _currentStep = 1;

  // Controllers Step 1
  final TextEditingController _phraseController = TextEditingController();
  String _authorityLevel = 'Principiante';
  final List<String> _selectedDiscourse = ['Experiencia', 'Estudio / Academia'];

  // Controllers Step 2
  final TextEditingController _probController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();
  final TextEditingController _wrongController = TextEditingController();
  final TextEditingController _beliefController = TextEditingController();

  // Controllers Step 3
  final List<String> _selectedTones = ['Directa', 'Inspiradora'];
  final TextEditingController _slangController = TextEditingController();
  String _polishLevel = 'Orgánico';
  final TextEditingController _refController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            VRMHeader(
              title: _getStepTitle(),
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
                  children: [_buildCurrentStep(), const SizedBox(height: 40)],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Identidad Narrativa';
      case 2:
        return 'Historia y Postura';
      case 3:
        return 'Estilo y Referencia';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. ¿Cómo te defines en una sola frase?'),
        const SizedBox(height: 16),
        VRMScriptEditor(
          controller: _phraseController,
          hintText:
              'Ej: El mentor de finanzas para jóvenes que buscan libertad',
          maxLines: 4,
          actions: [
            _buildPasteAction(_phraseController),
            const SizedBox(width: 4),
            _buildUploadAction(),
            _buildMicAction(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Esta frase ayudará a la IA a capturar tu esencia en cada guion.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppTheme.earth.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 48),
        _buildSectionTitle('2. ¿Cuál es tu nivel de autoridad?'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            _buildAuthorityCard('Principiante', 'APRENDIENDO EN PÚBLICO'),
            _buildAuthorityCard('Crecimiento', 'GANANDO TRACCIÓN'),
            _buildAuthorityCard('Experto', 'DOMINIO DEL SECTOR'),
            _buildAuthorityCard('Referente', 'LÍDER DE OPINIÓN'),
          ],
        ),
        const SizedBox(height: 48),
        _buildSectionTitle('3. Origen de tu discurso'),
        _buildSectionSubtitle('¿Desde qué perspectiva hablas?'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag('Experiencia', _selectedDiscourse),
            _buildTag('Error propio', _selectedDiscourse),
            _buildTag('Estudio / Academia', _selectedDiscourse),
            _buildTag('Análisis', _selectedDiscourse),
            _buildTag('Inspiración', _selectedDiscourse),
            _buildTag('Intuición', _selectedDiscourse),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep2Field(
          '4. El problema vivido',
          'Describe brevemente el desafío o problema que enfrentaste...',
          _probController,
          isLarge: true,
        ),
        _buildStep2Field(
          '5. Cambio tras aprendizaje',
          '¿Cuál fue el punto de inflexión en tu camino?',
          _changeController,
          isLarge: true,
        ),
        _buildStep2Field(
          '6. ¿Qué hace mal la gente?',
          'Un error común que detectas...',
          _wrongController,
        ),
        _buildStep2Field(
          '7. Creencia fuerte',
          'Algo en lo que crees firmemente...',
          _beliefController,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('8. ¿Cuál es tu tono predominante?'),
        _buildSectionSubtitle(
          'Selecciona los que mejor definan tu personalidad.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag('Directa', _selectedTones),
            _buildTag('Reflexiva', _selectedTones),
            _buildTag('Humorística', _selectedTones),
            _buildTag('Inspiradora', _selectedTones),
            _buildTag('Sarcástica', _selectedTones),
            _buildTag('Educativa', _selectedTones),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('9. Modismos y frases típicas'),
        const SizedBox(height: 12),
        VRMScriptEditor(
          controller: _slangController,
          hintText: 'Ej: \'¿Qué onda equipo?\', \'¡Brutal!\'',
          maxLines: 2,
          actions: [
            _buildPasteAction(_slangController),
            const SizedBox(width: 4),
            _buildUploadAction(),
            _buildMicAction(),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('10. Nivel de \'pulido\' del guion'),
        _buildSectionSubtitle('¿Qué tan estructurado debe ser el texto?'),
        const SizedBox(height: 16),
        _buildSegmentedControl(),
        const SizedBox(height: 32),
        _buildSectionTitle('11. Fragmentos de referencia'),
        const SizedBox(height: 12),
        VRMScriptEditor(
          controller: _refController,
          hintText:
              'Pega aquí un guion que ya hayas usado o un texto que represente fielmente tu estilo actual...',
          maxLines: 6,
          actions: [
            _buildPasteAction(_refController),
            const SizedBox(width: 4),
            _buildUploadAction(),
            _buildMicAction(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Esto nos ayuda a entrenar la IA con tu voz real.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.forest,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.earth.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child: Icon(
              Icons.question_mark_rounded,
              size: 12,
              color: AppTheme.earth,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: const TextStyle(fontSize: 14, color: AppTheme.earth),
    );
  }

  Widget _buildAuthorityCard(String title, String subtitle) {
    final isSelected = _authorityLevel == title;
    return GestureDetector(
      onTap: () => setState(() => _authorityLevel = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1FAF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.forestVibrant
                : Colors.grey.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.earth.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, List<String> selectedList) {
    final isSelected = selectedList.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedList.remove(label);
          } else {
            selectedList.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forestVibrant : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppTheme.forestVibrant
                : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.earth,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Field(
    String title,
    String hint,
    TextEditingController controller, {
    bool isLarge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 12),
        VRMScriptEditor(
          controller: controller,
          hintText: hint,
          maxLines: isLarge ? 5 : 2,
          actions: [
            _buildPasteAction(controller),
            const SizedBox(width: 4),
            _buildUploadAction(),
            _buildMicAction(),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPasteAction(TextEditingController controller) {
    return VRMScriptEditor.actionButton(
      onPressed: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) {
          setState(() {
            controller.text = data!.text!;
          });
        }
      },
      icon: Icons.paste_outlined,
      label: "Pegar",
      backgroundColor: const Color(0xFFF1F5F9),
      foregroundColor: const Color(0xFF64748B),
    );
  }

  Widget _buildUploadAction() {
    return VRMScriptEditor.actionIcon(
      onPressed: () {},
      icon: Icons.file_upload_outlined,
    );
  }

  Widget _buildMicAction() {
    return VRMScriptEditor.actionIcon(
      onPressed: () {},
      icon: Icons.mic_none_outlined,
    );
  }

  Widget _buildSegmentedControl() {
    final options = ['Orgánico', 'Equilibrado', 'Estructurado'];
    final labels = ['ESPONTÁNEO', '', 'GUIONIZADO'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: options.map((opt) {
              final isSel = _polishLevel == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _polishLevel = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (isSel)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel
                              ? AppTheme.forestVibrant
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 3) {
                setState(() => _currentStep++);
              } else {
                // Finalize logic
                Navigator.pop(context);
              }
            },
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
                if (_currentStep == 3) ...[
                  const Icon(Icons.check_circle, size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  _currentStep == 3 ? 'FINALIZAR PERFIL' : 'SIGUIENTE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                if (_currentStep < 3) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
          if (_currentStep > 1) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppTheme.forest,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'REGRESAR',
                    style: TextStyle(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
