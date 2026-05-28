import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();
  static const _keyTheme = 'theme_mode';
  static const _keyLocale = 'locale';
  static const _keyTextScale = 'text_scale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  double _textScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  double get textScale => _textScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyTheme);
    _themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final localeStr = prefs.getString(_keyLocale);
    _locale = localeStr != null ? Locale(localeStr) : null;
    _textScale = prefs.getDouble(_keyTextScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(0.8, 1.4);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, _textScale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_keyLocale);
    } else {
      await prefs.setString(_keyLocale, locale.languageCode);
    }
  }

  static Future<bool> checkConsent(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('consent_$userId') ?? false;
  }

  static Future<void> saveConsent(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_$userId', true);
  }
}
