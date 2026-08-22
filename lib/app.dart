import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/app_theme.dart';
import 'core/design_system/design_tokens.dart';
import 'core/localization/app_localizations.dart';
import 'core/settings/settings_controller.dart';
import 'features/workspace/workspace_page.dart';
import 'providers.dart';

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsControllerProvider).valueOrNull ??
        const AppSettings();

    return MaterialApp(
      title: 'aknirex-todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor:
                    Theme.of(context).scaffoldBackgroundColor,
                systemNavigationBarDividerColor:
                    Theme.of(context).scaffoldBackgroundColor,
              ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WorkspaceRoute(),
    );
  }
}

class WorkspaceRoute extends ConsumerWidget {
  const WorkspaceRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(todoWorkspaceProvider);
    return workspace.when(
      data: (value) => WorkspacePage(workspace: value),
      error: (_, _) => const StartupErrorView(),
      loading: () => const StartupLoadingView(),
    );
  }
}

class StartupLoadingView extends StatelessWidget {
  const StartupLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Semantics(
            label: l10n.loadingWorkspace,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class StartupErrorView extends StatelessWidget {
  const StartupErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Text(l10n.workspaceUnavailable, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
