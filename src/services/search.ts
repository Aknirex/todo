import { todoRepository } from '@/dal'
import type { Todo, TodoFilter } from '@/types'

/**
 * Search todos by keyword with optional additional filters.
 * - Uses todoRepository.search for keyword matching on title, detail, and tags.
 * - Applies extra filters (priority, completed, dateRange) on the result set.
 * - Sorts by match quality: title matches rank above tag/detail matches.
 */
export async function searchTodos(keyword: string, filter?: TodoFilter): Promise<Todo[]> {
  const raw = await todoRepository.search(keyword)

  const lowerKeyword = keyword.toLowerCase()

  let results = raw.filter(todo => {
    // Priority filter
    if (filter?.priority && todo.priority !== filter.priority) {
      return false
    }
    // Completed status filter
    if (filter?.completed !== undefined && todo.completed !== filter.completed) {
      return false
    }
    // Date range filter
    if (filter?.dueDateRange) {
      const d = todo.dueDate
      if (!d) return false
      if (d < filter.dueDateRange.start || d > filter.dueDateRange.end) {
        return false
      }
    }
    return true
  })

  // Sort by match quality: title match first, then detail, then tags
  results.sort((a, b) => {
    const aTitle = a.title.toLowerCase().includes(lowerKeyword) ? 0 : 1
    const bTitle = b.title.toLowerCase().includes(lowerKeyword) ? 0 : 1
    if (aTitle !== bTitle) return aTitle - bTitle

    const aDetail = a.detail.toLowerCase().includes(lowerKeyword) ? 1 : 2
    const bDetail = b.detail.toLowerCase().includes(lowerKeyword) ? 1 : 2
    return aDetail - bDetail
  })

  return results
}
