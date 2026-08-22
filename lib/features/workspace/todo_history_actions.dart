import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import 'todo_workspace.dart';

class TodoHistoryActions extends StatelessWidget {
  const TodoHistoryActions({
    required this.workspace,
    this.onHistoryChanged,
    super.key,
  });

  final TodoWorkspace workspace;
  final Future<void> Function()? onHistoryChanged;

  Future<void> _undo() async {
    if (await workspace.undo()) await onHistoryChanged?.call();
  }

  Future<void> _redo() async {
    if (await workspace.redo()) await onHistoryChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: workspace,
      builder:
          (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('undo-button'),
                tooltip: l10n.undo,
                onPressed: workspace.canUndo ? () => unawaited(_undo()) : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: const ValueKey('redo-button'),
                tooltip: l10n.redo,
                onPressed: workspace.canRedo ? () => unawaited(_redo()) : null,
                icon: const Icon(Icons.redo),
              ),
            ],
          ),
    );
  }
}
