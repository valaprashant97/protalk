import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static ThemeService get to => _instance;

  static const String _keyThemeMode = 'app_theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;
  Rx<ThemeMode> get themeModeRx => _themeMode;

  /// Returns whether the current active theme resolves to dark mode
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode.value == ThemeMode.dark;
  }

  /// Initializes ThemeService and restores user's saved preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_keyThemeMode);
      if (savedMode == 'light') {
        _themeMode.value = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode.value = ThemeMode.dark;
      } else {
        _themeMode.value = ThemeMode.system;
      }
    } catch (_) {
      _themeMode.value = ThemeMode.system;
    }
  }

  /// Sets and persists new theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'system';
      if (mode == ThemeMode.light) {
        modeStr = 'light';
      } else if (mode == ThemeMode.dark) {
        modeStr = 'dark';
      }
      await prefs.setString(_keyThemeMode, modeStr);
    } catch (_) {}
  }
}
