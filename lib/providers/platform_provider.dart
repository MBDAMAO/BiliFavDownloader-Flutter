import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlatformProvider with ChangeNotifier {
  String _platform = 'pornhub';

  PlatformProvider() {
    SharedPreferences.getInstance().then((prefs) {
      _platform = prefs.getString('x_platform') ?? 'pornhub';
      notifyListeners();
    });
  }

  String get platform {
    return _platform;
  }

  void setPlatform(String platform) async {
    _platform = platform;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('x_platform', platform);
    notifyListeners();
  }
}
