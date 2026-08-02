# aknirex-todo 技术方案

> 文档版本：v1.0 | 日期：2026-08-02 | 状态：初稿
> 基于：[PRD v1.0](PRD-aknirex-todo.md) | [产品愿景 v1.3](product-vision.md) | [同步方案 v1.2](sync-design.md)

---

## 1. 架构总览

### 1.1 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        UniApp 跨端层                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ 微信小程序 │  │ 微信小程序 │  │ Android  │  │  (iOS)   │       │
│  │  (手机)   │  │  (PC)    │  │   App    │  │  v1.1    │       │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘       │
│        └──────────────┴──────────────┴──────────────┘           │
│                           │                                     │
│  ┌────────────────────────┴────────────────────────────┐       │
│  │                   Vue 3 UI 层                        │       │
│  │  Pages │ Components │ Composables                    │       │
│  └────────────────────────┬────────────────────────────┘       │
│                           │                                     │
│  ┌────────────────────────┴────────────────────────────┐       │
│  │                   Pinia 状态层                       │       │
│  │  todoStore │ listStore │ agentStore │ undoStore     │       │
│  └──────┬─────────────┬─────────────┬─────────────────┘       │
│         │             │             │                           │
│  ┌──────┴──────┐ ┌────┴─────┐ ┌────┴──────┐                   │
│  │  数据访问层  │ │ LLM 适配 │ │ Agent API │                   │
│  │   (DAL)     │ │   层     │ │   服务    │                   │
│  └──────┬──────┘ └────┬─────┘ └────┬──────┘                   │
│         │             │             │                           │
│  ┌──────┴──────┐ ┌────┴─────────────┴──────┐                   │
│  │   SQLite    │ │   uni.request / WebSocket │                   │
│  │  本地存储    │ │      网络通信层           │                   │
│  └─────────────┘ └─────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 分层职责

| 层级 | 职责 | 关键技术 |
|------|------|----------|
| **UI 层** | 页面渲染、用户交互、路由 | Vue 3 Composition API、UniApp 组件 |
| **状态层** | 全局状态管理、业务逻辑编排 | Pinia、响应式系统 |
| **数据访问层** | 本地数据库 CRUD、数据迁移 | SQLite（uni-app 插件） |
| **LLM 适配层** | 统一 LLM 接口、Provider 差异适配 | OpenAI 兼容协议 |
| **Agent API 服务** | 第三方 Agent 接入、认证、限流 | RESTful API、API Key |
| **网络通信层** | HTTP 请求、WebSocket 连接 | uni.request、uni.connectSocket |

### 1.3 模块依赖关系

```
Pages
  │
  ├── todoStore ──► DAL (SQLite)
  │     │
  │     ├── undoStore (操作记录)
  │     │
  │     └── agentStore ──► LLM Adapter ──► uni.request (LLM API)
  │
  ├── listStore ──► DAL (SQLite)
  │
  └── Agent API Service ──► todoStore / listStore
        │
        └── HTTP Server (Android) / WebSocket (小程序)
```

---

## 2. 项目结构

```
aknirex-todo/
├── src/
│   ├── pages/                    # 页面
│   │   ├── index/                # 首页（todo 列表）
│   │   ├── detail/               # todo 详情/编辑
│   │   ├── agent/                # Agent 对话界面
│   │   ├── settings/             # 设置页（LLM 配置、关于）
│   │   ├── search/               # 全局搜索
│   │   └── share/                # 分享预览
│   │
│   ├── components/               # 通用组件
│   │   ├── TodoItem.vue          # todo 列表项
│   │   ├── PriorityPicker.vue    # 优先级选择器
│   │   ├── TagInput.vue          # 标签输入
│   │   ├── DatePicker.vue        # 日期选择
│   │   ├── FilterPanel.vue       # 筛选面板
│   │   ├── UndoButton.vue        # 撤销按钮
│   │   └── AgentMessage.vue      # Agent 消息气泡
│   │
│   ├── stores/                   # Pinia 状态管理
│   │   ├── todo.ts               # todo CRUD 状态
│   │   ├── list.ts               # 列表管理状态
│   │   ├── agent.ts              # Agent 配置与会话
│   │   ├── undo.ts               # 撤销栈
│   │   └── sync.ts               # 同步状态（v1.1）
│   │
│   ├── dal/                      # 数据访问层
│   │   ├── database.ts           # SQLite 初始化与迁移
│   │   ├── todo-repository.ts    # todo 数据操作
│   │   ├── list-repository.ts    # 列表数据操作
│   │   └── undo-repository.ts    # 撤销记录数据操作
│   │
│   ├── services/                 # 业务服务
│   │   ├── llm/
│   │   │   ├── adapter.ts        # LLM 统一接口
│   │   │   ├── openai.ts         # OpenAI 兼容适配器
│   │   │   └── prompts.ts        # Prompt 模板
│   │   │
│   │   ├── agent-api/
│   │   │   ├── server.ts         # API 服务入口
│   │   │   ├── auth.ts           # API Key 认证
│   │   │   ├── rate-limit.ts     # 限流
│   │   │   └── routes.ts         # 路由定义
│   │   │
│   │   ├── search.ts             # 搜索服务
│   │   ├── export.ts             # 导出服务
│   │   └── share.ts              # 分享服务
│   │
│   ├── utils/                    # 工具函数
│   │   ├── crypto.ts             # 加密工具（v1.1）
│   │   ├── uuid.ts               # UUID 生成
│   │   └── platform.ts           # 平台检测
│   │
│   ├── types/                    # TypeScript 类型定义
│   │   ├── todo.ts
│   │   ├── list.ts
│   │   ├── agent.ts
│   │   └── api.ts
│   │
│   ├── App.vue
│   ├── main.ts
│   ├── manifest.json             # UniApp 配置
│   ├── pages.json                # 页面路由配置
│   └── uni.scss                  # 全局样式
│
├── docs/                         # 文档
├── package.json
├── tsconfig.json
└── vite.config.ts
```

