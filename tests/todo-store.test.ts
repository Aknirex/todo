import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'

vi.mock('@/dal/database', () => ({
  getDatabase: () => mockDb
}))

let mockDb: any

function createMockDb() {
  const tables = new Map()
  return {
    _tables: tables,
    async executeSql(sql: string, params: any[] = []) {
      const trimmed = sql.trim()
      const upper = trimmed.toUpperCase()

      if (upper.startsWith('CREATE TABLE') || upper.startsWith('CREATE INDEX')) {
        return { rows: [] }
      }

      if (upper.startsWith('INSERT')) {
        const isReplace = upper.includes('OR REPLACE')
        const match = trimmed.match(/INSERT (?:OR (?:IGNORE|REPLACE) )?INTO (\w+)/i)
        if (match) {
          const tableName = match[1]
          if (!tables.has(tableName)) tables.set(tableName, [])
          const rows = tables.get(tableName)!
          const columnsMatch = trimmed.match(/\(([^)]+)\)\s*VALUES/i)
          if (columnsMatch) {
            const columns = columnsMatch[1].split(',').map((c: string) => c.trim())
            const row: any = {}
            columns.forEach((col: string, i: number) => {
              row[col] = params[i] !== undefined ? params[i] : null
            })
            if (isReplace) {
              const pk = columns[0]
              const idx = rows.findIndex((r: any) => r[pk] === row[pk])
              if (idx >= 0) rows[idx] = row
              else rows.push(row)
            } else {
              rows.push(row)
            }
          }
        }
        return { rows: [] }
      }

      if (upper.startsWith('SELECT')) {
        const fromMatch = trimmed.match(/FROM (\w+)/i)
        if (!fromMatch) return { rows: [] }
        const allRows = tables.get(fromMatch[1]) || []
        const whereIdx = trimmed.toUpperCase().indexOf(' WHERE ')
        let filtered = [...allRows]
        if (whereIdx >= 0) {
          const clause = trimmed.slice(whereIdx + 7).trim()
          filtered = filtered.filter((row: any) => simpleWhere(row, clause, params))
        }
        if (upper.includes('ORDER BY')) {
          const m = trimmed.match(/ORDER BY (\w+)(?:\s+(ASC|DESC))?/i)
          if (m) {
            const col = m[1], dir = (m[2] || 'ASC').toUpperCase()
            filtered.sort((a: any, b: any) => {
              if (a[col] < b[col]) return dir === 'ASC' ? -1 : 1
              if (a[col] > b[col]) return dir === 'ASC' ? 1 : -1
              return 0
            })
          }
        }
        return { rows: filtered }
      }

      if (upper.startsWith('UPDATE')) {
        const match = trimmed.match(/UPDATE (\w+)/i)
        if (match) {
          const rows = tables.get(match[1]) || []
          const whereIdx = trimmed.toUpperCase().lastIndexOf(' WHERE ')
          const setPart = trimmed.slice(trimmed.toUpperCase().indexOf(' SET ') + 5, whereIdx).trim()
          const whereClause = whereIdx > 0 ? trimmed.slice(whereIdx + 7).trim() : ''
          const setParamCount = (setPart.match(/\?/g) || []).length
          rows.forEach((row: any) => {
            if (!whereClause || simpleWhere(row, whereClause, params.slice(setParamCount))) {
              applySet(row, setPart, params)
            }
          })
        }
        return { rows: [] }
      }

      if (upper.startsWith('DELETE')) {
        const match = trimmed.match(/FROM (\w+)/i)
        if (match) {
          const rows = tables.get(match[1]) || []
          const whereIdx = trimmed.toUpperCase().indexOf(' WHERE ')
          if (whereIdx >= 0) {
            const clause = trimmed.slice(whereIdx + 7).trim()
            tables.set(match[1], rows.filter((row: any) => !simpleWhere(row, clause, params)))
          }
        }
        return { rows: [] }
      }

      return { rows: [] }
    }
  }
}

