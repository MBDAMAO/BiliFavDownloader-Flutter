// services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/settings.dart';

class SettingsService {
  static const String themeModeKey = 'themeMode';
  static const String notificationsKey = 'notifications';
  static const String languageKey = 'language';
  static const String fontSizeKey = 'fontSize';
  static const String cookiesKey = 'cookies';
  static const String midKey = 'mid';
  static const String usernameKey = 'username';
  static const String rankKey = 'rank';
  static const String uidKey = 'uid';
  static const String maxDownloadSpeedKey = 'maxDownloadSpeed';
  static const String maxTaskConcurrencyKey = 'maxTaskConcurrency';
  static const String themeColorKey = 'themeColor';
  static const String fileNameRuleKey = 'fileNameRule';
  static const String videoQualityKey = 'videoQuality';
  static const String audioQualityKey = 'audioQuality';

  Future<Settings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return Settings(
      fileNameRule:
          prefs.getString(fileNameRuleKey) ??
          Settings.defaultValues().fileNameRule,
      cookies: prefs.getString(cookiesKey) ?? Settings.defaultValues().cookies,
      themeMode: themeModeFromInt(
        prefs.getInt(themeModeKey) ?? Settings.defaultValues().themeMode.index,
      ),
      notificationsEnabled:
          prefs.getBool(notificationsKey) ??
          Settings.defaultValues().notificationsEnabled,
      language:
          prefs.getString(languageKey) ?? Settings.defaultValues().language,
      fontSize:
          prefs.getDouble(fontSizeKey) ?? Settings.defaultValues().fontSize,
      mid: prefs.getString(midKey) ?? Settings.defaultValues().mid,
      username:
          prefs.getString(usernameKey) ?? Settings.defaultValues().username,
      rank: prefs.getString(rankKey) ?? Settings.defaultValues().rank,
      uid: prefs.getString(uidKey) ?? Settings.defaultValues().uid,
      maxDownloadSpeed:
          prefs.getDouble(maxDownloadSpeedKey) ??
          Settings.defaultValues().maxDownloadSpeed,
      maxTaskConcurrency:
          prefs.getInt(maxTaskConcurrencyKey) ??
          Settings.defaultValues().maxTaskConcurrency,
      themeColor: hexToColor(
        prefs.getString(themeColorKey) ??
            Settings.defaultValues().themeColor.toARGB32().toString(),
      ),
      videoQuality:
          prefs.getInt(videoQualityKey) ??
          Settings.defaultValues().videoQuality,
      audioQuality:
          prefs.getInt(audioQualityKey) ??
          Settings.defaultValues().audioQuality,
    );
  }

  Future<void> saveSettings(Settings settings, String key) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case (cookiesKey):
        await prefs.setString(cookiesKey, settings.cookies);
      case (themeModeKey):
        await prefs.setInt(themeModeKey, themeModeToInt(settings.themeMode));
      case (notificationsKey):
        await prefs.setBool(notificationsKey, settings.notificationsEnabled);
      case (languageKey):
        await prefs.setString(languageKey, settings.language);
      case (fontSizeKey):
        await prefs.setDouble(fontSizeKey, settings.fontSize);
      case (midKey):
        await prefs.setString(midKey, settings.mid);
      case (usernameKey):
        await prefs.setString(usernameKey, settings.username);
      case (rankKey):
        await prefs.setString(rankKey, settings.rank);
      case (uidKey):
        await prefs.setString(uidKey, settings.uid);
      case (maxDownloadSpeedKey):
        await prefs.setDouble(maxDownloadSpeedKey, settings.maxDownloadSpeed);
      case (maxTaskConcurrencyKey):
        await prefs.setInt(maxTaskConcurrencyKey, settings.maxTaskConcurrency);
      case (themeColorKey):
        await prefs.setString(
          themeColorKey,
          settings.themeColor.toARGB32().toString(),
        );
      case (fileNameRuleKey):
        await prefs.setString(fileNameRuleKey, settings.fileNameRule);
      case (videoQualityKey):
        await prefs.setInt(videoQualityKey, settings.videoQuality);
      case (audioQualityKey):
        await prefs.setInt(audioQualityKey, settings.audioQuality);
      default:
    }
  }
}

// 将十六进制字符串转换为Color对象
Color hexToColor(String hexString) {
  return Color(int.parse(hexString));
}

// 主题模式转换函数
ThemeMode themeModeFromInt(int mode) {
  switch (mode) {
    case 0:
      return ThemeMode.system;
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

int themeModeToInt(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 0;
    case ThemeMode.light:
      return 1;
    case ThemeMode.dark:
      return 2;
  }
}

// 获取主题模式的中文名称
String getThemeModeName(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟随系统';
    case ThemeMode.light:
      return '明亮模式';
    case ThemeMode.dark:
      return '暗黑模式';
  }
}

// 获取主题模式的图标
IconData getThemeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.brightness_auto;
    case ThemeMode.light:
      return Icons.brightness_high;
    case ThemeMode.dark:
      return Icons.brightness_2;
  }
}
