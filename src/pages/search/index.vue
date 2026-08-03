<template>
  <view class="page-search">
    <!-- Search input -->
    <view class="search-bar">
      <input
        class="search-input"
        v-model="keyword"
        placeholder="搜索任务标题、详情或标签..."
        @input="onInput"
        confirm-type="search"
      />
      <view v-if="keyword" class="search-clear" @tap="clearSearch">
        <text>✕</text>
      </view>
    </view>

    <!-- Filter toggle -->
    <view class="filter-toggle" @tap="showFilters = !showFilters">
      <text class="filter-toggle-text">
        筛选条件 {{ showFilters ? '▲' : '▼' }}
      </text>
      <text v-if="activeFilterCount > 0" class="filter-badge">{{ activeFilterCount }}</text>
    </view>

    <!-- Filter panel -->
    <view class="filter-panel" v-if="showFilters">
      <!-- Priority filter -->
      <view class="filter-row">
        <text class="filter-label">优先级</text>
        <view class="filter-options">
          <view
            v-for="p in priorities"
            :key="p.value"
            :class="['filter-chip', filter.priority === p.value ? 'active' : '', `chip-${p.value}`]"
            @tap="togglePriority(p.value)"
          >
            <text>{{ p.label }}</text>
          </view>
        </view>
      </view>

      <!-- Completed status filter -->
      <view class="filter-row">
        <text class="filter-label">完成状态</text>
        <view class="filter-options">
          <view
            :class="['filter-chip', filter.completed === undefined ? 'active' : '']"
            @tap="filter.completed = undefined"
          >
            <text>全部</text>
          </view>
          <view
            :class="['filter-chip', filter.completed === false ? 'active chip-active' : '']"
            @tap="filter.completed = false"
          >
            <text>未完成</text>
          </view>
          <view
            :class="['filter-chip', filter.completed === true ? 'active chip-done' : '']"
            @tap="filter.completed = true"
          >
            <text>已完成</text>
          </view>
        </view>
      </view>

      <!-- Date range filter -->
      <view class="filter-row">
        <text class="filter-label">日期范围</text>
        <view class="date-range">
          <picker mode="date" :value="filter.dueDateRange?.start || ''" @change="onStartDate">
            <view class="date-picker">
              <text>{{ filter.dueDateRange?.start || '开始日期' }}</text>
            </view>
          </picker>
          <text class="date-sep">—</text>
          <picker mode="date" :value="filter.dueDateRange?.end || ''" @change="onEndDate">
            <view class="date-picker">
              <text>{{ filter.dueDateRange?.end || '结束日期' }}</text>
            </view>
          </picker>
        </view>
        <view v-if="filter.dueDateRange" class="filter-clear-date" @tap="clearDateRange">
          <text class="clear-link">清除</text>
        </view>
      </view>

      <!-- Reset filters -->
      <view class="filter-reset" @tap="resetFilters">
        <text class="reset-text">重置筛选</text>
      </view>
    </view>

    <!-- Loading indicator -->
    <view class="loading" v-if="loading">
      <text>搜索中...</text>
    </view>

    <!-- No results -->
    <view class="empty-state" v-if="!loading && keyword && results.length === 0">
      <text class="empty-text">未找到匹配结果</text>
    </view>

    <!-- Results list -->
    <view class="results" v-if="results.length > 0">
      <view
        class="result-item"
        v-for="todo in results"
        :key="todo.id"
        @tap="goDetail(todo.id)"
      >
        <view class="result-header">
          <text class="result-title">
            <text
              v-for="(seg, i) in highlightSegments(todo.title)"
              :key="i"
              :class="seg.highlight ? 'highlight' : ''"
            >{{ seg.text }}</text>
          </text>
          <text :class="['result-priority', `p-${todo.priority}`]">
            {{ priorityLabel(todo.priority) }}
          </text>
        </view>
        <view class="result-meta">
          <text v-if="todo.completed" class="result-status done">已完成</text>
          <text v-else class="result-status pending">未完成</text>
          <text v-if="todo.dueDate" class="result-date">{{ todo.dueDate }}</text>
          <text v-if="todo.tags.length > 0" class="result-tags">{{ todo.tags.join(', ') }}</text>
        </view>
        <!-- Detail snippet if keyword matches detail -->
        <view v-if="keyword && todo.detail" class="result-detail">
          <text
            v-for="(seg, i) in highlightSegments(truncateDetail(todo.detail))"
            :key="i"
            :class="seg.highlight ? 'highlight' : ''"
          >{{ seg.text }}</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { searchTodos } from '@/services/search'
