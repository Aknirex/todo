<template>
  <view class="page-agent">
    <!-- Not configured prompt -->
    <view v-if="!agentStore.configured" class="config-prompt">
      <text class="prompt-icon">⚠</text>
      <text class="prompt-text">未配置 API Key</text>
      <text class="prompt-hint">请在设置中配置 LLM 服务商的 API Key 后使用 AI 助手</text>
      <view class="prompt-btn" @tap="goSettings">
        <text class="prompt-btn-text">前往设置</text>
      </view>
    </view>

    <!-- Tabs -->
    <view v-else class="agent-content">
      <view class="tabs">
        <view
          :class="['tab', activeTab === 'decompose' ? 'tab-active' : '']"
          @tap="activeTab = 'decompose'"
        >
          <text class="tab-text">拆解</text>
        </view>
        <view
          :class="['tab', activeTab === 'summarize' ? 'tab-active' : '']"
          @tap="activeTab = 'summarize'"
        >
          <text class="tab-text">总结</text>
        </view>
      </view>

      <!-- Decompose Tab -->
      <view v-if="activeTab === 'decompose'" class="tab-content">
        <view class="input-area">
          <textarea
            class="text-input"
            v-model="decomposeText"
            placeholder="输入一段文字，AI 将帮你提取待办事项...&#10;&#10;例如：明天上午开会讨论项目进度，下午记得提交周报，有空把代码重构一下"
            :maxlength="2000"
            :disabled="loading"
          />
          <text class="char-count">{{ decomposeText.length }}/2000</text>
        </view>

        <view class="action-btn" @tap="handleDecompose" v-if="!loading">
          <text class="btn-label">拆解</text>
        </view>

        <view v-if="loading" class="loading-wrap">
          <text class="loading-text">AI 正在分析...</text>
        </view>

        <!-- Error -->
        <view v-if="errorMsg" class="error-msg">
          <text>{{ errorMsg }}</text>
        </view>

        <!-- Preview list -->
        <view v-if="decomposedItems.length > 0" class="preview-section">
          <view class="preview-header">
            <text class="preview-title">解析结果（{{ selectCount }}/{{ decomposedItems.length }} 已选）</text>
            <view class="toggle-all" @tap="toggleAll">
              <text class="toggle-all-text">{{ allSelected ? '取消全选' : '全选' }}</text>
            </view>
          </view>

          <view
            v-for="(item, i) in decomposedItems"
            :key="i"
            class="preview-item"
            @tap="toggleItem(i)"
          >
            <view :class="['preview-check', item.selected ? 'checked' : '']">
              <text v-if="item.selected">✓</text>
            </view>
            <view class="preview-content">
              <text class="preview-item-title">{{ item.title || '(无标题)' }}</text>
              <view class="preview-meta">
                <text :class="['priority-tag', `p-${item.priority}`]">{{ priorityLabel(item.priority) }}</text>
                <text v-if="item.tags && item.tags.length > 0" class="tags-text">
                  {{ item.tags.join(', ') }}
                </text>
              </view>
            </view>
          </view>

          <view class="save-btn" @tap="handleSaveDecomposed">
            <text class="save-text">保存选中项</text>
          </view>
        </view>
      </view>

      <!-- Summarize Tab -->
      <view v-if="activeTab === 'summarize'" class="tab-content">
        <view class="section-label">
          <text>选择要总结的待办事项</text>
        </view>

        <view v-if="todoStore.activeTodos.length === 0" class="empty-hint">
          <text>暂无待办事项</text>
        </view>

        <view v-else class="todo-select-list">
          <view
            v-for="todo in todoStore.activeTodos"
            :key="todo.id"
            class="todo-select-item"
            @tap="toggleTodoSelect(todo.id)"
          >
            <view :class="['select-check', selectedTodoIds.includes(todo.id) ? 'checked' : '']">
              <text v-if="selectedTodoIds.includes(todo.id)">✓</text>
            </view>
            <text class="todo-select-title">{{ todo.title || '(无标题)' }}</text>
          </view>
        </view>

        <view class="form-group">
          <text class="form-label">额外上下文（可选）</text>
          <textarea
            class="text-input context-input"
            v-model="summaryContext"
            placeholder="例如：本周工作进展汇报"
            :maxlength="500"
            :disabled="loading"
          />
        </view>

        <view class="action-btn" @tap="handleSummarize" v-if="!loading">
          <text class="btn-label">总结</text>
        </view>

        <view v-if="loading" class="loading-wrap">
          <text class="loading-text">AI 正在总结...</text>
        </view>

        <view v-if="errorMsg" class="error-msg">
          <text>{{ errorMsg }}</text>
        </view>

        <view v-if="summaryResult" class="summary-section">
          <view class="summary-header">
            <text class="summary-title">总结结果</text>
            <view class="copy-btn" @tap="handleCopy">
              <text class="copy-text">{{ copied ? '已复制' : '复制' }}</text>
            </view>
          </view>
          <view class="summary-content">
            <text class="summary-text">{{ summaryResult }}</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAgentStore, useTodoStore } from '@/stores'
