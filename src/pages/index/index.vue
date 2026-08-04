<template>
  <view class="page-index" :style="themeVars">
    <!-- Sidebar Backdrop -->
    <view :class="['sidebar-backdrop', sidebarOpen ? 'visible' : '']" @tap="closeSidebar"></view>

    <!-- Sidebar -->
    <view :class="['sidebar', sidebarOpen ? 'open' : '']">
      <view class="sidebar-header">
        <view class="collapse-btn" @tap="closeSidebar">
          <AppIcon name="panel-left" :size="18" color="var(--text-3)" />
        </view>
        <text class="app-name">aknirex-todo</text>
      </view>
      <scroll-view scroll-y class="sidebar-nav">
        <!-- Tree: Task Lists -->
        <view class="tree-group">
          <view class="tree-header" @tap="treeOpen = !treeOpen">
            <AppIcon name="chevron-down" :size="14" color="var(--text-3)" class="tree-chevron" :style="{ transform: treeOpen ? 'rotate(0)' : 'rotate(-90deg)' }" />
            <text>任务列表</text>
          </view>
          <view v-show="treeOpen" class="tree-children">
            <view
              v-for="list in sortedLists"
              :key="list.id"
              :class="['tree-item', activeListId === list.id ? 'active' : '']"
              @tap="selectList(list.id)"
            >
              <AppIcon name="list-todo" :size="15" class="tree-icon" />
              <text class="tree-name">{{ list.name }}</text>
              <text class="count">{{ getListCount(list.id) }}</text>
            </view>
            <view class="tree-item new-list" @tap="createNewList">
              <AppIcon name="plus" :size="15" color="var(--text-3)" />
              <text class="tree-name">新建列表</text>
            </view>
          </view>
        </view>

        <view :class="['nav-item', currentPage === 'agent' ? 'active' : '']" @tap="goAgent">
          <text class="ai-icon" style="font-size:28rpx;width:36rpx;text-align:center">AI</text>
          <text>Agent</text>
        </view>
        <view class="nav-item" @tap="openSearch">
          <AppIcon name="search" :size="18" />
          <text>搜索</text>
        </view>

        <view class="sidebar-spacer"></view>

        <view :class="['nav-item', currentPage === 'settings' ? 'active' : '']" @tap="goSettings">
          <AppIcon name="settings" :size="18" />
          <text>设置</text>
        </view>
      </scroll-view>
    </view>

    <!-- Main Content -->
    <view class="main">
      <!-- Topbar -->
      <view class="topbar">
        <view class="icon-btn" @tap="openSidebar">
          <AppIcon name="menu" :size="18" color="var(--text-2)" />
        </view>
        <text class="topbar-title">{{ activeListName }}</text>
        <view class="topbar-actions">
          <view class="undo-redo">
            <view class="icon-btn" @tap="handleUndo">
              <AppIcon name="undo-2" :size="18" color="var(--text-2)" />
              <text v-if="undoCount > 0" class="badge">{{ undoCount }}</text>
            </view>
          </view>
        </view>
      </view>

      <!-- Toolbar -->
      <view class="toolbar">
        <view class="dropdown-wrap">
          <view class="dropdown-trigger" @tap="showFilterPanel = !showFilterPanel" title="筛选">
            <AppIcon name="filter" :size="14" color="var(--text-2)" />
            <text v-if="activeFilterCount > 0" class="count">{{ activeFilterCount }}</text>
          </view>
          <view v-if="showFilterPanel" class="dropdown-panel">
            <view class="dropdown-hd">优先级</view>
            <view :class="['dropdown-item', filters.has('high') ? 'active' : '']" @tap="toggleFilter('high')">
              <text style="color:var(--danger)">●</text><text>高</text>
            </view>
            <view :class="['dropdown-item', filters.has('medium') ? 'active' : '']" @tap="toggleFilter('medium')">
              <text style="color:var(--warning)">●</text><text>中</text>
            </view>
            <view :class="['dropdown-item', filters.has('low') ? 'active' : '']" @tap="toggleFilter('low')">
              <text style="color:var(--success)">●</text><text>低</text>
            </view>
            <view class="dropdown-hd">状态</view>
            <view :class="['dropdown-item', filters.has('active') ? 'active' : '']" @tap="toggleFilter('active')">
              <text>进行中</text>
            </view>
            <view :class="['dropdown-item', filters.has('done') ? 'active' : '']" @tap="toggleFilter('done')">
              <text>已完成</text>
            </view>
            <view class="dropdown-ft" @tap="clearFilters"><text class="btn-ghost" style="font-size:24rpx">清除</text></view>
          </view>
        </view>
        <view class="dropdown-wrap">
          <view class="dropdown-trigger" @tap="showSortPanel = !showSortPanel" title="排序">
            <AppIcon name="arrow-up-down" :size="14" color="var(--text-2)" />
          </view>
          <view v-if="showSortPanel" class="dropdown-panel">
            <view class="dropdown-hd">排序</view>
            <view
              v-for="opt in ['created', 'priority', 'dueDate', 'alpha']"
              :key="opt"
              :class="['dropdown-item', sortBy === opt ? 'active' : '']"
              @tap="setSortBy(opt)"
            >
              <AppIcon name="check" :size="14" :color="sortBy === opt ? 'var(--primary)' : 'transparent'" />
              <text>{{ SORT_LABELS[opt] }}</text>
            </view>
            <view class="dropdown-ft" style="justify-content:space-between;align-items:center">
              <text style="font-size:22rpx;color:var(--text-3)">{{ sortLabel() }}</text>
              <view class="btn-ghost" style="font-size:24rpx;padding:8rpx 16rpx" @tap="toggleSortDir">
                <AppIcon name="arrow-up-down" :size="12" color="var(--primary)" />
                <text>切换方向</text>
              </view>
            </view>
          </view>
        </view>
        <view class="toolbar-spacer"></view>
        <view class="toolbar-action" @tap="goAgent">
          <text class="ai-icon" style="font-size:22rpx">AI</text>
        </view>
        <view class="toolbar-action" @tap="openSearch">
          <AppIcon name="search" :size="14" color="var(--text-2)" />
        </view>
      </view>

      <!-- Todo List -->
      <scroll-view scroll-y class="content">
        <view v-if="filteredActiveTodos.length > 0">
          <view class="section-hd">
            <text class="section-label">进行中</text>
            <text class="section-count">{{ filteredActiveTodos.length }}</text>
          </view>
          <view
            v-for="todo in filteredActiveTodos"
            :key="todo.id"
            :class="['todo', `p-${todo.priority}`]"
            @tap="goDetail(todo.id)"
          >
            <view :class="['todo-check', todo.completed ? 'checked' : '']" @tap.stop="handleToggle(todo.id)">
              <text v-if="todo.completed" style="color:#fff;font-size:20rpx">✓</text>
            </view>
            <view class="todo-body">
              <text class="todo-title">{{ todo.title || '(无标题)' }}</text>
              <view class="todo-meta">
                <text v-for="tag in todo.tags" :key="tag" class="todo-tag">{{ tag }}</text>
                <view v-if="todo.dueDate" :class="['todo-due', isOverdue(todo.dueDate) ? 'overdue' : '']">
                  <AppIcon name="calendar" :size="12" :color="isOverdue(todo.dueDate) ? 'var(--danger)' : 'var(--text-3)'" />
                  <text>{{ formatDue(todo.dueDate) }}</text>
                </view>
              </view>
            </view>
          </view>
        </view>

        <view v-if="filteredDoneTodos.length > 0">
          <view class="section-hd" style="margin-top:32rpx">
            <text class="section-label">已完成</text>
            <text class="section-count">{{ filteredDoneTodos.length }}</text>
          </view>
          <view
            v-for="todo in filteredDoneTodos"
            :key="todo.id"
            :class="['todo', `p-${todo.priority}`, 'done']"
            @tap="goDetail(todo.id)"
          >
            <view :class="['todo-check', 'checked']" @tap.stop="handleToggle(todo.id)">
              <text style="color:#fff;font-size:20rpx">✓</text>
            </view>
            <view class="todo-body">
              <text class="todo-title">{{ todo.title || '(无标题)' }}</text>
            </view>
          </view>
        </view>

        <view v-if="filteredActiveTodos.length === 0 && filteredDoneTodos.length === 0" class="empty">
          <AppIcon name="inbox" :size="48" color="var(--text-3)" />
          <text style="margin-top:16rpx">暂无待办事项</text>
          <text style="font-size:22rpx;margin-top:8rpx">点击右下角 + 添加第一个待办</text>
        </view>
      </scroll-view>

      <!-- FAB -->
      <view class="fab" @tap="openNewTask">
        <AppIcon name="plus" :size="22" color="#fff" />
      </view>
    </view>

    <!-- New Task Overlay -->
    <view :class="['new-task-overlay', newTaskOpen ? 'open' : '']">
      <view class="new-task-top">
        <view class="topbar" style="border:none;padding:0;height:auto;margin-bottom:24rpx">
          <text class="topbar-title">新建任务</text>
          <view class="topbar-actions">
            <view class="icon-btn" @tap="closeNewTask">
              <AppIcon name="x" :size="18" color="var(--text-2)" />
            </view>
          </view>
        </view>
        <view class="new-task-meta">
          <view style="display:flex;gap:6rpx">
            <view :class="['pill', newPriority === 'high' ? 'active-h' : '']" @tap="newPriority = 'high'">H</view>
            <view :class="['pill', newPriority === 'medium' ? 'active-m' : '']" @tap="newPriority = 'medium'">M</view>
            <view :class="['pill', newPriority === 'low' ? 'active-l' : '']" @tap="newPriority = 'low'">L</view>
          </view>
          <view :class="['meta-btn', newTaskTags.length > 0 ? 'active' : '']" @tap="showTagInput = !showTagInput">
            <AppIcon name="tag" :size="12" color="var(--text-3)" />
            <text>标签</text>
          </view>
          <view :class="['meta-btn', newDueDate ? 'active' : '']">
            <picker mode="date" :value="newDueDate || ''" @change="onNewDueChange">
              <view style="display:flex;align-items:center;gap:8rpx">
                <AppIcon name="calendar" :size="12" color="var(--text-3)" />
                <text>截止日期</text>
              </view>
            </picker>
          </view>
        </view>
        <view v-if="showTagInput" style="margin-top:16rpx;display:flex;gap:8rpx;flex-wrap:wrap">
          <text v-for="(tag, i) in newTaskTags" :key="i" class="todo-tag" @tap="newTaskTags.splice(i, 1)">
            {{ tag }} ×
          </text>
          <input
            v-model="newTagInput"
            placeholder="输入标签回车"
            style="font-size:24rpx;flex:1;min-width:120rpx"
            @confirm="addNewTag"
          />
        </view>
        <view class="new-task-title-row">
          <input
            v-model="newTitle"
            type="text"
            placeholder="任务标题..."
            @confirm="focusDetail"
          />
        </view>
      </view>
      <view class="new-task-body">
        <textarea
          ref="newDetailRef"
          v-model="newDetail"
          placeholder="添加详情（可选）..."
        />
        <view style="display:flex;justify-content:flex-end;gap:16rpx;margin-top:24rpx">
          <view class="btn btn-outline" @tap="closeNewTask">取消</view>
          <view class="btn btn-primary" @tap="createFromOverlay">
            <AppIcon name="check" :size="14" color="#fff" />
            <text>创建</text>
          </view>
        </view>
      </view>
    </view>

    <!-- Search Overlay -->
    <view :class="['search-overlay', searchOpen ? 'open' : '']">
      <view class="search-blur-bg"></view>
      <view class="search-overlay-inner">
        <view class="topbar">
          <view class="icon-btn" @tap="closeSearch">
            <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
          </view>
          <text class="topbar-title">搜索</text>
        </view>
        <view class="input-bar">
          <AppIcon name="search" :size="18" color="var(--text-3)" />
          <input
            v-model="searchKeyword"
            type="text"
            placeholder="搜索任务..."
            @confirm="doSearch"
          />
        </view>
        <scroll-view scroll-y class="search-content">
          <view v-if="!searchDone" class="search-history">
            <view class="search-history-hd">
              <text>最近搜索</text>
              <text style="color:var(--primary);font-size:22rpx" @tap="searchHistory = []">清除</text>
            </view>
            <view
              v-for="q in searchHistory"
              :key="q"
              class="search-history-item"
              @tap="fillSearch(q)"
            >
              <AppIcon name="clock" :size="14" color="var(--text-3)" />
              <text>{{ q }}</text>
            </view>
          </view>
          <view v-else>
            <view v-if="searchResults.length === 0" class="empty">
              <text>无搜索结果</text>
            </view>
            <view v-else>
              <view
                v-for="todo in searchResults"
                :key="todo.id"
                :class="['todo', `p-${todo.priority}`]"
                @tap="goDetail(todo.id); closeSearch()"
              >
                <view class="todo-body">
                  <text class="todo-title">{{ todo.title }}</text>
                  <view class="todo-meta">
                    <text v-for="tag in todo.tags" :key="tag" class="todo-tag">{{ tag }}</text>
                  </view>
                </view>
              </view>
            </view>
          </view>
        </scroll-view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useTodoStore, useListStore, useUndoStore } from '@/stores'