import type { Todo, Priority, TodoFilter } from '@/types'

const keyword = ref('')
const results = ref<Todo[]>([])
const loading = ref(false)
const showFilters = ref(false)
let debounceTimer: ReturnType<typeof setTimeout> | null = null

const priorities = [
  { value: 'high' as Priority, label: '高' },
  { value: 'medium' as Priority, label: '中' },
  { value: 'low' as Priority, label: '低' }
]

const filter = reactive<TodoFilter>({
  priority: undefined,
  completed: undefined,
  dueDateRange: undefined
})

const activeFilterCount = computed(() => {
  let count = 0
  if (filter.priority) count++
  if (filter.completed !== undefined) count++
  if (filter.dueDateRange) count++
  return count
})

function priorityLabel(p: Priority): string {
  const map: Record<Priority, string> = { high: '高', medium: '中', low: '低' }
  return map[p] || '中'
}

function onInput() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    doSearch()
  }, 300)
}

function togglePriority(p: Priority) {
  filter.priority = filter.priority === p ? undefined : p
}

function onStartDate(e: any) {
  const val = e.detail.value as string
  filter.dueDateRange = {
    start: val,
    end: filter.dueDateRange?.end || val
  }
}

function onEndDate(e: any) {
  const val = e.detail.value as string
  filter.dueDateRange = {
    start: filter.dueDateRange?.start || val,
    end: val
  }
}

function clearDateRange() {
  filter.dueDateRange = undefined
}

function resetFilters() {
  filter.priority = undefined
  filter.completed = undefined
  filter.dueDateRange = undefined
}

function clearSearch() {
  keyword.value = ''
  results.value = []
}

function truncateDetail(detail: string): string {
  return detail.length > 80 ? detail.slice(0, 80) + '...' : detail
}

interface TextSegment {
  text: string
  highlight: boolean
}

function highlightSegments(text: string): TextSegment[] {
  if (!keyword.value) return [{ text, highlight: false }]
  const kw = keyword.value
  const segments: TextSegment[] = []
  const lower = text.toLowerCase()
  const lowerKw = kw.toLowerCase()
  let cursor = 0

  while (cursor < text.length) {
    const idx = lower.indexOf(lowerKw, cursor)
    if (idx === -1) {
      segments.push({ text: text.slice(cursor), highlight: false })
      break
    }
    if (idx > cursor) {
      segments.push({ text: text.slice(cursor, idx), highlight: false })
    }
    segments.push({
      text: text.slice(idx, idx + kw.length),
      highlight: true
    })
    cursor = idx + kw.length
  }

  return segments
}

async function doSearch() {
  if (!keyword.value.trim()) {
    results.value = []
    return
  }
  loading.value = true
  try {
    results.value = await searchTodos(keyword.value.trim(), { ...filter })
  } finally {
    loading.value = false
  }
}

// Re-search when filters change and there is a keyword
watch(
  () => [filter.priority, filter.completed, filter.dueDateRange],
  () => {
    if (keyword.value.trim()) {
      doSearch()
    }
  }
)

function goDetail(id: string) {
  uni.navigateTo({ url: `/pages/detail/index?id=${id}` })
}
</script>

<style scoped>
.page-search {
  padding: 30rpx;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.search-bar {
  display: flex;
  align-items: center;
  background: #fff;
  border-radius: 12rpx;
  padding: 0 24rpx;
  margin-bottom: 20rpx;
}

.search-input {
  flex: 1;
  padding: 22rpx 0;
  font-size: 28rpx;
}

.search-clear {
  padding: 10rpx;
}

.filter-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  margin-bottom: 20rpx;
}

