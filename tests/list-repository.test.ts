import { describe, it, expect, beforeEach, vi } from 'vitest'
import { listRepository } from '@/dal/list-repository'
import { createMockDb, type MockDb } from './__mocks__/db'

let mockDb: MockDb

vi.mock('@/dal/database', () => ({
  getDatabase: () => mockDb
}))

describe('listRepository', () => {
  beforeEach(() => {
    mockDb = createMockDb()
    mockDb._tables.set('list', [
      { id: 'default', name: '默认列表', is_default: 1, created_at: '2026-01-01', sort_order: 0 }
    ])
  })

  it('findAll should return all lists', async () => {
    const results = await listRepository.findAll()
    expect(results).toHaveLength(1)
    expect(results[0].name).toBe('默认列表')
  })

  it('insert should add a new list', async () => {
    await listRepository.insert({
      id: 'list-2',
      name: '工作',
      isDefault: false,
      createdAt: '2026-01-02',
      sortOrder: 1
    })
    const rows = mockDb._tables.get('list')!
    expect(rows).toHaveLength(2)
  })

  it('findDefault should return the default list', async () => {
    const result = await listRepository.findDefault()
    expect(result).not.toBeNull()
    expect(result!.name).toBe('默认列表')
  })

  it('update should change list name', async () => {
    await listRepository.update('default', { name: '新名称' })
    const row = mockDb._tables.get('list')![0]
    expect(row.name).toBe('新名称')
  })
})