import { searchTodos } from '@/services/search'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'
import type { Todo, Priority } from '@/types'

const { themeVars } = useTheme()

const todoStore = useTodoStore()
const listStore = useListStore()
const undoStore = useUndoStore()

onLoad(async () => {
  if (listStore.lists.length === 0) await listStore.loadLists()
  if (todoStore.todos.length === 0) await todoStore.loadTodos()
})

// Sidebar
const sidebarOpen = ref(false)
const treeOpen = ref(true)
const activeListId = ref('default')
const currentPage = ref('list')

// New Task
const newTaskOpen = ref(false)
const newTitle = ref('')
const newDetail = ref('')
const newPriority = ref<Priority>('medium')
const newDueDate = ref<string | null>(null)
const newTaskTags = ref<string[]>([])
const newTagInput = ref('')
const showTagInput = ref(false)

// Search
const searchOpen = ref(false)
const searchKeyword = ref('')
const searchDone = ref(false)
const searchResults = ref<Todo[]>([])
const searchHistory = ref<string[]>([])

// Filter
const showFilterPanel = ref(false)
const showSortPanel = ref(false)
const filters = ref(new Set<string>())
const sortBy = ref('created')
const sortDir = ref<'asc' | 'desc'>('asc')

const undoCount = computed(() => undoStore.undoStack.length)

