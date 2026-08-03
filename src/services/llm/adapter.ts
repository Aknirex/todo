import type { AgentConfig } from '@/types'

export interface LlmMessage {
  role: 'system' | 'user' | 'assistant'
  content: string
}

export interface LlmRequest {
  messages: LlmMessage[]
  config: AgentConfig
  temperature?: number
  maxTokens?: number
}

export interface LlmAdapter {
  chat(request: LlmRequest): Promise<string>
}

const DEFAULT_BASE_URL = 'https://api.deepseek.com/v1'
const DEFAULT_MODEL = 'deepseek-chat'

function buildUrl(config: AgentConfig): string {
  const base = config.baseUrl || DEFAULT_BASE_URL
  // Normalize: strip trailing slash, then append /chat/completions
  const clean = base.replace(/\/+$/, '')
  return `${clean}/chat/completions`
}

function buildHeaders(config: AgentConfig): Record<string, string> {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${config.apiKey || ''}`
  }
}

class OpenAIAdapter implements LlmAdapter {
  async chat(request: LlmRequest): Promise<string> {
    const url = buildUrl(request.config)
    const headers = buildHeaders(request.config)

    const body = {
      model: request.config.model || DEFAULT_MODEL,
      messages: request.messages,
      temperature: request.temperature ?? 0.7,
      max_tokens: request.maxTokens ?? 2048
    }

    return new Promise<string>((resolve, reject) => {
      uni.request({
        url,
        method: 'POST',
        header: headers,
        data: body,
        timeout: 30000,
        success(res: any) {
          const statusCode = res.statusCode || 0
          if (statusCode >= 200 && statusCode < 300) {
            try {
              const content = res.data?.choices?.[0]?.message?.content
              if (typeof content === 'string' && content.length > 0) {
                resolve(content)
              } else {
                reject(new Error('LLM 返回内容为空'))
              }
            } catch (e) {
              reject(new Error('解析 LLM 响应失败'))
            }
          } else {
            const errMsg = res.data?.error?.message || res.errMsg || `HTTP ${statusCode}`
            reject(new Error(`API 请求失败: ${errMsg}`))
          }
        },
        fail(err: any) {
          reject(new Error(`网络请求失败: ${err.errMsg || '未知错误'}`))
        }
      })
    })
  }
}

export function createLlmAdapter(_provider?: string): LlmAdapter {
  return new OpenAIAdapter()
}