---

## 3. 数据模型

### 3.1 SQLite 表结构

#### todo 表

```sql
CREATE TABLE IF NOT EXISTS todo (
  id            TEXT PRIMARY KEY,           -- UUID
  title         TEXT DEFAULT '',            -- 标题，允许为空
  priority      TEXT NOT NULL DEFAULT 'medium',  -- high / medium / low
  due_date      TEXT,                       -- ISO 8601 日期，nullable
  tags          TEXT DEFAULT '[]',          -- JSON 数组字符串
  detail        TEXT DEFAULT '',            -- 多行文本
  completed     INTEGER NOT NULL DEFAULT 0, -- 0=未完成, 1=已完成
  list_id       TEXT NOT NULL,              -- 所属列表 ID
  created_at    TEXT NOT NULL,              -- ISO 8601 时间戳
  updated_at    TEXT NOT NULL,              -- ISO 8601 时间戳
  deleted       INTEGER NOT NULL DEFAULT 0, -- 软删除标记
  FOREIGN KEY (list_id) REFERENCES list(id)
);

CREATE INDEX idx_todo_list_id ON todo(list_id);
CREATE INDEX idx_todo_completed ON todo(completed);
CREATE INDEX idx_todo_priority ON todo(priority);
CREATE INDEX idx_todo_due_date ON todo(due_date);
CREATE INDEX idx_todo_deleted ON todo(deleted);
```

#### list 表

```sql
CREATE TABLE IF NOT EXISTS list (
  id            TEXT PRIMARY KEY,           -- UUID
  name          TEXT DEFAULT '默认列表',     -- 列表名称
  is_default    INTEGER NOT NULL DEFAULT 0, -- 是否默认列表
  created_at    TEXT NOT NULL,              -- ISO 8601 时间戳
  sort_order    INTEGER NOT NULL DEFAULT 0  -- 排序序号
);

-- 初始化默认列表
INSERT OR IGNORE INTO list (id, name, is_default, created_at, sort_order)
VALUES ('default', '默认列表', 1, datetime('now'), 0);
```

#### undo_record 表

```sql
CREATE TABLE IF NOT EXISTS undo_record (
  id            TEXT PRIMARY KEY,           -- UUID
  action_type   TEXT NOT NULL,              -- create / update / delete / toggle_complete / move
  entity_type   TEXT NOT NULL,              -- todo / list
  entity_id     TEXT NOT NULL,              -- 目标实体 ID
  before_state  TEXT,                       -- JSON: 操作前状态
  after_state   TEXT,                       -- JSON: 操作后状态
  created_at    TEXT NOT NULL               -- ISO 8601 时间戳
);

CREATE INDEX idx_undo_created_at ON undo_record(created_at);
```

#### agent_config 表

```sql
CREATE TABLE IF NOT EXISTS agent_config (
  id            TEXT PRIMARY KEY,           -- 固定值 'default'
  provider      TEXT,                       -- 提供商标识
  api_key       TEXT,                       -- 加密存储的 API Key
  base_url      TEXT,                       -- API 基础 URL
  model         TEXT,                       -- 模型名称
  updated_at    TEXT NOT NULL               -- ISO 8601 时间戳
);
```

#### sync_state 表（v1.1）

