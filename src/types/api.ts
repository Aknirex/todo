import type { Priority } from './todo'

export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T | null
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
}

export interface TodoFilter {
  priority?: Priority
  tags?: string[]
  completed?: boolean
  listId?: string
  dueDateRange?: { start: string; end: string }
  keyword?: string
}
