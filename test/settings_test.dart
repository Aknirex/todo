import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('shared preferences settings survive a new store instance', () async {
    SharedPreferences.setMockInitialValues({});
    final firstStore = SharedPreferencesSettingsStore();
    const saved = AppSettings(
      themeMode: ThemeMode.dark,
      locale: Locale('zh', 'CN'),
    );

    await firstStore.save(saved);
    final loaded = await SharedPreferencesSettingsStore().load();

    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.locale, const Locale('zh', 'CN'));
  });
}