.filter-toggle-text {
  font-size: 26rpx;
  color: #666;
}

.filter-badge {
  background: #4a90d9;
  color: #fff;
  font-size: 22rpx;
  padding: 4rpx 14rpx;
  border-radius: 20rpx;
}

.filter-panel {
  background: #fff;
  border-radius: 12rpx;
  padding: 24rpx;
  margin-bottom: 20rpx;
}

.filter-row {
  margin-bottom: 24rpx;
}

.filter-label {
  font-size: 26rpx;
  color: #666;
  margin-bottom: 14rpx;
  display: block;
}

.filter-options {
  display: flex;
  gap: 16rpx;
  flex-wrap: wrap;
}

.filter-chip {
  padding: 12rpx 28rpx;
  border-radius: 8rpx;
  font-size: 24rpx;
  background: #f5f5f5;
  color: #666;
  border: 2rpx solid transparent;
}

.filter-chip.active {
  background: #e8f0fe;
  color: #4a90d9;
  border-color: #4a90d9;
}

.filter-chip.chip-active.active {
  background: #e8f5e9;
  color: #27ae60;
  border-color: #27ae60;
}

.filter-chip.chip-done.active {
  background: #f3e5f5;
  color: #8e44ad;
  border-color: #8e44ad;
}

.filter-chip.chip-high.active {
  background: #ffeaea;
  color: #e74c3c;
  border-color: #e74c3c;
}

.filter-chip.chip-medium.active {
  background: #fff3e0;
  color: #f39c12;
  border-color: #f39c12;
}

.filter-chip.chip-low.active {
  background: #e8f5e9;
  color: #27ae60;
  border-color: #27ae60;
}

.date-range {
  display: flex;
  align-items: center;
  gap: 12rpx;
}

.date-picker {
  flex: 1;
  padding: 16rpx 20rpx;
  background: #f5f5f5;
  border-radius: 8rpx;
  font-size: 24rpx;
  color: #333;
  text-align: center;
}

.date-sep {
  font-size: 24rpx;
  color: #999;
}

.filter-clear-date {
  margin-top: 12rpx;
}

.clear-link {
  font-size: 24rpx;
  color: #4a90d9;
}

.filter-reset {
  padding: 16rpx;
  text-align: center;
  border-top: 1rpx solid #eee;
  margin-top: 8rpx;
}

.reset-text {
  font-size: 26rpx;
  color: #e74c3c;
}

.loading {
  padding: 80rpx 0;
  text-align: center;
  font-size: 26rpx;
  color: #999;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 120rpx;
}

.empty-text {
  font-size: 28rpx;
  color: #999;
}

.results {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.result-item {
  background: #fff;
  border-radius: 12rpx;
  padding: 24rpx;
}

.result-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10rpx;
}

.result-title {
  font-size: 30rpx;
  color: #333;
  flex: 1;
  min-width: 0;
}

.highlight {
  background-color: #fff176;
  color: #333;
  font-weight: bold;
}

.result-priority {
  font-size: 22rpx;
  padding: 4rpx 14rpx;
  border-radius: 4rpx;
  flex-shrink: 0;
  margin-left: 16rpx;
}

.result-priority.p-high {
  background: #ffeaea;
  color: #e74c3c;
}

.result-priority.p-medium {
  background: #fff3e0;
  color: #f39c12;
}

.result-priority.p-low {
  background: #e8f5e9;
  color: #27ae60;
}

.result-meta {
  display: flex;
  gap: 16rpx;
  flex-wrap: wrap;
  margin-bottom: 8rpx;
}

.result-status {
  font-size: 22rpx;
  padding: 2rpx 10rpx;
  border-radius: 4rpx;
}

.result-status.done {
  background: #f3e5f5;
  color: #8e44ad;
}

.result-status.pending {
  background: #e8f0fe;
  color: #4a90d9;
}

.result-date {
  font-size: 22rpx;
  color: #999;
}

.result-tags {
  font-size: 22rpx;
  color: #4a90d9;
}

.result-detail {
  font-size: 24rpx;
  color: #888;
  margin-top: 8rpx;
  line-height: 1.5;
}
</style>
