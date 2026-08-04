<template>
  <view class="page-settings" :style="themeVars">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">{{ $t('settings.title') }}</text>
    </view>

    <scroll-view scroll-y class="settings-content">
      <!-- AI Config -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.ai') }}</text>
        <view class="settings-row" @tap="goLlmSetup">
          <view class="label">
            <AppIcon name="key" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.apiKey') }}</text>
          </view>
          <view class="value">
            <text v-if="agentStore.configured" style="color:var(--success)">{{ $t('settings.configured') }}</text>
            <text v-else>{{ $t('settings.notConfigured') }}</text>
            <AppIcon v-if="agentStore.configured" name="circle-check" :size="14" color="var(--success)" />
          </view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="cloud" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.provider') }}</text>
          </view>
          <view class="value">{{ agentStore.config.provider || '—' }}</view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="cpu" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.model') }}</text>
          </view>
          <view class="value">{{ agentStore.config.model || '—' }}</view>
        </view>
      </view>

      <!-- Agent API -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.agentApi') }}</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="server" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.apiService') }}</text>
          </view>
          <view class="value">{{ $t('settings.notStarted') }}</view>
        </view>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="key-round" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.apiKey') }}</text>
          </view>
          <view class="value">{{ $t('settings.generate') }}</view>
        </view>
      </view>

      <!-- Appearance -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.appearance') }}</text>
        <view class="settings-row" @tap="toggleTheme">
          <view class="label">
            <AppIcon name="moon" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.darkMode') }}</text>
          </view>
          <view :class="['toggle', isDarkMode ? 'on' : '']"></view>
        </view>
      </view>

      <!-- Language -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.language') }}</text>
        <view class="settings-row" @tap="pickLanguage">
          <view class="label">
            <AppIcon name="globe" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.language') }}</text>
          </view>
          <view class="value">{{ $t(currentLocaleLabel) }} ›</view>
        </view>
      </view>

      <!-- Data -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.data') }}</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="undo-2" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.undoHistory') }}</text>
          </view>
          <view class="value">{{ undoStore.undoStack.length }} / 50</view>
        </view>
        <view class="settings-row" @tap="goExport">
          <view class="label">
            <AppIcon name="download" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.export') }}</text>
          </view>
          <view class="value">›</view>
        </view>
      </view>

      <!-- About -->
      <view class="settings-group">
        <text class="settings-group-hd">{{ $t('settings.about') }}</text>
        <view class="settings-row">
          <view class="label">
            <AppIcon name="info" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.version') }}</text>
          </view>
          <view class="value">v0.1.0</view>
        </view>
        <view class="settings-row" @tap="goLicense">
          <view class="label">
            <AppIcon name="scale" :size="16" color="var(--text-3)" />
            <text>{{ $t('settings.license') }}</text>
          </view>
          <view class="value">›</view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAgentStore, useUndoStore } from '@/stores'
import { useTheme } from '@/composables/useTheme'
import { setLocale, LOCALE_OPTIONS } from '@/locale'
import AppIcon from '@/components/AppIcon.vue'

const { t, locale } = useI18n()
const { themeVars, isDarkMode, toggleTheme } = useTheme()

const agentStore = useAgentStore()
const undoStore = useUndoStore()

const currentLocaleLabel = computed(() => {
  const opt = LOCALE_OPTIONS.find(o => o.value === locale.value)
  return opt ? opt.labelKey : 'settings.languageZh'
})

onMounted(async () => {
  await agentStore.loadConfig()
})

function pickLanguage() {
  uni.showActionSheet({
    itemList: LOCALE_OPTIONS.map(o => t(o.labelKey)),
    success: (res: any) => {
      const opt = LOCALE_OPTIONS[res.tapIndex]
      if (opt) setLocale(opt.value)
    }
  })
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




