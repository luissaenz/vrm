import 'package:flutter/material.dart';
import 'script_studio_advance_page.dart';

class ScriptStudioPage extends StatefulWidget {
  const ScriptStudioPage({super.key});

  @override
  State<ScriptStudioPage> createState() => _ScriptStudioPageState();
}

class _ScriptStudioPageState extends State<ScriptStudioPage> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedObjective = 'educar';

  // Forest theme colors from HTML design
  static const Color _primaryForest = Color(0xFF2D423F);
  static const Color _forestVibrant = Color(0xFF219653);
  static const Color _earthTone = Color(0xFF8D7B6D);
  static const Color _offWhite = Color(0xFFF8F9F8);
  static const Color _forestLight = Color(0xFFF1FAF5);

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildInputCard(),
                    const SizedBox(height: 32),
                    _buildObjectiveSection(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    _buildStudioSettingsButton(),
                    const SizedBox(height: 120), // Space for fixed footer
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
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: BoxDecoration(
        color: _offWhite.withValues(alpha: 0.8),
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
          // Close button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              color: _primaryForest,
              padding: EdgeInsets.zero,
            ),
          ),
          // Title
          const Text(
            'LABORATORIO DE IDEAS',
            style: TextStyle(
              color: _primaryForest,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          // Spacer
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          TextField(
            controller: _inputController,
            maxLines: null,
            style: const TextStyle(
              color: _primaryForest,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: '¿De qué quieres hablar hoy?',
              hintStyle: TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
              onPressed: () {
                // TODO: Implement voice input
              },
              icon: Icon(
                Icons.mic_none,
                color: _earthTone.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '¿Cuál es tu objetivo?',
            style: TextStyle(
              color: _primaryForest,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
        height: 112,
        decoration: BoxDecoration(
          color: isSelected ? _forestLight : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _forestVibrant : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _forestVibrant : _primaryForest,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? _forestVibrant : _primaryForest,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(vertical: 24),
    );
  }

  Widget _buildStudioSettingsButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScriptStudioAdvancePage(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('🛠️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Ajustes de Estudio',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Icon(Icons.keyboard_arrow_down, color: _earthTone, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final hasText = _inputController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _offWhite,
            _offWhite.withValues(alpha: 0.95),
            _offWhite.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: ElevatedButton(
        onPressed: hasText
            ? () {
                // TODO: Implement script generation
                debugPrint('Generate script with: ${_inputController.text}');
                debugPrint('Objective: $_selectedObjective');
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryForest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryForest.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 12,
          shadowColor: _primaryForest.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
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
