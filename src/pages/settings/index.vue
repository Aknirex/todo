<template>
  <view class="page-settings">
    <view class="section">
      <text class="section-title">LLM 配置</text>

      <view class="form-group">
        <text class="label">服务商</text>
        <picker
          :value="providerIndex"
          :range="providerOptions"
          @change="handleProviderChange"
        >
          <view class="picker-value">
            {{ providerOptions[providerIndex] || '请选择' }}
          </view>
        </picker>
      </view>

      <view class="form-group">
        <text class="label">API Key</text>
        <input
          class="input"
          v-model="agentStore.config.apiKey"
          placeholder="请输入 API Key"
          :password="!showKey"
        />
        <view class="toggle-key" @tap="showKey = !showKey">
          <text class="toggle-text">{{ showKey ? '隐藏' : '显示' }}</text>
        </view>
      </view>

      <view class="form-group">
        <text class="label">接口地址 (Base URL)</text>
        <input
          class="input"
          v-model="agentStore.config.baseUrl"
          placeholder="https://api.deepseek.com/v1"
        />
      </view>

      <view class="form-group">
        <text class="label">模型</text>
        <input
          class="input"
          v-model="agentStore.config.model"
          placeholder="deepseek-chat"
        />
      </view>

      <view class="save-btn" @tap="handleSave">
        <text class="save-text">保存配置</text>
      </view>

      <view v-if="saveMsg" class="save-msg">{{ saveMsg }}</view>
    </view>

    <view class="section">
      <text class="section-title">其他</text>
      <view class="link-item" @tap="goPage('/pages/share/index')">
        <text class="link-text">开源许可</text>
        <text class="link-arrow">></text>
      </view>
      <view class="link-item" @tap="goPage('/pages/search/index')">
        <text class="link-text">关于</text>
        <text class="link-arrow">></text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAgentStore } from '@/stores'

const agentStore = useAgentStore()
const showKey = ref(false)
const saveMsg = ref('')

const providerOptions = ['DeepSeek', '小米 Mimo', '自定义']
const providerMap: Record<string, { baseUrl: string; model: string }> = {
  deepseek: { baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat' },
  mimo: { baseUrl: 'https://api.mimo.xiaomi.com/v1', model: 'xiaomi-mimo' },
  custom: { baseUrl: '', model: '' }
}

const providerKeys = ['deepseek', 'mimo', 'custom']

const providerIndex = ref(0)

onMounted(async () => {
  await agentStore.loadConfig()
  const pIdx = providerKeys.indexOf(agentStore.config.provider || '')
  providerIndex.value = pIdx >= 0 ? pIdx : 0
})

function handleProviderChange(e: any) {
  const idx = Number(e.detail.value)
  providerIndex.value = idx
  const key = providerKeys[idx]
  agentStore.config.provider = key

  const defaults = providerMap[key]
  if (key !== 'custom') {
    agentStore.config.baseUrl = defaults.baseUrl
    agentStore.config.model = defaults.model
  } else {
    agentStore.config.baseUrl = ''
    agentStore.config.model = ''
  }
}

async function handleSave() {
  if (!agentStore.config.apiKey) {
    saveMsg.value = '请输入 API Key'
    return
  }
  try {
    await agentStore.saveConfig()
    saveMsg.value = '保存成功'
    setTimeout(() => { saveMsg.value = '' }, 2000)
  } catch (e: any) {
    saveMsg.value = e.message || '保存失败'
  }
}

function goPage(url: string) {
  uni.navigateTo({ url })
}
</script>

<style scoped>
.page-settings {
  padding: 30rpx;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.section {
  background: #fff;
  border-radius: 12rpx;
  padding: 30rpx;
  margin-bottom: 30rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 30rpx;
  display: block;
}

.form-group {
  margin-bottom: 30rpx;
}

.label {
  font-size: 26rpx;
  color: #666;
  margin-bottom: 12rpx;
  display: block;
}

.input {
  padding: 20rpx 24rpx;
  background: #f5f5f5;
  border-radius: 8rpx;
  font-size: 28rpx;
  color: #333;
}

.picker-value {
  padding: 20rpx 24rpx;
  background: #f5f5f5;
  border-radius: 8rpx;
  font-size: 28rpx;
  color: #333;
}

.toggle-key {
  margin-top: 8rpx;
  display: inline-block;
}

.toggle-text {
  font-size: 24rpx;
  color: #4a90d9;
}

.save-btn {
  margin-top: 40rpx;
  padding: 24rpx;
  background: #4a90d9;
  border-radius: 12rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.save-text {
  color: #fff;
  font-size: 30rpx;
}

.save-msg {
  margin-top: 16rpx;
  font-size: 24rpx;
  color: #27ae60;
  text-align: center;
}

.link-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24rpx 0;
  border-bottom: 1rpx solid #eee;
}

.link-item:last-child {
  border-bottom: none;
}

.link-text {
  font-size: 28rpx;
  color: #333;
}

.link-arrow {
  font-size: 28rpx;
  color: #ccc;
}
</style>
