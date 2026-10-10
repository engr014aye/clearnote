import 'package:flutter/cupertino.dart';
import 'database_helper.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themePrefKey = 'user_theme_brightness';
  Brightness _brightness = Brightness.light;

  Brightness get brightness => _brightness;
  bool get isDarkMode => _brightness == Brightness.dark;

  ThemeManager() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final value = await DatabaseHelper.instance.getSetting(_themePrefKey);
      if (value != null) {
        _brightness = value == 'dark' ? Brightness.dark : Brightness.light;
        notifyListeners();
      }
    } catch (_) {
      // Default to light mode
    }
  }

  Future<void> toggleTheme() async {
    _brightness = isDarkMode ? Brightness.light : Brightness.dark;
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting(
        _themePrefKey,
        isDarkMode ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  CupertinoThemeData get currentTheme {
    if (isDarkMode) {
      return const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF818CF8), // Vibrant Indigo
        scaffoldBackgroundColor: Color(0xFF0B0F19), // Deep Obsidian
        barBackgroundColor: Color(0xEB131B2E), // Translucent Dark Slate
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF818CF8),
          textStyle: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 16,
            letterSpacing: -0.2,
          ),
          navTitleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
        ),
      );
    } else {
      return const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF4F46E5), // Rich Indigo
        scaffoldBackgroundColor: Color(0xFFF8FAFC), // Pure Light Slate
        barBackgroundColor: Color(0xEBFFFFFF), // Translucent Pure White
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF4F46E5),
          textStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            letterSpacing: -0.2,
          ),
          navTitleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
        ),
      );
    }
  }
}
