import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light or dark, chosen on the Profil tab and remembered on the device.
/// Until someone chooses, the app follows the system.
class ThemeSettings extends ChangeNotifier {
  ThemeSettings({this._mode = ThemeMode.system, this.onChanged});

  /// Remembers the new choice, e.g. on the device.
  final void Function(ThemeMode mode)? onChanged;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  void choose(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    onChanged?.call(mode);
  }

  /// The choice saved on the device, and saves every new one there.
  static Future<ThemeSettings> load() async {
    final preferences = SharedPreferencesAsync();
    const key = 'theme';
    final saved = await preferences.getString(key);
    return ThemeSettings(
      mode: ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system,
      onChanged: (mode) => preferences.setString(key, mode.name),
    );
  }
}
