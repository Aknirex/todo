import type { ApiResponse } from '@/types'

export interface AgentApiRoute {
  method: string
  path: string
  handler: (params: { body?: any; query?: any; pathParams?: any }) => Promise<ApiResponse>
}

export interface AgentApiServer {
  routes: AgentApiRoute[]
  apiKey: string | null
  port: number
  running: boolean
}

export function createApiServer(port: number = 8080): AgentApiServer {
  return {
    routes: [],
    apiKey: null,
    port,
    running: false
  }
}

export function registerRoute(
  server: AgentApiServer,
  method: string,
  path: string,
  handler: AgentApiRoute['handler']
): void {
  server.routes.push({ method: method.toUpperCase(), path, handler })
}

export function setApiKey(server: AgentApiServer, key: string): void {
  server.apiKey = key
}

export function matchRoute(
  server: AgentApiServer,
  method: string,
  path: string
): { route: AgentApiRoute; pathParams: Record<string, string> } | null {
  for (const route of server.routes) {
    if (route.method !== method.toUpperCase()) continue
    const params = matchPath(route.path, path)
    if (params !== null) {
      return { route, pathParams: params }
    }
  }
  return null
}

function matchPath(pattern: string, path: string): Record<string, string> | null {
  const patternParts = pattern.split('/')
  const pathParts = path.split('/')

  if (patternParts.length !== pathParts.length) return null

  const params: Record<string, string> = {}
  for (let i = 0; i < patternParts.length; i++) {
    if (patternParts[i].startsWith(':')) {
      params[patternParts[i].slice(1)] = pathParts[i]
    } else if (patternParts[i] !== pathParts[i]) {
      return null
    }
  }
  return params
}

export function verifyApiKey(server: AgentApiServer, requestApiKey: string | undefined): boolean {
  if (!server.apiKey) return true
  return requestApiKey === server.apiKey
}

export function successResponse<T>(data: T): ApiResponse<T> {
  return { code: 0, message: 'success', data }
}

export function errorResponse(code: number, message: string): ApiResponse {
  return { code, message, data: null }
}
