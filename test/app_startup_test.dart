import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/backup/backup_service.dart';
import 'package:aknirex_todo/core/storage/app_database.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets('app starts with the localized workspace shell', (tester) async {
    final settings = MemorySettingsStore(
      const AppSettings(locale: Locale('zh', 'CN')),
    );
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          todoWorkspaceProvider.overrideWith((ref) async => workspace),
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todo 工作区'), findsOneWidget);
    expect(find.byTooltip('Switch to English'), findsOneWidget);
  });

  testWidgets('saved language is reflected after rebuilding', (tester) async {
    final settings = MemorySettingsStore(
      const AppSettings(locale: Locale('en')),
    );
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          todoWorkspaceProvider.overrideWith((ref) async => workspace),
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todo workspace'), findsOneWidget);
    expect(find.byTooltip('切换到简体中文'), findsOneWidget);
  });

  testWidgets(
    'home opens a blank Todo editor and creates only on confirmation',
    (tester) async {
      final settings = MemorySettingsStore(const AppSettings());
      final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
      await workspace.start();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(settings),
            todoWorkspaceProvider.overrideWith((ref) async => workspace),
          ],
          child: const TodoApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byTooltip('Create Todo'), findsOneWidget);

      await tester.tap(find.byTooltip('Create Todo'));
      await tester.pumpAndSettle();

      expect(workspace.current.todos, isEmpty);
      expect(find.byKey(const ValueKey('todo-detail-input')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('todo-create-button')));
      await tester.pumpAndSettle();

      expect(workspace.current.todos, hasLength(1));
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('No Todos yet.'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(workspace.current.todos.single.completed, isTrue);
      expect(find.byType(Checkbox), findsOneWidget);
    },
  );

  testWidgets('settings page persists language, theme, and local export', (
    tester,
  ) async {
    final settings = MemorySettingsStore(
      const AppSettings(locale: Locale('zh', 'CN')),
    );
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    final database = AppDatabase.inMemory();
    await database.initialize();
    addTearDown(database.close);
    final backupService = BackupService(
      database: database,
      settingsStore: settings,
    );
    var clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          todoWorkspaceProvider.overrideWith((ref) async => workspace),
          backupServiceProvider.overrideWith((ref) async => backupService),
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.value.locale, const Locale('en'));
    expect(settings.value.themeMode, ThemeMode.dark);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('backup-export-button')));
    await tester.pumpAndSettle();
    expect(clipboardText, contains('"version":1'));
  });

  testWidgets('settings page imports a local JSON backup', (tester) async {
    final settings = MemorySettingsStore(
      const AppSettings(locale: Locale('en')),
    );
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    final database = AppDatabase.inMemory();
    await database.initialize();
    addTearDown(database.close);
    final backupService = BackupService(
      database: database,
      settingsStore: settings,
    );
    final clipboardText = await backupService.exportJson();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          todoWorkspaceProvider.overrideWith((ref) async => workspace),
          backupServiceProvider.overrideWith((ref) async => backupService),
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('backup-import-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('backup-import-button')));
    await tester.pumpAndSettle();
    expect(find.text('Backup imported successfully.'), findsOneWidget);
  });
}