const sortedLists = computed(() => {
  const lists = [...listStore.lists]
  lists.sort((a, b) => {
    if (a.isDefault) return -1
    if (b.isDefault) return 1
    return a.sortOrder - b.sortOrder
  })
  return lists
})

const activeListName = computed(() => {
  const list = listStore.lists.find(l => l.id === activeListId.value)
  return list?.name || '默认列表'
})

const PRIORITY_ORDER: Record<string, number> = { high: 0, medium: 1, low: 2 }
const SORT_LABELS: Record<string, string> = {
  created: '创建时间',
  priority: '优先级',
  dueDate: '截止日期',
  alpha: '名称 A→Z'
}

function applySort(list: Todo[]): Todo[] {
  const dir = sortDir.value === 'asc' ? 1 : -1
  const arr = [...list]
  switch (sortBy.value) {
    case 'priority':
      arr.sort((a, b) => dir * ((PRIORITY_ORDER[a.priority] ?? 1) - (PRIORITY_ORDER[b.priority] ?? 1)))
      break
    case 'dueDate':
      arr.sort((a, b) => dir * (new Date(a.dueDate || 0).getTime() - new Date(b.dueDate || 0).getTime()))
      break
    case 'alpha':
      arr.sort((a, b) => dir * a.title.localeCompare(b.title))
      break
    default:
      arr.sort((a, b) => dir * (new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()))
  }
  return arr
}

