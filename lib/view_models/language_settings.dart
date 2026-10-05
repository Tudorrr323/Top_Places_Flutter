import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language of the app, chosen on the Profil tab and remembered on the
/// device. Romanian until someone chooses English.
class LanguageSettings extends ChangeNotifier {
  LanguageSettings({this._locale = romanian, this.onChanged});

  static const romanian = Locale('ro');
  static const english = Locale('en');
  static const supported = [romanian, english];

  /// Remembers the new language, e.g. on the device.
  final void Function(Locale locale)? onChanged;

  Locale _locale;

  Locale get locale => _locale;

  bool get isRomanian => _locale == romanian;

  void choose(Locale locale) {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    onChanged?.call(locale);
  }

  /// The language saved on the device, and saves every new choice there.
  static Future<LanguageSettings> load() async {
    final preferences = SharedPreferencesAsync();
    const key = 'language';
    final saved = await preferences.getString(key);
    return LanguageSettings(
      locale: saved == english.languageCode ? english : romanian,
      onChanged: (locale) => preferences.setString(key, locale.languageCode),
    );
  }
}
