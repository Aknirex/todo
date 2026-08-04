<template>
  <view class="page-agent" :style="themeVars">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title" style="display:flex;align-items:center;gap:12rpx">
        <text class="ai-icon" style="font-size:32rpx">AI</text>
        <text>{{ $t('nav.agent') }}</text>
      </text>
    </view>

    <scroll-view scroll-y class="agent-content">
      <!-- Mode Switch -->
      <view class="agent-mode-switch">
        <view :class="['mode-tab', mode === 'decompose' ? 'active' : '']" @tap="mode = 'decompose'">
          <AppIcon name="file-text" :size="15" />
          <text>{{ $t('agent.decomposeTab') }}</text>
        </view>
        <view :class="['mode-tab', mode === 'summarize' ? 'active' : '']" @tap="mode = 'summarize'">
          <AppIcon name="chart-column" :size="15" />
          <text>{{ $t('agent.summarizeTab') }}</text>
        </view>
      </view>

      <!-- Decompose Panel -->
      <view v-if="mode === 'decompose'" class="agent-panel">
        <text class="panel-title">{{ $t('agent.decompose.title') }}</text>
        <text class="panel-desc">{{ $t('agent.decompose.desc') }}</text>

        <view class="agent-scope">
          <view class="scope-hd">
            <AppIcon name="book-open" :size="13" color="var(--text-3)" />
            <text>{{ $t('agent.scope.read') }}</text>
          </view>
          <picker :range="listNames" @change="onReadListChange">
            <view class="scope-select">{{ readListName }}</view>
          </picker>
        </view>

        <textarea
          class="agent-textarea"
          v-model="decomposeText"
          :placeholder="$t('agent.decompose.placeholder')"
        />

        <view class="agent-actions">
          <view class="btn btn-primary" @tap="doDecompose">
            <text class="ai-icon" style="font-size:24rpx">AI</text>
            <text>{{ $t('agent.decompose.btn') }}</text>
          </view>
        </view>

        <!-- Decompose Result -->
        <view v-if="decomposeResults.length > 0" class="agent-result">
          <text class="result-hd">{{ $t('agent.decompose.result', { n: decomposeResults.length }) }}</text>
          <view v-for="(item, i) in decomposeResults" :key="i" class="result-item">
            <checkbox :checked="item.selected" @tap="item.selected = !item.selected" />
            <text style="flex:1">{{ item.title }}</text>
            <text class="todo-tag" style="margin-left:auto">{{ item.priority }}</text>
          </view>
          <view class="agent-actions" style="margin-top:20rpx">
            <view class="btn btn-primary" @tap="saveDecomposed">
              <AppIcon name="check" :size="14" color="#fff" />
              <text>{{ $t('agent.decompose.save') }}</text>
            </view>
            <view class="btn btn-ghost" @tap="editDecomposed">
              <AppIcon name="pencil" :size="14" color="var(--primary)" />
              <text>{{ $t('agent.decompose.edit') }}</text>
            </view>
          </view>
        </view>
      </view>

      <!-- Summarize Panel -->
      <view v-if="mode === 'summarize'" class="agent-panel">
        <text class="panel-title">{{ $t('agent.summarize.title') }}</text>
        <text class="panel-desc">{{ $t('agent.summarize.desc') }}</text>

        <view class="agent-scope">
          <view class="scope-hd">
            <AppIcon name="book-open" :size="13" color="var(--text-3)" />
            <text>{{ $t('agent.scope.read') }}</text>
          </view>
          <picker :range="listNames" @change="onSumListChange">
            <view class="scope-select">{{ sumListName }}</view>
          </picker>
        </view>

        <textarea
          class="agent-textarea"
          v-model="summarizeContext"
          :placeholder="$t('agent.summarize.placeholder')"
        />

        <view class="agent-actions">
          <view class="btn btn-primary" @tap="doSummarize">
            <text class="ai-icon" style="font-size:24rpx">AI</text>
            <text>{{ $t('agent.summarize.btn') }}</text>
          </view>
        </view>

        <view v-if="summaryText" class="summary-box">
          <text>{{ summaryText }}</text>
        </view>
        <view v-if="summaryText" class="agent-actions">
          <view class="btn btn-primary" @tap="copySummary">
            <AppIcon name="clipboard-copy" :size="14" color="#fff" />
            <text>{{ $t('agent.summarize.copy') }}</text>
          </view>
          <view class="btn btn-outline" @tap="editSummary">
            <AppIcon name="pencil" :size="14" color="var(--text-2)" />
            <text>{{ $t('agent.summarize.edit') }}</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useTodoStore, useListStore, useAgentStore } from '@/stores'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'
