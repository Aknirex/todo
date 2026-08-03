import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

describe('platform', () => {
  const originalEnv = { ...process.env }

  afterEach(() => {
    process.env = { ...originalEnv }
    vi.resetModules()
  })

  it('should return h5 as default fallback', async () => {
    const { getPlatform } = await import('@/utils/platform')
    expect(getPlatform()).toBe('h5')
  })
})
