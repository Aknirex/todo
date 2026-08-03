import { describe, it, expect } from 'vitest'
import { uuid } from '@/utils/uuid'

describe('uuid', () => {
  it('should return a string', () => {
    expect(typeof uuid()).toBe('string')
  })

  it('should return a valid UUID format', () => {
    const id = uuid()
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
  })

  it('should generate unique values', () => {
    const ids = new Set(Array.from({ length: 100 }, () => uuid()))
    expect(ids.size).toBe(100)
  })
})
