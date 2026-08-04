import { getDatabase } from './database'
import type { Todo, CreateTodoInput, UpdateTodoInput, TodoFilter } from '@/types'

function now(): string {
  return new Date().toISOString()
}

function rowToTodo(row: any): Todo {
  return {
    id: row.id,
    title: row.title,
    priority: row.priority,
    dueDate: row.due_date || null,
    tags: JSON.parse(row.tags || '[]'),
    detail: row.detail || '',
    completed: row.completed === 1,
    listId: row.list_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deleted: row.deleted === 1
  }
}

export const todoRepository = {
  async findAll(filter?: TodoFilter): Promise<Todo[]> {
    const db = getDatabase()
    let sql = 'SELECT * FROM todo WHERE deleted = 0'
    const params: any[] = []

    if (filter?.listId) {
      sql += ' AND list_id = ?'
      params.push(filter.listId)
    }
    if (filter?.priority) {
      sql += ' AND priority = ?'
      params.push(filter.priority)
    }
    if (filter?.completed !== undefined) {
      sql += ' AND completed = ?'
      params.push(filter.completed ? 1 : 0)
    }

    sql += ' ORDER BY created_at DESC'

    const result = await db.executeSql(sql, params)
    return result.rows.map(rowToTodo)
  },

  async findById(id: string): Promise<Todo | null> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM todo WHERE id = ? AND deleted = 0',
      [id]
    )
    return result.rows.length > 0 ? rowToTodo(result.rows[0]) : null
  },

  async insert(todo: Todo): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `INSERT INTO todo (id, title, priority, due_date, tags, detail,
       completed, list_id, created_at, updated_at, deleted)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [todo.id, todo.title, todo.priority, todo.dueDate,
       JSON.stringify(todo.tags), todo.detail, todo.completed ? 1 : 0,
       todo.listId, todo.createdAt, todo.updatedAt, 0]
    )
  },

  async update(id: string, input: UpdateTodoInput): Promise<void> {
    const db = getDatabase()
    const fields: string[] = []
    const params: any[] = []

    if (input.title !== undefined) { fields.push('title = ?'); params.push(input.title) }
    if (input.priority !== undefined) { fields.push('priority = ?'); params.push(input.priority) }
    if (input.dueDate !== undefined) { fields.push('due_date = ?'); params.push(input.dueDate) }
    if (input.tags !== undefined) { fields.push('tags = ?'); params.push(JSON.stringify(input.tags)) }
    if (input.detail !== undefined) { fields.push('detail = ?'); params.push(input.detail) }
    if (input.listId !== undefined) { fields.push('list_id = ?'); params.push(input.listId) }

    fields.push('updated_at = ?')
    params.push(now())
    params.push(id)

    await db.executeSql(
      `UPDATE todo SET ${fields.join(', ')} WHERE id = ?`, params
    )
  },

  async softDelete(id: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      'UPDATE todo SET deleted = 1, updated_at = ? WHERE id = ?',
      [now(), id]
    )
  },

  async restore(todo: Todo): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `INSERT OR REPLACE INTO todo (id, title, priority, due_date, tags, detail,
       completed, list_id, created_at, updated_at, deleted)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [todo.id, todo.title, todo.priority, todo.dueDate,
       JSON.stringify(todo.tags), todo.detail, todo.completed ? 1 : 0,
       todo.listId, todo.createdAt, todo.updatedAt, todo.deleted ? 1 : 0]
    )
  },

  async hardDelete(id: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql('DELETE FROM todo WHERE id = ?', [id])
  },

  async toggleComplete(id: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `UPDATE todo SET completed = CASE WHEN completed = 1 THEN 0 ELSE 1 END,
       updated_at = ? WHERE id = ?`,
      [now(), id]
    )
  },

  async search(keyword: string): Promise<Todo[]> {
    const db = getDatabase()
    const like = `%${keyword}%`
    const result = await db.executeSql(
      `SELECT * FROM todo WHERE deleted = 0
       AND (title LIKE ? OR detail LIKE ? OR tags LIKE ?)`,
      [like, like, like]
    )
    return result.rows.map(rowToTodo)
  }
}
