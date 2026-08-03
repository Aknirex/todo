import { getDatabase } from './database'
import type { TodoList } from '@/types'

function rowToList(row: any): TodoList {
  return {
    id: row.id,
    name: row.name,
    isDefault: row.is_default === 1,
    createdAt: row.created_at,
    sortOrder: row.sort_order
  }
}

export const listRepository = {
  async findAll(): Promise<TodoList[]> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM list ORDER BY sort_order ASC'
    )
    return result.rows.map(rowToList)
  },

  async findById(id: string): Promise<TodoList | null> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM list WHERE id = ?',
      [id]
    )
    return result.rows.length > 0 ? rowToList(result.rows[0]) : null
  },

  async findDefault(): Promise<TodoList | null> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM list WHERE is_default = 1'
    )
    return result.rows.length > 0 ? rowToList(result.rows[0]) : null
  },

  async insert(list: TodoList): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `INSERT INTO list (id, name, is_default, created_at, sort_order)
       VALUES (?, ?, ?, ?, ?)`,
      [list.id, list.name, list.isDefault ? 1 : 0, list.createdAt, list.sortOrder]
    )
  },

  async update(id: string, input: { name?: string; sortOrder?: number }): Promise<void> {
    const db = getDatabase()
    const fields: string[] = []
    const params: any[] = []

    if (input.name !== undefined) { fields.push('name = ?'); params.push(input.name) }
    if (input.sortOrder !== undefined) { fields.push('sort_order = ?'); params.push(input.sortOrder) }

    if (fields.length === 0) return
    params.push(id)

    await db.executeSql(
      `UPDATE list SET ${fields.join(', ')} WHERE id = ?`, params
    )
  },

  async delete(id: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql('DELETE FROM list WHERE id = ? AND is_default = 0', [id])
  }
}