const filteredActiveTodos = computed(() => {
  let todos = todoStore.todosByList(activeListId.value).filter(t => !t.completed && !t.deleted)
  if (filters.value.has('high') || filters.value.has('medium') || filters.value.has('low')) {
    todos = todos.filter(t => filters.value.has(t.priority))
  }
  if (filters.value.has('done')) {
    return []
  }
  return applySort(todos)
})

const filteredDoneTodos = computed(() => {
  let todos = todoStore.todosByList(activeListId.value).filter(t => t.completed && !t.deleted)
  if (filters.value.has('high') || filters.value.has('medium') || filters.value.has('low')) {
    todos = todos.filter(t => filters.value.has(t.priority))
  }
  if (filters.value.has('active')) {
    return []
  }
  return applySort(todos)
})

const activeFilterCount = computed(() => filters.value.size)

function getListCount(listId: string): number {
  return todoStore.todosByList(listId).filter(t => !t.deleted && !t.completed).length
}

function selectList(id: string) {
  activeListId.value = id
  closeSidebar()
}

function openSidebar() { sidebarOpen.value = true }
function closeSidebar() { sidebarOpen.value = false }

async function createNewList() {
  uni.showModal({
    title: '新建列表',
    editable: true,
    placeholderText: '列表名称',
    success: async (res: any) => {
      if (!res.confirm) return
      const name = (res.content || '').trim() || '新列表'
      const list = await listStore.createList(name)
      activeListId.value = list.id
      closeSidebar()
    }
  })
}