```sql
CREATE TABLE IF NOT EXISTS sync_state (
  id            TEXT PRIMARY KEY,           -- 固定值 'default'
  session_id    TEXT,                       -- 同步会话 ID
  encrypt_key   TEXT,                       -- 加密密钥（本地加密存储）
  last_seq      INTEGER DEFAULT 0,          -- 最后同步序列号
  paired_at     TEXT,                       -- 配对时间
  updated_at    TEXT NOT NULL               -- ISO 8601 时间戳
);
```

### 3.2 TypeScript 类型定义

```typescript
// types/todo.ts
export type Priority = 'high' | 'medium' | 'low';

export interface Todo {
  id: string;
  title: string;
  priority: Priority;
  dueDate: string | null;      // ISO 8601 date
  tags: string[];
  detail: string;
  completed: boolean;
  listId: string;
  createdAt: string;           // ISO 8601 datetime
  updatedAt: string;
  deleted: boolean;
}

export interface CreateTodoInput {
  title?: string;
  priority?: Priority;
  dueDate?: string | null;
  tags?: string[];
  detail?: string;
  listId?: string;
}

export interface UpdateTodoInput {
  title?: string;
  priority?: Priority;
  dueDate?: string | null;
  tags?: string[];
  detail?: string;
  listId?: string;
}

// types/list.ts
export interface TodoList {
  id: string;
  name: string;
  isDefault: boolean;
  createdAt: string;
  sortOrder: number;
}

// types/agent.ts
export type AgentActionType = 'create' | 'update' | 'delete' | 'toggle_complete' | 'move';
export type EntityType = 'todo' | 'list';

export interface UndoRecord {
  id: string;
  actionType: AgentActionType;
  entityType: EntityType;
  entityId: string;
  beforeState: string | null;  // JSON
  afterState: string | null;   // JSON
  createdAt: string;
}

export interface AgentConfig {
  provider: string | null;
  apiKey: string | null;
  baseUrl: string | null;
  model: string | null;
}

// types/api.ts
export interface ApiResponse<T = any> {
  code: number;       // 0=成功, 非0=错误
  message: string;
  data: T | null;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface TodoFilter {
  priority?: Priority;
  tags?: string[];
  completed?: boolean;
  listId?: string;
  dueDateRange?: { start: string; end: string };
  keyword?: string;
}
```

---

## 4. 状态管理（Pinia）

### 4.1 Store 设计

#### todoStore

```typescript
// stores/todo.ts
export const useTodoStore = defineStore('todo', () => {
  // --- State ---
  const todos = ref<Todo[]>([]);
  const loading = ref(false);

  // --- Getters ---
  const activeTodos = computed(() =>
    todos.value.filter(t => !t.deleted && !t.completed)
  );
  const completedTodos = computed(() =>
    todos.value.filter(t => !t.deleted && t.completed)
  );
  const todosByList = (listId: string) =>
    todos.value.filter(t => !t.deleted && t.listId === listId);

  // --- Actions ---
  async function createTodo(input: CreateTodoInput): Promise<Todo> {
    const todo = buildTodo(input);
    todos.value.push(todo);
    await todoRepository.insert(todo);
    undoStore.record('create', 'todo', todo.id, null, todo);
    return todo;
  }

  async function updateTodo(id: string, input: UpdateTodoInput): Promise<void> {
    const index = todos.value.findIndex(t => t.id === id);
    if (index === -1) return;
    const before = { ...todos.value[index] };
    const updated = { ...todos.value[index], ...input, updatedAt: now() };
    todos.value[index] = updated;
    await todoRepository.update(id, input);
    undoStore.record('update', 'todo', id, before, updated);
  }

  async function deleteTodo(id: string): Promise<void> {
    const index = todos.value.findIndex(t => t.id === id);
    if (index === -1) return;
    const before = { ...todos.value[index] };
    todos.value[index].deleted = true;
    await todoRepository.softDelete(id);
    undoStore.record('delete', 'todo', id, before, null);
  }

  async function toggleComplete(id: string): Promise<void> {
    const index = todos.value.findIndex(t => t.id === id);
    if (index === -1) return;
    const before = { ...todos.value[index] };
    todos.value[index].completed = !todos.value[index].completed;
    todos.value[index].updatedAt = now();
    await todoRepository.toggleComplete(id);
    undoStore.record('toggle_complete', 'todo', id, before, todos.value[index]);
  }

  async function loadTodos(): Promise<void> {
    loading.value = true;
    todos.value = await todoRepository.findAll();
    loading.value = false;
  }

  return { todos, loading, activeTodos, completedTodos, todosByList,
           createTodo, updateTodo, deleteTodo, toggleComplete, loadTodos };
});
```

