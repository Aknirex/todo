import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aknirex_todo/core/settings/settings_controller.dart';

void main() {
  test('settings store persists theme and locale through the seam', () async {
    final store = MemorySettingsStore();
    const settings = AppSettings(
      themeMode: ThemeMode.dark,
      locale: Locale('en'),
    );

    await store.save(settings);

    expect(await store.load(), same(store.value));
    expect(store.value.themeMode, ThemeMode.dark);
    expect(store.value.locale?.languageCode, 'en');
  });
}
