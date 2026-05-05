import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../recording/models/teleprompter_prefs.dart';

class SettingsService {
  static const String _keyTeleprompterPrefs = 'teleprompter_prefs';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyCloudSync = 'cloud_sync_enabled';
  static const String _keyInfluencerProfile = 'influencer_profile';
  static const String _keyMemberSince = 'member_since';

  static SettingsService? _instance;
  SettingsService._();
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }

  Future<void> setTeleprompterPrefs(TeleprompterPrefs teleprompterPrefs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyTeleprompterPrefs,
      jsonEncode(teleprompterPrefs.toMap()),
    );
  }

  Future<TeleprompterPrefs> getTeleprompterPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTeleprompterPrefs);
    if (json == null) return TeleprompterPrefs.defaults();
    return TeleprompterPrefs.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyThemeMode);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCloudSync, enabled);
  }

  Future<bool> getCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCloudSync) ?? false;
  }

  Future<void> setInfluencerProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInfluencerProfile, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getInfluencerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyInfluencerProfile);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<DateTime?> getMemberSince() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyMemberSince);
    if (timestamp == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_keyMemberSince, now);
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
