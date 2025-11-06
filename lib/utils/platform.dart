// utils/platform.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 获取应用程序的根存储目录
/// 不同平台返回不同的标准存储路径
Future<Directory> getRootPath() async {
  Directory appDir;
  String appName = 'biliTracker';

  if (Platform.isAndroid) {
    // 安卓平台
    // getExternalStorageDirectory() 返回外部存储目录
    // 通常路径为: /storage/emulated/0/Android/data/[应用包名]/files/
    // 该目录在应用卸载时会被自动清理
    appDir = (await getExternalStorageDirectory())!;
  } else if (Platform.isIOS) {
    // iOS平台
    // getApplicationDocumentsDirectory() 返回应用的文档目录
    // 路径通常为: /var/mobile/Containers/Data/Application/[UUID]/Documents/
    // 该目录会被iCloud自动备份，应用卸载时会被删除
    appDir = await getApplicationDocumentsDirectory();
    appDir = Directory(p.join(appDir.path, appName));
  } else if (Platform.isWindows) {
    // Windows平台
    // 文档目录通常为: C:\Users\[用户名]\Documents\[应用相关目录]
    appDir = await getApplicationDocumentsDirectory();
    appDir = Directory(p.join(appDir.path, appName));
  } else if (Platform.isMacOS) {
    // macOS平台
    // 文档目录通常为: ~/Documents/[应用相关目录]
    appDir = await getApplicationDocumentsDirectory();
    appDir = Directory(p.join(appDir.path, appName));
  } else if (Platform.isLinux) {
    // Linux平台
    // 通常为用户主目录下的特定目录: ~/.local/share/[应用包名]
    appDir = await getApplicationDocumentsDirectory();
    appDir = Directory(p.join(appDir.path, appName));
  } else {
    // 其他未明确处理的平台，使用默认文档目录
    appDir = await getApplicationDocumentsDirectory();
    appDir = Directory(p.join(appDir.path, appName));
  }
  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }

  return appDir;
}

/// 获取应用程序的缓存目录
/// 用于存储临时文件，可能会被系统自动清理
Future<Directory> getCachePath() async {
  return await getTemporaryDirectory();
}

/// 获取应用程序的文档目录
/// 用于存储用户生成的数据，不会被系统随意清理
Future<Directory> getDocumentsPath() async {
  return await getApplicationDocumentsDirectory();
}

Future<Directory> getDatabaseDirectory() async {
  final dir = Directory(p.join((await getRootPath()).path, 'db'));
  final filePath = p.join(dir.path, 'bili_tracker.db');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return Directory(filePath);
}

Future<Directory> getDownloadDirectory() async {
  return await _getDirWithName('download');
}

Future<Directory> getCoverDirectory() async {
  return await _getDirWithName('cover');
}

Future<Directory> getTempDirectory() async {
  return await _getDirWithName('temp');
}

Future<Directory> getLogsDirectory() async {
  return await _getDirWithName('logs');
}

Future<Directory> _getDirWithName(String folderName) async {
  final appDir = await getRootPath();
  final dir2 = Directory(p.join(appDir.path, folderName));
  if (await dir2.exists()) {
    return dir2;
  } else {
    final created = await dir2.create();
    if (await created.exists()) {
      return created;
    }
    throw Exception('无法访问$folderName目录');
  }
}

Future<void> requestVideoPermission() async {
  // >= 13
  if (Platform.isAndroid && Platform.version.compareTo('13') >= 0) {
    // Video permissions.
    if (await Permission.videos.isDenied || await Permission.videos.isPermanentlyDenied) {
      final state = await Permission.videos.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
    // Audio permissions.
    if (await Permission.audio.isDenied || await Permission.audio.isPermanentlyDenied) {
      final state = await Permission.audio.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
  } else {
    if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
      final state = await Permission.storage.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
  }
}
