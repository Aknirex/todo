import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/settings_controller.dart';
import 'core/backup/backup_service.dart';
import 'core/storage/app_database.dart';
import 'features/workspace/todo_workspace.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await AppDatabase.open();
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BackupService(
    database: database,
    settingsStore: ref.watch(settingsStoreProvider),
  );
});

final todoWorkspaceProvider = FutureProvider<TodoWorkspace>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  final workspace = TodoWorkspace(DriftTodoWorkspaceStore(database));
  await workspace.start();
  return workspace;
});
