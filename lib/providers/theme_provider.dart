import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void cycleTheme() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
  }

  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'Theo hệ thống',
        ThemeMode.light => 'Sáng',
        ThemeMode.dark => 'Tối',
      };
}
