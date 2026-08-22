import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('zh', 'CN'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  bool get isEnglish => locale.languageCode == 'en';

  String get workspaceTitle => isEnglish ? 'Todo workspace' : 'Todo 工作区';
  String get workspaceSubtitle => isEnglish
      ? 'A calm place for the next thing.'
      : '专注记录下一件要做的事。';
  String get emptyWorkspace =>
      isEnglish ? 'Your workspace is ready.' : '工作区已准备就绪。';
  String get emptyWorkspaceHint => isEnglish
      ? 'Todo actions will appear here in the next layer.'
      : 'Todo 行为将在后续应用层接入。';
  String get defaultList => isEnglish ? 'Default List' : '默认 List';
  String get activeTodos => isEnglish ? 'Active' : '未完成';
  String get completedTodos => isEnglish ? 'Completed' : '已完成';
  String get noTodos => isEnglish ? 'No Todos yet.' : '还没有 Todo。';
  String get createTodo => isEnglish ? 'Create Todo' : '创建 Todo';
  String get newTodo => isEnglish ? 'New Todo' : '新建 Todo';
  String get editTodo => isEnglish ? 'Edit Todo' : '编辑 Todo';
  String get titleLabel => isEnglish ? 'Title' : '标题';
  String get detailLabel => isEnglish ? 'Detail' : '详情';
  String get priorityLabel => isEnglish ? 'Priority' : 'Priority';
  String get dueDateLabel => isEnglish ? 'DueDate' : 'DueDate';
  String get tagsLabel => isEnglish ? 'Tags' : 'Tag';
  String get noDueDate => isEnglish ? 'No DueDate' : '无 DueDate';
  String get clearDueDate => isEnglish ? 'Clear DueDate' : '清除 DueDate';
  String get highPriority => isEnglish ? 'High' : 'High';
  String get mediumPriority => isEnglish ? 'Medium' : 'Medium';
  String get lowPriority => isEnglish ? 'Low' : 'Low';
  String get create => isEnglish ? 'Create' : '创建';
  String get save => isEnglish ? 'Save' : '保存';
  String get tagsHint => isEnglish
      ? 'Separate tags with commas'
      : '使用逗号分隔多个 Tag';
  String get todoRow => isEnglish ? 'Todo row' : 'Todo 行';
  String get languageTooltip => isEnglish ? '切换到简体中文' : 'Switch to English';
  String get themeTooltip => isEnglish ? 'Change theme' : '切换主题';
  String get currentLanguage => isEnglish ? 'EN' : '中';
  String get loadingWorkspace => isEnglish ? 'Loading workspace' : '正在加载工作区';
  String get workspaceUnavailable => isEnglish
      ? 'The workspace could not be opened.'
      : '无法打开工作区。';
  String get themeLight => isEnglish ? 'Light' : '浅色';
  String get themeDark => isEnglish ? 'Dark' : '深色';
  String get themeSystem => isEnglish ? 'System' : '跟随系统';
  String get themeMenuLabel => isEnglish ? 'Theme' : '主题';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' || locale.languageCode == 'zh';
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
