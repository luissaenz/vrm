import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import 'services/device_info_service.dart';
import '../settings/services/settings_service.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  DeviceInfo? _deviceInfo;
  DateTime? _memberSince;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await DeviceInfoService.instance.getDeviceInfo();
    final memberSince = await SettingsService.instance.getMemberSince();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _memberSince = memberSince;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            VRMHeader(
              title: l10n.accountProfile,
              onBack: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new,
              iconOnRight: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, colors, isDark),
                    const SizedBox(height: 30),
                    const VRMStepIndicator(
                      stepNumber: '',
                      title: 'INFORMACIÓN DE CUENTA',
                    ),
                    const SizedBox(height: 12),
                    _buildAccountInfo(context, colors, isDark),
                    const SizedBox(height: 30),
                    const VRMStepIndicator(
                      stepNumber: '',
                      title: 'AJUSTES ADICIONALES',
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsSection(context, colors),
                    const SizedBox(height: 30),
                    const VRMStepIndicator(
                      stepNumber: '',
                      title: 'ZONA DE PELIGRO',
                    ),
                    const SizedBox(height: 12),
                    _buildDangerZone(context, colors),
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

  Widget _buildProfileHeader(
    BuildContext context,
    AppColors colors,
    bool isDark,
  ) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.forest.withValues(alpha: 0.05),
              border: Border.all(color: colors.cardBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: 50,
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.anonymousUser,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context)!.upgradeYourAccount.toUpperCase(),
              style: TextStyle(
                color: context.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(
    BuildContext context,
    AppColors colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.cardBackground : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            icon: Icons.email_outlined,
            label: AppLocalizations.of(context)!.email,
            value: AppLocalizations.of(context)!.notConfigured,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.phone_android,
            label: AppLocalizations.of(context)!.deviceId,
            value: _isLoading ? '...' : (_deviceInfo?.model ?? 'Unknown'),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today,
            label: AppLocalizations.of(context)!.memberSince,
            value: _isLoading
                ? '...'
                : (_memberSince != null
                      ? '${_memberSince!.day}/${_memberSince!.month}/${_memberSince!.year}'
                      : 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.forest.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colors.forest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.forest.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.forest,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppColors colors) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            onTap: () {},
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.language_outlined,
            title: l10n.language,
            onTap: () {},
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.storage_outlined,
            title: l10n.storage,
            onTap: () {},
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: l10n.privacyAndSecurity,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, AppColors colors) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode ? colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: l10n.clearAllData,
            textColor: Colors.red,
            onTap: () => _showClearDataDialog(context),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: l10n.signOut,
            textColor: Colors.red,
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? context.appColors.forest),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor ?? context.appColors.forest,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: context.appColors.forest.withValues(alpha: 0.1),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(l10n.clearDataConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appDir = await getApplicationDocumentsDirectory();
                final vrmDataDir = Directory('${appDir.path}/vrm_data');

                if (await vrmDataDir.exists()) {
                  await vrmDataDir.delete(recursive: true);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.dataCleared)));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.signedOut)));
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
