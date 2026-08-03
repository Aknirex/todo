import type { Todo } from '@/types'
import type { LlmMessage } from './adapter'

export function buildDecomposePrompt(text: string): LlmMessage[] {
  return [
    {
      role: 'system',
      content: `你是一个任务管理助手。用户会给你一段文字，请从中提取出待办事项。

请返回一个 JSON 数组，每个元素包含以下字段：
- title: 待办事项标题（字符串，必填）
- priority: 优先级，只能是 "high"、"medium" 或 "low"（默认 "medium"）
- tags: 标签数组，每个标签为字符串（可为空数组）

要求：
1. 只返回 JSON 数组，不要包含任何其他文字
2. 如果用户提到了优先级相关的词（如"紧急"、"重要"、"尽快"），设为 high
3. 如果用户提到了"有空再做"、"不急"等词，设为 low
4. 从文字中提取有意义的关键词作为标签
5. 如果原文不包含明确的任务，返回空数组 []`
    },
    {
      role: 'user',
      content: text
    }
  ]
}

export function buildSummarizePrompt(todos: Todo[], context?: string): LlmMessage[] {
  const todoListText = todos
    .filter(t => !t.deleted)
    .map(t => {
      const status = t.completed ? '✓已完成' : '○待完成'
      const priority = { high: '高优先', medium: '中优先', low: '低优先' }[t.priority] || ''
      const tags = t.tags.length > 0 ? ` [${t.tags.join(', ')}]` : ''
      return `- ${status} ${priority} ${t.title}${tags}${t.detail ? ` — ${t.detail}` : ''}`
    })
    .join('\n')

  const contextLine = context ? `\n额外上下文: ${context}` : ''

  return [
    {
      role: 'system',
      content: `你是一个任务管理助手。请根据用户的待办事项列表，生成一段简洁有条理的总结文字。

要求：
1. 按优先级和完成状态组织内容
2. 突出需要关注的高优先级待办事项
3. 语气友好、鼓励性
4. 控制在 3-5 段以内
5. 纯文本输出，不使用 markdown 格式`
    },
    {
      role: 'user',
      content: `以下是我的待办事项列表：\n\n${todoListText}${contextLine}`
    }
  ]
}
