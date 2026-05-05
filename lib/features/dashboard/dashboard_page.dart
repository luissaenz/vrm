import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/shared/widgets/section_header.dart';
import 'package:vrm_app/shared/widgets/action_card.dart';
import 'package:vrm_app/shared/widgets/project_card.dart';
import 'package:vrm_app/features/new_project/new_project_page.dart';
import 'package:vrm_app/features/influencer_profile/influencer_profile_page.dart';
import 'package:vrm_app/features/account/account_profile_page.dart';
import 'package:vrm_app/features/settings/settings_page.dart';
import 'package:vrm_app/features/onboarding/data/onboarding_repository.dart';
import 'package:vrm_app/features/onboarding/data/user_profile.dart';
import 'package:vrm_app/core/data/project_repository.dart';
import 'package:vrm_app/core/models/project_state.dart';
import '../../core/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  UserProfile _profile = UserProfile.empty();
  final _repository = OnboardingRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final profile = await _repository.getUserProfile();
    if (mounted) {
      if (!profile.onboardingCompleted ||
          profile.identity == UserIdentity.none) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        setState(() => _profile = profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context, l10n),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(l10n),
              _buildMainGreeting(l10n),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    VRMActionCard(
                      title: l10n.newProject,
                      subtitle: l10n.voiceControlActive,
                      icon: Icons.mic,
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
                            builder: (context) => const InfluencerProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const _RecentProjectsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountProfilePage(),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appColors.cardBorder,
                      width: 2,
                    ),
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
                        color: context.appColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _getProfileLabel(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.appColors.cardBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.settings,
                size: 20,
                color: context.isDarkMode
                    ? Colors.white
                    : context.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGreeting(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMainTitle(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getMainSubtitle(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getProfileLabel() {
    switch (_profile.identity) {
      case UserIdentity.leader:
        return 'Líder Ejecutivo';
      case UserIdentity.influencer:
        return 'Creador Flow';
      case UserIdentity.seller:
        return 'Vendedor Pro';
      default:
        return 'Creador';
    }
  }

  String _getMainTitle() {
    switch (_profile.identity) {
      case UserIdentity.leader:
        return 'Modo Eficiencia';
      case UserIdentity.influencer:
        return 'Modo Flow';
      case UserIdentity.seller:
        return 'Modo Persuasión';
      default:
        return '¿Listo para crear?';
    }
  }

  String _getMainSubtitle() {
    switch (_profile.identity) {
      case UserIdentity.leader:
        return 'Tu tiempo es dinero. Máxima precisión.';
      case UserIdentity.influencer:
        return 'Encuentra tu voz. Conecta con tu audiencia.';
      case UserIdentity.seller:
        return 'Convierte espectadores en clientes.';
      default:
        return 'Captura tus ideas y dales vida hoy.';
    }
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            context.colorScheme.surface,
            context.colorScheme.surface.withValues(alpha: 0.0),
          ],
          stops: const [0.6, 1.0],
        ),
      ),
      child: _buildActualNavBar(context, l10n),
    );
  }

  Widget _buildActualNavBar(BuildContext context, AppLocalizations l10n) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? context.colorScheme.surface.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: context.appColors.cardBorder.withValues(alpha: 0.2),
              ),
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
                ? context.colorScheme.primary
                : context.appColors.textSecondary,
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isActive
                  ? context.colorScheme.primary
                  : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  const _RecentProjectsSection();

  String _getTimeAgo(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);

    if (diff.inDays >= 1) {
      if (diff.inDays == 1) return l10n.editedYesterday;
      return 'Editado hace ${diff.inDays} días';
    } else if (diff.inHours >= 1) {
      return l10n.editedHoursAgo(diff.inHours.toString());
    } else {
      return 'Editado hace poco';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final repository = ProjectRepository();

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: VRMSectionHeader(
              title: l10n.recentProjects,
              actionLabel: l10n.viewAll,
              onActionPressed: () {},
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ProjectState>>(
            future: repository.listProjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(context, l10n);
              }

              final projects = snapshot.data!.take(5).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: projects.map((project) {
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: repository.getSessionData(project.projectId),
                      builder: (context, sessionSnapshot) {
                        final session = sessionSnapshot.data;
                        final approvedCount = (session?['approvedClips'] as Map?)?.length ?? 0;
                        final totalChunks = project.script?.totalChunks ?? 0;
                        final progress = totalChunks > 0 ? approvedCount / totalChunks : 0.0;
                        final isCompleted = progress >= 1.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VRMProjectCard(
                            title: project.input?.rawTopic ?? 'Sin título',
                            time: _getTimeAgo(context, project.updatedAt),
                            progress: progress,
                            statusText: l10n.fragmentCount(
                              approvedCount.toString(),
                              totalChunks.toString(),
                            ),
                            badgeText: isCompleted ? l10n.ready : l10n.draft,
                            progressLabel: l10n.progressLabel,
                            icon: isCompleted ? Icons.check_circle_rounded : Icons.create_rounded,
                            badgeBg: isCompleted
                                ? (isDark
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : const Color(0xFFECFDF5))
                                : (isDark
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : const Color(0xFFFFF7ED)),
                            badgeTextCol: isCompleted
                                ? (isDark ? const Color(0xFF10B981) : const Color(0xFF047857))
                                : (isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C)),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_collection_outlined,
            size: 48,
            color: context.appColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.readyToCreate,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.captureIdeas,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