#### undoStore

```typescript
// stores/undo.ts
export const useUndoStore = defineStore('undo', () => {
  const MAX_STACK_SIZE = 50;
  const undoStack = ref<UndoRecord[]>(());

  function record(
    actionType: AgentActionType,
    entityType: EntityType,
    entityId: string,
    before: any,
    after: any
  ): void {
    const record: UndoRecord = {
      id: uuid(),
      actionType,
      entityType,
      entityId,
      beforeState: before ? JSON.stringify(before) : null,
      afterState: after ? JSON.stringify(after) : null,
      createdAt: now()
    };
    undoStack.value.push(record);
    // 超过上限时丢弃最早记录
    if (undoStack.value.length > MAX_STACK_SIZE) {
      undoStack.value.shift();
    }
    // 异步持久化
    undoRepository.insert(record);
  }

  async function undo(): Promise<boolean> {
    const record = undoStack.value.pop();
    if (!record) return false;
    await applyUndo(record);
    await undoRepository.delete(record.id);
    return true;
  }

  const canUndo = computed(() => undoStack.value.length > 0);

  return { undoStack, record, undo, canUndo };
});
```

#### agentStore

```typescript
// stores/agent.ts
export const useAgentStore = defineStore('agent', () => {
  const config = ref<AgentConfig>({
    provider: null,
    apiKey: null,
    baseUrl: null,
    model: null
  });
  const configured = computed(() => !!config.value.apiKey);

  // Agent 对话历史（内存中，不持久化）
  const messages = ref<AgentMessage[]>([]);

  async function loadConfig(): Promise<void> {
    config.value = await agentConfigRepository.load();
  }

  async function saveConfig(newConfig: AgentConfig): Promise<void> {
    config.value = newConfig;
    await agentConfigRepository.save(newConfig);
  }

  async function decomposeText(text: string): Promise<CreateTodoInput[]> {
    const response = await llmAdapter.chat({
      messages: buildDecomposePrompt(text),
      config: config.value
    });
    return parseDecomposeResponse(response);
  }

  async function summarizeTodos(todos: Todo[], context?: string): Promise<string> {
    const response = await llmAdapter.chat({
      messages: buildSummarizePrompt(todos, context),
      config: config.value
    });
    return response;
  }

  return { config, configured, messages, loadConfig, saveConfig,
           decomposeText, summarizeTodos };
});
```

### 4.2 Store 初始化顺序

```typescript
// main.ts
async function initApp() {
  // 1. 初始化数据库
  await initDatabase();

  // 2. 加载配置
  const agentStore = useAgentStore();
  await agentStore.loadConfig();

  // 3. 加载数据
  const todoStore = useTodoStore();
  const listStore = useListStore();
  await Promise.all([
    todoStore.loadTodos(),
    listStore.loadLists()
  ]);

  // 4. 加载撤销栈
  const undoStore = useUndoStore();
  await undoStore.loadFromDb();
}
```

---

## 5. 数据访问层（DAL）

### 5.1 数据库初始化与迁移

```typescript
// dal/database.ts
import { openDatabase } from '@/utils/sqlite';

const DB_NAME = 'aknirex_todo';
const DB_VERSION = 1;

let db: any = null;

export async function initDatabase(): Promise<void> {
  db = await openDatabase(DB_NAME, DB_VERSION);
  await runMigrations(db);
}

async function runMigrations(db: any): Promise<void> {
  // 版本 1：初始表结构
  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS todo (
      id TEXT PRIMARY KEY,
      title TEXT DEFAULT '',
      priority TEXT NOT NULL DEFAULT 'medium',
      due_date TEXT,
      tags TEXT DEFAULT '[]',
      detail TEXT DEFAULT '',
      completed INTEGER NOT NULL DEFAULT 0,
      list_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0
    )
  `);
  // ... 其他表创建
}

