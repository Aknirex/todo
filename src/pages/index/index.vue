<template>
  <view class="page-index">
    <view class="header">
      <text class="title">aknirex-todo</text>
      <view class="header-actions">
        <view class="btn-icon" @tap="goSearch">
          <text class="icon">搜索</text>
        </view>
        <view class="btn-icon" @tap="goSettings">
          <text class="icon">设置</text>
        </view>
      </view>
    </view>

    <scroll-view scroll-x class="tab-bar" :show-scrollbar="false">
      <view
        class="tab"
        v-for="list in sortedLists"
        :key="list.id"
        :class="{ active: list.id === activeListId }"
        @tap="activeListId = list.id"
        @longpress="handleListLongPress(list)"
      >
        <text class="tab-name">{{ list.name }}</text>
      </view>
      <view class="tab add-tab" @tap="startCreateList">
        <text class="tab-name">+</text>
      </view>
    </scroll-view>

    <view class="quick-add">
      <input
        class="quick-add-input"
        v-model="newTitle"
        placeholder="添加待办..."
        confirm-type="done"
        @confirm="handleQuickAdd"
      />
      <view class="quick-add-btn" @tap="handleQuickAdd">
        <text class="btn-text">+</text>
      </view>
    </view>

    <view class="todo-list" v-if="activeTodos.length > 0">
      <view
        class="todo-item"
        v-for="todo in activeTodos"
        :key="todo.id"
        @tap="goDetail(todo.id)"
      >
        <view class="todo-check" @tap.stop="handleToggle(todo.id)">
          <view :class="['checkbox', todo.completed ? 'checked' : '']">
            <text v-if="todo.completed">✓</text>
          </view>
        </view>
        <view class="todo-content">
          <text class="todo-title">{{ todo.title || '(无标题)' }}</text>
          <view class="todo-meta">
            <text :class="['priority', `priority-${todo.priority}`]">{{ priorityLabel(todo.priority) }}</text>
            <text v-if="todo.dueDate" class="due-date">{{ todo.dueDate }}</text>
          </view>
        </view>
        <view class="todo-delete" @tap.stop="handleDelete(todo.id)">
          <text class="delete-text">删除</text>
        </view>
      </view>
    </view>

    <view class="empty-state" v-else>
      <text class="empty-text">暂无待办事项</text>
      <text class="empty-hint">在上方输入框添加你的第一个待办</text>
    </view>

    <view class="undo-bar" v-if="undoStore.canUndo" @tap="handleUndo">
      <text class="undo-text">撤销</text>
    </view>

    <!-- Prompt modal for create / rename list -->
    <view class="prompt-overlay" v-if="promptVisible" @tap="cancelPrompt">
      <view class="prompt-dialog" @tap.stop>
        <text class="prompt-title">{{ promptTitle }}</text>
        <input
          class="prompt-input"
          v-model="promptValue"
          :placeholder="promptPlaceholder"
          confirm-type="done"
          @confirm="confirmPrompt"
        />
        <view class="prompt-actions">
          <view class="prompt-btn" @tap="cancelPrompt">
            <text class="prompt-btn-text">取消</text>
          </view>
          <view class="prompt-btn prompt-btn-primary" @tap="confirmPrompt">
            <text class="prompt-btn-text primary-text">确定</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useTodoStore, useListStore, useUndoStore } from '@/stores'
import type { Priority, TodoList } from '@/types'

const todoStore = useTodoStore()
const listStore = useListStore()
const undoStore = useUndoStore()
const newTitle = ref('')
const activeListId = ref('')
const defaultListId = ref('')

// Sort lists: default list first, then by sortOrder
const sortedLists = computed(() => {
  return [...listStore.lists].sort((a, b) => {
    if (a.id === defaultListId.value) return -1
    if (b.id === defaultListId.value) return 1
    return a.sortOrder - b.sortOrder
  })
})

const activeTodos = computed(() => todoStore.todosByList(activeListId.value))

