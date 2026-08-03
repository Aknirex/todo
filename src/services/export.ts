import type { Todo, Priority } from '@/types'

const PRIORITY_LABEL: Record<Priority, string> = {
  high: '[高]',
  medium: '[中]',
  low: '[低]'
}

function formatTodoLine(todo: Todo): string {
  const status = todo.completed ? '[已完成]' : '[未完成]'
  const priority = PRIORITY_LABEL[todo.priority]
  const date = todo.dueDate ? ` 截止: ${todo.dueDate}` : ''
  const tags = todo.tags.length > 0 ? ` 标签: ${todo.tags.join(', ')}` : ''
  return `${status}${priority} ${todo.title}${date}${tags}`
}

/**
 * Export todos as plain text, one line per todo.
 */
export function exportAsText(todos: Todo[]): string {
  return todos.map(formatTodoLine).join('\n')
}

/**
 * Export todos as Markdown.
 * Includes a heading, numbered list with title, priority, tags, due date, and status.
 */
export function exportAsMarkdown(todos: Todo[]): string {
  const lines: string[] = ['# 待办事项导出\n']

  todos.forEach((todo, index) => {
    const status = todo.completed ? '✓ 已完成' : '○ 未完成'
    const priority = PRIORITY_LABEL[todo.priority]
    lines.push(`## ${index + 1}. ${todo.title}`)
    lines.push('')
    lines.push(`- **状态**: ${status}`)
    lines.push(`- **优先级**: ${priority}`)
    if (todo.dueDate) {
      lines.push(`- **截止日期**: ${todo.dueDate}`)
    }
    if (todo.tags.length > 0) {
      lines.push(`- **标签**: ${todo.tags.join(', ')}`)
    }
    if (todo.detail) {
      lines.push(`- **详情**: ${todo.detail}`)
    }
    lines.push('')
  })

  return lines.join('\n')
}
