import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers.dart';
import '../settings/settings_page.dart';
import 'todo.dart';
import 'todo_editor_page.dart';
import 'todo_history_actions.dart';
import 'todo_query.dart';
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
            _WorkspaceActions(
              workspace: workspace,
              onTheme: () => unawaited(_showThemeMenu(context, ref)),
            ),
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

class _WorkspaceActions extends ConsumerWidget {
  const _WorkspaceActions({required this.workspace, required this.onTheme});

  final TodoWorkspace workspace;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (MediaQuery.sizeOf(context).width < 600) {
      return ListenableBuilder(
        listenable: workspace,
        builder: (context, _) => PopupMenuButton<_WorkspaceAction>(
          key: const ValueKey('workspace-actions-menu'),
          tooltip: MaterialLocalizations.of(context).showMenuTooltip,
          onSelected: (action) {
            switch (action) {
              case _WorkspaceAction.theme:
                onTheme();
              case _WorkspaceAction.undo:
                unawaited(workspace.undo());
              case _WorkspaceAction.redo:
                unawaited(workspace.redo());
              case _WorkspaceAction.settings:
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _WorkspaceAction.theme,
              child: Text(l10n.themeMenuLabel),
            ),
            PopupMenuItem(
              value: _WorkspaceAction.undo,
              enabled: workspace.canUndo,
              child: Text(l10n.undo),
            ),
            PopupMenuItem(
              value: _WorkspaceAction.redo,
              enabled: workspace.canRedo,
              child: Text(l10n.redo),
            ),
            PopupMenuItem(
              value: _WorkspaceAction.settings,
              child: Text(l10n.settingsTitle),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.themeTooltip,
          icon: const Icon(Icons.brightness_6_outlined),
          onPressed: onTheme,
        ),
        IconButton(
          tooltip: l10n.languageTooltip,
          onPressed: () => unawaited(
            ref
                .read(settingsControllerProvider.notifier)
                .setLocale(
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
        TodoHistoryActions(workspace: workspace),
        IconButton(
          tooltip: l10n.settingsTooltip,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => unawaited(
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
      ],
    );
  }
}

enum _WorkspaceAction { theme, undo, redo, settings }

class _WorkspaceContent extends StatefulWidget {
  const _WorkspaceContent({required this.workspace});

  final TodoWorkspace workspace;

  @override
  State<_WorkspaceContent> createState() => _WorkspaceContentState();
}

class _WorkspaceContentState extends State<_WorkspaceContent> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  TodoQuery _query = const TodoQuery();

  TodoWorkspace get workspace => widget.workspace;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = _query.copyWith(search: value));
    });
  }

  void _setQuery(TodoQuery query) => setState(() => _query = query);

  void _togglePriority(TodoPriority priority) {
    final priorities = Set<TodoPriority>.of(_query.priorities);
    if (!priorities.add(priority)) priorities.remove(priority);
    _setQuery(_query.copyWith(priorities: priorities));
  }

  void _toggleTag(String tag) {
    final tags = Set<String>.of(_query.tags);
    if (!tags.add(tag)) tags.remove(tag);
    _setQuery(_query.copyWith(tags: tags));
  }

  void _toggleDueDate(TodoDueDateFilter filter) {
    final filters = Set<TodoDueDateFilter>.of(_query.dueDateFilters);
    if (!filters.add(filter)) filters.remove(filter);
    _setQuery(_query.copyWith(dueDateFilters: filters));
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _setQuery(const TodoQuery());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workspace,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final result = workspace.queryTodos(query: _query);
        final active = result.matches
            .where((match) => !match.todo.completed)
            .toList(growable: false);
        final completed = result.matches
            .where((match) => match.todo.completed)
            .toList(growable: false);
        final allTodos = workspace.current.todos;
        final hasQuery =
            _query.search.trim().isNotEmpty ||
            _query.priorities.isNotEmpty ||
            _query.tags.isNotEmpty ||
            _query.completed != null ||
            _query.dueDateFilters.isNotEmpty;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: workspace.current.lists.isEmpty
              ? null
              : FloatingActionButton(
                  tooltip: l10n.createTodo,
                  onPressed: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TodoEditorPage(workspace: workspace),
                      ),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
          body: Center(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.medium,
                0,
                AppSpacing.section + AppDimensions.appBarHeight,
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (workspace.current.lists.isEmpty)
                        const _EmptyWorkspaceState()
                      else
                        for (final list in workspace.current.lists) ...[
                          Text(
                            list.name,
                            style: Theme.of(context).textTheme.displaySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          TextField(
                            key: const ValueKey('todo-search-input'),
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            scrollPadding: const EdgeInsets.only(
                              bottom:
                                  AppSpacing.section +
                                  AppDimensions.appBarHeight,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.searchTodos,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: MaterialLocalizations.of(
                                        context,
                                      ).deleteButtonTooltip,
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          _QueryControls(
                            query: _query,
                            availableTags: allTodos
                                .expand((todo) => todo.tags)
                                .toSet()
                                .toList(growable: false),
                            onPrioritySelected: _togglePriority,
                            onTagSelected: _toggleTag,
                            onCompletedSelected: (completed) => _setQuery(
                              completed == null
                                  ? _query.copyWith(clearCompleted: true)
                                  : _query.copyWith(completed: completed),
                            ),
                            onDueDateSelected: _toggleDueDate,
                            onSortSelected: (sort) =>
                                _setQuery(_query.copyWith(sort: sort)),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          if (result.matches.isEmpty &&
                              hasQuery &&
                              allTodos.isNotEmpty)
                            _EmptyQueryState(onClear: _clearQuery)
                          else ...[
                            _TodoSection(
                              title: l10n.activeTodos,
                              matches: active
                                  .where(
                                    (match) => match.todo.listId == list.id,
                                  )
                                  .toList(growable: false),
                              workspace: workspace,
                            ),
                            const SizedBox(height: AppSpacing.large),
                            _TodoSection(
                              title: l10n.completedTodos,
                              matches: completed
                                  .where(
                                    (match) => match.todo.listId == list.id,
                                  )
                                  .toList(growable: false),
                              workspace: workspace,
                            ),
                            const SizedBox(height: AppSpacing.large),
                          ],
                          const SizedBox(height: AppSpacing.large),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueryControls extends StatelessWidget {
  const _QueryControls({
    required this.query,
    required this.availableTags,
    required this.onPrioritySelected,
    required this.onTagSelected,
    required this.onCompletedSelected,
    required this.onDueDateSelected,
    required this.onSortSelected,
  });

  final TodoQuery query;
  final List<String> availableTags;
  final ValueChanged<TodoPriority> onPrioritySelected;
  final ValueChanged<String> onTagSelected;
  final ValueChanged<bool?> onCompletedSelected;
  final ValueChanged<TodoDueDateFilter> onDueDateSelected;
  final ValueChanged<TodoSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PriorityMenu(query: query, onSelected: onPrioritySelected),
              _TagMenu(
                query: query,
                availableTags: availableTags,
                onSelected: onTagSelected,
              ),
              PopupMenuButton<_CompletionChoice>(
                key: const ValueKey('todo-status-filter'),
                onSelected: (choice) => onCompletedSelected(choice.value),
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: _CompletionChoice.all,
                    checked: query.completed == null,
                    child: Text(l10n.allFilter),
                  ),
                  CheckedPopupMenuItem(
                    value: _CompletionChoice.active,
                    checked: query.completed == false,
                    child: Text(l10n.activeFilter),
                  ),
                  CheckedPopupMenuItem(
                    value: _CompletionChoice.completed,
                    checked: query.completed == true,
                    child: Text(l10n.completedFilter),
                  ),
                ],
                child: _FilterButtonLabel(
                  label: _statusLabel(l10n, query.completed),
                ),
              ),
              _DueDateMenu(query: query, onSelected: onDueDateSelected),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        KeyedSubtree(
          key: ValueKey('todo-sort-value-${query.sort.name}'),
          child: DropdownButtonFormField<TodoSort>(
            key: const ValueKey('todo-sort-filter'),
            initialValue: query.sort,
            decoration: InputDecoration(labelText: l10n.sortLabel),
            items: [
              DropdownMenuItem(
                value: TodoSort.activeNewest,
                child: Text(l10n.sortActiveNewest),
              ),
              DropdownMenuItem(
                value: TodoSort.priority,
                child: Text(l10n.sortPriority),
              ),
              DropdownMenuItem(
                value: TodoSort.dueDate,
                child: Text(l10n.sortDueDate),
              ),
              DropdownMenuItem(
                value: TodoSort.titleAscending,
                child: Text(l10n.sortTitleAscending),
              ),
              DropdownMenuItem(
                value: TodoSort.titleDescending,
                child: Text(l10n.sortTitleDescending),
              ),
            ],
            onChanged: (sort) {
              if (sort != null) onSortSelected(sort);
            },
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, bool? completed) {
    if (completed == true) return l10n.completedFilter;
    if (completed == false) return l10n.activeFilter;
    return l10n.filterStatus;
  }
}

enum _CompletionChoice {
  all(null),
  active(false),
  completed(true);

  const _CompletionChoice(this.value);

  final bool? value;
}

class _PriorityMenu extends StatelessWidget {
  const _PriorityMenu({required this.query, required this.onSelected});

  final TodoQuery query;
  final ValueChanged<TodoPriority> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<TodoPriority>(
      key: const ValueKey('todo-priority-filter'),
      onSelected: onSelected,
      itemBuilder: (context) => TodoPriority.values
          .map(
            (priority) => CheckedPopupMenuItem(
              value: priority,
              checked: query.priorities.contains(priority),
              child: Text(_priorityLabel(l10n, priority)),
            ),
          )
          .toList(growable: false),
      child: _FilterButtonLabel(label: l10n.filterPriority),
    );
  }
}

class _TagMenu extends StatelessWidget {
  const _TagMenu({
    required this.query,
    required this.availableTags,
    required this.onSelected,
  });

  final TodoQuery query;
  final List<String> availableTags;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      key: const ValueKey('todo-tag-filter'),
      onSelected: onSelected,
      itemBuilder: (context) {
        if (availableTags.isEmpty) {
          return [PopupMenuItem(enabled: false, child: Text(l10n.noTags))];
        }
        return availableTags
            .map(
              (tag) => CheckedPopupMenuItem(
                value: tag,
                checked: query.tags.contains(tag),
                child: Text(tag),
              ),
            )
            .toList(growable: false);
      },
      child: _FilterButtonLabel(label: l10n.filterTags),
    );
  }
}

class _DueDateMenu extends StatelessWidget {
  const _DueDateMenu({required this.query, required this.onSelected});

  final TodoQuery query;
  final ValueChanged<TodoDueDateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      TodoDueDateFilter.today: l10n.todayDueDate,
      TodoDueDateFilter.thisWeek: l10n.thisWeekDueDate,
      TodoDueDateFilter.thisMonth: l10n.thisMonthDueDate,
      TodoDueDateFilter.overdue: l10n.overdueDueDate,
      TodoDueDateFilter.noDueDate: l10n.noDueDateFilter,
    };
    return PopupMenuButton<TodoDueDateFilter>(
      key: const ValueKey('todo-due-date-filter'),
      onSelected: onSelected,
      itemBuilder: (context) => TodoDueDateFilter.values
          .map(
            (filter) => CheckedPopupMenuItem(
              value: filter,
              checked: query.dueDateFilters.contains(filter),
              child: Text(labels[filter]!),
            ),
          )
          .toList(growable: false),
      child: _FilterButtonLabel(label: l10n.filterDueDate),
    );
  }
}

class _EmptyQueryState extends StatelessWidget {
  const _EmptyQueryState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const ValueKey('todo-empty-results'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(l10n.noMatchingTodos),
            const SizedBox(height: AppSpacing.small),
            TextButton(
              key: const ValueKey('todo-clear-query'),
              onPressed: onClear,
              child: Text(l10n.clearSearchAndFilters),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkspaceState extends StatelessWidget {
  const _EmptyWorkspaceState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              l10n.emptyWorkspace,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(l10n.emptyWorkspaceHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _priorityLabel(AppLocalizations l10n, TodoPriority priority) {
  switch (priority) {
    case TodoPriority.high:
      return l10n.highPriority;
    case TodoPriority.medium:
      return l10n.mediumPriority;
    case TodoPriority.low:
      return l10n.lowPriority;
  }
}

class _TodoSection extends StatelessWidget {
  const _TodoSection({
    required this.title,
    required this.matches,
    required this.workspace,
  });

  final String title;
  final List<TodoMatch> matches;
  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        if (matches.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Text(
                title == l10n.activeTodos
                    ? l10n.noActiveTodos
                    : l10n.noCompletedTodos,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: _TodoRow(match: match, workspace: workspace),
            ),
          ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.match, required this.workspace});

  final TodoMatch match;
  final TodoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final todo = match.todo;
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
              SizedBox(
                width: AppDimensions.minimumTouchTarget,
                height: AppDimensions.minimumTouchTarget,
                child: Checkbox(
                  value: todo.completed,
                  onChanged: (_) => unawaited(workspace.toggleTodo(todo.id)),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TodoEditorPage(workspace: workspace, todo: todo),
                      ),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppDimensions.minimumTouchTarget,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todo.title.isEmpty)
                            const SizedBox(
                              height: AppDimensions.minimumTouchTarget,
                            )
                          else
                            _HighlightedTitle(match: match),
                          if (todo.tags.isNotEmpty || todo.dueDate != null) ...[
                            const SizedBox(height: AppSpacing.xSmall),
                            _TodoMetadata(todo: todo),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('todo-delete-${todo.id}'),
                tooltip: AppLocalizations.of(context).deleteTodo,
                onPressed: () => unawaited(workspace.deleteTodo(todo.id)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedTitle extends StatelessWidget {
  const _HighlightedTitle({required this.match});

  final TodoMatch match;

  @override
  Widget build(BuildContext context) {
    final title = match.todo.title;
    if (match.titleRanges.isEmpty) {
      return Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: match.todo.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      );
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in match.titleRanges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: title.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: title.substring(range.start, range.end),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      cursor = range.end;
    }
    if (cursor < title.length) {
      spans.add(TextSpan(text: title.substring(cursor)));
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(
          decoration: match.todo.completed ? TextDecoration.lineThrough : null,
        ),
        children: spans,
      ),
    );
  }
}

class _FilterButtonLabel extends StatelessWidget {
  const _FilterButtonLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.minimumTouchTarget,
        minHeight: AppDimensions.minimumTouchTarget,
      ),
      child: Center(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TodoMetadata extends StatelessWidget {
  const _TodoMetadata({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      if (todo.dueDate != null)
        MaterialLocalizations.of(context).formatCompactDate(todo.dueDate!),
      ...todo.tags,
    ];
    return Wrap(
      spacing: AppSpacing.xSmall,
      runSpacing: AppSpacing.xSmall,
      children: [
        _MetadataBadge(
          label: _priorityLabel(l10n, todo.priority),
          color: Theme.of(context).colorScheme.primary,
        ),
        for (final label in labels) _MetadataBadge(label: label),
      ],
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12) ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
