export type AgentActionType = 'create' | 'update' | 'delete' | 'toggle_complete' | 'move'
export type EntityType = 'todo' | 'list'

export interface UndoRecord {
  id: string
  actionType: AgentActionType
  entityType: EntityType
  entityId: string
  beforeState: string | null
  afterState: string | null
  createdAt: string
}

export interface AgentConfig {
  provider: string | null
  apiKey: string | null
  baseUrl: string | null
  model: string | null
}

export interface AgentMessage {
  role: 'user' | 'assistant'
  content: string
  timestamp: string
}
