export default {
  common: {
    noTitle: '(No title)',
    cancel: 'Cancel',
    confirm: 'OK',
    clear: 'Clear'
  },
  due: {
    today: 'Today',
    tomorrow: 'Tomorrow',
    overdueDays: '{n} day(s) overdue',
    overdue: 'Overdue'
  },
  nav: {
    agent: 'Agent',
    search: 'Search',
    settings: 'Settings',
    newList: 'New list',
    newListPlaceholder: 'List name',
    newListDefault: 'New list'
  },
  sidebar: {
    tasks: 'Task lists',
    defaultList: 'Default list'
  },
  toolbar: {
    filter: 'Filter',
    sort: 'Sort'
  },
  filter: {
    title: 'Priority',
    status: 'Status',
    high: 'High',
    medium: 'Medium',
    low: 'Low',
    active: 'Active',
    done: 'Done'
  },
  sort: {
    title: 'Sort',
    created: 'Created',
    priority: 'Priority',
    dueDate: 'Due date',
    alpha: 'Name A→Z',
    asc: 'Ascending',
    desc: 'Descending'
  },
  section: {
    active: 'Active',
    done: 'Done'
  },
  empty: {
    title: 'No todos yet',
    sub: 'Tap + at the bottom right to add your first todo'
  },
  newTask: {
    title: 'New task',
    placeholderTitle: 'Task title...',
    placeholderDetail: 'Add details (optional)...',
    placeholderTag: 'Type a tag and press enter',
    create: 'Create',
    tags: 'Tags',
    due: 'Due date'
  },
  search: {
    title: 'Search',
    placeholder: 'Search tasks...',
    placeholderFull: 'Search task title, detail or tags...',
    recent: 'Recent searches',
    clearHistory: 'Clear',
    noResults: 'No results',
    noResultsFull: 'No matching results',
    filterToggle: 'Filters',
    status: 'Status',
    all: 'All',
    pending: 'Pending',
    done: 'Done',
    dateRange: 'Date range',
    startDate: 'Start date',
    endDate: 'End date',
    clearDate: 'Clear',
    reset: 'Reset filters',
    loading: 'Searching...'
  },
  detail: {
    title: 'Task detail',
    fieldTitle: 'Title',
    titlePlaceholder: 'Enter title',
    fieldPriority: 'Priority',
    fieldDue: 'Due date',
    selectDate: 'Select date',
    fieldTags: 'Tags',
    addTag: '+ Add',
    tagPlaceholder: 'Type a tag and press enter',
    detail: 'Detail',
    detailPlaceholder: 'Add details...',
    deleteTitle: 'Delete task',
    deleteContent: 'You can undo this later'
  },
  agent: {
    decomposeTab: 'Text → tasks',
    summarizeTab: 'Tasks → text',
    decompose: {
      title: 'Text → task breakdown',
      desc: 'Paste chat logs or meeting notes; AI breaks them into todos',
      placeholder: 'e.g. The boss wants the Q2 report by next Wednesday...',
      btn: 'Start breakdown',
      result: 'Breakdown result ({n} tasks)',
      save: 'Save to task list',
      edit: 'Edit then save',
      fail: 'Breakdown failed',
      saved: 'Saved {n} tasks'
    },
    summarize: {
      title: 'Tasks → text summary',
      desc: 'Turn your todos into a coherent summary',
      placeholder: 'Additional notes (optional)',
      btn: 'Generate summary',
      copy: 'Copy',
      edit: 'Edit',
      fail: 'Summary failed'
    },
    scope: {
      read: 'Read from'
    },
    needApiKey: 'Please configure an API Key first',
    editHint: 'Please edit the text directly and save'
  },
  settings: {
    title: 'Settings',
    ai: 'AI Configuration',
    apiKey: 'API Key',
    configured: 'Configured',
    notConfigured: 'Not configured',
    provider: 'Provider',
    model: 'Model',
    agentApi: 'Agent API',
    apiService: 'API Service',
    notStarted: 'Not started',
    generate: 'Tap to generate',
    appearance: 'Appearance',
    darkMode: 'Dark mode',
    data: 'Data',
    undoHistory: 'Undo history',
    export: 'Export data',
    about: 'About',
    version: 'Version',
    license: 'License',
    language: 'Language',
    languageZh: '简体中文',
    languageEn: 'English'
  },
  llm: {
    title: 'AI Setup',
    heading: 'Configure your AI',
    sub: 'Pick a provider and enter an API Key to get started',
    recommended: 'Recommended',
    apiKey: 'API Key',
    keyPlaceholder: 'sk-...',
    save: 'Save configuration',
    needKey: 'Please enter an API Key',
    saved: 'Configuration saved'
  },
  share: {
    title: 'Export data',
    format: 'Choose export format',
    text: 'Plain text',
    selectCount: 'Select todos ({n} / {m})',
    selectAll: 'Select all',
    deselectAll: 'Deselect all',
    empty: 'No todos yet',
    preview: 'Preview',
    copy: 'Copy to clipboard',
    copied: 'Copied to clipboard',
    copyFail: 'Copy failed'
  }
}
