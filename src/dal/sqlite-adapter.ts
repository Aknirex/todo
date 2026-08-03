type Row = Record<string, any>

class H5Database {
  private storageKey: string
  private tables: Map<string, Row[]>
  private versionKey: string

  constructor(name: string) {
    this.storageKey = `h5db_${name}`
    this.versionKey = `h5db_${name}_ver`
    this.tables = new Map()
    this._load()
  }

  private _load() {
    try {
      const storedVer = localStorage.getItem(this.versionKey)
      if (storedVer !== '2') {
        localStorage.removeItem(this.storageKey)
        localStorage.setItem(this.versionKey, '2')
      }
      const raw = localStorage.getItem(this.storageKey)
      if (raw) {
        const obj = JSON.parse(raw)
        for (const [k, v] of Object.entries(obj)) {
          this.tables.set(k, v as Row[])
        }
      }
    } catch {}
  }

  private _save() {
    try {
      const obj: Record<string, Row[]> = {}
      for (const [k, v] of this.tables) obj[k] = v
      localStorage.setItem(this.storageKey, JSON.stringify(obj))
    } catch {}
  }

  async executeSql(sql: string, params: any[] = []): Promise<{ rows: Row[] }> {
    const trimmed = sql.trim()
    const upper = trimmed.toUpperCase()

    if (upper.startsWith('CREATE TABLE')) {
      const m = trimmed.match(/CREATE TABLE IF NOT EXISTS (\w+)/i)
      if (m && !this.tables.has(m[1])) this.tables.set(m[1], [])
      return { rows: [] }
    }
    if (upper.startsWith('CREATE INDEX')) return { rows: [] }

    if (upper.startsWith('INSERT')) {
      const isReplace = upper.includes('OR REPLACE')
      const isIgnore = upper.includes('OR IGNORE')
      const m = trimmed.match(/INSERT\s+(?:OR\s+(?:IGNORE|REPLACE)\s+)?INTO\s+(\w+)/i)
      if (m) {
        const table = m[1]
        if (!this.tables.has(table)) this.tables.set(table, [])
        const rows = this.tables.get(table)!
        const cm = trimmed.match(/\(([^)]+)\)\s*VALUES/i)
        if (cm) {
          const cols = cm[1].split(',').map(c => c.trim())
          const row: Row = {}
          cols.forEach((col, i) => { row[col] = params[i] ?? null })

          if (isIgnore) {
            const pk = cols[0]
            const exists = rows.some(r => r[pk] === row[pk])
            if (!exists) rows.push(row)
          } else if (isReplace) {
            const pk = cols[0]
            const idx = rows.findIndex(r => r[pk] === row[pk])
            idx >= 0 ? rows[idx] = row : rows.push(row)
          } else {
            rows.push(row)
          }
          this._save()
        }
      }
      return { rows: [] }
    }

    if (upper.startsWith('SELECT')) {
      const fm = trimmed.match(/FROM (\w+)/i)
      if (!fm) return { rows: [] }
      let rows = [...(this.tables.get(fm[1]) || [])]
      const wi = upper.indexOf(' WHERE ')
      if (wi >= 0) rows = rows.filter(r => this._where(r, trimmed.slice(wi + 7), params))
      if (upper.includes('ORDER BY')) {
        const om = trimmed.match(/ORDER BY (\w+)(?:\s+(ASC|DESC))?/i)
        if (om) {
          const col = om[1], dir = (om[2] || 'ASC').toUpperCase()
          rows.sort((a, b) => a[col] < b[col] ? (dir === 'ASC' ? -1 : 1) : a[col] > b[col] ? (dir === 'ASC' ? 1 : -1) : 0)
        }
      }
      if (upper.includes('LIMIT')) {
        const lm = trimmed.match(/LIMIT\s+(\d+)/i)
        if (lm) rows = rows.slice(0, parseInt(lm[1]))
      }
      return { rows }
    }