import type { CreateTodoInput, Priority, Todo } from '@/types'

const agentStore = useAgentStore()
const todoStore = useTodoStore()

const activeTab = ref<'decompose' | 'summarize'>('decompose')
const loading = ref(false)
const errorMsg = ref('')

// Decompose state
const decomposeText = ref('')
interface DecomposedItem extends CreateTodoInput {
  selected: boolean
}
const decomposedItems = ref<DecomposedItem[]>([])

const allSelected = computed(() =>
  decomposedItems.value.length > 0 && decomposedItems.value.every(it => it.selected)
)

const selectCount = computed(() =>
  decomposedItems.value.filter(it => it.selected).length
)

// Summarize state
const selectedTodoIds = ref<string[]>([])
const summaryContext = ref('')
const summaryResult = ref('')
const copied = ref(false)

onMounted(async () => {
  await agentStore.loadConfig()
  await todoStore.loadTodos()
})

function priorityLabel(p: Priority | undefined): string {
  const map: Record<string, string> = { high: '高', medium: '中', low: '低' }
  return map[p || 'medium'] || '中'
}

function goSettings() {
  uni.navigateTo({ url: '/pages/settings/index' })
}

function toggleItem(i: number) {
  decomposedItems.value[i].selected = !decomposedItems.value[i].selected
}

function toggleAll() {
  const target = !allSelected.value
  decomposedItems.value.forEach(it => { it.selected = target })
}

async function handleDecompose() {
  if (!decomposeText.value.trim()) {
    errorMsg.value = '请输入文字内容'
    return
  }

  errorMsg.value = ''
  decomposedItems.value = []
  loading.value = true

  try {
    const items = await agentStore.decomposeText(decomposeText.value)
    decomposedItems.value = items.map(it => ({ ...it, selected: true }))
  } catch (e: any) {
    errorMsg.value = e.message || '拆解失败'
  } finally {
    loading.value = false
  }
}

async function handleSaveDecomposed() {
  const selected = decomposedItems.value.filter(it => it.selected)
  if (selected.length === 0) {
    errorMsg.value = '请至少选择一项'
    return
  }

  errorMsg.value = ''
  loading.value = true

  try {
    for (const item of selected) {
      await todoStore.createTodo({
        title: item.title,
        priority: item.priority,
        tags: item.tags,
        listId: 'default'
      })
    }
    decomposedItems.value = []
    decomposeText.value = ''
  } catch (e: any) {
    errorMsg.value = e.message || '保存失败'
  } finally {
    loading.value = false
  }
}

function toggleTodoSelect(id: string) {
  const idx = selectedTodoIds.value.indexOf(id)
  if (idx === -1) {
    selectedTodoIds.value.push(id)
  } else {
    selectedTodoIds.value.splice(idx, 1)
  }
}

async function handleSummarize() {
  if (selectedTodoIds.value.length === 0) {
    errorMsg.value = '请至少选择一项待办事项'
    return
  }

  errorMsg.value = ''
  summaryResult.value = ''
  loading.value = true

  try {
    const selectedTodos = todoStore.todos.filter(
      t => selectedTodoIds.value.includes(t.id)
    )
    const result = await agentStore.summarizeTodos(
      selectedTodos,
      summaryContext.value || undefined
    )
    summaryResult.value = result
  } catch (e: any) {
    errorMsg.value = e.message || '总结失败'
  } finally {
    loading.value = false
  }
}

function handleCopy() {
  uni.setClipboardData({
    data: summaryResult.value,
    success() {
      copied.value = true
      setTimeout(() => { copied.value = false }, 2000)
    }
  })
}
</script>

<style scoped>
.page-agent {
  padding: 30rpx;
  min-height: 100vh;
  background-color: #f5f5f5;
}

/* Config prompt */
.config-prompt {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 200rpx;
  gap: 20rpx;
}

.prompt-icon {
  font-size: 64rpx;
}

.prompt-text {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
}

.prompt-hint {
  font-size: 26rpx;
  color: #999;
  text-align: center;
  line-height: 1.6;
  padding: 0 40rpx;
}

.prompt-btn {
  margin-top: 20rpx;
  padding: 20rpx 60rpx;
  background: #4a90d9;
  border-radius: 12rpx;
}

.prompt-btn-text {
  color: #fff;
  font-size: 30rpx;
}

/* Tabs */
.agent-content {
  display: flex;
  flex-direction: column;
}