function toggleFilter(f: string) {
  filters.value.has(f) ? filters.value.delete(f) : filters.value.add(f)
}
function clearFilters() { filters.value.clear() }
function setSortBy(s: string) {
  sortBy.value = s
  showSortPanel.value = false
}
function toggleSortDir() {
  sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
}
function sortLabel(): string {
  return (SORT_LABELS[sortBy.value] || '创建时间') + (sortDir.value === 'asc' ? ' ↑' : ' ↓')
}

// New Task
function openNewTask() {
  newTaskOpen.value = true
  newTitle.value = ''
  newDetail.value = ''
  newPriority.value = 'medium'
  newDueDate.value = null
  newTaskTags.value = []
  showTagInput.value = false
}
function closeNewTask() { newTaskOpen.value = false }
function addNewTag() {
  const tag = newTagInput.value.trim()
  if (tag && !newTaskTags.value.includes(tag)) {
    newTaskTags.value.push(tag)
  }
  newTagInput.value = ''
}
function onNewDueChange(e: any) { newDueDate.value = e.detail.value || null }
function focusDetail() { /* uni-app auto-focus handled by component */ }

async function createFromOverlay() {
  const title = newTitle.value.trim()
  const detail = newDetail.value.trim()
  if (!title && !detail) return
  await todoStore.createTodo({
    title,
    priority: newPriority.value,
    dueDate: newDueDate.value,
    tags: newTaskTags.value,
    detail,
    listId: activeListId.value
  })
  closeNewTask()
}

// Search
function openSearch() {
  searchOpen.value = true
  searchDone.value = false
  searchKeyword.value = ''
}
function closeSearch() { searchOpen.value = false }
function fillSearch(q: string) {
  searchKeyword.value = q
  doSearch()
}
async function doSearch() {
  const q = searchKeyword.value.trim()
  if (!q) return
  if (!searchHistory.value.includes(q)) {
    searchHistory.value.unshift(q)
    if (searchHistory.value.length > 10) searchHistory.value.pop()
  }
  searchDone.value = true
  searchResults.value = await searchTodos(q)
}

// Todo actions
async function handleToggle(id: string) { await todoStore.toggleComplete(id) }
async function handleUndo() {
  await undoStore.undo()
  await Promise.all([todoStore.loadTodos(), listStore.loadLists()])
}

