import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/shared/widgets/section_header.dart';
import 'package:vrm_app/shared/widgets/stat_card.dart';
import 'package:vrm_app/shared/widgets/action_card.dart';
import 'package:vrm_app/shared/widgets/project_card.dart';
import 'package:vrm_app/shared/widgets/calendar_day.dart';
import 'package:vrm_app/features/new_project/new_project_page.dart';
// TODO: Implement InfluencerProfilePage
// import 'package:vrm_app/features/influencer_profile/influencer_profile_page.dart';
import 'package:vrm_app/features/onboarding/data/onboarding_repository.dart';
import 'package:vrm_app/features/onboarding/data/user_profile.dart';
import '../../core/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  UserProfile _profile = UserProfile.empty();
  final _repository = OnboardingRepository();
  DateTime _selectedDate = DateTime.now();

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
              _buildStatsSection(l10n),
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
                        // TODO: Implement InfluencerProfilePage
                        debugPrint('InfluencerProfilePage not yet implemented');
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
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
          Container(
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

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VRMStatCard(
              value: '5',
              label: l10n.streakLabel,
              icon: Icons.local_fire_department,
              color: const Color(0xFFF97316), // Orange 500
            ),
            const SizedBox(width: 12),
            VRMStatCard(
              value: '42',
              label: l10n.fragments,
              icon: Icons.mic,
              color: const Color(0xFF10B981), // Emerald 500
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(AppLocalizations l10n) {
    // Generate 5 days starting from today
    final today = DateTime.now();
    final calendarDays = List.generate(5, (index) {
      return today.add(Duration(days: index));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VRMSectionHeader(title: l10n.calendar, icon: Icons.calendar_month),
          const SizedBox(height: 20),
          Row(
            children: calendarDays.map((date) {
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, today);

              // Use 'HOY'/'TODAY' for the current date
              final locale = Localizations.localeOf(context).languageCode;
              String dayName;
              if (isToday) {
                dayName = locale == 'es' ? 'HOY' : 'TODAY';
              } else {
                dayName = DateFormat.E(locale).format(date).toUpperCase();
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: date == calendarDays.last ? 0 : 8,
                  ),
                  child: VRMCalendarDay(
                    day: dayName,
                    date: date.day.toString(),
                    isSelected: isSelected,
                    isToday: isToday,
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
                  // TODO: Implement InfluencerProfilePage
                  debugPrint('InfluencerProfilePage not yet implemented');
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const InfluencerProfilePage(),
                  //   ),
                  // );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  badgeBg: isDark
                      ? Colors.orange.withValues(alpha: 0.1)
                      : const Color(0xFFFFF7ED),
                  badgeTextCol: isDark
                      ? const Color(0xFFF97316)
                      : const Color(0xFFC2410C),
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
                  badgeBg: isDark
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFECFDF5),
                  badgeTextCol: isDark
                      ? const Color(0xFF10B981)
                      : const Color(0xFF047857),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
