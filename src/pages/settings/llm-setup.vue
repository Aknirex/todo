<template>
  <view class="page-llm" :style="themeVars">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">{{ $t('llm.title') }}</text>
    </view>

    <scroll-view scroll-y class="llm-content">
      <view style="text-align:center;padding:32rpx 0 40rpx">
        <text class="ai-icon" style="font-size:96rpx">AI</text>
        <text class="heading">{{ $t('llm.heading') }}</text>
        <text class="sub">{{ $t('llm.sub') }}</text>
      </view>

      <!-- Provider Cards -->
      <view
        v-for="p in providers"
        :key="p.id"
        :class="['provider-card', selectedProvider === p.id ? 'selected' : '']"
        @tap="selectProvider(p)"
      >
        <text class="provider-name">
          <text :style="{ color: p.color }">●</text>
          {{ p.name }}
          <text v-if="p.recommended" class="rec-badge">{{ $t('llm.recommended') }}</text>
        </text>
        <text class="provider-desc">{{ p.desc }}</text>
        <text v-if="p.price" class="provider-price">{{ p.price }}</text>
      </view>

      <!-- API Key Input -->
      <view style="margin-top:32rpx">
        <text style="font-size:24rpx;color:var(--text-3)">{{ $t('llm.apiKey') }}</text>
        <input
          class="key-input"
          v-model="apiKey"
          type="text"
          password
          :placeholder="$t('llm.keyPlaceholder')"
        />
      </view>

      <view class="btn btn-primary" style="width:100%;margin-top:28rpx" @tap="saveConfig">
        {{ $t('llm.save') }}
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAgentStore } from '@/stores'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'

const { t } = useI18n()
const { themeVars } = useTheme()

const agentStore = useAgentStore()

const providers = [
  { id: 'deepseek', name: 'DeepSeek', desc: '国内首选，性能强，价格极低', price: '约 ¥0.001 / 次调用', color: 'var(--success)', recommended: true, baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat' },
  { id: 'mimo', name: '小米 Mimo', desc: '小米生态用户便利', price: '约 ¥0.002 / 次调用', color: 'var(--primary)', recommended: false, baseUrl: 'https://api.mimo.xiaomi.com/v1', model: 'mimo-chat' },
  { id: 'custom', name: '其他 OpenAI 兼容', desc: '支持任何 OpenAI 兼容接口', price: '', color: 'var(--text-3)', recommended: false, baseUrl: '', model: '' }
]

const selectedProvider = ref('deepseek')
const apiKey = ref('')
const baseUrl = ref('https://api.deepseek.com/v1')
const model = ref('deepseek-chat')

onMounted(async () => {
  await agentStore.loadConfig()
  if (agentStore.config.provider) {
    selectedProvider.value = agentStore.config.provider
    apiKey.value = agentStore.config.apiKey || ''
    baseUrl.value = agentStore.config.baseUrl || ''
    model.value = agentStore.config.model || ''
  }
})

function selectProvider(p: typeof providers[0]) {
  selectedProvider.value = p.id
  baseUrl.value = p.baseUrl
  model.value = p.model
}

async function saveConfig() {
  if (!apiKey.value.trim()) {
    uni.showToast({ title: t('llm.needKey'), icon: 'none' })
    return
  }
  agentStore.config.provider = selectedProvider.value
  agentStore.config.apiKey = apiKey.value.trim()
  agentStore.config.baseUrl = baseUrl.value
  agentStore.config.model = model.value
  await agentStore.saveConfig()
  uni.showToast({ title: t('llm.saved'), icon: 'success' })
  setTimeout(() => uni.navigateBack(), 1000)
}

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.page-llm {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}
.llm-content {
  flex: 1;
  padding: 24rpx 32rpx;
}
.heading {
  display: block;
  font-size: 36rpx;
  font-weight: 600;
  margin: 20rpx 0 8rpx;
}
.sub {
  display: block;
  font-size: 26rpx;
  color: var(--text-3);
}
.provider-card.selected {
  border-left-color: var(--primary-hover);
  box-shadow: var(--shadow-lg);
}
.provider-name {
  font-size: 28rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.rec-badge {
  font-size: 22rpx;
  font-weight: 400;
  color: var(--text-3);
}
.provider-desc {
  font-size: 24rpx;
  color: var(--text-3);
  display: block;
}
.provider-price {
  font-size: 24rpx;
  color: var(--primary);
  font-weight: 600;
  display: block;
  margin-top: 8rpx;
}
.key-input {
  width: 100%;
  padding: 20rpx 24rpx;
  border: 1rpx solid var(--border);
  border-radius: 16rpx;
  font-size: 26rpx;
  margin-top: 8rpx;
  background: var(--input-bg);
  color: var(--text);
  box-sizing: border-box;
}
</style>

