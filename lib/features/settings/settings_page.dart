import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/backup_service.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/settings/settings_controller.dart';
import '../../providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(settingsControllerProvider).valueOrNull ??
        const AppSettings();
    final systemLocale =
        Localizations.localeOf(context).languageCode == 'en'
            ? const Locale('en')
            : const Locale('zh', 'CN');
    final selectedLocale = settings.locale ?? systemLocale;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            _LanguageOption(
              label: l10n.languageChinese,
              value: const Locale('zh', 'CN'),
              groupValue: selectedLocale,
              onChanged:
                  (locale) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setLocale(locale),
                  ),
            ),
            _LanguageOption(
              label: l10n.languageEnglish,
              value: const Locale('en'),
              groupValue: selectedLocale,
              onChanged:
                  (locale) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setLocale(locale),
                  ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              l10n.themeMenuLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            _ThemeOption(
              label: l10n.themeSystem,
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged:
                  (mode) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(mode),
                  ),
            ),
            _ThemeOption(
              label: l10n.themeLight,
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged:
                  (mode) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(mode),
                  ),
            ),
            _ThemeOption(
              label: l10n.themeDark,
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged:
                  (mode) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(mode),
                  ),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.priorityColorsLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  key: const ValueKey('priority-colors-reset'),
                  onPressed:
                      () => unawaited(
                        ref
                            .read(settingsControllerProvider.notifier)
                            .resetPriorityColors(),
                      ),
                  child: Text(l10n.resetPriorityColors),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _PriorityColorRow(
              key: const ValueKey('priority-color-high'),
              label: l10n.highPriority,
              color: settings.priorityPalette.high,
              onPick:
                  (color) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setPriorityColor(PrioritySlot.high, color),
                  ),
            ),
            _PriorityColorRow(
              key: const ValueKey('priority-color-medium'),
              label: l10n.mediumPriority,
              color: settings.priorityPalette.medium,
              onPick:
                  (color) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setPriorityColor(PrioritySlot.medium, color),
                  ),
            ),
            _PriorityColorRow(
              key: const ValueKey('priority-color-low'),
              label: l10n.lowPriority,
              color: settings.priorityPalette.low,
              onPick:
                  (color) => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setPriorityColor(PrioritySlot.low, color),
                  ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              l10n.backupLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            FilledButton.icon(
              key: const ValueKey('backup-export-button'),
              onPressed: () => unawaited(_export(context, ref)),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.exportBackup),
            ),
            const SizedBox(height: AppSpacing.small),
            OutlinedButton.icon(
              key: const ValueKey('backup-import-button'),
              onPressed: () => unawaited(_import(context, ref)),
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.importBackup),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      final json = await ref
          .read(backupServiceProvider.future)
          .then((service) => service.exportJson());
      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupCopied)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupExportFailed)));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final source = clipboard?.text;
    if (source == null || source.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noBackupToImport)));
      }
      return;
    }
    try {
      final result = await ref
          .read(backupServiceProvider.future)
          .then((service) => service.importJson(source));
      if (context.mounted) {
        if (result.hasConflicts) {
          await showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(l10n.importConflicts),
                  content: SingleChildScrollView(
                    child: Text(
                      result.conflicts
                          .map(
                            (conflict) =>
                                '${conflict.recordType} ${conflict.id}: '
                                '${conflict.reason}',
                          )
                          .join('\n'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel,
                      ),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.importSucceeded)));
        }
      }
      ref.invalidate(settingsControllerProvider);
      ref.invalidate(todoWorkspaceProvider);
    } on BackupValidationException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupImportFailed)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupImportFailed)));
      }
    }
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final Locale value;
  final Locale groupValue;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<Locale>(
      contentPadding: EdgeInsets.zero,
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      title: Text(label),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      contentPadding: EdgeInsets.zero,
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      title: Text(label),
    );
  }
}

const _priorityColorChoices = <Color>[
  Color(0xFFE5484D),
  Color(0xFFF76B15),
  Color(0xFFF5B301),
  Color(0xFFCDA000),
  Color(0xFF46A758),
  Color(0xFF12A594),
  Color(0xFF0091FF),
  Color(0xFF315CFF),
  Color(0xFF8E4EC6),
  Color(0xFFC13AE0),
  Color(0xFFE93D82),
  Color(0xFF7C7C86),
  Color(0xFF6F4E37),
  Color(0xFF11131A),
];

class _PriorityColorRow extends StatelessWidget {
  const _PriorityColorRow({
    required this.label,
    required this.color,
    required this.onPick,
    super.key,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: SizedBox(
        width: AppDimensions.minimumTouchTarget,
        height: AppDimensions.minimumTouchTarget,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: const SizedBox(width: 28, height: 28),
          ),
        ),
      ),
      onTap: () => unawaited(_chooseColor(context)),
    );
  }

  Future<void> _chooseColor(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<Color>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.chooseColor),
            content: SizedBox(
              width: 280,
              child: Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final choice in _priorityColorChoices)
                    _ColorChoice(
                      color: choice,
                      selected: choice == color,
                      onTap: () => Navigator.of(context).pop(choice),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ),
    );
    if (selected != null) onPick(selected);
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border =
        selected
            ? Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: 3,
            )
            : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: border,
        ),
        child:
            selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
      ),
    );
  }
}
