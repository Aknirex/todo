import { openDatabase } from './sqlite-adapter'

let db: any = null

export async function initDatabase(): Promise<void> {
  db = await openDatabase('aknirex_todo', 1)
  await runMigrations(db)
}

export function getDatabase() {
  if (!db) throw new Error('Database not initialized')
  return db
}

async function runMigrations(db: any): Promise<void> {
  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS list (
      id TEXT PRIMARY KEY,
      name TEXT DEFAULT '默认列表',
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  `)

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
  `)

  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_todo_list_id ON todo(list_id)`)
  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_todo_completed ON todo(completed)`)
  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_todo_priority ON todo(priority)`)
  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_todo_due_date ON todo(due_date)`)
  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_todo_deleted ON todo(deleted)`)

  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS undo_record (
      id TEXT PRIMARY KEY,
      action_type TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      before_state TEXT,
      after_state TEXT,
      created_at TEXT NOT NULL
    )
  `)

  await db.executeSql(`CREATE INDEX IF NOT EXISTS idx_undo_created_at ON undo_record(created_at)`)

  await db.executeSql(`
    CREATE TABLE IF NOT EXISTS agent_config (
      id TEXT PRIMARY KEY,
      provider TEXT,
      api_key TEXT,
      base_url TEXT,
      model TEXT,
      updated_at TEXT NOT NULL
    )
  `)

  await db.executeSql(`
    INSERT OR IGNORE INTO list (id, name, is_default, created_at, sort_order)
    VALUES ('default', '默认列表', 1, datetime('now'), 0)
  `)
}
