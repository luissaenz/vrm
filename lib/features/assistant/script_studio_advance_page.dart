import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ScriptStudioAdvancePage extends StatefulWidget {
  const ScriptStudioAdvancePage({super.key});

  @override
  State<ScriptStudioAdvancePage> createState() =>
      _ScriptStudioAdvancePageState();
}

class _ScriptStudioAdvancePageState extends State<ScriptStudioAdvancePage> {
  // State variables
  String _selectedObjective = 'educar';
  String _selectedCallToAction = 'auto';
  String _selectedApproach = 'auto';
  final Set<String> _selectedHooks = {'polemico'};
  final Set<String> _selectedEnergies = {'motivacional'};
  String _selectedAudience = 'pro';
  double _speechRate = 150.0; // WPM
  bool _rememberSettings = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildCollapsibleHeader(),
                    const SizedBox(height: 24),
                    _buildObjectivesSection(),
                    const SizedBox(height: 24),
                    _buildCallToActionDropdown(),
                    const SizedBox(height: 20),
                    _buildApproachDropdown(),
                    const SizedBox(height: 24),
                    _buildHooksSection(),
                    const SizedBox(height: 24),
                    _buildEnergySection(),
                    const SizedBox(height: 24),
                    _buildAudienceSection(),
                    const SizedBox(height: 24),
                    _buildSpeechRateSection(),
                    const SizedBox(height: 24),
                    _buildRememberSettingsToggle(),
                    const SizedBox(height: 120), // Space for footer
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, size: 24),
              color: AppTheme.textMuted,
              padding: EdgeInsets.zero,
            ),
          ),
          // Title
          const Text(
            'AJUSTES DE ESTUDIO',
            style: TextStyle(
              color: AppTheme.forest,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          // Spacer
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCollapsibleHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text('🛠️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Ajustes de Estudio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          Icon(
            Icons.expand_more,
            color: AppTheme.textMuted.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cuál es tu objetivo?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildObjectiveCard(
                id: 'conectar',
                icon: Icons.favorite,
                label: 'Conectar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildObjectiveCard(
                id: 'educar',
                icon: Icons.school,
                label: 'Educar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildObjectiveCard(
                id: 'vender',
                icon: Icons.shopping_bag,
                label: 'Vender',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObjectiveCard({
    required String id,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedObjective == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedObjective = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.forestVibrant : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.forestVibrant : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? AppTheme.forestVibrant : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToActionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿QUÉ DEBEN HACER AL FINAL?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.earth.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCallToAction,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            icon: const Icon(Icons.unfold_more, color: AppTheme.textMuted),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            items: const [
              DropdownMenuItem(
                value: 'auto',
                child: Text('Auto (Recomendado)'),
              ),
              DropdownMenuItem(value: 'subscribe', child: Text('Suscribirse')),
              DropdownMenuItem(value: 'buy', child: Text('Comprar')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCallToAction = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApproachDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿CÓMO LO CONTAMOS?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.earth.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedApproach,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            icon: const Icon(Icons.unfold_more, color: AppTheme.textMuted),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            items: const [
              DropdownMenuItem(
                value: 'auto',
                child: Text('Auto (Recomendado)'),
              ),
              DropdownMenuItem(
                value: 'storytelling',
                child: Text('Storytelling'),
              ),
              DropdownMenuItem(
                value: 'direct',
                child: Text('Directo al punto'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedApproach = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿CÓMO ATRAPAMOS?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.earth.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPillButton(
              label: 'Polémico',
              isSelected: _selectedHooks.contains('polemico'),
              onTap: () => _toggleSelection(_selectedHooks, 'polemico'),
            ),
            _buildPillButton(
              label: 'Pregunta',
              isSelected: _selectedHooks.contains('pregunta'),
              onTap: () => _toggleSelection(_selectedHooks, 'pregunta'),
            ),
            _buildPillButton(
              label: 'Secreto',
              isSelected: _selectedHooks.contains('secreto'),
              onTap: () => _toggleSelection(_selectedHooks, 'secreto'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿QUÉ ENERGÍA PROYECTAS?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.earth.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPillButton(
              label: 'Directa',
              isSelected: _selectedEnergies.contains('directa'),
              onTap: () => _toggleSelection(_selectedEnergies, 'directa'),
            ),
            _buildPillButton(
              label: 'Motivacional',
              isSelected: _selectedEnergies.contains('motivacional'),
              onTap: () => _toggleSelection(_selectedEnergies, 'motivacional'),
            ),
            _buildPillButton(
              label: 'Irónica',
              isSelected: _selectedEnergies.contains('ironica'),
              onTap: () => _toggleSelection(_selectedEnergies, 'ironica'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forestVibrant : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.forestVibrant : AppTheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.earth,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _toggleSelection(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Widget _buildAudienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿A QUIÉN LE HABLAS?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.earth.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildSegmentButton('novato', 'Novato')),
              Expanded(child: _buildSegmentButton('pro', 'Pro')),
              Expanded(child: _buildSegmentButton('experto', 'Experto')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String value, String label) {
    final isSelected = _selectedAudience == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedAudience = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VELOCIDAD DE HABLA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.earth.withValues(alpha: 0.8),
                letterSpacing: 1.5,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_speechRate.round()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestVibrant,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'WPM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.forestVibrant,
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: AppTheme.forestVibrant,
            overlayColor: AppTheme.forestVibrant.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _speechRate,
            min: 100,
            max: 200,
            onChanged: (value) {
              setState(() => _speechRate = value);
            },
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LENTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestVibrant,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'NORMAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestVibrant,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'RÁPIDO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestVibrant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRememberSettingsToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recordar estos ajustes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Se aplicarán a tus próximos guiones',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _rememberSettings,
            onChanged: (value) {
              setState(() => _rememberSettings = value);
            },
            activeThumbColor: AppTheme.forestVibrant,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
        onPressed: () {
          // TODO: Implement script generation with advanced settings
          debugPrint('Generate script with advanced settings');
          debugPrint('Objective: $_selectedObjective');
          debugPrint('Call to action: $_selectedCallToAction');
          debugPrint('Approach: $_selectedApproach');
          debugPrint('Hooks: $_selectedHooks');
          debugPrint('Energies: $_selectedEnergies');
          debugPrint('Audience: $_selectedAudience');
          debugPrint('Speech rate: $_speechRate WPM');
          debugPrint('Remember settings: $_rememberSettings');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 12,
          shadowColor: AppTheme.forest.withValues(alpha: 0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨', style: TextStyle(fontSize: 18, color: Color(0xFFFBBF24))),
            SizedBox(width: 12),
            Text(
              'GENERAR GUION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
