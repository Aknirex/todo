<template>
  <view class="page-license" :style="themeVars">
    <view class="topbar">
      <view class="icon-btn" @tap="goBack">
        <AppIcon name="arrow-left" :size="18" color="var(--text-2)" />
      </view>
      <text class="topbar-title">许可协议</text>
    </view>

    <view class="license-content">
      <view class="license-card">
        <text class="license-title">MIT License</text>
        <text class="license-subtitle">Copyright (c) 2026 aknirex-todo</text>
        <text class="license-body">
          Permission is hereby granted, free of charge, to any person obtaining a copy
          of this software and associated documentation files (the "Software"), to deal
          in the Software without restriction, including without limitation the rights
          to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
          copies of the Software, and to permit persons to whom the Software is
          furnished to do so, subject to the following conditions:

          The above copyright notice and this permission notice shall be included in all
          copies or substantial portions of the Software.

          THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
          IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
          FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
          AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
          LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
          OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
          SOFTWARE.
        </text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useTheme } from '@/composables/useTheme'
import AppIcon from '@/components/AppIcon.vue'

const { themeVars } = useTheme()

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.page-license {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}

.license-content {
  padding: 30rpx;
}

.license-card {
  background: var(--card);
  border-radius: var(--radius);
  padding: 40rpx 30rpx;
  box-shadow: var(--shadow);
}

.license-title {
  font-size: 36rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.license-subtitle {
  font-size: 24rpx;
  color: var(--text-3);
  display: block;
  margin-bottom: 32rpx;
}

.license-body {
  font-size: 26rpx;
  color: var(--text-2);
  line-height: 1.8;
  white-space: pre-wrap;
}
</style>
