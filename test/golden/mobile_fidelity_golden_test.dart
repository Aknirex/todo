import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/settings/settings_page.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets('workspace empty state light', (tester) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    await _pumpApp(
      tester,
      workspace,
      const AppSettings(themeMode: ThemeMode.light),
    );

    await expectLater(
      find.byType(TodoApp),
      matchesGoldenFile('goldens/workspace_light_empty.png'),
    );
  });

  testWidgets('workspace empty state dark', (tester) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    await _pumpApp(
      tester,
      workspace,
      const AppSettings(themeMode: ThemeMode.dark),
    );

    await expectLater(
      find.byType(TodoApp),
      matchesGoldenFile('goldens/workspace_dark_empty.png'),
    );
  });

  testWidgets('settings page mobile layout', (tester) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    await _pumpApp(
      tester,
      workspace,
      const AppSettings(themeMode: ThemeMode.light),
    );

    await tester.tap(find.byKey(const ValueKey('workspace-actions-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('goldens/settings_light.png'),
    );
  });
}

Future<void> _setMobileSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  TodoWorkspace workspace,
  AppSettings settings,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore(settings)),
        todoWorkspaceProvider.overrideWith((ref) async => workspace),
      ],
      child: const TodoApp(),
    ),
  );
  await tester.pumpAndSettle();
}
