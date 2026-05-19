import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import 'services/settings_service.dart';
import '../recording/models/teleprompter_prefs.dart';

const _privacyPolicyUrl =
    'https://raw.githubusercontent.com/luissaenz/vrm/main/PRIVACY_POLICY.md';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService.instance;
  ThemeMode _themeMode = ThemeMode.light;
  bool _cloudSyncEnabled = false;
  TeleprompterPrefs _teleprompterPrefs = TeleprompterPrefs.defaults();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeMode = await _settings.getThemeMode();
    final cloudSync = await _settings.getCloudSyncEnabled();
    final teleprompter = await _settings.getTeleprompterPrefs();
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
        _cloudSyncEnabled = cloudSync;
        _teleprompterPrefs = teleprompter;
        _isLoading = false;
      });
    }
  }

  Future<void> _onThemeChanged(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  Future<void> _onCloudSyncChanged(bool value) async {
    await _settings.setCloudSyncEnabled(value);
    if (mounted) {
      setState(() => _cloudSyncEnabled = value);
    }
  }

  Future<void> _showFontSizeDialog() async {
    double tempFontSize = _teleprompterPrefs.fontSize;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.fontSize),
        content: StatefulBuilder(
          builder: (context, setSliderState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${tempFontSize.toInt()}px'),
                Slider(
                  min: 16,
                  max: 48,
                  value: tempFontSize,
                  onChanged: (v) => setSliderState(() => tempFontSize = v),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newPrefs = TeleprompterPrefs(
                fontSize: tempFontSize,
                readingSpeed: _teleprompterPrefs.readingSpeed,
                brightness: _teleprompterPrefs.brightness,
              );
              await _settings.setTeleprompterPrefs(newPrefs);
              if (context.mounted) {
                setState(() => _teleprompterPrefs = newPrefs);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSpeedDialog() async {
    double tempSpeed = _teleprompterPrefs.readingSpeed;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.scrollSpeed),
        content: StatefulBuilder(
          builder: (context, setSliderState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${tempSpeed.toInt()} PPM'),
                Slider(
                  min: 60,
                  max: 300,
                  value: tempSpeed,
                  onChanged: (v) => setSliderState(() => tempSpeed = v),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newPrefs = TeleprompterPrefs(
                fontSize: _teleprompterPrefs.fontSize,
                readingSpeed: tempSpeed,
                brightness: _teleprompterPrefs.brightness,
              );
              await _settings.setTeleprompterPrefs(newPrefs);
              if (context.mounted) {
                setState(() => _teleprompterPrefs = newPrefs);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            VRMHeader(
              title: l10n.settings,
              onBack: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new,
              iconOnRight: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSection(
                      context,
                      title: l10n.appearance,
                      children: [_buildThemeSwitcher(context)],
                    ),
                    _buildSection(
                      context,
                      title: l10n.recording,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.timer_outlined,
                          title: l10n.defaultRecordingDuration,
                          subtitle: l10n.configureDefaultTime,
                          onTap: () => _showComingSoon(context),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.camera_alt_outlined,
                          title: l10n.cameraSettings,
                          subtitle: l10n.resolutionAndQuality,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                    _buildSection(
                      context,
                      title: l10n.teleprompter,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.text_fields,
                          title: l10n.fontSize,
                          subtitle: '${_teleprompterPrefs.fontSize.toInt()}px',
                          onTap: _showFontSizeDialog,
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.speed_outlined,
                          title: l10n.scrollSpeed,
                          subtitle:
                              '${_teleprompterPrefs.readingSpeed.toInt()} PPM',
                          onTap: _showSpeedDialog,
                        ),
                      ],
                    ),
                    _buildSection(
                      context,
                      title: l10n.dataAndStorage,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.cloud_outlined,
                          title: l10n.cloudSync,
                          subtitle: _cloudSyncEnabled
                              ? 'Enabled'
                              : l10n.cloudSyncDisabled,
                          trailing: Switch(
                            value: _cloudSyncEnabled,
                            onChanged: _onCloudSyncChanged,
                          ),
                          onTap: () => _showComingSoon(context),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.storage_outlined,
                          title: l10n.manageStorage,
                          subtitle: l10n.clearCacheAndData,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                    _buildSection(
                      context,
                      title: l10n.about,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.info_outlined,
                          title: l10n.appVersion,
                          subtitle: '1.0.0',
                          onTap: () => _showComingSoon(context),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.description_outlined,
                          title: l10n.termsOfService,
                          onTap: () => _showComingSoon(context),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          title: l10n.privacyPolicy,
                          onTap: () => _openPrivacyPolicy(context),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.help_outline,
                          title: l10n.helpAndSupport,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VRMStepIndicator(stepNumber: '', title: title.toUpperCase()),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.isDarkMode ? colors.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitcher(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(
        context.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: context.appColors.forest,
      ),
      title: Text(l10n.theme),
      subtitle: Text(l10n.selectThemeMode),
      trailing: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            icon: const Icon(Icons.light_mode, size: 18),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            icon: const Icon(Icons.dark_mode, size: 18),
          ),
        ],
        selected: {_themeMode},
        onSelectionChanged: (newSelection) =>
            _onThemeChanged(newSelection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.forest.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: colors.forest),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colors.forest,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.forest.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: context.appColors.forest.withValues(alpha: 0.1),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: ${e.toString()}')),
        );
      }
    }
  }
}
