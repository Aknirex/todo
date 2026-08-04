export default {
  common: {
    noTitle: '(无标题)',
    cancel: '取消',
    confirm: '确定',
    clear: '清除'
  },
  due: {
    today: '今天',
    tomorrow: '明天',
    overdueDays: '逾期 {n} 天',
    overdue: '逾期'
  },
  nav: {
    agent: 'Agent',
    search: '搜索',
    settings: '设置',
    newList: '新建列表',
    newListPlaceholder: '列表名称',
    newListDefault: '新列表'
  },
  sidebar: {
    tasks: '任务列表',
    defaultList: '默认列表'
  },
  toolbar: {
    filter: '筛选',
    sort: '排序'
  },
  filter: {
    title: '优先级',
    status: '状态',
    high: '高',
    medium: '中',
    low: '低',
    active: '进行中',
    done: '已完成'
  },
  sort: {
    title: '排序',
    created: '创建时间',
    priority: '优先级',
    dueDate: '截止日期',
    alpha: '名称 A→Z',
    asc: '升序',
    desc: '降序'
  },
  section: {
    active: '进行中',
    done: '已完成'
  },
  empty: {
    title: '暂无待办事项',
    sub: '点击右下角 + 添加第一个待办'
  },
  newTask: {
    title: '新建任务',
    placeholderTitle: '任务标题...',
    placeholderDetail: '添加详情（可选）...',
    placeholderTag: '输入标签回车',
    create: '创建',
    tags: '标签',
    due: '截止日期'
  },
  search: {
    title: '搜索',
    placeholder: '搜索任务...',
    placeholderFull: '搜索任务标题、详情或标签...',
    recent: '最近搜索',
    clearHistory: '清除',
    noResults: '无搜索结果',
    noResultsFull: '未找到匹配结果',
    filterToggle: '筛选条件',
    status: '完成状态',
    all: '全部',
    pending: '未完成',
    done: '已完成',
    dateRange: '日期范围',
    startDate: '开始日期',
    endDate: '结束日期',
    clearDate: '清除',
    reset: '重置筛选',
    loading: '搜索中...'
  },
  detail: {
    title: '任务详情',
    fieldTitle: '标题',
    titlePlaceholder: '输入标题',
    fieldPriority: '优先级',
    fieldDue: '截止日期',
    selectDate: '选择日期',
    fieldTags: '标签',
    addTag: '+ 添加',
    tagPlaceholder: '输入标签回车',
    detail: '详情',
    detailPlaceholder: '添加详情...',
    deleteTitle: '删除任务',
    deleteContent: '删除后可通过撤销恢复'
  },
  agent: {
    decomposeTab: '文本→任务',
    summarizeTab: '任务→文本',
    decompose: {
      title: '文本 → 任务拆解',
      desc: '粘贴聊天记录、会议纪要，AI 自动拆解为待办',
      placeholder: '例如：领导说下周三前要交Q2报告...',
      btn: '开始拆解',
      result: '拆解结果（{n} 项任务）',
      save: '保存到任务列表',
      edit: '编辑后保存',
      fail: '拆解失败',
      saved: '已保存 {n} 项任务'
    },
    summarize: {
      title: '任务 → 文本总结',
      desc: '将待办整理成连贯的文本',
      placeholder: '附加说明（可选）',
      btn: '生成总结',
      copy: '复制',
      edit: '编辑',
      fail: '总结失败'
    },
    scope: {
      read: '读取来源'
    },
    needApiKey: '请先配置 API Key',
    editHint: '请直接编辑后保存'
  },
  settings: {
    title: '设置',
    ai: 'AI 配置',
    apiKey: 'API Key',
    configured: '已配置',
    notConfigured: '未配置',
    provider: '提供商',
    model: '模型',
    agentApi: 'Agent API',
    apiService: 'API 服务',
    notStarted: '未启动',
    generate: '点击生成',
    appearance: '外观',
    darkMode: '深色模式',
    data: '数据',
    undoHistory: '撤销历史',
    export: '导出数据',
    about: '关于',
    version: '版本',
    license: '许可协议',
    language: '语言',
    languageZh: '简体中文',
    languageEn: 'English'
  },
  llm: {
    title: '配置 AI',
    heading: '配置你的 AI',
    sub: '选择一个 AI 提供商，输入 API Key 即可使用',
    recommended: '推荐',
    apiKey: 'API Key',
    keyPlaceholder: 'sk-...',
    save: '保存配置',
    needKey: '请输入 API Key',
    saved: '配置已保存'
  },
  share: {
    title: '导出数据',
    format: '选择导出格式',
    text: '纯文本',
    selectCount: '选择待办事项（{n} / {m}）',
    selectAll: '全选',
    deselectAll: '取消全选',
    empty: '暂无待办事项',
    preview: '预览',
    copy: '复制到剪贴板',
    copied: '已复制到剪贴板',
    copyFail: '复制失败'
  }
}
