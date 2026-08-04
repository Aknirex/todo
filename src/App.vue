<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app'
import { initDatabase } from '@/dal'
import { useTodoStore, useListStore, useAgentStore, useUndoStore } from '@/stores'

onLaunch(async () => {
  // #ifdef H5
  if (typeof document !== 'undefined') {
    const stored = uni.getStorageSync('aknirex-theme')
    document.documentElement.setAttribute('data-theme', stored === 'dark' ? 'dark' : 'light')
  }
  // #endif
  console.log('App Launch — initializing database...')
  await initDatabase()

  const agentStore = useAgentStore()
  const todoStore = useTodoStore()
  const listStore = useListStore()
  const undoStore = useUndoStore()

  await agentStore.loadConfig()
  await Promise.all([
    todoStore.loadTodos(),
    listStore.loadLists()
  ])

  if (listStore.lists.length === 0) {
    await listStore.createList('默认列表')
  }

  await undoStore.loadFromDb()
  console.log('App initialized — lists:', listStore.lists.length, 'todos:', todoStore.todos.length)
})
</script>

<style>
/* ===== GLOBAL DESIGN TOKENS (from prototype) ===== */
:root, [data-theme="light"] {
  --bg: #f2f3f5;
  --card: #fff;
  --card-hover: #f7f8fa;
  --text: #1a1a1a;
  --text-2: #555666;
  --text-3: #8f959e;
  --border: #e5e6eb;
  --border-light: #f0f1f2;
  --primary: #2563eb;
  --primary-hover: #1d4ed8;
  --primary-light: #eff6ff;
  --primary-bg: rgba(37,99,235,0.08);
  --danger: #ef4444;
  --danger-light: rgba(239,68,68,0.08);
  --warning: #f59e0b;
  --warning-light: rgba(245,158,11,0.08);
  --success: #22c55e;
  --success-light: rgba(34,197,94,0.08);
  --input-bg: #f2f3f5;
  --checkbox-border: #c9cdd4;
  --scrollbar-thumb: #d1d5db;
  --overlay: rgba(0,0,0,0.3);
  --dropdown-bg: #fff;
  --dropdown-shadow: 0 8px 24px rgba(0,0,0,0.12);
  --sidebar-bg: rgba(255,255,255,0.45);
  --sidebar-hover: rgba(242,243,245,0.4);
  --sidebar-active: var(--primary-light);
  --sidebar-active-text: var(--primary);
  --search-blur: rgba(242,243,245,0.85);
  --radius: 10px;
  --radius-sm: 6px;
  --shadow: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04);
  --shadow-lg: 0 4px 12px rgba(0,0,0,0.08);
}
[data-theme="dark"] {
  --bg: #111113; --card: #1c1c1e; --card-hover: #252528;
  --text: #e5e5e7; --text-2: #a1a1aa; --text-3: #71717a;
  --border: #2e2e32; --border-light: #232326;
  --primary: #3b82f6; --primary-hover: #60a5fa;
  --primary-light: rgba(59,130,246,0.12); --primary-bg: rgba(59,130,246,0.1);
  --danger: #f87171; --danger-light: rgba(248,113,113,0.12);
  --warning: #fbbf24; --warning-light: rgba(251,191,36,0.12);
  --success: #4ade80; --success-light: rgba(74,222,128,0.12);
  --input-bg: #27272a; --checkbox-border: #52525b; --scrollbar-thumb: #3f3f46;
  --overlay: rgba(0,0,0,0.5);
  --dropdown-bg: #27272a; --dropdown-shadow: 0 8px 24px rgba(0,0,0,0.4);
  --sidebar-bg: rgba(24,24,27,0.45); --sidebar-hover: rgba(39,39,42,0.4);
  --sidebar-active: var(--primary-light); --sidebar-active-text: var(--primary);
  --search-blur: rgba(17,17,19,0.88);
  --shadow: 0 1px 3px rgba(0,0,0,0.2), 0 1px 2px rgba(0,0,0,0.1);
  --shadow-lg: 0 4px 12px rgba(0,0,0,0.3);
}

page {
  background: var(--bg);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", "PingFang SC", sans-serif;
  color: var(--text);
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  font-size: 28rpx;
  overflow-x: hidden;
}

* {
  box-sizing: border-box;
}

/* ===== Topbar ===== */
.topbar {
  height: 88rpx;
  background: var(--card);
  display: flex;
  align-items: center;
  padding: 0 32rpx;
  gap: 16rpx;
  border-bottom: 1rpx solid var(--border-light);
  flex-shrink: 0;
}
.topbar-title {
  font-size: 32rpx;
  font-weight: 700;
  flex: 1;
}
.topbar-actions { display: flex; gap: 4rpx; }

/* ===== Icon Buttons ===== */
.icon-btn {
  width: 68rpx; height: 68rpx; border-radius: 16rpx; border: none;
  background: transparent; display: flex; align-items: center;
  justify-content: center; color: var(--text-2); font-size: 28rpx;
}
.icon-btn:active { background: var(--card-hover); }
.icon-btn.danger:active { background: var(--danger-light); color: var(--danger); }

