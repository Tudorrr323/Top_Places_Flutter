import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/view_models/language_settings.dart';

void main() {
  test('Romanian until English is chosen, which is then remembered', () {
    final remembered = <Locale>[];
    final language = LanguageSettings(onChanged: remembered.add);
    var notified = 0;
    language.addListener(() => notified++);
    expect(language.isRomanian, isTrue);

    language.choose(LanguageSettings.english);
    language.choose(LanguageSettings.english);

    expect(language.locale, LanguageSettings.english);
    expect(notified, 1, reason: 'the same language twice changes nothing');
    expect(remembered, [LanguageSettings.english]);
  });
}
