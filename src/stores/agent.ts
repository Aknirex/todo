import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { agentConfigRepository } from '@/dal'
import { createLlmAdapter, buildDecomposePrompt, buildSummarizePrompt } from '@/services/llm'
import type { AgentConfig, AgentMessage, CreateTodoInput, Todo, Priority } from '@/types'

export const useAgentStore = defineStore('agent', () => {
  const config = ref<AgentConfig>({
    provider: null,
    apiKey: null,
    baseUrl: null,
    model: null
  })

  const messages = ref<AgentMessage[]>([])

  const configured = computed(() => !!config.value.apiKey)

  function now(): string {
    return new Date().toISOString()
  }

  async function loadConfig(): Promise<void> {
    config.value = await agentConfigRepository.load()
  }

  async function saveConfig(): Promise<void> {
    await agentConfigRepository.save(config.value)
  }

  function parseDecomposeResponse(raw: string): CreateTodoInput[] {
    // Strip markdown code fences if present
    let json = raw.trim()
    const codeBlockMatch = json.match(/```(?:json)?\s*([\s\S]*?)```/)
    if (codeBlockMatch) {
      json = codeBlockMatch[1].trim()
    }

    let parsed: any[]
    try {
      parsed = JSON.parse(json)
    } catch {
      // Try to find a JSON array in the text
      const arrayMatch = json.match(/\[[\s\S]*\]/)
      if (arrayMatch) {
        parsed = JSON.parse(arrayMatch[0])
      } else {
        throw new Error('无法解析 LLM 返回的 JSON')
      }
    }

    if (!Array.isArray(parsed)) {
      throw new Error('LLM 返回的不是数组格式')
    }

    const validPriorities: Priority[] = ['high', 'medium', 'low']

    return parsed.map((item: any) => ({
      title: typeof item.title === 'string' ? item.title : '',
      priority: validPriorities.includes(item.priority) ? item.priority : 'medium',
      tags: Array.isArray(item.tags)
        ? item.tags.filter((t: any) => typeof t === 'string')
        : []
    }))
  }

  async function decomposeText(text: string): Promise<CreateTodoInput[]> {
    if (!text.trim()) throw new Error('请输入文字内容')

    const adapter = createLlmAdapter(config.value.provider || undefined)
    const promptMessages = buildDecomposePrompt(text)

    const response = await adapter.chat({
      messages: promptMessages,
      config: config.value
    })

    messages.value.push({
      role: 'user',
      content: text,
      timestamp: now()
    })

    const parsed = parseDecomposeResponse(response)

    messages.value.push({
      role: 'assistant',
      content: JSON.stringify(parsed, null, 2),
      timestamp: now()
    })

    return parsed
  }

  async function summarizeTodos(todos: Todo[], context?: string): Promise<string> {
    if (todos.length === 0) throw new Error('没有可总结的待办事项')

    const adapter = createLlmAdapter(config.value.provider || undefined)
    const promptMessages = buildSummarizePrompt(todos, context)

    const response = await adapter.chat({
      messages: promptMessages,
      config: config.value
    })

    messages.value.push({
      role: 'assistant',
      content: response,
      timestamp: now()
    })

    return response
  }

  return {
    config,
    messages,
    configured,
    loadConfig,
    saveConfig,
    decomposeText,
    summarizeTodos
  }
})
