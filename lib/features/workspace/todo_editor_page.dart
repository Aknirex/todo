import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'todo.dart';
import 'todo_workspace.dart';

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

  bool get _shouldDismissKeyboard =>
      !_keyboardDismissed && _editorFocusScopeNode.hasFocus;

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
    if (_editorFocusScopeNode.hasFocus && mounted) {
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

  Future<void> _saveExistingAndLeave({required bool routeAlreadyPopped}) async {
    if (_leaving) return;
    _leaving = true;
    await widget.workspace.updateTodo(_draftTodo());
    if (!routeAlreadyPopped && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _leaveFromPageBack() async {
    if (_leaving) return;
    _leaving = true;
    if (!widget.isNew) {
      await widget.workspace.updateTodo(_draftTodo());
    }
    if (mounted) Navigator.of(context).pop();
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

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime(today.year, today.month, today.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope<void>(
      canPop: !_shouldDismissKeyboard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _dismissKeyboard();
        } else if (!widget.isNew) {
          unawaited(_saveExistingAndLeave(routeAlreadyPopped: true));
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
                    DropdownButtonFormField<TodoPriority>(
                      key: const ValueKey('todo-priority-input'),
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: l10n.priorityLabel,
                      ),
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
                    const SizedBox(height: AppSpacing.medium),
                    InputDecorator(
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
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(
                      key: const ValueKey('todo-tags-input'),
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: l10n.tagsLabel,
                        hintText: l10n.tagsHint,
                      ),
                    ),
                    if (widget.isNew) ...[
                      const SizedBox(height: AppSpacing.large),
                      FilledButton(
                        key: const ValueKey('todo-create-button'),
                        onPressed: _createTodo,
                        child: Text(l10n.create),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(BuildContext context, DateTime? dueDate) {
    if (dueDate == null) return AppLocalizations.of(context).noDueDate;
    return MaterialLocalizations.of(context).formatCompactDate(dueDate);
  }
}

List<String> parseTodoTags(String input) {
  return normalizeTodoTags(input.split(','));
}
