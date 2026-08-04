<template>
  <view class="page-settings" :style="themeVars">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">设置</text>
    </view>

    <scroll-view scroll-y class="settings-content">
      <!-- AI Config -->
      <view class="settings-group">
        <text class="settings-group-hd">AI 配置</text>
        <view class="settings-row" @tap="goLlmSetup">
          <view class="label">
            <AppIcon name="key" :size="16" color="var(--text-3)" />
            <text>API Key</text>
          </view>
          <view class="value">
            <text v-if="agentStore.configured" style="color:var(--success)">已配置</text>
            <text v-else>未配置</text>
            <AppIcon v-if="agentStore.configured" name="circle-check" :size="14" color="var(--success)" />
          </view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="cloud" :size="16" color="var(--text-3)" />
            <text>提供商</text>
          </view>
          <view class="value">{{ agentStore.config.provider || '—' }}</view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="cpu" :size="16" color="var(--text-3)" />
            <text>模型</text>
          </view>
          <view class="value">{{ agentStore.config.model || '—' }}</view>
        </view>
      </view>

      <!-- Agent API -->
      <view class="settings-group">
        <text class="settings-group-hd">Agent API</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="server" :size="16" color="var(--text-3)" />
            <text>API 服务</text>
          </view>
          <view class="value">未启动</view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="key-round" :size="16" color="var(--text-3)" />
            <text>API Key</text>
          </view>
          <view class="value">点击生成</view>
        </view>
      </view>

      <!-- Appearance -->
      <view class="settings-group">
        <text class="settings-group-hd">外观</text>
        <view class="settings-row" @tap="toggleTheme">
          <view class="label">
            <AppIcon name="moon" :size="16" color="var(--text-3)" />
            <text>深色模式</text>
          </view>
          <view :class="['toggle', isDarkMode ? 'on' : '']"></view>
        </view>
      </view>

      <!-- Data -->
      <view class="settings-group">
        <text class="settings-group-hd">数据</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="undo-2" :size="16" color="var(--text-3)" />
            <text>撤销历史</text>
          </view>
          <view class="value">{{ undoStore.undoStack.length }} / 50</view>
        </view>
        <view class="settings-row" @tap="goExport">
          <view class="label">
            <AppIcon name="download" :size="16" color="var(--text-3)" />
            <text>导出数据</text>
          </view>
          <view class="value">›</view>
        </view>
      </view>

      <!-- About -->
      <view class="settings-group">
        <text class="settings-group-hd">关于</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="info" :size="16" color="var(--text-3)" />
            <text>版本</text>
          </view>
          <view class="value">v0.1.0</view>
        </view>
        <view class="settings-row" @tap="goLicense">
          <view class="label">
            <AppIcon name="scale" :size="16" color="var(--text-3)" />
            <text>许可协议</text>
          </view>
          <view class="value">›</view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAgentStore, useUndoStore } from '@/stores'
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'

const { themeVars, isDarkMode, toggleTheme } = useTheme()

const agentStore = useAgentStore()
const undoStore = useUndoStore()

onMounted(async () => {
  await agentStore.loadConfig()
})

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




