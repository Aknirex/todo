export interface MockRow {
  [key: string]: any
}

export interface MockDb {
  executeSql: (sql: string, params?: any[]) => Promise<{ rows: MockRow[] }>
  _tables: Map<string, MockRow[]>
}

export function createMockDb(): MockDb {
  const tables = new Map<string, MockRow[]>()

  function extractWhereClause(sql: string): string | null {
    const upper = sql.toUpperCase()
    const whereIdx = upper.indexOf(' WHERE ')
    if (whereIdx === -1) return null

    let depth = 0
    let i = whereIdx + 7
    const start = i

    for (; i < sql.length; i++) {
      if (sql[i] === '(') depth++
      else if (sql[i] === ')') depth--

      if (depth <= 0) {
        const rest = sql.slice(i).toUpperCase()
        if (rest.match(/^\s+(ORDER|LIMIT|GROUP|;|$)/) || i === sql.length - 1) {
          return sql.slice(start, i + 1).trim()
        }
      }
    }
    return sql.slice(start).trim()
  }

  const db: MockDb = {
    _tables: tables,
    async executeSql(sql: string, params: any[] = []) {
      const trimmed = sql.trim()
      const upper = trimmed.toUpperCase()

      if (upper.startsWith('CREATE TABLE')) {
        const match = trimmed.match(/CREATE TABLE IF NOT EXISTS (\w+)/i)
        if (match) {
          const tableName = match[1]
          if (!tables.has(tableName)) {
            tables.set(tableName, [])
          }
        }
        return { rows: [] }
      }

      if (upper.startsWith('CREATE INDEX')) {
        return { rows: [] }
      }

      if (upper.startsWith('INSERT')) {
        const isReplace = upper.includes('OR REPLACE')
        const match = trimmed.match(/INSERT (?:OR (?:IGNORE|REPLACE) )?INTO (\w+)/i)
        if (match) {
          const tableName = match[1]
          if (!tables.has(tableName)) {
            tables.set(tableName, [])
          }
          const rows = tables.get(tableName)!
          const columnsMatch = trimmed.match(/\(([^)]+)\)\s*VALUES/i)
          if (columnsMatch) {
            const columns = columnsMatch[1].split(',').map(c => c.trim())
            const row: MockRow = {}
            columns.forEach((col, i) => {
              row[col] = params[i] !== undefined ? params[i] : null
            })

            if (isReplace) {
              const pkCol = columns[0]
              const existingIdx = rows.findIndex(r => r[pkCol] === row[pkCol])
              if (existingIdx >= 0) {
                rows[existingIdx] = row
              } else {
                rows.push(row)
              }
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
        const tableName = fromMatch[1]
        const allRows = tables.get(tableName) || []

        const whereClause = extractWhereClause(trimmed)
        let filtered = [...allRows]
        if (whereClause) {
          filtered = filtered.filter(row =>
            evaluateWhere(whereClause, row, params)
          )
        }

        if (upper.includes('ORDER BY')) {
          const orderMatch = trimmed.match(/ORDER BY (\w+)(?:\s+(ASC|DESC))?/i)
          if (orderMatch) {
            const col = orderMatch[1]
            const dir = (orderMatch[2] || 'ASC').toUpperCase()
            filtered.sort((a, b) => {
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
          const tableName = match[1]
          const rows = tables.get(tableName) || []

          // Split by WHERE - take the last WHERE to handle subqueries
          const whereIdx = trimmed.toUpperCase().lastIndexOf(' WHERE ')
          const setPart = whereIdx > 0
            ? trimmed.slice(trimmed.toUpperCase().indexOf(' SET ') + 5, whereIdx).trim()
            : trimmed.slice(trimmed.toUpperCase().indexOf(' SET ') + 5).trim()
          const whereClause = whereIdx > 0 ? trimmed.slice(whereIdx + 7).trim() : null

          if (setPart && whereClause) {
            const setParamCount = (setPart.match(/\?/g) || []).length
            const setParams = params.slice(0, setParamCount)
            const whereParams = params.slice(setParamCount)

            rows.forEach(row => {
              if (evaluateWhere(whereClause, row, whereParams)) {
                applySetClauses(setPart, row, setParams)
              }
            })
          }
        }
        return { rows: [] }
      }

      if (upper.startsWith('DELETE')) {
        const match = trimmed.match(/FROM (\w+)/i)
        if (match) {
          const tableName = match[1]
          const rows = tables.get(tableName) || []
          const whereClause = extractWhereClause(trimmed)
          if (whereClause) {
            const remaining = rows.filter(row =>
              !evaluateWhere(whereClause, row, params)
            )
            tables.set(tableName, remaining)
          }
        }
        return { rows: [] }
      }

      return { rows: [] }
    }
  }
  return db
}

function applySetClauses(setPart: string, row: MockRow, params: any[]): void {
  let paramIndex = 0
  const setClauses = splitSetClauses(setPart)

  for (const clause of setClauses) {
    const eqIdx = clause.indexOf('=')
    if (eqIdx === -1) continue
    const col = clause.slice(0, eqIdx).trim()
    const valExpr = clause.slice(eqIdx + 1).trim()

    if (valExpr === '?') {
      row[col] = params[paramIndex++]
    } else if (valExpr.toUpperCase().includes('CASE')) {
      const whenMatch = valExpr.match(/CASE WHEN (\w+) = (\d+) THEN (\d+) ELSE (\d+) END/i)
      if (whenMatch) {
        const [, refCol, matchVal, thenVal, elseVal] = whenMatch
        row[col] = row[refCol] === parseInt(matchVal) ? parseInt(thenVal) : parseInt(elseVal)
      }
    } else if (/^\d+$/.test(valExpr)) {
      row[col] = parseInt(valExpr)
    } else if (valExpr.startsWith("'") && valExpr.endsWith("'")) {
      row[col] = valExpr.slice(1, -1)
    } else {
      row[col] = valExpr
    }
  }
}

function splitSetClauses(setPart: string): string[] {
  const result: string[] = []
  let depth = 0
  let current = ''

  for (const char of setPart) {
    if (char === '(') depth++
    else if (char === ')') depth--

    if (char === ',' && depth === 0) {
      result.push(current.trim())
      current = ''
    } else {
      current += char
    }
  }
  if (current.trim()) result.push(current.trim())
  return result
}

function evaluateWhere(clause: string, row: MockRow, params: any[]): boolean {
  // Split by AND (top-level only)
  const andParts = splitByKeyword(clause, 'AND')
  let paramOffset = 0

  for (const part of andParts) {
    const trimmed = part.trim()

    // Check for OR conditions
    if (hasTopLevelKeyword(trimmed, 'OR')) {
      const orParts = splitByKeyword(trimmed, 'OR')
      let orMatch = false
      for (const orPart of orParts) {
        const result = evalCondition(orPart.trim(), row, params, paramOffset)
        paramOffset = result.newOffset
        if (result.match) orMatch = true
      }
      if (!orMatch) return false
    } else {
      const result = evalCondition(trimmed, row, params, paramOffset)
      paramOffset = result.newOffset
      if (!result.match) return false
    }
  }

  return true
}

function hasTopLevelKeyword(clause: string, keyword: string): boolean {
  let depth = 0
  const upper = clause.toUpperCase()
  const kw = ` ${keyword} `
  let idx = 0
  while (idx < clause.length) {
    if (clause[idx] === '(') depth++
    else if (clause[idx] === ')') depth--
    if (depth === 0 && upper.slice(idx).startsWith(kw)) return true
    idx++
  }
  return false
}

function splitByKeyword(clause: string, keyword: string): string[] {
  const result: string[] = []
  let depth = 0
  let current = ''
  const upper = clause.toUpperCase()
  const kw = ` ${keyword} `
  let i = 0

  while (i < clause.length) {
    if (clause[i] === '(') depth++
    else if (clause[i] === ')') depth--

    if (depth === 0 && upper.slice(i).startsWith(kw)) {
      result.push(current.trim())
      current = ''
      i += kw.length
      continue
    }
    current += clause[i]
    i++
  }
  if (current.trim()) result.push(current.trim())
  return result
}

function evalCondition(
  cond: string,
  row: MockRow,
  params: any[],
  offset: number
): { match: boolean; newOffset: number } {
  const trimmed = cond.replace(/^\(/, '').replace(/\)$/, '').trim()

  if (trimmed.toUpperCase().includes('LIKE')) {
    const parts = trimmed.split(/\s+LIKE\s+/i)
    const col = parts[0].trim()
    const val = params[offset] as string
    const pattern = val.replace(/%/g, '')
    return {
      match: String(row[col] || '').toLowerCase().includes(pattern.toLowerCase()),
      newOffset: offset + 1
    }
  }

  if (trimmed.includes('=')) {
    const parts = trimmed.split('=').map(s => s.trim())
    const col = parts[0]
    const valPart = parts[1]

    if (valPart === '?') {
      return { match: row[col] === params[offset], newOffset: offset + 1 }
    }
    if (valPart === '0' || valPart === '1') {
      return { match: row[col] === parseInt(valPart), newOffset: offset }
    }
  }

  if (trimmed.includes('<>') || trimmed.includes('!=')) {
    const parts = trimmed.split(/<>|!=/).map(s => s.trim())
    const col = parts[0]
    const valPart = parts[1]
    if (valPart === '?') {
      return { match: row[col] !== params[offset], newOffset: offset + 1 }
    }
  }

  return { match: true, newOffset: offset }
}
