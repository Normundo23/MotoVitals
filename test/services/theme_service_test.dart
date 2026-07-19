import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_vitals/services/theme_service.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial theme is dark', () {
      final themeService = ThemeService();
      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('toggleTheme changes theme and saves to prefs', () async {
      final themeService = ThemeService();
      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('setTheme changes theme and saves to prefs', () async {
      final themeService = ThemeService();
      await themeService.setTheme(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('init loads theme from prefs', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final themeService = ThemeService();
      await themeService.init();
      expect(themeService.themeMode, ThemeMode.light);
    });
  });
}
