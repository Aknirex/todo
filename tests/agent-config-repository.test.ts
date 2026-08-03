import { describe, it, expect, beforeEach, vi } from 'vitest'
import { agentConfigRepository } from '@/dal/agent-config-repository'
import { createMockDb, type MockDb } from './__mocks__/db'

let mockDb: MockDb

vi.mock('@/dal/database', () => ({
  getDatabase: () => mockDb
}))

describe('agentConfigRepository', () => {
  beforeEach(() => {
    mockDb = createMockDb()
    mockDb._tables.set('agent_config', [])
  })

  it('save and load should persist config', async () => {
    await agentConfigRepository.save({
      provider: 'deepseek',
      apiKey: 'sk-test',
      baseUrl: 'https://api.deepseek.com',
      model: 'deepseek-chat'
    })

    const config = await agentConfigRepository.load()
    expect(config.provider).toBe('deepseek')
    expect(config.apiKey).toBe('sk-test')
  })

  it('load should return defaults when no config exists', async () => {
    const config = await agentConfigRepository.load()
    expect(config.provider).toBeNull()
    expect(config.apiKey).toBeNull()
  })
})
