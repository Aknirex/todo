import { getDatabase } from './database'
import type { UndoRecord } from '@/types'

function rowToUndoRecord(row: any): UndoRecord {
  return {
    id: row.id,
    actionType: row.action_type,
    entityType: row.entity_type,
    entityId: row.entity_id,
    beforeState: row.before_state || null,
    afterState: row.after_state || null,
    createdAt: row.created_at
  }
}

export const undoRepository = {
  async insert(record: UndoRecord): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `INSERT INTO undo_record (id, action_type, entity_type, entity_id, before_state, after_state, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [record.id, record.actionType, record.entityType, record.entityId,
       record.beforeState, record.afterState, record.createdAt]
    )
  },

  async findRecent(limit: number = 50): Promise<UndoRecord[]> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM undo_record ORDER BY created_at DESC LIMIT ?',
      [limit]
    )
    return result.rows.map(rowToUndoRecord)
  },

  async delete(id: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql('DELETE FROM undo_record WHERE id = ?', [id])
  },

  async deleteOlderThan(date: string): Promise<void> {
    const db = getDatabase()
    await db.executeSql('DELETE FROM undo_record WHERE created_at < ?', [date])
  }
}
