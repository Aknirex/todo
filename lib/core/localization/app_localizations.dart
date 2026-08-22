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
  String get workspaceSubtitle =>
      isEnglish ? 'A calm place for the next thing.' : '专注记录下一件要做的事。';
  String get emptyWorkspace =>
      isEnglish ? 'Your workspace is ready.' : '工作区已准备就绪。';
  String get emptyWorkspaceHint =>
      isEnglish
          ? 'Todo actions will appear here in the next layer.'
          : 'Todo 行为将在后续应用层接入。';
  String get defaultList => isEnglish ? 'Default List' : '默认 List';
  String get activeTodos => isEnglish ? 'Active' : '未完成';
  String get completedTodos => isEnglish ? 'Completed' : '已完成';
  String get noTodos => isEnglish ? 'No Todos yet.' : '还没有 Todo。';
  String get noMatchingTodos =>
      isEnglish ? 'No Todos match these conditions.' : '没有符合条件的 Todo。';
  String get clearSearchAndFilters =>
      isEnglish ? 'Clear search and filters' : '清除搜索和筛选';
  String get searchTodos =>
      isEnglish ? 'Search title, detail, or tags' : '搜索标题、详情或 Tag';
  String get filterPriority => isEnglish ? 'Priority' : 'Priority';
  String get filterTags => isEnglish ? 'Tags' : 'Tag';
  String get filterStatus => isEnglish ? 'Status' : '状态';
  String get filterDueDate => isEnglish ? 'DueDate' : 'DueDate';
  String get allFilter => isEnglish ? 'All' : '全部';
  String get activeFilter => isEnglish ? 'Active' : '未完成';
  String get completedFilter => isEnglish ? 'Completed' : '已完成';
  String get todayDueDate => isEnglish ? 'Today' : '今天';
  String get thisWeekDueDate => isEnglish ? 'This week' : '本周';
  String get thisMonthDueDate => isEnglish ? 'This month' : '本月';
  String get overdueDueDate => isEnglish ? 'Overdue' : '逾期';
  String get noDueDateFilter => isEnglish ? 'No DueDate' : '无 DueDate';
  String get noTags => isEnglish ? 'No tags' : '无 Tag';
  String get sortLabel => isEnglish ? 'Sort' : '排序';
  String get sortActiveNewest => isEnglish ? 'Active, newest' : '未完成，最新';
  String get sortPriority => isEnglish ? 'Priority' : 'Priority';
  String get sortDueDate => isEnglish ? 'DueDate' : 'DueDate';
  String get sortTitleAscending => isEnglish ? 'Title A-Z' : '标题 A-Z';
  String get sortTitleDescending => isEnglish ? 'Title Z-A' : '标题 Z-A';
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
  String get tagsHint =>
      isEnglish ? 'Separate tags with commas' : '使用逗号分隔多个 Tag';
  String get todoRow => isEnglish ? 'Todo row' : 'Todo 行';
  String get languageTooltip => isEnglish ? '切换到简体中文' : 'Switch to English';
  String get themeTooltip => isEnglish ? 'Change theme' : '切换主题';
  String get currentLanguage => isEnglish ? 'EN' : '中';
  String get loadingWorkspace => isEnglish ? 'Loading workspace' : '正在加载工作区';
  String get workspaceUnavailable =>
      isEnglish ? 'The workspace could not be opened.' : '无法打开工作区。';
  String get themeLight => isEnglish ? 'Light' : '浅色';
  String get themeDark => isEnglish ? 'Dark' : '深色';
  String get themeSystem => isEnglish ? 'System' : '跟随系统';
  String get themeMenuLabel => isEnglish ? 'Theme' : '主题';
  String get undo => isEnglish ? 'Undo' : 'Undo';
  String get redo => isEnglish ? 'Redo' : 'Redo';
  String get deleteTodo => isEnglish ? 'Delete Todo' : '删除 Todo';
  String get settingsTooltip => isEnglish ? 'Settings' : '设置';
  String get settingsTitle => isEnglish ? 'Settings' : '设置';
  String get languageLabel => isEnglish ? 'Language' : '语言';
  String get languageEnglish => 'English';
  String get languageChinese => '简体中文';
  String get backupLabel => isEnglish ? 'JSON backup' : 'JSON 备份';
  String get exportBackup => isEnglish ? 'Copy JSON backup' : '复制 JSON 备份';
  String get importBackup => isEnglish ? 'Import JSON backup' : '导入 JSON 备份';
  String get backupCopied =>
      isEnglish ? 'JSON backup copied to the clipboard.' : 'JSON 备份已复制到剪贴板。';
  String get backupExportFailed =>
      isEnglish ? 'The backup could not be exported.' : '备份无法导出。';
  String get noBackupToImport =>
      isEnglish
          ? 'There is no JSON backup in the clipboard.'
          : '剪贴板中没有 JSON 备份。';
  String get importSucceeded =>
      isEnglish ? 'Backup imported successfully.' : '备份导入成功。';
  String get importConflicts => isEnglish ? 'Conflicts' : '冲突';
  String get backupImportFailed =>
      isEnglish ? 'The backup could not be imported.' : '备份无法导入。';
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
