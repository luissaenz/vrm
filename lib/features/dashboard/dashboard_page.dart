import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: _buildBottomNav(l10n),
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
                  _buildTopBar(l10n),
                  const SizedBox(height: 28),
                  _buildMainGreeting(l10n),
                  const SizedBox(height: 28),
                  _buildStatsSection(l10n),
                  const SizedBox(height: 20),
                  VRMActionCard(
                    title: l10n.newProject,
                    subtitle: l10n.voiceControlActive,
                    icon: Icons.mic,
                    onTap: () {
                      // TODO: Navegar a grabación
                    },
                  ),
                  const SizedBox(height: 36),
                  const _RecentProjectsSection(),
                  const SizedBox(height: 36),
                  _buildCalendarSection(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goodMorning,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                    inherit: true,
                  ),
                ),
                Text(
                  l10n.creator,
                  style: const TextStyle(
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

  Widget _buildMainGreeting(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.readyToCreate,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
            letterSpacing: -0.8,
            inherit: true,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          l10n.captureIdeas,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTheme.textMuted,
            inherit: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VRMStatCard(
            value: l10n.days('5'),
            label: l10n.streakLabel,
            icon: Icons.local_fire_department,
            color: AppTheme.accentOrange,
          ),
          const SizedBox(width: 16),
          VRMStatCard(
            value: '42',
            label: l10n.fragments,
            icon: Icons.mic,
            color: AppTheme.accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VRMSectionHeader(title: l10n.calendar, icon: Icons.calendar_month),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VRMCalendarDay(
              day: l10n.wed,
              date: '24',
              isSelected: true,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: l10n.thu,
              date: '25',
              isSelected: false,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: l10n.fri,
              date: '26',
              isSelected: false,
              onTap: () {},
            ),
            VRMCalendarDay(
              day: l10n.sat,
              date: '27',
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
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
          _buildNavItem(Icons.grid_view_sharp, l10n.panel, true),
          _buildNavItem(Icons.play_circle_outline, l10n.videos, false),
          _buildNavItem(Icons.mic_none_outlined, l10n.script, false),
          _buildNavItem(Icons.person_outline, l10n.profile, false),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VRMSectionHeader(
          title: l10n.recentProjects,
          actionLabel: l10n.viewAll,
          onActionPressed: () {
            // TODO: Ver todos los proyectos
          },
        ),
        const SizedBox(height: 16),
        VRMProjectCard(
          title: 'Reseña Tech: iPhone 15',
          time: l10n.editedHoursAgo('2'),
          progress: 0.3,
          statusText: l10n.fragmentCount('3', '10'),
          badgeText: l10n.draft,
          progressLabel: l10n.progressLabel,
          icon: Icons.smartphone,
          badgeBg: const Color(0xFFFFF7ED),
          badgeTextCol: AppTheme.accentOrange,
        ),
        VRMProjectCard(
          title: 'Vlog Japón: Día 1',
          time: l10n.editedYesterday,
          progress: 1.0,
          statusText: l10n.fragmentCount('12', '12'),
          badgeText: l10n.ready,
          progressLabel: l10n.progressLabel,
          icon: Icons.airplanemode_active,
          badgeBg: const Color(0xFFECFDF5),
          badgeTextCol: AppTheme.primaryGreen,
        ),
      ],
    );
  }
}