    if (upper.startsWith('UPDATE')) {
      const m = trimmed.match(/UPDATE (\w+)/i)
      if (m) {
        const rows = this.tables.get(m[1]) || []
        const wi = upper.lastIndexOf(' WHERE ')
        const setPart = trimmed.slice(upper.indexOf(' SET ') + 5, wi >= 0 ? wi : undefined).trim()
        const spc = (setPart.match(/\?/g) || []).length
        const wc = wi >= 0 ? trimmed.slice(wi + 7).trim() : ''
        rows.forEach(row => {
          if (!wc || this._where(row, wc, params.slice(spc))) this._applySet(row, setPart, params)
        })
        this._save()
      }
      return { rows: [] }
    }

    if (upper.startsWith('DELETE')) {
      const m = trimmed.match(/FROM (\w+)/i)
      if (m) {
        const table = m[1], rows = this.tables.get(table) || []
        const wi = upper.indexOf(' WHERE ')
        if (wi >= 0) {
          this.tables.set(table, rows.filter(r => !this._where(r, trimmed.slice(wi + 7), params)))
          this._save()
        }
      }
      return { rows: [] }
    }

    return { rows: [] }
  }

  private _applySet(row: Row, setPart: string, params: any[]) {
    let pi = 0
    for (const clause of setPart.split(/,(?![^()]*\))/)) {
      const eq = clause.indexOf('=')
      if (eq < 0) continue
      const col = clause.slice(0, eq).trim(), val = clause.slice(eq + 1).trim()
      if (val === '?') row[col] = params[pi++]
      else if (/CASE WHEN/i.test(val)) {
        const cm = val.match(/CASE WHEN (\w+) = (\d+) THEN (\d+) ELSE (\d+) END/i)
        if (cm) row[col] = row[cm[1]] === parseInt(cm[2]) ? parseInt(cm[3]) : parseInt(cm[4])
      } else if (/^\d+$/.test(val)) row[col] = parseInt(val)
      else row[col] = val
    }
  }

  private _where(row: Row, clause: string, params: any[]): boolean {
    let pi = 0
    for (const part of clause.replace(/^\(|\)$/g, '').split(/\s+AND\s+/i)) {
      const p = part.trim().replace(/^\(|\)$/g, '')
      if (p.toUpperCase().includes(' OR ')) {
        let ok = false
        for (const op of p.split(/\s+OR\s+/i)) {
          const r = this._eval(row, op.trim(), params, pi); pi = r.o; if (r.k) ok = true
        }
        if (!ok) return false
      } else {
        const r = this._eval(row, p, params, pi); pi = r.o; if (!r.k) return false
      }
    }
    return true
  }

  private _eval(row: Row, c: string, params: any[], o: number): { k: boolean; o: number } {
    const cond = c.replace(/^\(|\)$/g, '').trim()
    if (cond.toUpperCase().includes('LIKE')) {
      const [col] = cond.split(/\s+LIKE\s+/i)
      const pat = String(params[o]).replace(/%/g, '')
      return { k: String(row[col.trim()] || '').toLowerCase().includes(pat.toLowerCase()), o: o + 1 }
    }
    if (cond.includes('=')) {
      const [col, val] = cond.split('=').map(s => s.trim())
      if (val === '?') return { k: row[col] === params[o], o: o + 1 }
      if (val === '0' || val === '1') return { k: row[col] === parseInt(val), o }
    }
    if (cond.includes('<>') || cond.includes('!=')) {
      const [col, val] = cond.split(/<>|!=/).map(s => s.trim())
      if (val === '?') return { k: row[col] !== params[o], o: o + 1 }
    }
    return { k: true, o }
  }
}

export async function openDatabase(name: string, _version: number): Promise<any> {
  if (typeof (uni as any).openDatabase === 'function') {
    return new Promise((resolve, reject) => {
      const db = (uni as any).openDatabase({
        name, version: 1,
        success: () => resolve(db),
        fail: (err: any) => reject(err)
      })
    })
  }
  return new H5Database(name)
}
