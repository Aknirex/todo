import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'todo.dart';
import 'todo_workspace.dart';
import 'todo_history_actions.dart';

class TodoEditorPage extends StatefulWidget {
  const TodoEditorPage({required this.workspace, this.todo, super.key});

  final TodoWorkspace workspace;
  final Todo? todo;

  bool get isNew => todo == null;

  @override
  State<TodoEditorPage> createState() => _TodoEditorPageState();
}

class _TodoEditorPageState extends State<TodoEditorPage>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _detailController;
  late final TextEditingController _tagsController;
  late final FocusNode _detailFocusNode;
  late final FocusScopeNode _editorFocusScopeNode;
  late TodoPriority _priority;
  DateTime? _dueDate;
  bool _keyboardDismissed = false;
  bool _leaving = false;
  double _lastViewInset = 0;

  bool get _editorHasTextFocus =>
      _editorFocusScopeNode.hasFocus && !_editorFocusScopeNode.hasPrimaryFocus;

  bool get _shouldDismissKeyboard => !_keyboardDismissed && _editorHasTextFocus;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _detailController = TextEditingController(text: todo?.detail ?? '');
    _tagsController = TextEditingController(text: todo?.tags.join(', ') ?? '');
    _detailFocusNode = FocusNode();
    _editorFocusScopeNode = FocusScopeNode();
    _priority = todo?.priority ?? TodoPriority.medium;
    _dueDate = todo?.dueDate;
    WidgetsBinding.instance.addObserver(this);
    _editorFocusScopeNode.addListener(_handleFocusChange);
    if (widget.isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _detailFocusNode.requestFocus();
      });
    }
  }

  @override
  void didChangeMetrics() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final viewInset = views.first.viewInsets.bottom;
    if (_lastViewInset > 0 && viewInset == 0 && mounted) {
      setState(() => _keyboardDismissed = true);
    }
    _lastViewInset = viewInset;
  }

  void _handleFocusChange() {
    if (_editorHasTextFocus && mounted) {
      setState(() => _keyboardDismissed = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorFocusScopeNode.removeListener(_handleFocusChange);
    _editorFocusScopeNode.dispose();
    _detailFocusNode.dispose();
    _titleController.dispose();
    _detailController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _keyboardDismissed = true;
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    if (mounted) setState(() {});
  }

  Todo _draftTodo() {
    final todo = widget.todo!;
    return todo.copyWith(
      title: _titleController.text,
      detail: _detailController.text,
      priority: _priority,
      dueDate: _dueDate,
      clearDueDate: _dueDate == null,
      tags: parseTodoTags(_tagsController.text),
    );
  }

  Future<void> _leaveFromPageBack() async {
    if (_leaving) return;
    _leaving = true;
    try {
      if (!widget.isNew) {
        await widget.workspace.updateTodo(_draftTodo());
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _leaving = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
      }
    }
  }

  Future<void> _saveDraftAfterSystemPop() async {
    if (widget.isNew) return;
    try {
      await widget.workspace.updateTodo(_draftTodo());
    } catch (_) {
      // The route has already left the tree for a native back gesture.
    }
  }

  Future<void> _createTodo() async {
    if (_leaving) return;
    _leaving = true;
    await widget.workspace.createTodo(
      title: _titleController.text,
      detail: _detailController.text,
      priority: _priority,
      dueDate: _dueDate,
      tags: parseTodoTags(_tagsController.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteTodo() async {
    if (_leaving || widget.todo == null) return;
    _leaving = true;
    await widget.workspace.deleteTodo(widget.todo!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleHistoryChanged() async {
    if (!mounted || widget.todo == null) return;
    Todo? current;
    for (final todo in widget.workspace.current.todos) {
      if (todo.id == widget.todo!.id) {
        current = todo;
        break;
      }
    }
    if (current == null) {
      _leaving = true;
      Navigator.of(context).pop();
      return;
    }
    _titleController.text = current.title;
    _detailController.text = current.detail;
    _tagsController.text = current.tags.join(', ');
    setState(() {
      _priority = current!.priority;
      _dueDate = current.dueDate;
    });
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime(today.year, today.month, today.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(
        () => _dueDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope<void>(
      canPop: !_shouldDismissKeyboard && !_leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (!_leaving) unawaited(_saveDraftAfterSystemPop());
          return;
        }
        if (_shouldDismissKeyboard) {
          _dismissKeyboard();
        } else {
          unawaited(_leaveFromPageBack());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_leaveFromPageBack()),
          ),
          title: Text(widget.isNew ? l10n.newTodo : l10n.editTodo),
          actions: [
            if (!widget.isNew)
              TodoHistoryActions(
                workspace: widget.workspace,
                onHistoryChanged: _handleHistoryChanged,
              ),
            if (!widget.isNew)
              IconButton(
                key: const ValueKey('todo-detail-delete-button'),
                tooltip: l10n.deleteTodo,
                onPressed: () => unawaited(_deleteTodo()),
                icon: const Icon(Icons.delete_outline),
              ),
            const SizedBox(width: AppSpacing.small),
          ],
        ),
        body: SafeArea(
          child: FocusScope(
            node: _editorFocusScopeNode,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.medium,
                AppSpacing.page,
                AppSpacing.large,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('todo-title-input'),
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.titleLabel),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(
                      key: const ValueKey('todo-detail-input'),
                      controller: _detailController,
                      focusNode: _detailFocusNode,
                      autofocus: widget.isNew,
                      minLines: 4,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(labelText: l10n.detailLabel),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (widget.isNew)
                      _buildNewComposerFields(context, l10n)
                    else
                      _buildEditFields(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar:
            widget.isNew
                ? AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: _buildNewComposerActions(context, l10n),
                )
                : null,
      ),
    );
  }

  Widget _buildEditFields(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _priorityField(l10n),
        const SizedBox(height: AppSpacing.medium),
        _dueDateField(context, l10n),
        const SizedBox(height: AppSpacing.medium),
        _tagsField(l10n),
      ],
    );
  }

  Widget _buildNewComposerFields(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _priorityField(l10n)),
            const SizedBox(width: AppSpacing.small),
            Expanded(flex: 3, child: _tagsField(l10n)),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
      ],
    );
  }

  Widget _buildNewComposerActions(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.small,
        AppSpacing.page,
        AppSpacing.small,
      ),
      child: Row(
        children: [
          Expanded(child: _dueDateField(context, l10n)),
          const SizedBox(width: AppSpacing.small),
          SizedBox(
            width: 104,
            child: FilledButton(
              key: const ValueKey('todo-create-button'),
              onPressed: _createTodo,
              child: Text(l10n.create),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityField(AppLocalizations l10n) {
    return KeyedSubtree(
      key: ValueKey('todo-priority-value-${_priority.name}'),
      child: DropdownButtonFormField<TodoPriority>(
        key: const ValueKey('todo-priority-input'),
        isExpanded: true,
        initialValue: _priority,
        decoration: InputDecoration(labelText: l10n.priorityLabel),
        items: [
          DropdownMenuItem(
            value: TodoPriority.high,
            child: Text(l10n.highPriority),
          ),
          DropdownMenuItem(
            value: TodoPriority.medium,
            child: Text(l10n.mediumPriority),
          ),
          DropdownMenuItem(
            value: TodoPriority.low,
            child: Text(l10n.lowPriority),
          ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _priority = value);
        },
      ),
    );
  }

  Widget _dueDateField(BuildContext context, AppLocalizations l10n) {
    return InputDecorator(
      decoration: InputDecoration(labelText: l10n.dueDateLabel),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              key: const ValueKey('todo-due-date-input'),
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_formatDueDate(context, _dueDate)),
            ),
          ),
          if (_dueDate != null)
            IconButton(
              tooltip: l10n.clearDueDate,
              onPressed: () => setState(() => _dueDate = null),
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }

  Widget _tagsField(AppLocalizations l10n) {
    return TextField(
      key: const ValueKey('todo-tags-input'),
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: l10n.tagsLabel,
        hintText: l10n.tagsHint,
      ),
    );
  }

  String _formatDueDate(BuildContext context, DateTime? dueDate) {
    if (dueDate == null) return AppLocalizations.of(context).noDueDate;
    return MaterialLocalizations.of(context).formatCompactDate(dueDate);
  }
}

final RegExp _tagSeparators = RegExp(r'[,，]');

List<String> parseTodoTags(String input) {
  return normalizeTodoTags(input.split(_tagSeparators));
}