export function getDatabase() {
  if (!db) throw new Error('Database not initialized');
  return db;
}
```

### 5.2 Repository 模式

```typescript
// dal/todo-repository.ts
export const todoRepository = {
  async findAll(filter?: TodoFilter): Promise<Todo[]> {
    const db = getDatabase();
    let sql = 'SELECT * FROM todo WHERE deleted = 0';
    const params: any[] = [];

    if (filter?.listId) {
      sql += ' AND list_id = ?';
      params.push(filter.listId);
    }
    if (filter?.priority) {
      sql += ' AND priority = ?';
      params.push(filter.priority);
    }
    if (filter?.completed !== undefined) {
      sql += ' AND completed = ?';
      params.push(filter.completed ? 1 : 0);
    }

    sql += ' ORDER BY created_at DESC';

    const result = await db.executeSql(sql, params);
    return result.rows.map(rowToTodo);
  },

  async insert(todo: Todo): Promise<void> {
    const db = getDatabase();
    await db.executeSql(
      `INSERT INTO todo (id, title, priority, due_date, tags, detail,
       completed, list_id, created_at, updated_at, deleted)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [todo.id, todo.title, todo.priority, todo.dueDate,
       JSON.stringify(todo.tags), todo.detail, todo.completed ? 1 : 0,
       todo.listId, todo.createdAt, todo.updatedAt, 0]
    );
  },

  async update(id: string, input: UpdateTodoInput): Promise<void> {
    const db = getDatabase();
    const fields: string[] = [];
    const params: any[] = [];

    if (input.title !== undefined) { fields.push('title = ?'); params.push(input.title); }
    if (input.priority !== undefined) { fields.push('priority = ?'); params.push(input.priority); }
    if (input.dueDate !== undefined) { fields.push('due_date = ?'); params.push(input.dueDate); }
    if (input.tags !== undefined) { fields.push('tags = ?'); params.push(JSON.stringify(input.tags)); }
    if (input.detail !== undefined) { fields.push('detail = ?'); params.push(input.detail); }
    if (input.listId !== undefined) { fields.push('list_id = ?'); params.push(input.listId); }

    fields.push('updated_at = ?');
    params.push(now());
    params.push(id);

    await db.executeSql(
      `UPDATE todo SET ${fields.join(', ')} WHERE id = ?`, params
    );
  },

  async softDelete(id: string): Promise<void> {
    const db = getDatabase();
    await db.executeSql(
      'UPDATE todo SET deleted = 1, updated_at = ? WHERE id = ?',
      [now(), id]
    );
  },

  async toggleComplete(id: string): Promise<void> {
    const db = getDatabase();
    await db.executeSql(
      `UPDATE todo SET completed = CASE WHEN completed = 1 THEN 0 ELSE 1 END,
       updated_at = ? WHERE id = ?`,
      [now(), id]
    );
  },

  async search(keyword: string): Promise<Todo[]> {
    const db = getDatabase();
    const like = `%${keyword}%`;
    const result = await db.executeSql(
      `SELECT * FROM todo WHERE deleted = 0
       AND (title LIKE ? OR detail LIKE ? OR tags LIKE ?)`,
      [like, like, like]
    );
    return result.rows.map(rowToTodo);
  }
};

function rowToTodo(row: any): Todo {
  return {
    id: row.id,
    title: row.title,
    priority: row.priority,
    dueDate: row.due_date,
    tags: JSON.parse(row.tags || '[]'),
    detail: row.detail,
    completed: row.completed === 1,
    listId: row.list_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deleted: row.deleted === 1
  };
}
```

---

## 6. LLM 适配层

### 6.1 统一接口

```typescript
// services/llm/adapter.ts
export interface LlmMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface LlmRequest {
  messages: LlmMessage[];
  config: AgentConfig;
  temperature?: number;
  maxTokens?: number;
}

export interface LlmAdapter {
  chat(request: LlmRequest): Promise<string>;
}

// services/llm/openai.ts
export class OpenAIAdapter implements LlmAdapter {
  async chat(request: LlmRequest): Promise<string> {
    const { config, messages, temperature = 0.7, maxTokens = 2000 } = request;

    const baseUrl = config.baseUrl || 'https://api.deepseek.com';
    const url = `${baseUrl}/v1/chat/completions`;

    const response = await uni.request({
      url,
      method: 'POST',
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`
      },
      data: {
        model: config.model || 'deepseek-chat',
        messages,
        temperature,
        max_tokens: maxTokens
      },
      timeout: 30000
    });

    if (response.statusCode !== 200) {
      throw new LlmError(response.statusCode, response.data?.error?.message);
    }

    return response.data.choices[0].message.content;
  }
}

// 工厂函数
export function createLlmAdapter(provider?: string): LlmAdapter {
  // 首版所有 provider 都是 OpenAI 兼容接口
  return new OpenAIAdapter();
}
```

### 6.2 Prompt 模板

```typescript
// services/llm/prompts.ts

