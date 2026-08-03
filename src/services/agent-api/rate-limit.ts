const RATE_LIMIT = 100
const WINDOW_MS = 60000

const requestCounts = new Map<string, { count: number; resetAt: number }>()

export function checkRateLimit(apiKey: string): boolean {
  const now = Date.now()
  const record = requestCounts.get(apiKey)

  if (!record || now > record.resetAt) {
    requestCounts.set(apiKey, { count: 1, resetAt: now + WINDOW_MS })
    return true
  }

  if (record.count >= RATE_LIMIT) {
    return false
  }

  record.count++
  return true
}

export function resetRateLimit(apiKey: string): void {
  requestCounts.delete(apiKey)
}

export function getRemainingRequests(apiKey: string): number {
  const record = requestCounts.get(apiKey)
  if (!record || Date.now() > record.resetAt) return RATE_LIMIT
  return Math.max(0, RATE_LIMIT - record.count)
}
