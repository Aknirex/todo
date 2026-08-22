import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (_) => SharedPreferencesSettingsStore(),
);

enum PersistedThemeMode { system, light, dark }

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  final ThemeMode themeMode;
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

abstract interface class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  static const themeKey = 'settings.themeMode';
  static const localeKey = 'settings.locale';

  @override
  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final theme = switch (preferences.getString(themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = switch (preferences.getString(localeKey)) {
      'en' => const Locale('en'),
      'zh-CN' => const Locale('zh', 'CN'),
      _ => null,
    };
    return AppSettings(themeMode: theme, locale: locale);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final theme = switch (settings.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await preferences.setString(themeKey, theme);
    final locale = settings.locale;
    if (locale == null) {
      await preferences.remove(localeKey);
    } else if (locale.languageCode == 'en') {
      await preferences.setString(localeKey, 'en');
    } else {
      await preferences.setString(localeKey, 'zh-CN');
    }
  }
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.value = const AppSettings()]);

  AppSettings value;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsStoreProvider).load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _update((settings) => settings.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    await _update((settings) => settings.copyWith(locale: locale));
  }

  Future<void> _update(AppSettings Function(AppSettings) update) async {
    final current = state.valueOrNull ?? const AppSettings();
    final next = update(current);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).save(next);
  }
}