// 文本 → Todo 拆解
export function buildDecomposePrompt(text: string): LlmMessage[] {
  return [
    {
      role: 'system',
      content: `你是一个任务拆解助手。用户会给你一段文本（可能是聊天记录、会议纪要、任务描述等），你需要将其拆解为若干个独立的待办事项。

输出要求：
1. 返回 JSON 数组，每个元素包含 title、priority、tags 三个字段
2. title：一行简洁的任务标题（10-50字）
3. priority：high / medium / low，根据任务紧急程度判断
4. tags：标签数组，提取关键分类（如"会议"、"报告"、"客户"等）
5. 如果文本中没有明确的任务，返回空数组
6. 忽略寒暄、无关内容，只提取实际可执行的任务

输出格式（严格 JSON，不要包含其他文字）：
[{"title": "...", "priority": "...", "tags": ["...", "..."]}]`
    },
    {
      role: 'user',
      content: text
    }
  ];
}

// Todo → 文本总结
export function buildSummarizePrompt(todos: Todo[], context?: string): LlmMessage[] {
  const todoList = todos.map(t =>
    `- [${t.completed ? 'x' : ' '}] ${t.title} (优先级: ${t.priority}${t.tags.length ? ', 标签: ' + t.tags.join('/') : ''}${t.dueDate ? ', 截止: ' + t.dueDate : ''})`
  ).join('\n');

  return [
    {
      role: 'system',
      content: `你是一个任务整理助手。用户会给你一组待办事项，你需要将其整理成一段连贯、有条理的文字。

要求：
1. 按优先级分组（高→中→低）
2. 已完成的任务单独列出
3. 语言简洁、专业，适合直接复制发送到工作群或写入周报
4. ${context ? `用户说明用途：${context}` : '默认用于任务梳理和思路整理'}`
    },
    {
      role: 'user',
      content: todoList
    }
  ];
}
```

---

## 7. Agent API 设计

### 7.1 API 服务架构

微信小程序不支持监听 TCP 端口，第三方 Agent 无法直接连接。采用以下策略：

| 平台 | API 提供方式 |
|------|-------------|
| Android App | 内置 HTTP 服务器，局域网内可访问 |
| 微信小程序 | 通过 Android 端代理，或未来云端 Webhook |

**首版方案**：Android App 作为 API 服务端，第三方 Agent 通过局域网 HTTP 调用。

### 7.2 接口规范

**Base URL**：`http://{device-ip}:{port}/api/v1`

**认证**：请求头 `X-Api-Key: {api-key}`

**通用响应格式**：

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

**错误码**：

| HTTP 状态码 | code | 说明 |
|-------------|------|------|
| 401 | 1001 | API Key 无效或缺失 |
| 429 | 1002 | 请求频率超限 |
| 400 | 2001 | 请求参数错误 |
| 404 | 2002 | 资源不存在 |
| 500 | 3001 | 服务器内部错误 |

### 7.3 接口清单

#### POST /api/v1/todos — 创建 Todo

请求体：
```json
{
  "title": "完成项目报告",
  "priority": "high",
  "dueDate": "2026-08-10",
  "tags": ["工作", "报告"],
  "detail": "需要包含Q2数据",
  "listId": "default"
}
```

响应：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid-xxx",
    "title": "完成项目报告",
    "priority": "high",
    "dueDate": "2026-08-10",
    "tags": ["工作", "报告"],
    "detail": "需要包含Q2数据",
    "completed": false,
    "listId": "default",
    "createdAt": "2026-08-02T10:00:00Z",
    "updatedAt": "2026-08-02T10:00:00Z"
  }
}
```

#### POST /api/v1/todos/batch — 批量创建

请求体：
```json
{
  "todos": [
    { "title": "任务1", "priority": "high" },
    { "title": "任务2", "priority": "medium", "tags": ["标签1"] }
  ],
  "listId": "default"
}
```

#### GET /api/v1/todos — 列出 Todo

查询参数：
| 参数 | 类型 | 说明 |
|------|------|------|
| listId | string | 按列表筛选 |
| priority | string | 按优先级筛选 |
| completed | boolean | 按完成状态筛选 |
| tag | string | 按标签筛选 |
| keyword | string | 关键词搜索 |
| page | number | 页码，默认 1 |
| pageSize | number | 每页数量，默认 20 |

#### GET /api/v1/todos/:id — 获取单个 Todo

#### PATCH /api/v1/todos/:id — 更新 Todo

请求体（所有字段可选）：
```json
{
  "title": "新标题",
  "priority": "low",
  "tags": ["新标签"]
}
```

#### DELETE /api/v1/todos/:id — 删除 Todo

#### POST /api/v1/todos/:id/toggle — 切换完成状态

#### GET /api/v1/lists — 列出所有列表

#### GET /api/v1/lists/:id — 获取列表详情（含 todo）

#### GET /api/v1/search — 全局搜索

查询参数：`q=关键词`

#### POST /api/v1/undo — 撤销最近操作

### 7.4 限流

```typescript
// services/agent-api/rate-limit.ts
const RATE_LIMIT = 100;  // 每分钟最大请求数
const WINDOW_MS = 60000; // 1 分钟窗口