onMounted(async () => {
  await Promise.all([todoStore.loadTodos(), listStore.loadLists()])

  // Ensure a default list exists
  const existingDefault = listStore.lists.find(l => l.isDefault)
  if (existingDefault) {
    defaultListId.value = existingDefault.id
  } else if (listStore.lists.length > 0) {
    // Use first list as fallback default
    defaultListId.value = listStore.lists[0].id
  } else {
    const list = await listStore.createList('默认列表')
    defaultListId.value = list.id
  }

  activeListId.value = defaultListId.value
})

function priorityLabel(p: Priority): string {
  const map: Record<Priority, string> = { high: '高', medium: '中', low: '低' }
  return map[p] || '中'
}

async function handleQuickAdd() {
  const title = newTitle.value.trim()
  if (!title) return
  await todoStore.createTodo({ title, priority: 'medium', listId: activeListId.value })
  newTitle.value = ''
}

async function handleToggle(id: string) {
  await todoStore.toggleComplete(id)
}

async function handleDelete(id: string) {
  await todoStore.deleteTodo(id)
}

async function handleUndo() {
  const rec = await undoStore.undo()
  if (!rec) return
  await todoStore.loadTodos()
}

// ── List tab interactions ──

async function handleListLongPress(list: TodoList) {
  const itemList: string[] = ['重命名']
  if (list.id !== defaultListId.value) {
    itemList.push('删除')
  }
  const res = await uni.showActionSheet({ itemList })
  if (res.tapIndex === 0) {
    handleRenameList(list)
  } else if (res.tapIndex === 1 && list.id !== defaultListId.value) {
    handleDeleteList(list)
  }
}

async function handleRenameList(list: TodoList) {
  const newName = await showPrompt('重命名列表', list.name)
  if (newName && newName !== list.name) {
    await listStore.updateList(list.id, { name: newName })
  }
}

async function handleDeleteList(list: TodoList) {
  const res = await uni.showModal({
    title: '确认删除',
    content: `确定要删除列表"${list.name}"吗？列表中的待办事项不会被删除。`
  })
  if (!res.confirm) return
  await listStore.deleteList(list.id)
  if (activeListId.value === list.id) {
    activeListId.value = defaultListId.value
  }
}

async function startCreateList() {
  const name = await showPrompt('新建列表', '')
  if (!name) return
  const list = await listStore.createList(name)
  activeListId.value = list.id
}

// ── Prompt modal (reusable inline prompt) ──

const promptVisible = ref(false)
const promptTitle = ref('')
const promptPlaceholder = ref('')
const promptValue = ref('')
let promptResolve: ((v: string | null) => void) | null = null

function showPrompt(title: string, defaultValue: string = '', placeholder: string = '输入名称'): Promise<string | null> {
  return new Promise(resolve => {
    promptTitle.value = title
    promptValue.value = defaultValue
    promptPlaceholder.value = placeholder
    promptVisible.value = true
    promptResolve = resolve
  })
}

function confirmPrompt() {
  const v = promptValue.value.trim()
  promptVisible.value = false
  promptResolve?.(v || null)
  promptResolve = null
}

function cancelPrompt() {
  promptVisible.value = false
  promptResolve?.(null)
  promptResolve = null
}

function goDetail(id: string) {
  uni.navigateTo({ url: `/pages/detail/index?id=${id}` })
}

function goSearch() {
  uni.navigateTo({ url: '/pages/search/index' })
}

function goSettings() {
  uni.navigateTo({ url: '/pages/settings/index' })
}
</script>

<style scoped>
.page-index {
  padding: 30rpx;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30rpx;
}

.title {
  font-size: 48rpx;
  font-weight: bold;
  color: #333;
}

.header-actions {
  display: flex;
  gap: 20rpx;
}

.btn-icon {
  padding: 10rpx 20rpx;
  background: #fff;
  border-radius: 8rpx;
}