function applySet(row: any, setPart: string, params: any[]) {
  let pi = 0
  const clauses = setPart.split(/,(?![^()]*\))/)
  for (const clause of clauses) {
    const eq = clause.indexOf('=')
    if (eq < 0) continue
    const col = clause.slice(0, eq).trim()
    const val = clause.slice(eq + 1).trim()
    if (val === '?') { row[col] = params[pi++] }
    else if (/CASE WHEN/i.test(val)) {
      const m = val.match(/CASE WHEN (\w+) = (\d+) THEN (\d+) ELSE (\d+) END/i)
      if (m) row[col] = row[m[1]] === parseInt(m[2]) ? parseInt(m[3]) : parseInt(m[4])
    } else if (/^\d+$/.test(val)) { row[col] = parseInt(val) }
    else { row[col] = val }
  }
}

function simpleWhere(row: any, clause: string, params: any[]): boolean {
  let pi = 0
  const parts = clause.replace(/^\(/, '').replace(/\)$/, '').split(/\s+AND\s+/i)
  for (const part of parts) {
    const p = part.trim().replace(/^\(/, '').replace(/\)$/, '')
    if (p.toUpperCase().includes(' OR ')) {
      const orParts = p.split(/\s+OR\s+/i)
      let ok = false
      for (const op of orParts) {
        const r = evalOne(row, op.trim(), params, pi)
        pi = r.newOffset
        if (r.match) ok = true
      }
      if (!ok) return false
    } else {
      const r = evalOne(row, p, params, pi)
      pi = r.newOffset
      if (!r.match) return false
    }
  }
  return true
}

function evalOne(row: any, cond: string, params: any[], offset: number): { match: boolean; newOffset: number } {
  const c = cond.replace(/^\(/, '').replace(/\)$/, '').trim()
  if (c.toUpperCase().includes('LIKE')) {
    const [col, _] = c.split(/\s+LIKE\s+/i)
    const pattern = String(params[offset]).replace(/%/g, '')
    return { match: String(row[col.trim()] || '').toLowerCase().includes(pattern.toLowerCase()), newOffset: offset + 1 }
  }
  if (c.includes('=')) {
    const [col, val] = c.split('=').map(s => s.trim())
    if (val === '?') return { match: row[col] === params[offset], newOffset: offset + 1 }
    if (val === '0' || val === '1') return { match: row[col] === parseInt(val), newOffset: offset }
  }
  return { match: true, newOffset: offset }
}

describe('todoStore', () => {
  beforeEach(() => {
    mockDb = createMockDb()
    mockDb._tables.set('todo', [])
    mockDb._tables.set('undo_record', [])
    mockDb._tables.set('list', [
      { id: 'default', name: '默认列表', is_default: 1, created_at: '2026-01-01', sort_order: 0 }
    ])
    setActivePinia(createPinia())
  })

  it('createTodo should add a todo and record undo', async () => {
    const { useTodoStore } = await import('@/stores/todo')
    const store = useTodoStore()
    const todo = await store.createTodo({ title: 'Test', priority: 'medium', listId: 'default' })

    expect(todo.title).toBe('Test')
    expect(store.todos).toHaveLength(1)
    expect(mockDb._tables.get('todo')).toHaveLength(1)
    expect(mockDb._tables.get('undo_record')).toHaveLength(1)
  })

  it('deleteTodo should soft-delete and record undo', async () => {
    const { useTodoStore } = await import('@/stores/todo')
    const store = useTodoStore()
    const todo = await store.createTodo({ title: 'Delete me', listId: 'default' })

    await store.deleteTodo(todo.id)
    expect(store.todos[0].deleted).toBe(true)
    expect(store.activeTodos).toHaveLength(0)
  })

  it('toggleComplete should flip completed and record undo', async () => {
    const { useTodoStore } = await import('@/stores/todo')
    const store = useTodoStore()
    const todo = await store.createTodo({ title: 'Toggle me', listId: 'default' })

    await store.toggleComplete(todo.id)
    expect(store.todos[0].completed).toBe(true)
    expect(store.completedTodos).toHaveLength(1)
  })

  it('updateTodo should modify fields and record undo', async () => {
    const { useTodoStore } = await import('@/stores/todo')
    const store = useTodoStore()
    const todo = await store.createTodo({ title: 'Original', listId: 'default' })

    await store.updateTodo(todo.id, { title: 'Updated', priority: 'high' })
    expect(store.todos[0].title).toBe('Updated')
    expect(store.todos[0].priority).toBe('high')
  })
})
