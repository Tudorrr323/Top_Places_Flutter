import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/view_models/theme_settings.dart';

void main() {
  test('like the system until a theme is chosen, which is remembered', () {
    final remembered = <ThemeMode>[];
    final theme = ThemeSettings(onChanged: remembered.add);
    var notified = 0;
    theme.addListener(() => notified++);
    expect(theme.mode, ThemeMode.system);

    theme.choose(ThemeMode.dark);
    theme.choose(ThemeMode.dark);

    expect(theme.mode, ThemeMode.dark);
    expect(notified, 1, reason: 'the same theme twice changes nothing');
    expect(remembered, [ThemeMode.dark]);
  });
}
