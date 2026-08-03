export type Priority = 'high' | 'medium' | 'low'

export interface Todo {
  id: string
  title: string
  priority: Priority
  dueDate: string | null
  tags: string[]
  detail: string
  completed: boolean
  listId: string
  createdAt: string
  updatedAt: string
  deleted: boolean
}

export interface CreateTodoInput {
  title?: string
  priority?: Priority
  dueDate?: string | null
  tags?: string[]
  detail?: string
  listId?: string
}

export interface UpdateTodoInput {
  title?: string
  priority?: Priority
  dueDate?: string | null
  tags?: string[]
  detail?: string
  listId?: string
}