import type { CreateTodoInput, Priority } from '@/types'

const { t } = useI18n()
const { themeVars } = useTheme()

const todoStore = useTodoStore()
const listStore = useListStore()
const agentStore = useAgentStore()

const mode = ref<'decompose' | 'summarize'>('decompose')
const decomposeText = ref('')
const decomposeResults = ref<{ title: string; priority: string; selected: boolean }[]>([])
const readListId = ref('default')
const sumListId = ref('default')
const summarizeContext = ref('')
const summaryText = ref('')
const loading = ref(false)

const listNames = computed(() => listStore.lists.map(l => l.name))
const readListName = computed(() => listStore.lists.find(l => l.id === readListId.value)?.name || '默认列表')
const sumListName = computed(() => listStore.lists.find(l => l.id === sumListId.value)?.name || '默认列表')

onMounted(async () => {
  await agentStore.loadConfig()
  if (listStore.lists.length === 0) await listStore.loadLists()
})

function onReadListChange(e: any) {
  const idx = e.detail.value
  readListId.value = listStore.lists[idx]?.id || 'default'
}
function onSumListChange(e: any) {
  const idx = e.detail.value
  sumListId.value = listStore.lists[idx]?.id || 'default'
}

async function doDecompose() {
  if (!agentStore.configured) {
    uni.showToast({ title: t('agent.needApiKey'), icon: 'none' })
    return
  }
  if (!decomposeText.value.trim()) return
  loading.value = true
  try {
    const results = await agentStore.decomposeText(decomposeText.value)
    decomposeResults.value = results.map(r => ({
      title: r.title || '',
      priority: r.priority || 'medium',
      selected: true
    }))
  } catch (e: any) {
    uni.showToast({ title: e.message || t('agent.decompose.fail'), icon: 'none' })
  }
  loading.value = false
}

async function saveDecomposed() {
  const selected = decomposeResults.value.filter(r => r.selected)
  for (const item of selected) {
    await todoStore.createTodo({
      title: item.title,
      priority: item.priority as Priority,
      listId: readListId.value
    })
  }
  uni.showToast({ title: t('agent.decompose.saved', { n: selected.length }), icon: 'success' })
  decomposeResults.value = []
  decomposeText.value = ''
}

function editDecomposed() {
  // Allow editing in-place (already editable via checkboxes)
  uni.showToast({ title: t('agent.editHint'), icon: 'none' })
}

async function doSummarize() {
  if (!agentStore.configured) {
    uni.showToast({ title: t('agent.needApiKey'), icon: 'none' })
    return
  }
  loading.value = true
  try {
    const todos = todoStore.todosByList(sumListId.value).filter(t => !t.deleted)
    summaryText.value = await agentStore.summarizeTodos(todos, summarizeContext.value || undefined)
  } catch (e: any) {
    uni.showToast({ title: e.message || t('agent.summarize.fail'), icon: 'none' })
  }
  loading.value = false
}

function copySummary() {
  uni.setClipboardData({ data: summaryText.value })
}
function editSummary() {
  uni.showToast({ title: t('agent.editHint'), icon: 'none' })
}

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.page-agent {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}
.agent-content {
  flex: 1;
  padding: 24rpx 32rpx;
}
.panel-title {
  font-size: 30rpx;
  font-weight: 600;
  display: block;
  margin-bottom: 8rpx;
}
.panel-desc {
  font-size: 24rpx;
  color: var(--text-3);
  display: block;
  margin-bottom: 24rpx;
}
.scope-hd {
  font-size: 22rpx;
  font-weight: 600;
  color: var(--text-3);
  display: flex;
  align-items: center;
  gap: 10rpx;
  margin-bottom: 16rpx;
}
.scope-select {
  padding: 14rpx 20rpx;
  border: 1rpx solid var(--border);
  border-radius: 12rpx;
  font-size: 26rpx;
  background: var(--input-bg);
}
.result-hd {
  font-size: 24rpx;
  font-weight: 600;
  color: var(--text-3);
  display: block;
  margin-bottom: 16rpx;
}
</style>