.icon {
  font-size: 24rpx;
  color: #666;
}

/* ── Tab bar ── */

.tab-bar {
  display: flex;
  flex-direction: row;
  white-space: nowrap;
  margin-bottom: 30rpx;
}

.tab {
  display: inline-flex;
  align-items: center;
  padding: 14rpx 28rpx;
  margin-right: 16rpx;
  background: #fff;
  border-radius: 10rpx;
  flex-shrink: 0;
}

.tab.active {
  background: #4a90d9;
}

.tab.active .tab-name {
  color: #fff;
}

.tab-name {
  font-size: 26rpx;
  color: #333;
}

.add-tab {
  background: #e8f0fe;
}

.add-tab .tab-name {
  font-size: 32rpx;
  font-weight: bold;
  color: #4a90d9;
}

/* ── Quick add ── */

.quick-add {
  display: flex;
  gap: 16rpx;
  margin-bottom: 40rpx;
}

.quick-add-input {
  flex: 1;
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
}

.quick-add-btn {
  width: 80rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #4a90d9;
  border-radius: 12rpx;
}

.btn-text {
  color: #fff;
  font-size: 36rpx;
  font-weight: bold;
}

/* ── Todo list ── */

.todo-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.todo-item {
  display: flex;
  align-items: center;
  padding: 24rpx;
  background: #fff;
  border-radius: 12rpx;
  gap: 20rpx;
}

.todo-check {
  flex-shrink: 0;
}

.checkbox {
  width: 44rpx;
  height: 44rpx;
  border: 2rpx solid #ddd;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  color: #fff;
}

.checkbox.checked {
  background: #4a90d9;
  border-color: #4a90d9;
}

.todo-content {
  flex: 1;
  min-width: 0;
}

.todo-title {
  font-size: 30rpx;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.todo-meta {
  display: flex;
  gap: 16rpx;
  margin-top: 8rpx;
}

.priority {
  font-size: 22rpx;
  padding: 2rpx 12rpx;
  border-radius: 4rpx;
}

.priority-high {
  background: #ffeaea;
  color: #e74c3c;
}

.priority-medium {
  background: #fff3e0;
  color: #f39c12;
}

.priority-low {
  background: #e8f5e9;
  color: #27ae60;
}

.due-date {
  font-size: 22rpx;
  color: #999;
}

.todo-delete {
  flex-shrink: 0;
  padding: 10rpx 16rpx;
}

.delete-text {
  font-size: 24rpx;
  color: #e74c3c;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 200rpx;
  gap: 16rpx;
}

.empty-text {
  font-size: 32rpx;
  color: #999;
}

.empty-hint {
  font-size: 24rpx;
  color: #bbb;
}

.undo-bar {
  position: fixed;
  bottom: 60rpx;
  left: 50%;
  transform: translateX(-50%);
  padding: 16rpx 48rpx;
  background: #333;
  border-radius: 40rpx;
}

.undo-text {
  color: #fff;
  font-size: 28rpx;
}

/* ── Prompt modal ── */

.prompt-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.prompt-dialog {
  width: 560rpx;
  background: #fff;
  border-radius: 16rpx;
  padding: 40rpx 36rpx 30rpx;
}

.prompt-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  display: block;
  margin-bottom: 24rpx;
}

.prompt-input {
  width: 100%;
  padding: 20rpx 20rpx;
  background: #f5f5f5;
  border-radius: 10rpx;
  font-size: 28rpx;
  margin-bottom: 30rpx;
  box-sizing: border-box;
}

.prompt-actions {
  display: flex;
  justify-content: flex-end;
  gap: 24rpx;
}

.prompt-btn {
  padding: 14rpx 32rpx;
  border-radius: 8rpx;
}

.prompt-btn-primary {
  background: #4a90d9;
}

.prompt-btn-text {
  font-size: 28rpx;
  color: #666;
}

.primary-text {
  color: #fff;
}
</style>
