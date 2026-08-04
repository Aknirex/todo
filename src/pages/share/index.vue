<template>
  <view class="page-share" :style="themeVars">
    <!-- Topbar -->
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">导出数据</text>
    </view>

    <view class="share-content">
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
        <AppIcon name="clipboard-copy" :size="16" color="#fff" />
        <text class="btn-text">复制到剪贴板</text>
      </view>
    </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useTodoStore } from '@/stores'
import { exportAsText, exportAsMarkdown } from '@/services/export'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'
import type { Priority } from '@/types'

const { themeVars } = useTheme()

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

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.page-share {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}

.share-content {
  padding: 30rpx;
}

.section {
  margin-bottom: 32rpx;
}

.section-label {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text-2);
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
  background: var(--card);
  border-radius: var(--radius);
  font-size: 28rpx;
  color: var(--text-2);
  border: 2rpx solid transparent;
  box-shadow: var(--shadow);
}

.format-chip.active {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-bg);
}

.select-actions {
  display: flex;
  gap: 24rpx;
  margin-bottom: 16rpx;
}

.select-link {
  font-size: 24rpx;
  color: var(--primary);
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
  background: var(--card);
  border-radius: var(--radius);
  gap: 20rpx;
  box-shadow: var(--shadow);
}

.todo-checkbox {
  width: 40rpx;
  height: 40rpx;
  border: 2rpx solid var(--checkbox-border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22rpx;
  color: #fff;
  flex-shrink: 0;
}

.todo-checkbox.checked {
  background: var(--primary);
  border-color: var(--primary);
}

.todo-content {
  flex: 1;
  min-width: 0;
}

.todo-title {
  font-size: 28rpx;
  color: var(--text);
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
  border-radius: 8rpx;
}

.todo-priority.p-high {
  background: var(--danger-light);
  color: var(--danger);
}

.todo-priority.p-medium {
  background: var(--warning-light);
  color: var(--warning);
}

.todo-priority.p-low {
  background: var(--success-light);
  color: var(--success);
}

.todo-date {
  font-size: 20rpx;
  color: var(--text-3);
}

.todo-tags {
  font-size: 20rpx;
  color: var(--primary);
}

.todo-status {
  font-size: 20rpx;
  padding: 2rpx 10rpx;
  border-radius: 8rpx;
}

.todo-status.done {
  background: var(--success-light);
  color: var(--success);
}

.todo-status.pending {
  background: var(--primary-bg);
  color: var(--primary);
}

.empty-hint {
  padding: 60rpx 0;
  text-align: center;
}

.hint-text {
  font-size: 26rpx;
  color: var(--text-3);
}

.preview-card {
  background: var(--card);
  border-radius: var(--radius);
  padding: 24rpx;
  box-shadow: var(--shadow);
}

.preview-content {
  font-size: 24rpx;
  color: var(--text-2);
  line-height: 1.7;
  white-space: pre-wrap;
}

.actions {
  margin-top: 40rpx;
}

.btn-copy {
  padding: 24rpx;
  background: var(--primary);
  border-radius: var(--radius);
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
}

.btn-text {
  color: #fff;
  font-size: 30rpx;
  font-weight: 600;
}
</style>
