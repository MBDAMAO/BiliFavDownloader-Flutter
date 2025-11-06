// providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;
  late Settings _settings;

  Settings get settings => _settings;

  SettingsProvider(this._settingsService)
    : _settings = Settings.defaultValues() {
    _loadSettings(); // 异步加载实际值
  }

  Future<void> _loadSettings() async {
    _settings = await _settingsService.getSettings();
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    _settings = _settings.copyWith(
      notificationsEnabled: !_settings.notificationsEnabled,
    );
    await _settingsService.saveSettings(
      _settings,
      SettingsService.notificationsKey,
    );
    notifyListeners();
  }

  Future<void> changeLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _settingsService.saveSettings(_settings, SettingsService.languageKey);
    notifyListeners();
  }

  Future<void> changeFontSize(double fontSize) async {
    _settings = _settings.copyWith(fontSize: fontSize);
    await _settingsService.saveSettings(_settings, SettingsService.fontSizeKey);
    notifyListeners();
  }

  Future<void> changeCookies(String cookies) async {
    _settings = _settings.copyWith(cookies: cookies);
    await _settingsService.saveSettings(_settings, SettingsService.cookiesKey);
    notifyListeners();
  }

  Future<void> changeMid(String mid) async {
    _settings = _settings.copyWith(mid: mid);
    await _settingsService.saveSettings(_settings, SettingsService.midKey);
    notifyListeners();
  }

  Future<void> changeUsername(String username) async {
    _settings = _settings.copyWith(username: username);
    await _settingsService.saveSettings(_settings, SettingsService.usernameKey);
    notifyListeners();
  }

  Future<void> changeRank(String rank) async {
    _settings = _settings.copyWith(rank: rank);
    await _settingsService.saveSettings(_settings, SettingsService.rankKey);
    notifyListeners();
  }

  Future<void> changeUid(String uid) async {
    _settings = _settings.copyWith(uid: uid);
    await _settingsService.saveSettings(_settings, SettingsService.uidKey);
    notifyListeners();
  }

  Future<void> changeTheme(Color themeColor) async {
    _settings = _settings.copyWith(themeColor: themeColor);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.themeColorKey,
    );
    notifyListeners();
  }

  Future<void> changeThemeMode(ThemeMode themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.themeModeKey,
    );
    notifyListeners();
  }

  Future<void> changeMaxConcurrency(int maxConcurrency) async {
    _settings = _settings.copyWith(maxTaskConcurrency: maxConcurrency);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.maxTaskConcurrencyKey,
    );
    notifyListeners();
  }

  Future<void> changeMaxSpeed(double maxSpeed) async {
    _settings = _settings.copyWith(maxDownloadSpeed: maxSpeed);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.maxDownloadSpeedKey,
    );
    notifyListeners();
  }

  Future<void> changeFileNameRule(String fileNameRule) async {
    _settings = _settings.copyWith(fileNameRule: fileNameRule);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.fileNameRuleKey,
    );
    notifyListeners();
  }

  Future<void> changeVideoQuality(int videoQuality) async {
    _settings = _settings.copyWith(videoQuality: videoQuality);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.videoQualityKey,
    );
    notifyListeners();
  }

  Future<void> changeAudioQuality(int audioQuality) async {
    _settings = _settings.copyWith(audioQuality: audioQuality);
    await _settingsService.saveSettings(
      _settings,
      SettingsService.audioQualityKey,
    );
    notifyListeners();
  }
}
