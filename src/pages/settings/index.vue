<template>
  <view class="page-settings">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">←</view>
      <text class="topbar-title">设置</text>
    </view>

    <scroll-view scroll-y class="settings-content">
      <!-- AI Config -->
      <view class="settings-group">
        <text class="settings-group-hd">AI 配置</text>
        <view class="settings-row" @tap="goLlmSetup">
          <text class="label">🔑 API Key</text>
          <text class="value">
            <text v-if="agentStore.configured" style="color:var(--success)">已配置 ✓</text>
            <text v-else>未配置</text>
          </text>
        </view>
        <view class="settings-row">
          <text class="label">☁️ 提供商</text>
          <text class="value">{{ agentStore.config.provider || '—' }}</text>
        </view>
        <view class="settings-row">
          <text class="label">🧠 模型</text>
          <text class="value">{{ agentStore.config.model || '—' }}</text>
        </view>
      </view>

      <!-- Agent API -->
      <view class="settings-group">
        <text class="settings-group-hd">Agent API</text>
        <view class="settings-row">
          <text class="label">🖥️ API 服务</text>
          <text class="value">未启动</text>
        </view>
        <view class="settings-row">
          <text class="label">🔑 API Key</text>
          <text class="value">点击生成 ›</text>
        </view>
      </view>

      <!-- Appearance -->
      <view class="settings-group">
        <text class="settings-group-hd">外观</text>
        <view class="settings-row" @tap="toggleTheme">
          <text class="label">🌙 深色模式</text>
          <view :class="['toggle', isDark ? 'on' : '']"></view>
        </view>
      </view>

      <!-- Data -->
      <view class="settings-group">
        <text class="settings-group-hd">数据</text>
        <view class="settings-row">
          <text class="label">↩️ 撤销历史</text>
          <text class="value">{{ undoStore.undoStack.length }} / 50</text>
        </view>
        <view class="settings-row" @tap="goExport">
          <text class="label">📥 导出数据</text>
          <text class="value">›</text>
        </view>
      </view>

      <!-- About -->
      <view class="settings-group">
        <text class="settings-group-hd">关于</text>
        <view class="settings-row">
          <text class="label">ℹ️ 版本</text>
          <text class="value">v0.1.0</text>
        </view>
        <view class="settings-row" @tap="goLicense">
          <text class="label">⚖️ 许可协议</text>
          <text class="value">›</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAgentStore, useUndoStore } from '@/stores'

const agentStore = useAgentStore()
const undoStore = useUndoStore()
const isDark = ref(false)

onMounted(async () => {
  await agentStore.loadConfig()
})

function toggleTheme() {
  isDark.value = !isDark.value
  // UniApp theme switching would go here
}

function goBack() { uni.navigateBack() }
function goLlmSetup() { uni.navigateTo({ url: '/pages/settings/llm-setup' }) }
function goExport() { uni.navigateTo({ url: '/pages/share/index' }) }
function goLicense() { uni.navigateTo({ url: '/pages/settings/license' }) }
</script>

<style scoped>
.page-settings {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}
.settings-content {
  flex: 1;
  padding: 24rpx 32rpx;
}
</style>
