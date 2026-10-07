import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _themeKey = 'fixxi_theme_dark';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> isDarkMode() async {
    final p = await _getPrefs;
    return p.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await _getPrefs;
    await p.setBool(_themeKey, value);
  }
}
