<template>
  <view class="page-share">
    <!-- Format selector -->
    <view class="section">
      <text class="section-label">选择导出格式</text>
      <view class="format-options">
        <view
          :class="['format-chip', format === 'text' ? 'active' : '']"
          @tap="format = 'text'"
        >
          <text>纯文本</text>
        </view>
        <view
          :class="['format-chip', format === 'markdown' ? 'active' : '']"
          @tap="format = 'markdown'"
        >
          <text>Markdown</text>
        </view>
      </view>
    </view>

    <!-- Todo list for selection -->
    <view class="section">
      <text class="section-label">
        选择待办事项（{{ selectedIds.size }} / {{ todos.length }}）
      </text>
      <view class="select-actions">
        <text class="select-link" @tap="selectAll">全选</text>
        <text class="select-link" @tap="deselectAll">取消全选</text>
      </view>
      <view class="todo-list" v-if="todos.length > 0">
        <view
          class="todo-item"
          v-for="todo in todos"
          :key="todo.id"
          @tap="toggleSelect(todo.id)"
        >
          <view :class="['todo-checkbox', isSelected(todo.id) ? 'checked' : '']">
            <text v-if="isSelected(todo.id)">✓</text>
          </view>
          <view class="todo-content">
            <text class="todo-title">{{ todo.title || '(无标题)' }}</text>
            <view class="todo-meta">
              <text :class="['todo-priority', `p-${todo.priority}`]">
                {{ priorityLabel(todo.priority) }}
              </text>
              <text v-if="todo.dueDate" class="todo-date">{{ todo.dueDate }}</text>
              <text v-if="todo.tags.length > 0" class="todo-tags">
                {{ todo.tags.join(', ') }}
              </text>
              <text :class="['todo-status', todo.completed ? 'done' : 'pending']">
                {{ todo.completed ? '已完成' : '未完成' }}
              </text>
            </view>
          </view>
        </view>
      </view>
      <view class="empty-hint" v-else>
        <text class="hint-text">暂无待办事项</text>
      </view>
    </view>

    <!-- Preview -->
    <view class="section" v-if="previewText">
      <text class="section-label">预览</text>
      <view class="preview-card">
        <text class="preview-content">{{ previewText }}</text>
      </view>
    </view>

    <!-- Actions -->
    <view class="actions" v-if="selectedIds.size > 0">
      <view class="btn-copy" @tap="handleCopy">
        <text class="btn-text">复制到剪贴板</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useTodoStore } from '@/stores'
import { exportAsText, exportAsMarkdown } from '@/services/export'
import type { Priority } from '@/types'

const todoStore = useTodoStore()
const format = ref<'text' | 'markdown'>('text')
const selectedIds = ref<Set<string>>(new Set())

const todos = computed(() =>
  todoStore.todos.filter(t => !t.deleted)
)

onMounted(async () => {
  await todoStore.loadTodos()
})

function priorityLabel(p: Priority): string {
  const map: Record<Priority, string> = { high: '高', medium: '中', low: '低' }
  return map[p] || '中'
}

function isSelected(id: string): boolean {
  return selectedIds.value.has(id)
}

function toggleSelect(id: string) {
  const set = selectedIds.value
  const next = new Set(set)
  if (next.has(id)) {
    next.delete(id)
  } else {
    next.add(id)
  }
  selectedIds.value = next
}

function selectAll() {
  selectedIds.value = new Set(todos.value.map(t => t.id))
}

function deselectAll() {
  selectedIds.value = new Set()
}

const previewText = computed(() => {
  const selected = todos.value.filter(t => selectedIds.value.has(t.id))
  if (selected.length === 0) return ''
  if (format.value === 'text') {
    return exportAsText(selected)
  }
  return exportAsMarkdown(selected)
})

function handleCopy() {
  if (!previewText.value) return
  uni.setClipboardData({
    data: previewText.value,
    success() {
      uni.showToast({ title: '已复制到剪贴板', icon: 'success' })
    },
    fail() {
      uni.showToast({ title: '复制失败', icon: 'error' })
    }
  })
}
</script>

<style scoped>
.page-share {
  padding: 30rpx;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.section {
  margin-bottom: 32rpx;
}

.section-label {
  font-size: 28rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 16rpx;
  display: block;
}

.format-options {
  display: flex;
  gap: 16rpx;
}

.format-chip {
  flex: 1;
  padding: 24rpx;
  text-align: center;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  color: #666;
  border: 2rpx solid transparent;
}

.format-chip.active {
  border-color: #4a90d9;
  color: #4a90d9;
  background: #e8f0fe;
}

.select-actions {
  display: flex;
  gap: 24rpx;
  margin-bottom: 16rpx;
}

.select-link {
  font-size: 24rpx;
  color: #4a90d9;
}

.todo-list {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
  max-height: 500rpx;
  overflow-y: auto;
}

.todo-item {
  display: flex;
  align-items: center;
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 10rpx;
  gap: 20rpx;
}

.todo-checkbox {
  width: 40rpx;
  height: 40rpx;
  border: 2rpx solid #ddd;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22rpx;
  color: #fff;
  flex-shrink: 0;
}

.todo-checkbox.checked {
  background: #4a90d9;
  border-color: #4a90d9;
}

.todo-content {
  flex: 1;
  min-width: 0;
}

.todo-title {
  font-size: 28rpx;
  color: #333;
  display: block;
}

.todo-meta {
  display: flex;
  gap: 12rpx;
  flex-wrap: wrap;
  margin-top: 6rpx;
}

.todo-priority {
  font-size: 20rpx;
  padding: 2rpx 10rpx;
  border-radius: 4rpx;
}

.todo-priority.p-high {
  background: #ffeaea;
  color: #e74c3c;
}

.todo-priority.p-medium {
  background: #fff3e0;
  color: #f39c12;
}

.todo-priority.p-low {
  background: #e8f5e9;
  color: #27ae60;
}

.todo-date {
  font-size: 20rpx;
  color: #999;
}

.todo-tags {
  font-size: 20rpx;
  color: #4a90d9;
}

.todo-status {
  font-size: 20rpx;
  padding: 2rpx 10rpx;
  border-radius: 4rpx;
}

.todo-status.done {
  background: #f3e5f5;
  color: #8e44ad;
}

.todo-status.pending {
  background: #e8f0fe;
  color: #4a90d9;
}

.empty-hint {
  padding: 60rpx 0;
  text-align: center;
}

.hint-text {
  font-size: 26rpx;
  color: #bbb;
}

.preview-card {
  background: #fff;
  border-radius: 12rpx;
  padding: 24rpx;
}

.preview-content {
  font-size: 24rpx;
  color: #555;
  line-height: 1.7;
  white-space: pre-wrap;
}

.actions {
  margin-top: 40rpx;
}

.btn-copy {
  padding: 24rpx;
  background: #4a90d9;
  border-radius: 12rpx;
  text-align: center;
}

.btn-text {
  color: #fff;
  font-size: 30rpx;
  font-weight: bold;
}
</style>
