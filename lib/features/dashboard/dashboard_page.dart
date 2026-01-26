import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/shared/widgets/section_header.dart';
import 'package:vrm_app/shared/widgets/stat_card.dart';
import 'package:vrm_app/shared/widgets/action_card.dart';
import 'package:vrm_app/shared/widgets/project_card.dart';
import 'package:vrm_app/shared/widgets/calendar_day.dart';
import 'package:vrm_app/features/new_project/new_project_page.dart';
import 'package:vrm_app/features/influencer_profile/influencer_profile_page.dart';
import '../../core/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context, l10n),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(l10n),
                  _buildMainGreeting(l10n),
                  _buildStatsSection(l10n),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        VRMActionCard(
                          title: l10n.newProject,
                          subtitle: l10n.voiceControlActive,
                          icon: Icons.keyboard_voice,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewProjectPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        VRMActionCard(
                          title: 'Perfil Influencer',
                          subtitle: 'Configura tu identidad real',
                          icon: Icons.person_search_rounded,
                          actionIcon: Icons.arrow_forward_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InfluencerProfilePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const _RecentProjectsSection(),
                  const SizedBox(height: 40),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://i.pravatar.cc/150?u=vrm_user_alex',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.goodMorning,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B), // Slate 500
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    l10n.creator,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.earthBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.settings, size: 20, color: AppTheme.forest),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGreeting(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.readyToCreate,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.captureIdeas,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B), // Slate 500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          VRMStatCard(
            value: l10n.days('5'),
            label: l10n.streakLabel,
            icon: Icons.local_fire_department,
            color: const Color(0xFFEA580C), // Orange 600
          ),
          const SizedBox(width: 16),
          VRMStatCard(
            value: '42',
            label: l10n.fragments,
            icon: Icons.mic,
            color: AppTheme.forest,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VRMSectionHeader(title: l10n.calendar, icon: Icons.calendar_month),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                VRMCalendarDay(
                  day: l10n.wed,
                  date: '24',
                  isSelected: true,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                VRMCalendarDay(
                  day: l10n.thu,
                  date: '25',
                  isSelected: false,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                VRMCalendarDay(
                  day: l10n.fri,
                  date: '26',
                  isSelected: false,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                VRMCalendarDay(
                  day: l10n.sat,
                  date: '27',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: AppTheme.earthBorder, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                Icons.grid_view_rounded,
                l10n.panel,
                true,
                () {},
              ),
              _buildNavItem(
                context,
                Icons.video_library_rounded,
                l10n.videos,
                false,
                () {},
              ),
              _buildNavItem(
                context,
                Icons.mic_none_rounded,
                l10n.script,
                false,
                () {},
              ),
              _buildNavItem(
                context,
                Icons.person_rounded,
                l10n.profile,
                false,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfluencerProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive
                ? AppTheme.forest
                : const Color(0xFF94A3B8), // Slate 400
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isActive
                  ? AppTheme.forest
                  : const Color(0xFF94A3B8), // Slate 400
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  const _RecentProjectsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: VRMSectionHeader(
              title: l10n.recentProjects,
              actionLabel: l10n.viewAll,
              onActionPressed: () {},
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                VRMProjectCard(
                  title: 'Reseña Tech: iPhone 15',
                  time: l10n.editedHoursAgo('2'),
                  progress: 0.3,
                  statusText: l10n.fragmentCount('3', '10'),
                  badgeText: l10n.draft,
                  progressLabel: l10n.progressLabel,
                  icon: Icons.smartphone_rounded,
                  badgeBg: const Color(0xFFFFF7ED),
                  badgeTextCol: const Color(0xFFC2410C), // Orange 700
                ),
                const SizedBox(height: 4),
                VRMProjectCard(
                  title: 'Vlog Japón: Día 1',
                  time: l10n.editedYesterday,
                  progress: 1.0,
                  statusText: l10n.fragmentCount('12', '12'),
                  badgeText: l10n.ready,
                  progressLabel: l10n.progressLabel,
                  icon: Icons.flight_rounded,
                  badgeBg: const Color(0xFFECFDF5),
                  badgeTextCol: const Color(0xFF047857), // Emerald 700
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
