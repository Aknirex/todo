import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets('English workspace shell is fully localized', (tester) async {
    await _verifyLocale(tester, const Locale('en'), {
      'activeEmpty': 'No active Todos.',
      'completedEmpty': 'No completed Todos.',
      'priority': 'Priority',
      'tags': 'Tags',
      'dueDate': 'Due date',
      'undo': 'Undo',
      'redo': 'Redo',
      'newTodo': 'New Todo',
      'title': 'Title',
      'detail': 'Detail',
    });
  });

  testWidgets('Chinese workspace shell is fully localized', (tester) async {
    await _verifyLocale(tester, const Locale('zh', 'CN'), {
      'activeEmpty': '没有未完成的 Todo。',
      'completedEmpty': '没有已完成的 Todo。',
      'priority': '优先级',
      'tags': '标签',
      'dueDate': '日期',
      'undo': '撤销',
      'redo': '重做',
      'newTodo': '新建 Todo',
      'title': '标题',
      'detail': '详情',
    });
  });
}

Future<void> _verifyLocale(
  WidgetTester tester,
  Locale locale,
  Map<String, String> text,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
  await workspace.start();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(
          MemorySettingsStore(AppSettings(locale: locale)),
        ),
        todoWorkspaceProvider.overrideWith((ref) async => workspace),
      ],
      child: const TodoApp(),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text(text['activeEmpty']!), findsOneWidget);
  expect(find.text(text['completedEmpty']!), findsOneWidget);
  expect(find.text('A calm place for the next thing.'), findsNothing);
  expect(find.text(text['tags']!), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('workspace-actions-menu')));
  await tester.pumpAndSettle();
  expect(find.text(text['undo']!), findsOneWidget);
  expect(find.text(text['redo']!), findsOneWidget);
  expect(
    find.text(locale.languageCode == 'en' ? '切换到简体中文' : 'Switch to English'),
    findsNothing,
  );
  await tester.tapAt(const Offset(20, 300));
  await tester.pumpAndSettle();

  await tester.tap(
    find.byTooltip(text['newTodo'] == 'New Todo' ? 'Create Todo' : '创建 Todo'),
  );
  await tester.pumpAndSettle();
  expect(find.text(text['newTodo']!), findsOneWidget);
  expect(find.text(text['title']!), findsOneWidget);
  expect(find.text(text['detail']!), findsOneWidget);
  expect(find.text(text['priority']!), findsAtLeastNWidgets(1));
  expect(find.text(text['dueDate']!), findsAtLeastNWidgets(1));
  expect(find.text(text['tags']!), findsAtLeastNWidgets(1));
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('todo-priority-filter')));
  await tester.pumpAndSettle();
  expect(find.text(text['priority']!), findsAtLeastNWidgets(1));
  await tester.tapAt(const Offset(20, 300));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('todo-due-date-filter')));
  await tester.pumpAndSettle();
  expect(find.text(text['dueDate']!), findsOneWidget);
  await tester.tapAt(const Offset(20, 300));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('todo-tag-filter')));
  await tester.pumpAndSettle();
}
