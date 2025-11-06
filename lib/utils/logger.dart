import 'dart:io';

import 'package:bili_tracker/utils/platform.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

class MyLogger {
  static Future<Logger> create() async {
    final dir2 = Directory(p.join((await getRootPath()).path, 'logs'));
    if (!dir2.existsSync()) {
      await dir2.create(recursive: true);
    }
    final date = DateTime.now().toIso8601String().split('T')[0];
    final path = p.join(dir2.path, '$date.log');
    final logger = Logger(
      output: FileOutput(file: File(path), overrideExisting: false),
      printer: HybridPrinter(
        SimplePrinter(),
        error: PrettyPrinter(colors: false),
        fatal: PrettyPrinter(colors: false),
      ),
    );
    return logger;
  }
}
