import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers.dart';
import 'todo.dart';
import 'todo_workspace.dart';

class WorkspacePage extends ConsumerWidget {
  const WorkspacePage({required this.workspace, super.key});

  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.workspaceTitle),
          actions: [
            IconButton(
              tooltip: l10n.themeTooltip,
              icon: const Icon(Icons.brightness_6_outlined),
              onPressed: () => unawaited(_showThemeMenu(context, ref)),
            ),
            IconButton(
              tooltip: l10n.languageTooltip,
              onPressed: () => unawaited(
                ref.read(settingsControllerProvider.notifier).setLocale(
                  l10n.isEnglish
                      ? const Locale('zh', 'CN')
                      : const Locale('en'),
                ),
              ),
              icon: Text(
                l10n.currentLanguage,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: _WorkspaceContent(workspace: workspace),
        ),
      ),
    );
  }

  Future<void> _showThemeMenu(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final selected =
        ref.read(settingsControllerProvider).valueOrNull?.themeMode ??
            ThemeMode.system;
    final choice = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.themeMenuLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              _ThemeOption(
                label: l10n.themeSystem,
                value: ThemeMode.system,
                groupValue: selected,
              ),
              _ThemeOption(
                label: l10n.themeLight,
                value: ThemeMode.light,
                groupValue: selected,
              ),
              _ThemeOption(
                label: l10n.themeDark,
                value: ThemeMode.dark,
                groupValue: selected,
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && context.mounted) {
      await ref.read(settingsControllerProvider.notifier).setThemeMode(choice);
    }
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.minimumTouchTarget,
      child: RadioListTile<ThemeMode>(
        contentPadding: EdgeInsets.zero,
        value: value,
        groupValue: groupValue,
        onChanged: (value) => Navigator.of(context).pop(value),
        title: Text(label),
      ),
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({required this.workspace});

  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workspace,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final active = workspace.current.todos
            .where((todo) => !todo.completed)
            .toList(growable: false);
        final completed = workspace.current.todos
            .where((todo) => todo.completed)
            .toList(growable: false);
        final defaultList = workspace.current.lists.firstWhere(
          (list) => list.isDefault,
        );
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            tooltip: l10n.createTodo,
            onPressed: () => unawaited(workspace.createTodo()),
            child: const Icon(Icons.add),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      defaultList.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.section),
                    _TodoSection(
                      title: l10n.activeTodos,
                      todos: active,
                      workspace: workspace,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _TodoSection(
                      title: l10n.completedTodos,
                      todos: completed,
                      workspace: workspace,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodoSection extends StatelessWidget {
  const _TodoSection({
    required this.title,
    required this.todos,
    required this.workspace,
  });

  final String title;
  final List<Todo> todos;
  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        if (todos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Text(
                AppLocalizations.of(context).noTodos,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ...todos.map(
            (todo) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: _TodoRow(todo: todo, workspace: workspace),
            ),
          ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.todo, required this.workspace});

  final Todo todo;
  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        label: AppLocalizations.of(context).todoRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xSmall,
          ),
          child: Row(
            children: [
              Checkbox(
                value: todo.completed,
                onChanged: (_) => unawaited(workspace.toggleTodo(todo.id)),
              ),
              Expanded(
                child: todo.title.isEmpty
                    ? const SizedBox(height: AppDimensions.minimumTouchTarget)
                    : Text(
                        todo.title,
                        style: todo.completed
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
