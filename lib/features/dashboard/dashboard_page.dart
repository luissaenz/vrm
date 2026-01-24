import 'package:flutter/material.dart';
import 'package:vrm_app/shared/widgets/section_header.dart';
import 'package:vrm_app/shared/widgets/stat_card.dart';
import 'package:vrm_app/shared/widgets/action_card.dart';
import 'package:vrm_app/shared/widgets/project_card.dart';
import 'package:vrm_app/shared/widgets/calendar_day.dart';
import '../../core/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 28),
                  _buildMainGreeting(),
                  const SizedBox(height: 28),
                  _buildStatsSection(),
                  const SizedBox(height: 20),
                  VRMActionCard(
                    title: 'Nuevo Proyecto',
                    subtitle: 'Control por voz activado',
                    icon: Icons.mic,
                    onTap: () {
                      // TODO: Navegar a grabación
                    },
                  ),
                  const SizedBox(height: 36),
                  const _RecentProjectsSection(),
                  const SizedBox(height: 36),
                  _buildCalendarSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=vrm_user_alex',
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUENOS DÍAS,',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                    inherit: true,
                  ),
                ),
                Text(
                  'Alex Rivera',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                    inherit: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.settings, size: 16, color: AppTheme.textMain),
        ),
      ],
    );
  }

  Widget _buildMainGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Listo para crear?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
            letterSpacing: -0.8,
            inherit: true,
          ),
        ),
        SizedBox(height: 1),
        Text(
          'Captura tus ideas, un fragmento a la vez.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppTheme.textMuted,
            inherit: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VRMStatCard(
            value: '5 Días',
            label: 'RACHA DE\nGRABACIÓN',
            icon: Icons.local_fire_department,
            color: AppTheme.accentOrange,
          ),
          SizedBox(width: 16),
          VRMStatCard(
            value: '42',
            label: 'FRAGMENTOS',
            icon: Icons.mic,
            color: AppTheme.accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VRMSectionHeader(title: 'Calendario', icon: Icons.calendar_month),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VRMCalendarDay(
              day: 'MIE',
              date: '24',
              isSelected: true,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: 'JUE',
              date: '25',
              isSelected: false,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: 'VIE',
              date: '26',
              isSelected: false,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: 'SAB',
              date: '27',
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_sharp, 'PANEL', true),
          _buildNavItem(Icons.play_circle_outline, 'VIDEOS', false),
          _buildNavItem(Icons.mic_none_outlined, 'SCRIPT', false),
          _buildNavItem(Icons.person_outline, 'PERFIL', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive
              ? AppTheme.primaryGreen
              : AppTheme.textMuted.withOpacity(0.4),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive
                ? AppTheme.primaryGreen
                : AppTheme.textMuted.withOpacity(0.4),
            inherit: true,
          ),
        ),
      ],
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  const _RecentProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VRMSectionHeader(
          title: 'Proyectos Recientes',
          actionLabel: 'Ver todos',
          onActionPressed: () {
            // TODO: Ver todos los proyectos
          },
        ),
        const SizedBox(height: 16),
        const VRMProjectCard(
          title: 'Reseña Tech: iPhone 15',
          time: 'Editado hace 2 horas',
          progress: 0.3,
          statusText: '3/10 Fragmentos',
          badgeText: 'BORRADOR',
          icon: Icons.smartphone,
          badgeBg: Color(0xFFFFF7ED), // Light orange background
          badgeTextCol: AppTheme.accentOrange, // Exact theme orange
        ),
        const VRMProjectCard(
          title: 'Vlog Japón: Día 1',
          time: 'Editado ayer',
          progress: 1.0,
          statusText: '12/12 Fragmentos',
          badgeText: 'LISTO',
          icon: Icons.airplanemode_active,
          badgeBg: Color(0xFFECFDF5),
          badgeTextCol:
              AppTheme.primaryGreen, // Mismo verde que el botón principal
        ),
      ],
    );
  }
}