function goDetail(id: string) { uni.navigateTo({ url: `/pages/detail/index?id=${id}` }) }
function goAgent() { closeSidebar(); uni.navigateTo({ url: '/pages/agent/index' }) }
function goSettings() { closeSidebar(); uni.navigateTo({ url: '/pages/settings/index' }) }

function isOverdue(date: string): boolean {
  return new Date(date) < new Date(new Date().toDateString())
}
function formatDue(date: string): string {
  const d = new Date(date)
  const today = new Date(new Date().toDateString())
  const diff = Math.floor((d.getTime() - today.getTime()) / 86400000)
  if (diff === 0) return '今天'
  if (diff === 1) return '明天'
  if (diff === -1) return '逾期 1 天'
  if (diff < -1) return `逾期 ${-diff} 天`
  return date
}
</script>

<style scoped>
.page-index {
  position: relative;
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}

/* Sidebar */
.sidebar-backdrop {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 45;
  opacity: 0;
  pointer-events: none;
  background: var(--overlay);
  transition: opacity 0.25s;
}
.sidebar-backdrop.visible {
  opacity: 1;
  pointer-events: auto;
}
.sidebar {
  position: fixed;
  top: 0; bottom: 0; left: 0;
  width: 480rpx;
  background: var(--sidebar-bg);
  -webkit-backdrop-filter: blur(80rpx) saturate(1.6);
  backdrop-filter: blur(80rpx) saturate(1.6);
  border-right: 1rpx solid rgba(255,255,255,0.25);
  z-index: 46;
  transform: translateX(-100%);
  transition: transform 0.25s;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 8rpx 0 48rpx rgba(0,0,0,0.08);
}
.sidebar.open {
  transform: translateX(0);
}
.sidebar-header {
  height: 96rpx;
  display: flex;
  align-items: center;
  padding: 0 24rpx;
  gap: 16rpx;
}
.collapse-btn {
  width: 64rpx;
  height: 64rpx;
  border-radius: 12rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  color: var(--text-3);
}
.app-name {
  font-size: 28rpx;
  font-weight: 700;
  color: var(--text);
}
.sidebar-nav {
  flex: 1;
  padding: 8rpx 16rpx;
}
.sidebar-spacer {
  flex: 0 0 35%;
  min-height: 80rpx;
}

