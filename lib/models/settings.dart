import 'package:flutter/material.dart';

class Settings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String language;
  final double fontSize;
  final String cookies;
  final String username;
  final String uid;
  final String rank;
  final String mid;
  final String fileNameRule;
  final int maxTaskConcurrency;
  final double maxDownloadSpeed;
  final Color themeColor;
  final int videoQuality;
  final int audioQuality;

  Settings({
    required this.mid,
    required this.themeMode,
    required this.cookies,
    required this.notificationsEnabled,
    required this.language,
    required this.fontSize,
    required this.username,
    required this.uid,
    required this.fileNameRule,
    required this.rank,
    required this.maxDownloadSpeed,
    required this.maxTaskConcurrency,
    required this.themeColor,
    required this.videoQuality,
    required this.audioQuality,
  });

  Settings copyWith({
    bool? isDarkMode,
    String? cookies,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    String? language,
    String? mid,
    double? fontSize,
    String? username,
    String? uid,
    String? rank,
    double? maxDownloadSpeed,
    int? maxTaskConcurrency,
    String? fileNameRule,
    Color? themeColor,
    int? videoQuality,
    int? audioQuality,
  }) {
    return Settings(
      cookies: cookies ?? this.cookies,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      mid: mid ?? this.mid,
      username: username ?? this.username,
      uid: uid ?? this.uid,
      rank: rank ?? this.rank,
      maxDownloadSpeed: maxDownloadSpeed ?? this.maxDownloadSpeed,
      maxTaskConcurrency: maxTaskConcurrency ?? this.maxTaskConcurrency,
      fileNameRule: fileNameRule ?? this.fileNameRule,
      themeColor: themeColor ?? this.themeColor,
      videoQuality: videoQuality ?? this.videoQuality,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }

  static Settings defaultValues() {
    return Settings(
      cookies: 'none',
      themeMode: ThemeMode.dark,
      notificationsEnabled: true,
      language: 'zh',
      fontSize: 16.0,
      mid: '',
      username: '',
      uid: '',
      rank: '',
      fileNameRule: '{title}-{avid}-{cid}.mp4',
      maxDownloadSpeed: 10,
      maxTaskConcurrency: 1,
      themeColor: Colors.purple,
      videoQuality: -1, // -1 表示不限制
      audioQuality: -1, // -1 表示不限制
    );
  }
}
