import { describe, it, expect, beforeEach } from 'vitest'
import { todoRepository } from '@/dal/todo-repository'
import { createMockDb, type MockDb } from './__mocks__/db'

let mockDb: MockDb

vi.mock('@/dal/database', () => ({
  getDatabase: () => mockDb
}))

describe('todoRepository', () => {
  beforeEach(() => {
    mockDb = createMockDb()
    mockDb._tables.set('todo', [])
  })

  describe('insert', () => {
    it('should insert a todo into the database', async () => {
      const todo = {
        id: 'test-1',
        title: 'Test todo',
        priority: 'medium' as const,
        dueDate: null,
        tags: [],
        detail: '',
        completed: false,
        listId: 'default',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
        deleted: false
      }

      await todoRepository.insert(todo)
      const rows = mockDb._tables.get('todo')!
      expect(rows).toHaveLength(1)
      expect(rows[0].id).toBe('test-1')
      expect(rows[0].title).toBe('Test todo')
    })
  })

  describe('findAll', () => {
    it('should return all non-deleted todos', async () => {
      mockDb._tables.set('todo', [
        { id: '1', title: 'A', priority: 'high', due_date: null, tags: '[]', detail: '', completed: 0, list_id: 'default', created_at: '2026-01-01', updated_at: '2026-01-01', deleted: 0 },
        { id: '2', title: 'B', priority: 'low', due_date: null, tags: '[]', detail: '', completed: 0, list_id: 'default', created_at: '2026-01-02', updated_at: '2026-01-02', deleted: 1 }
      ])

      const results = await todoRepository.findAll()
      expect(results).toHaveLength(1)
      expect(results[0].id).toBe('1')
    })

    it('should filter by listId', async () => {
      mockDb._tables.set('todo', [
        { id: '1', title: 'A', priority: 'high', due_date: null, tags: '[]', detail: '', completed: 0, list_id: 'list-1', created_at: '2026-01-01', updated_at: '2026-01-01', deleted: 0 },
        { id: '2', title: 'B', priority: 'low', due_date: null, tags: '[]', detail: '', completed: 0, list_id: 'list-2', created_at: '2026-01-02', updated_at: '2026-01-02', deleted: 0 }
      ])

      const results = await todoRepository.findAll({ listId: 'list-1' })
      expect(results).toHaveLength(1)
      expect(results[0].listId).toBe('list-1')
    })
  })

  describe('softDelete', () => {
    it('should mark todo as deleted', async () => {
      mockDb._tables.set('todo', [
        { id: '1', title: 'A', deleted: 0, updated_at: '2026-01-01' }
      ])

      await todoRepository.softDelete('1')
      const row = mockDb._tables.get('todo')![0]
      expect(row.deleted).toBe(1)
    })
  })

  describe('toggleComplete', () => {
    it('should toggle completed from 0 to 1', async () => {
      mockDb._tables.set('todo', [
        { id: '1', title: 'A', completed: 0, updated_at: '2026-01-01' }
      ])

      await todoRepository.toggleComplete('1')
      const row = mockDb._tables.get('todo')![0]
      expect(row.completed).toBe(1)
    })
  })

  describe('search', () => {
    it('should find todos matching keyword in title', async () => {
      mockDb._tables.set('todo', [
        { id: '1', title: 'Buy groceries', detail: '', tags: '[]', deleted: 0 },
        { id: '2', title: 'Write report', detail: 'summary', tags: '[]', deleted: 0 }
      ])

      const results = await todoRepository.search('report')
      expect(results).toHaveLength(1)
      expect(results[0].title).toBe('Write report')
    })
  })
})
