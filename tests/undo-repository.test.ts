import { describe, it, expect, beforeEach, vi } from 'vitest'
import { undoRepository } from '@/dal/undo-repository'
import { createMockDb, type MockDb } from './__mocks__/db'

let mockDb: MockDb

vi.mock('@/dal/database', () => ({
  getDatabase: () => mockDb
}))

describe('undoRepository', () => {
  beforeEach(() => {
    mockDb = createMockDb()
    mockDb._tables.set('undo_record', [])
  })

  it('insert should add an undo record', async () => {
    await undoRepository.insert({
      id: 'undo-1',
      actionType: 'create',
      entityType: 'todo',
      entityId: 'todo-1',
      beforeState: null,
      afterState: '{"id":"todo-1"}',
      createdAt: '2026-01-01T00:00:00Z'
    })
    const rows = mockDb._tables.get('undo_record')!
    expect(rows).toHaveLength(1)
  })

  it('findRecent should return records ordered by created_at DESC', async () => {
    mockDb._tables.set('undo_record', [
      { id: 'undo-1', action_type: 'create', entity_type: 'todo', entity_id: 't1', before_state: null, after_state: '{}', created_at: '2026-01-01' },
      { id: 'undo-2', action_type: 'update', entity_type: 'todo', entity_id: 't2', before_state: '{}', after_state: '{}', created_at: '2026-01-02' }
    ])
    const results = await undoRepository.findRecent(10)
    expect(results).toHaveLength(2)
    expect(results[0].id).toBe('undo-2')
  })

  it('delete should remove a record by id', async () => {
    mockDb._tables.set('undo_record', [
      { id: 'undo-1', action_type: 'create', entity_type: 'todo', entity_id: 't1', created_at: '2026-01-01' }
    ])
    await undoRepository.delete('undo-1')
    expect(mockDb._tables.get('undo_record')).toHaveLength(0)
  })
})