const requestCounts = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(apiKey: string): boolean {
  const now = Date.now();
  const record = requestCounts.get(apiKey);

  if (!record || now > record.resetAt) {
    requestCounts.set(apiKey, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }

  if (record.count >= RATE_LIMIT) {
    return false;
  }

  record.count++;
  return true;
}
```

### 7.5 Android HTTP 服务器

```typescript
// services/agent-api/server.ts
// 使用 uni-app 原生插件或轻量 HTTP 服务器

import { HttpServer } from '@/plugins/http-server';

let server: HttpServer | null = null;

export async function startApiServer(port: number = 8080): Promise<void> {
  server = new HttpServer(port);

  server.use(authMiddleware);
  server.use(rateLimitMiddleware);

  // 注册路由
  server.post('/api/v1/todos', handleCreateTodo);
  server.get('/api/v1/todos', handleListTodos);
  server.get('/api/v1/todos/:id', handleGetTodo);
  server.patch('/api/v1/todos/:id', handleUpdateTodo);
  server.delete('/api/v1/todos/:id', handleDeleteTodo);
  server.post('/api/v1/todos/:id/toggle', handleToggleTodo);
  server.post('/api/v1/todos/batch', handleBatchCreate);
  server.get('/api/v1/lists', handleListLists);
  server.get('/api/v1/lists/:id', handleGetList);
  server.get('/api/v1/search', handleSearch);
  server.post('/api/v1/undo', handleUndo);

  await server.listen();
  console.log(`Agent API server started on port ${port}`);
}

export async function stopApiServer(): Promise<void> {
  if (server) {
    await server.close();
    server = null;
  }
}
```

---

## 8. 搜索实现

### 8.1 搜索策略

首版使用 SQLite LIKE 查询，满足基本需求：

```typescript
// services/search.ts
export async function searchTodos(keyword: string, filter?: TodoFilter): Promise<Todo[]> {
  // 1. 关键词搜索
  let results = await todoRepository.search(keyword);

  // 2. 应用筛选条件
  if (filter) {
    results = applyFilter(results, filter);
  }

  // 3. 按匹配度排序（标题匹配优先于详情匹配）
  results.sort((a, b) => {
    const aTitle = a.title.toLowerCase().includes(keyword.toLowerCase()) ? 0 : 1;
    const bTitle = b.title.toLowerCase().includes(keyword.toLowerCase()) ? 0 : 1;
    return aTitle - bTitle;
  });

  return results;
}
```

### 8.2 后续优化

当 todo 数据量超过 1000 条时，考虑：
- SQLite FTS5 全文索引
- 内存缓存热门搜索结果

---

## 9. 平台适配

### 9.1 微信小程序约束

| 约束 | 影响 | 应对方案 |
|------|------|----------|
| 包体大小限制（2MB） | 无法打包过多静态资源 | 图片使用 CDN、代码按需加载 |
| 不支持 TCP 监听 | Agent API 无法直接提供 | Android 端代理（首版） |
| WebSocket 最大并发 5 条 | 同步连接受限 | 单连接复用（v1.1） |
| 个人主体 AI 类目审核 | 可能被拒 | 准备 H5 备用方案 |
| 本地存储限制（10MB） | SQLite 数据量受限 | 数据量极小（纯文本 todo），远低于限制 |

### 9.2 Android 适配

| 项目 | 方案 |
|------|------|
| 打包 | UniApp 云打包或本地 Android Studio |
| HTTP 服务器 | 使用 uni-app 原生插件（如 `uts-http-server`） |
| 应用商店 | 华为、小米、OPPO、vivo、应用宝 |
| 权限 | 网络权限（Agent API 服务） |

### 9.3 平台检测

```typescript
// utils/platform.ts
export function getPlatform(): 'mp-weixin' | 'app' | 'h5' {
  // #ifdef MP-WEIXIN
  return 'mp-weixin';
  // #endif

  // #ifdef APP-PLUS
  return 'app';
  // #endif

  // #ifdef H5
  return 'h5';
  // #endif

  return 'h5'; // fallback
}

export function supportsAgentApi(): boolean {
  return getPlatform() === 'app';
}
```

---

## 10. 同步架构（v1.1 预留）

### 10.1 操作日志兼容

Undo Stack 的操作记录天然兼容同步需求：

```typescript
// 同步数据格式（v1.1）
interface SyncOperation {
  seq: number;           // 单调递增序列号
  action: string;        // 同 UndoRecord.actionType
  entityType: string;    // 同 UndoRecord.entityType
  entityId: string;      // 同 UndoRecord.entityId
  data: any;             // 操作数据
  timestamp: number;     // 操作时间戳
  deviceId: string;      // 设备标识
}
```

### 10.2 预留接口

```typescript
// stores/sync.ts（v1.1 实现）
export const useSyncStore = defineStore('sync', () => {
  const connected = ref(false);
  const lastSeq = ref(0);

  // v1.1 实现
  async function connect(sessionId: string, encryptKey: string): Promise<void> {
    // WebSocket 连接到 Cloudflare Workers 中继
  }

  async function sendOperation(op: SyncOperation): Promise<void> {
    // AES-256-GCM 加密后发送
  }

  async function onOperation received(op: SyncOperation): Promise<void> {
    // 解密、应用到本地
  }

  return { connected, lastSeq, connect, sendOperation };
});
```

---

## 11. 安全考虑

### 11.1 API Key 存储

```typescript
// 微信小程序端：wx.setStorageSync 加密存储
// Android 端：SharedPreferences 或 KeyStore

export async function encryptApiKey(key: string): Promise<string> {
  // 使用设备唯一标识作为加密密钥
  const deviceId = await getDeviceId();
  return aesEncrypt(key, deviceId);
}

export async function decryptApiKey(encrypted: string): Promise<string> {
  const deviceId = await getDeviceId();
  return aesDecrypt(encrypted, deviceId);
}
```

### 11.2 第三方 API 安全

| 风险 | 应对 |
|------|------|
| API Key 泄露 | 本地加密存储，不上传任何服务器 |
| Agent API 滥用 | 限流 + API Key 认证 |
| LLM 响应注入 | 解析 JSON 响应时严格校验格式 |
| 中间人攻击 | HTTPS 强制（LLM API 调用） |

---

## 12. 性能考虑

### 12.1 首次加载

| 优化点 | 方案 |
|--------|------|
| 数据库初始化 | 异步执行，不阻塞 UI 渲染 |
| todo 加载 | 分页加载，默认只加载最近 100 条 |
| 图片资源 | 使用 CDN，本地缓存 |

### 12.2 运行时性能

| 场景 | 方案 |
|------|------|
| 长列表渲染 | 虚拟列表（只渲染可见区域） |
| 搜索 | 防抖（300ms），避免频繁查询 |
| 撤销栈 | 内存中维护，异步持久化 |
| LLM 调用 | 超时 30 秒，loading 状态反馈 |

### 12.3 存储优化

| 数据 | 策略 |
|------|------|
| todo 数据 | SQLite，定期清理软删除记录（30 天后） |
| 撤销记录 | 最多 50 条，超出丢弃 |
| Agent 配置 | 单条记录，覆盖写入 |
| 对话历史 | 内存中，不持久化 |

---

## 13. 技术选型决策记录

| 决策 | 选择 | 替代方案 | 理由 |
|------|------|----------|------|
| 跨端框架 | UniApp (Vue 3 + TS) | React Native、Flutter | 微信小程序原生支持，一套代码三端 |
| 状态管理 | Pinia | Vuex | Vue 3 官方推荐，Composition API 友好 |
| 本地存储 | SQLite | IndexedDB、localStorage | 结构化查询，性能好，支持复杂筛选 |
| LLM 接口 | OpenAI 兼容 | 自定义协议 | 覆盖最多提供商，社区标准 |
| HTTP 服务器 | uni-app 原生插件 | 内嵌 Node.js | 轻量，Android 专用 |
| 搜索 | SQLite LIKE | FTS5、Elasticsearch | 首版数据量小，后续可升级 |
| 构建工具 | Vite | Webpack | UniApp 官方推荐，开发体验好 |

---

## 14. 开发环境

### 14.1 依赖

```json
{
  "dependencies": {
    "vue": "^3.4",
    "pinia": "^2.1",
    "@dcloudio/uni-app": "latest",
    "@dcloudio/uni-mp-weixin": "latest",
    "@dcloudio/uni-app-plus": "latest"
  },
  "devDependencies": {
    "typescript": "^5.3",
    "vite": "^5.0",
    "@dcloudio/vite-plugin-uni": "latest",
    "@types/node": "^20"
  }
}
```

### 14.2 脚本

```json
{
  "scripts": {
    "dev:mp-weixin": "uni -p mp-weixin",
    "dev:app": "uni -p app",
    "build:mp-weixin": "uni build -p mp-weixin",
    "build:app": "uni build -p app",
    "typecheck": "vue-tsc --noEmit"
  }
}
```

---

*本文档为开发的技术依据。架构变更需更新本文档并通知团队。*
