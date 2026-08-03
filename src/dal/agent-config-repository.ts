import { getDatabase } from './database'
import type { AgentConfig } from '@/types'

export const agentConfigRepository = {
  async load(): Promise<AgentConfig> {
    const db = getDatabase()
    const result = await db.executeSql(
      'SELECT * FROM agent_config WHERE id = ?',
      ['default']
    )
    if (result.rows.length === 0) {
      return { provider: null, apiKey: null, baseUrl: null, model: null }
    }
    const row = result.rows[0]
    return {
      provider: row.provider || null,
      apiKey: row.api_key || null,
      baseUrl: row.base_url || null,
      model: row.model || null
    }
  },

  async save(config: AgentConfig): Promise<void> {
    const db = getDatabase()
    await db.executeSql(
      `INSERT OR REPLACE INTO agent_config (id, provider, api_key, base_url, model, updated_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      ['default', config.provider, config.apiKey, config.baseUrl, config.model,
       new Date().toISOString()]
    )
  }
}
