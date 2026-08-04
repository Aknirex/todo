<template>
  <view class="page-detail" :style="themeVars">
    <!-- Topbar -->
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">{{ $t('detail.title') }}</text>
      <view class="topbar-actions">
        <view class="undo-redo">
          <view class="icon-btn" @tap="handleUndo">
            <AppIcon name="undo-2" :size="18" color="var(--text-2)" />
            <text v-if="undoCount > 0" class="badge">{{ undoCount }}</text>
          </view>
        </view>
        <view class="icon-btn danger" @tap="handleDelete">
          <AppIcon name="trash-2" :size="18" color="var(--text-2)" />
        </view>
      </view>
    </view>

    <scroll-view scroll-y class="detail-content">
      <!-- Basic Fields -->
      <view class="settings-group">
        <view class="settings-row">
          <view class="label"><text>{{ $t('detail.fieldTitle') }}</text></view>
          <input
            class="field-input"
            v-model="form.title"
            :placeholder="$t('detail.titlePlaceholder')"
            style="text-align:right"
          />
        </view>
        <view class="settings-row">
          <view class="label"><text>{{ $t('detail.fieldPriority') }}</text></view>
          <view style="display:flex;gap:6rpx">
            <view :class="['pill', form.priority === 'high' ? 'active-h' : '']" @tap="form.priority = 'high'">H</view>
            <view :class="['pill', form.priority === 'medium' ? 'active-m' : '']" @tap="form.priority = 'medium'">M</view>
            <view :class="['pill', form.priority === 'low' ? 'active-l' : '']" @tap="form.priority = 'low'">L</view>
          </view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="calendar" :size="14" color="var(--text-3)" />
            <text>{{ $t('detail.fieldDue') }}</text>
          </view>
          <picker mode="date" :value="form.dueDate || ''" @change="onDateChange">
            <text class="value">{{ form.dueDate || $t('detail.selectDate') }}</text>
          </picker>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="tag" :size="14" color="var(--text-3)" />
            <text>{{ $t('detail.fieldTags') }}</text>
          </view>
          <view style="display:flex;gap:8rpx;flex-wrap:wrap;justify-content:flex-end">
            <text v-for="(tag, i) in form.tags" :key="i" class="todo-tag" @tap="removeTag(i)">{{ tag }} ×</text>
            <text class="todo-tag" style="background:var(--card-hover);color:var(--text-3)" @tap="showTagInput = !showTagInput">{{ $t('detail.addTag') }}</text>
          </view>
        </view>
        <view v-if="showTagInput" class="settings-row">
          <input v-model="newTag" :placeholder="$t('detail.tagPlaceholder')" style="font-size:26rpx;flex:1" @confirm="addTag" />
        </view>
      </view>

      <!-- Detail -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('detail.detail') }}</text>
        <view style="padding:16rpx 28rpx 28rpx">
          <textarea
            class="detail-textarea"
            v-model="form.detail"
            :placeholder="$t('detail.detailPlaceholder')"
          />
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useTodoStore, useUndoStore } from '@/stores'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'
import type { Priority } from '@/types'

const { t } = useI18n()
const { themeVars } = useTheme()

const todoStore = useTodoStore()
const undoStore = useUndoStore()
const todoId = ref('')
const showTagInput = ref(false)
const newTag = ref('')

const undoCount = computed(() => undoStore.undoStack.length)

const form = reactive({
  title: '',
  priority: 'medium' as Priority,
  dueDate: null as string | null,
  tags: [] as string[],
  detail: ''
})

onMounted(() => {
  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  const id = page.$page?.options?.id || page.options?.id
  if (id) {
    todoId.value = id
    const todo = todoStore.todos.find(t => t.id === id)
    if (todo) {
      form.title = todo.title
      form.priority = todo.priority
      form.dueDate = todo.dueDate
      form.tags = [...todo.tags]
      form.detail = todo.detail
    }
  }
})

function onDateChange(e: any) { form.dueDate = e.detail.value || null }
function addTag() {
  const tag = newTag.value.trim()
  if (tag && !form.tags.includes(tag)) form.tags.push(tag)
  newTag.value = ''
}
function removeTag(i: number) { form.tags.splice(i, 1) }

async function handleDelete() {
  if (!todoId.value) return
  uni.showModal({
    title: t('detail.deleteTitle'),
    content: t('detail.deleteContent'),
    confirmColor: '#ef4444',
    success: async (res: any) => {
      if (!res.confirm) return
      await todoStore.deleteTodo(todoId.value)
      uni.navigateBack()
    }
  })
}

async function handleUndo() {
  await undoStore.undo()
  await todoStore.loadTodos()
  // Reload form
  if (todoId.value) {
    const todo = todoStore.todos.find(t => t.id === todoId.value)
    if (todo) {
      form.title = todo.title
      form.priority = todo.priority
      form.dueDate = todo.dueDate
      form.tags = [...todo.tags]
      form.detail = todo.detail
    }
  }
}

function goBack() {
  // Save on back
  if (todoId.value) {
    todoStore.updateTodo(todoId.value, {
      title: form.title,
      priority: form.priority,
      dueDate: form.dueDate,
      tags: form.tags,
      detail: form.detail
    })
  }
  uni.navigateBack()
}
</script>

<style scoped>
.page-detail {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}
.detail-content {
  flex: 1;
  padding: 24rpx 32rpx;
}
.field-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 26rpx;
  background: transparent;
  color: var(--text);
  min-width: 0;
}
.detail-textarea {
  width: 100%;
  min-height: 160rpx;
  border: none;
  padding: 0;
  font-size: 26rpx;
  background: transparent;
  color: var(--text);
  box-sizing: border-box;
}
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