.tabs {
  display: flex;
  background: #fff;
  border-radius: 12rpx;
  overflow: hidden;
  margin-bottom: 30rpx;
}

.tab {
  flex: 1;
  padding: 24rpx;
  text-align: center;
  border-bottom: 4rpx solid transparent;
}

.tab-active {
  border-bottom-color: #4a90d9;
}

.tab-text {
  font-size: 30rpx;
  color: #666;
}

.tab-active .tab-text {
  color: #4a90d9;
  font-weight: bold;
}

.tab-content {
  flex: 1;
}

/* Input */
.input-area {
  position: relative;
  margin-bottom: 20rpx;
}

.text-input {
  width: 100%;
  min-height: 200rpx;
  padding: 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  color: #333;
  box-sizing: border-box;
}

.char-count {
  text-align: right;
  font-size: 22rpx;
  color: #ccc;
  margin-top: 8rpx;
  display: block;
}

.action-btn {
  padding: 24rpx;
  background: #4a90d9;
  border-radius: 12rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 30rpx;
}

.btn-label {
  color: #fff;
  font-size: 30rpx;
}

.loading-wrap {
  padding: 40rpx;
  text-align: center;
}

.loading-text {
  font-size: 28rpx;
  color: #999;
}

.error-msg {
  padding: 20rpx;
  background: #ffeaea;
  border-radius: 8rpx;
  margin-bottom: 20rpx;
  font-size: 26rpx;
  color: #e74c3c;
}

/* Preview */
.preview-section {
  background: #fff;
  border-radius: 12rpx;
  padding: 24rpx;
}

.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
  padding-bottom: 16rpx;
  border-bottom: 1rpx solid #eee;
}

.preview-title {
  font-size: 26rpx;
  color: #666;
}

.toggle-all-text {
  font-size: 24rpx;
  color: #4a90d9;
}

.preview-item {
  display: flex;
  align-items: flex-start;
  padding: 16rpx 0;
  gap: 16rpx;
  border-bottom: 1rpx solid #f5f5f5;
}

.preview-item:last-child {
  border-bottom: none;
}

.preview-check {
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
  margin-top: 4rpx;
}

.preview-check.checked {
  background: #4a90d9;
  border-color: #4a90d9;
}

.preview-content {
  flex: 1;
  min-width: 0;
}

.preview-item-title {
  font-size: 28rpx;
  color: #333;
}

.preview-meta {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-top: 8rpx;
}

.priority-tag {
  font-size: 20rpx;
  padding: 2rpx 10rpx;
  border-radius: 4rpx;
}

.p-high { background: #ffeaea; color: #e74c3c; }
.p-medium { background: #fff3e0; color: #f39c12; }
.p-low { background: #e8f5e9; color: #27ae60; }

.tags-text {
  font-size: 20rpx;
  color: #999;
}

.save-btn {
  margin-top: 24rpx;
  padding: 20rpx;
  background: #27ae60;
  border-radius: 12rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.save-text {
  color: #fff;
  font-size: 28rpx;
}

/* Summarize */
.section-label {
  margin-bottom: 16rpx;
  font-size: 26rpx;
  color: #666;
}

.empty-hint {
  padding: 40rpx;
  text-align: center;
  font-size: 26rpx;
  color: #999;
}

.todo-select-list {
  background: #fff;
  border-radius: 12rpx;
  padding: 0 24rpx;
  margin-bottom: 30rpx;
}

.todo-select-item {
  display: flex;
  align-items: center;
  padding: 20rpx 0;
  gap: 16rpx;
  border-bottom: 1rpx solid #f5f5f5;
}

.todo-select-item:last-child {
  border-bottom: none;
}

.select-check {
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

.select-check.checked {
  background: #4a90d9;
  border-color: #4a90d9;
}

.todo-select-title {
  flex: 1;
  font-size: 28rpx;
  color: #333;
}

.form-group {
  margin-bottom: 20rpx;
}

.form-label {
  font-size: 26rpx;
  color: #666;
  margin-bottom: 12rpx;
  display: block;
}

.context-input {
  min-height: 120rpx;
}

.summary-section {
  background: #fff;
  border-radius: 12rpx;
  padding: 24rpx;
  margin-top: 30rpx;
}

.summary-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16rpx;
  padding-bottom: 16rpx;
  border-bottom: 1rpx solid #eee;
}

.summary-title {
  font-size: 26rpx;
  color: #666;
}

.copy-btn {
  padding: 8rpx 20rpx;
  background: #f0f0f0;
  border-radius: 8rpx;
}

.copy-text {
  font-size: 24rpx;
  color: #4a90d9;
}

.summary-content {
  line-height: 1.8;
}

.summary-text {
  font-size: 28rpx;
  color: #333;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