/* ===== Undo/Redo ===== */
.undo-redo {
  display: flex; gap: 4rpx; padding: 0 8rpx;
  border-right: 1rpx solid var(--border-light); margin-right: 8rpx;
}

/* ===== Toolbar ===== */
.toolbar {
  display: flex; align-items: center; padding: 16rpx 32rpx; gap: 12rpx;
  background: var(--card); border-bottom: 1rpx solid var(--border-light); flex-shrink: 0;
}
.toolbar-action {
  display: inline-flex; align-items: center; justify-content: center;
  width: 68rpx; height: 56rpx; padding: 0; border-radius: 12rpx;
  border: 1rpx solid var(--border); background: transparent;
  font-size: 24rpx; color: var(--text-2); flex-shrink: 0;
}
.toolbar-action:active { border-color: var(--primary); color: var(--primary); }
.toolbar-spacer { flex: 1; }

/* ===== AI Icon ===== */
.ai-icon {
  font-weight: 800; letter-spacing: 1rpx; color: var(--primary);
  position: relative; display: inline-flex; align-items: center; justify-content: center;
}

/* ===== Todo Items ===== */
.todo {
  display: flex; align-items: flex-start; gap: 20rpx; padding: 22rpx 24rpx;
  background: var(--card); border-radius: var(--radius); margin-bottom: 12rpx;
  box-shadow: var(--shadow); transition: all 0.15s; border: 1rpx solid transparent;
  position: relative; padding-left: 32rpx;
}
.todo:active { border-color: var(--border); box-shadow: var(--shadow-lg); }
.todo.done { opacity: 0.5; }
.todo.done .todo-title { text-decoration: line-through; color: var(--text-3); }
.todo::before {
  content: ''; position: absolute; left: 8rpx; top: 24rpx; bottom: 24rpx;
  width: 6rpx; border-radius: 4rpx;
}
.todo.p-high::before { background: var(--danger); }
.todo.p-medium::before { background: var(--warning); }
.todo.p-low::before { background: var(--success); }

.todo-check {
  width: 40rpx; height: 40rpx; border-radius: 50%; flex-shrink: 0;
  border: 3rpx solid var(--checkbox-border); display: flex; align-items: center;
  justify-content: center; transition: all 0.15s; margin-top: 2rpx;
}
.todo-check:active { border-color: var(--primary); }
.todo-check.checked { background: var(--primary); border-color: var(--primary); }
.todo-body { flex: 1; min-width: 0; }
.todo-title { font-size: 28rpx; font-weight: 500; word-break: break-word; }
.todo-meta { display: flex; gap: 12rpx; margin-top: 8rpx; flex-wrap: wrap; align-items: center; }
.todo-tag {
  font-size: 20rpx; padding: 2rpx 14rpx; border-radius: 16rpx;
  background: var(--primary-bg); color: var(--primary); font-weight: 500;
}
.todo-due { font-size: 22rpx; color: var(--text-3); display: flex; align-items: center; gap: 6rpx; }
.todo-due.overdue { color: var(--danger); }

/* ===== Section Header ===== */
.section-hd { display: flex; align-items: center; justify-content: space-between; padding: 16rpx 0 12rpx; }
.section-label { font-size: 26rpx; font-weight: 600; color: var(--text-3); text-transform: uppercase; letter-spacing: 1rpx; }
.section-count { font-size: 24rpx; color: var(--text-3); }

/* ===== FAB ===== */
.fab {
  position: fixed; bottom: 20%; right: 40rpx; width: 104rpx; height: 104rpx;
  border-radius: 32rpx; background: var(--primary); color: #fff; border: none;
  box-shadow: 0 8rpx 32rpx rgba(37,99,235,0.3); display: flex; align-items: center;
  justify-content: center; z-index: 20; font-size: 44rpx;
}
.fab:active { transform: scale(1.05); }

/* ===== Pills ===== */
.pill {
  padding: 8rpx 20rpx; border-radius: 24rpx; border: 1rpx solid var(--border);
  background: transparent; font-size: 22rpx; font-weight: 600; color: var(--text-3);
}
.pill.active-h { background: var(--danger-light); border-color: var(--danger); color: var(--danger); }
.pill.active-m { background: var(--warning-light); border-color: var(--warning); color: var(--warning); }
.pill.active-l { background: var(--success-light); border-color: var(--success); color: var(--success); }

/* ===== Meta Buttons ===== */
.meta-btn {
  display: inline-flex; align-items: center; gap: 8rpx; padding: 8rpx 20rpx;
  border-radius: 12rpx; border: 1rpx solid var(--border); background: transparent;
  font-size: 22rpx; color: var(--text-3);
}
.meta-btn:active { border-color: var(--primary); color: var(--primary); }
.meta-btn.active { background: var(--primary-bg); border-color: var(--primary); color: var(--primary); }

