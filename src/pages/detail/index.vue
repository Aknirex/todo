<template>
  <view class="page-detail">
    <view class="field">
      <text class="label">标题</text>
      <input class="input" v-model="form.title" placeholder="输入标题" />
    </view>

    <view class="field">
      <text class="label">优先级</text>
      <view class="priority-picker">
        <view
          v-for="p in priorities"
          :key="p.value"
          :class="['priority-option', form.priority === p.value ? 'active' : '', `p-${p.value}`]"
          @tap="form.priority = p.value"
        >
          <text>{{ p.label }}</text>
        </view>
      </view>
    </view>

    <view class="field">
      <text class="label">截止日期</text>
      <picker mode="date" :value="form.dueDate || ''" @change="onDateChange">
        <view class="picker-display">
          <text>{{ form.dueDate || '选择日期' }}</text>
        </view>
      </picker>
    </view>

    <view class="field">
      <text class="label">标签</text>
      <view class="tags">
        <view class="tag" v-for="(tag, i) in form.tags" :key="i">
          <text>{{ tag }}</text>
          <text class="tag-remove" @tap="removeTag(i)">×</text>
        </view>
      </view>
      <view class="tag-add">
        <input class="tag-input" v-model="newTag" placeholder="添加标签" @confirm="addTag" />
      </view>
    </view>

    <view class="field">
      <text class="label">详情</text>
      <textarea class="textarea" v-model="form.detail" placeholder="补充详情..." />
    </view>

    <view class="actions">
      <view class="btn-save" @tap="handleSave">
        <text class="btn-text">保存</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useTodoStore } from '@/stores'
import type { Priority } from '@/types'

const todoStore = useTodoStore()
const todoId = ref('')

const priorities = [
  { value: 'high' as Priority, label: '高' },
  { value: 'medium' as Priority, label: '中' },
  { value: 'low' as Priority, label: '低' }
]

const form = reactive({
  title: '',
  priority: 'medium' as Priority,
  dueDate: null as string | null,
  tags: [] as string[],
  detail: ''
})

const newTag = ref('')

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

function onDateChange(e: any) {
  form.dueDate = e.detail.value || null
}

function addTag() {
  const tag = newTag.value.trim()
  if (tag && !form.tags.includes(tag)) {
    form.tags.push(tag)
  }
  newTag.value = ''
}

function removeTag(index: number) {
  form.tags.splice(index, 1)
}

async function handleSave() {
  if (todoId.value) {
    await todoStore.updateTodo(todoId.value, {
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
  padding: 30rpx;
  background: #f5f5f5;
  min-height: 100vh;
}

.field {
  margin-bottom: 32rpx;
}

.label {
  font-size: 26rpx;
  color: #666;
  margin-bottom: 12rpx;
  display: block;
}

.input {
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
}

.priority-picker {
  display: flex;
  gap: 16rpx;
}

.priority-option {
  flex: 1;
  padding: 16rpx;
  text-align: center;
  border-radius: 8rpx;
  font-size: 26rpx;
  background: #fff;
  border: 2rpx solid #eee;
}

.priority-option.active.p-high {
  background: #ffeaea;
  border-color: #e74c3c;
  color: #e74c3c;
}

.priority-option.active.p-medium {
  background: #fff3e0;
  border-color: #f39c12;
  color: #f39c12;
}

.priority-option.active.p-low {
  background: #e8f5e9;
  border-color: #27ae60;
  color: #27ae60;
}

.picker-display {
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  color: #333;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
  margin-bottom: 12rpx;
}

.tag {
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding: 8rpx 16rpx;
  background: #e8f0fe;
  border-radius: 6rpx;
  font-size: 24rpx;
  color: #4a90d9;
}

.tag-remove {
  font-size: 28rpx;
  color: #999;
}

.tag-input {
  padding: 16rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 26rpx;
}

.textarea {
  padding: 20rpx 24rpx;
  background: #fff;
  border-radius: 12rpx;
  font-size: 28rpx;
  min-height: 200rpx;
  width: 100%;
  box-sizing: border-box;
}

.actions {
  margin-top: 60rpx;
}

.btn-save {
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