/* Tree */
.tree-group { margin-bottom: 8rpx; }
.tree-header {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 12rpx 20rpx;
  border-radius: 16rpx;
  color: var(--text-3);
  font-size: 22rpx;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1rpx;
}
.tree-chevron {
  transition: transform 0.2s;
}
.tree-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 14rpx 20rpx 14rpx 48rpx;
  border-radius: 16rpx;
  color: var(--text-2);
  font-size: 26rpx;
  margin-bottom: 2rpx;
}
.tree-item:active, .tree-item.active {
  background: var(--primary-light);
  color: var(--primary);
}
.tree-icon { display: flex; }
.tree-name { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.new-list {
  opacity: 0.75;
  font-size: 26rpx;
}
.new-list:active {
  background: var(--sidebar-hover);
  color: var(--text-2);
}
.count {
  font-size: 20rpx;
  color: var(--text-3);
  background: var(--input-bg);
  padding: 2rpx 12rpx;
  border-radius: 16rpx;
}

/* Nav Items */
.nav-item {
  display: flex;
  align-items: center;
  gap: 20rpx;
  padding: 16rpx 20rpx;
  border-radius: 16rpx;
  color: var(--text-2);
  font-size: 26rpx;
  font-weight: 500;
  margin-bottom: 2rpx;
}
.nav-item:active, .nav-item.active {
  background: var(--primary-light);
  color: var(--primary);
}

/* Main */
.main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Content */
.content {
  flex: 1;
  padding: 24rpx 32rpx 80rpx;
}

/* Dropdown Panel */
.dropdown-wrap { position: relative; }
.dropdown-trigger {
  display: inline-flex; align-items: center; justify-content: center;
  width: 68rpx; height: 56rpx; padding: 0;
  border-radius: 12rpx; border: 1rpx solid var(--border); background: var(--card);
  font-size: 24rpx; color: var(--text-2); flex-shrink: 0; position: relative;
}
.dropdown-trigger:active { border-color: var(--primary); color: var(--primary); }
.dropdown-trigger .count {
  position: absolute; top: -8rpx; right: -8rpx;
  min-width: 28rpx; height: 28rpx; border-radius: 14rpx;
  background: var(--primary); color: #fff; font-size: 18rpx;
  font-weight: 700; line-height: 28rpx; text-align: center; padding: 0 6rpx;
}
.dropdown-panel {
  position: absolute;
  top: calc(100% + 8rpx);
  left: 0;
  min-width: 300rpx;
  background: var(--dropdown-bg);
  border-radius: var(--radius);
  box-shadow: var(--dropdown-shadow);
  border: 1rpx solid var(--border);
  z-index: 100;
  overflow: hidden;
}
.dropdown-hd {
  padding: 20rpx 24rpx 12rpx;
  font-size: 22rpx;
  font-weight: 600;
  color: var(--text-3);
  text-transform: uppercase;
  letter-spacing: 1rpx;
}
.dropdown-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 16rpx 24rpx;
  font-size: 26rpx;
  color: var(--text-2);
}
.dropdown-item:active { background: var(--card-hover); }
.dropdown-item.active { color: var(--primary); font-weight: 600; }
.dropdown-ft {
  padding: 16rpx 24rpx;
  border-top: 1rpx solid var(--border-light);
}

/* Badge */
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

/* Section */
.section-label {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text-3);
  text-transform: uppercase;
  letter-spacing: 1rpx;
}
.section-count {
  font-size: 24rpx;
  color: var(--text-3);
}

/* New Task Overlay */
.new-task-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 60;
  display: flex;
  flex-direction: column;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.2s;
}
.new-task-overlay.open {
  pointer-events: auto;
  opacity: 1;
}
.new-task-top {
  background: var(--card);
  padding: 32rpx;
  border-bottom: 1rpx solid var(--border-light);
}
.new-task-meta {
  display: flex;
  align-items: center;
  gap: 12rpx;
  flex-wrap: wrap;
}
.new-task-title-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  margin-top: 20rpx;
}
.new-task-title-row input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 34rpx;
  font-weight: 600;
  background: transparent;
  color: var(--text);
  padding: 8rpx 0;
}
.new-task-body {
  flex: 1;
  background: var(--bg);
  padding: 24rpx 32rpx;
}
.new-task-body textarea {
  width: 100%;
  min-height: 240rpx;
  border: 1rpx solid var(--border);
  border-radius: var(--radius);
  padding: 24rpx;
  font-size: 26rpx;
  outline: none;
  background: var(--card);
  color: var(--text);
  box-sizing: border-box;
}

/* Search Overlay */
.search-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 55;
  display: flex;
  flex-direction: column;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.2s;
}
.search-overlay.open {
  pointer-events: auto;
  opacity: 1;
}
.search-blur-bg {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: var(--search-blur);
  -webkit-backdrop-filter: blur(24rpx);
  backdrop-filter: blur(24rpx);
}
.search-overlay-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  flex: 1;
}
.search-content {
  flex: 1;
  padding: 24rpx 32rpx;
}
.search-history { padding: 24rpx 32rpx; }
.search-history-hd {
  font-size: 22rpx;
  font-weight: 600;
  color: var(--text-3);
  text-transform: uppercase;
  letter-spacing: 1rpx;
  margin-bottom: 16rpx;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.search-history-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 16rpx 0;
  font-size: 26rpx;
  color: var(--text-2);
  border-bottom: 1rpx solid var(--border-light);
}

/* Empty State */
.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 96rpx 40rpx;
  color: var(--text-3);
}
.empty .app-icon { opacity: 0.4; }
</style>