/* ===== Settings Groups ===== */
.settings-group {
  background: var(--card); border-radius: var(--radius); margin-bottom: 24rpx;
  box-shadow: var(--shadow); overflow: hidden;
}
.settings-group-hd {
  font-size: 22rpx; font-weight: 600; color: var(--text-3); padding: 20rpx 28rpx 8rpx;
  text-transform: uppercase; letter-spacing: 1rpx;
}
.settings-row {
  padding: 22rpx 28rpx; display: flex; align-items: center; justify-content: space-between;
  border-bottom: 1rpx solid var(--border-light); font-size: 26rpx;
}
.settings-row:last-child { border-bottom: none; }
.settings-row:active { background: var(--card-hover); }
.settings-row .label { display: flex; align-items: center; gap: 16rpx; }
.settings-row .value { font-size: 24rpx; color: var(--text-3); display: flex; align-items: center; gap: 8rpx; }

/* ===== Toggle ===== */
.toggle {
  width: 80rpx; height: 44rpx; border-radius: 22rpx; background: var(--border);
  position: relative; transition: background 0.2s;
}
.toggle.on { background: var(--primary); }
.toggle::after {
  content: ''; position: absolute; top: 4rpx; left: 4rpx; width: 36rpx; height: 36rpx;
  border-radius: 50%; background: #fff; transition: transform 0.2s;
  box-shadow: 0 2rpx 6rpx rgba(0,0,0,0.2);
}
.toggle.on::after { transform: translateX(36rpx); }

/* ===== Provider Cards ===== */
.provider-card {
  background: var(--card); border-radius: var(--radius); padding: 28rpx;
  margin-bottom: 16rpx; box-shadow: var(--shadow); border-left: 6rpx solid var(--primary);
}
.provider-card:active { box-shadow: var(--shadow-lg); }
.provider-card .desc { font-size: 24rpx; color: var(--text-3); }
.provider-card .price { font-size: 24rpx; color: var(--primary); font-weight: 600; margin-top: 8rpx; }

/* ===== Agent ===== */
.agent-mode-switch { display: flex; gap: 8rpx; margin-bottom: 24rpx; }
.mode-tab {
  padding: 14rpx 28rpx; border-radius: 12rpx; border: none; background: transparent;
  font-size: 26rpx; font-weight: 500; color: var(--text-3);
  display: flex; align-items: center; gap: 10rpx;
}
.mode-tab.active { background: var(--primary-light); color: var(--primary); }
.agent-panel { background: var(--card); border-radius: var(--radius); padding: 32rpx; box-shadow: var(--shadow); }
.agent-panel .panel-desc { font-size: 24rpx; color: var(--text-3); margin-bottom: 24rpx; }
.agent-textarea {
  width: 100%; min-height: 200rpx; border: 1rpx solid var(--border); border-radius: 16rpx;
  padding: 20rpx 24rpx; font-size: 26rpx; outline: none; background: var(--input-bg);
  color: var(--text); box-sizing: border-box;
}
.agent-textarea:focus { border-color: var(--primary); }
.agent-actions { display: flex; gap: 16rpx; margin-top: 20rpx; }
.agent-result {
  margin-top: 24rpx; padding: 24rpx; border-radius: 16rpx;
  border: 2rpx dashed var(--border); background: var(--card-hover);
}
.result-item {
  display: flex; align-items: center; gap: 16rpx; padding: 12rpx 0;
  border-bottom: 1rpx solid var(--border-light); font-size: 26rpx;
}
.result-item:last-child { border-bottom: none; }
.summary-box {
  margin-top: 24rpx; padding: 28rpx; border-radius: 16rpx; background: var(--card-hover);
  border: 1rpx solid var(--border); font-size: 26rpx; line-height: 1.8; white-space: pre-wrap;
}
.agent-scope { background: var(--card-hover); border-radius: 16rpx; padding: 28rpx; margin-bottom: 24rpx; }

/* ===== Buttons ===== */
.btn { padding: 16rpx 32rpx; border-radius: 16rpx; border: none; font-size: 26rpx; font-weight: 600; display: inline-flex; align-items: center; gap: 10rpx; }
.btn-primary { background: var(--primary); color: #fff; }
.btn-primary:active { background: var(--primary-hover); }
.btn-ghost { background: transparent; color: var(--primary); }
.btn-ghost:active { background: var(--primary-bg); }
.btn-outline { background: transparent; color: var(--text-2); border: 1rpx solid var(--border); }

/* ===== Input Bar ===== */
.input-bar {
  display: flex; align-items: center; gap: 16rpx; padding: 20rpx 32rpx;
  background: var(--card); border-bottom: 1rpx solid var(--border-light);
}
.input-bar input {
  flex: 1; border: none; outline: none; font-size: 28rpx; background: var(--input-bg);
  padding: 16rpx 24rpx; border-radius: 16rpx; color: var(--text);
}

/* ===== Empty State ===== */
.empty { text-align: center; padding: 96rpx 40rpx; color: var(--text-3); }

/* ===== Badge ===== */
.badge {
  position: absolute;
  top: -2rpx;
  right: -4rpx;
  min-width: auto;
  height: auto;
  border-radius: 0;
  background: transparent;
  color: var(--text-3);
  font-size: 18rpx;
  font-weight: 600;
  line-height: 1;
  text-align: center;
  padding: 0;
  pointer-events: none;
}
</style>
