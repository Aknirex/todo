import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/design_tokens.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (_) => SharedPreferencesSettingsStore(),
);

enum PersistedThemeMode { system, light, dark }

enum PrioritySlot { high, medium, low }

class PriorityPalette {
  const PriorityPalette({
    this.high = AppColors.priorityHighDefault,
    this.medium = AppColors.priorityMediumDefault,
    this.low = AppColors.priorityLowDefault,
  });

  final Color high;
  final Color medium;
  final Color low;

  Color of(PrioritySlot slot) => switch (slot) {
    PrioritySlot.high => high,
    PrioritySlot.medium => medium,
    PrioritySlot.low => low,
  };

  PriorityPalette withSlot(PrioritySlot slot, Color color) {
    switch (slot) {
      case PrioritySlot.high:
        return PriorityPalette(high: color, medium: medium, low: low);
      case PrioritySlot.medium:
        return PriorityPalette(high: high, medium: color, low: low);
      case PrioritySlot.low:
        return PriorityPalette(high: high, medium: medium, low: color);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PriorityPalette &&
      other.high == high &&
      other.medium == medium &&
      other.low == low;

  @override
  int get hashCode => Object.hash(high, medium, low);
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.priorityPalette = const PriorityPalette(),
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final PriorityPalette priorityPalette;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    PriorityPalette? priorityPalette,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      priorityPalette: priorityPalette ?? this.priorityPalette,
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
  static const priorityHighKey = 'settings.priorityColor.high';
  static const priorityMediumKey = 'settings.priorityColor.medium';
  static const priorityLowKey = 'settings.priorityColor.low';

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
    final palette = PriorityPalette(
      high: _colorFor(
        preferences.getInt(priorityHighKey),
        AppColors.priorityHighDefault,
      ),
      medium: _colorFor(
        preferences.getInt(priorityMediumKey),
        AppColors.priorityMediumDefault,
      ),
      low: _colorFor(
        preferences.getInt(priorityLowKey),
        AppColors.priorityLowDefault,
      ),
    );
    return AppSettings(
      themeMode: theme,
      locale: locale,
      priorityPalette: palette,
    );
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
    final palette = settings.priorityPalette;
    await preferences.setInt(priorityHighKey, palette.high.toARGB32());
    await preferences.setInt(priorityMediumKey, palette.medium.toARGB32());
    await preferences.setInt(priorityLowKey, palette.low.toARGB32());
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

  Future<void> setPriorityColor(PrioritySlot slot, Color color) async {
    await _update(
      (settings) => settings.copyWith(
        priorityPalette: settings.priorityPalette.withSlot(slot, color),
      ),
    );
  }

  Future<void> resetPriorityColors() async {
    await _update(
      (settings) => settings.copyWith(priorityPalette: const PriorityPalette()),
    );
  }

  Future<void> _update(AppSettings Function(AppSettings) update) async {
    final current = state.valueOrNull ?? const AppSettings();
    final next = update(current);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).save(next);
  }
}

Color _colorFor(int? value, Color fallback) {
  return value == null ? fallback : Color(value);
}
