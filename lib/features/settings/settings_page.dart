import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              context,
              title: l10n.appearance,
              children: [
                _buildThemeSwitcher(context),
              ],
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
                  onTap: () {
                    // Navigate to recording duration settings
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.camera_alt_outlined,
                  title: l10n.cameraSettings,
                  subtitle: l10n.resolutionAndQuality,
                  onTap: () {
                    // Navigate to camera settings
                  },
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
                  subtitle: l10n.defaultTextSize,
                  onTap: () {
                    // Navigate to font size settings
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.speed_outlined,
                  title: l10n.scrollSpeed,
                  subtitle: l10n.defaultScrollSpeed,
                  onTap: () {
                    // Navigate to scroll speed settings
                  },
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
                  subtitle: l10n.cloudSyncDisabled,
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // Toggle cloud sync
                    },
                  ),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.storage_outlined,
                  title: l10n.manageStorage,
                  subtitle: l10n.clearCacheAndData,
                  onTap: () {
                    // Navigate to storage management
                  },
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
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: l10n.termsOfService,
                  onTap: () {
                    // Open terms of service
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  onTap: () {
                    // Open privacy policy
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: l10n.helpAndSupport,
                  onTap: () {
                    // Open help
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.forest.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.isDarkMode ? colors.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: children,
            ),
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
          ButtonSegment<ThemeMode>(
            value: ThemeMode.system,
            icon: const Icon(Icons.settings_brightness, size: 18),
          ),
        ],
        selected: {ThemeMode.dark}, // Should be dynamic
        onSelectionChanged: (newSelection) {
          // Update theme mode
        },
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
}
