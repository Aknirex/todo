<template>
  <image class="app-icon" :src="src" :style="sizeStyle" mode="aspectFit" />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ICONS } from './icons'
import { LIGHT_VARS, DARK_VARS, useTheme } from '@/composables/useTheme'

const props = withDefaults(
  defineProps<{
    name: string
    size?: number | string
    color?: string
  }>(),
  { name: '', size: 18, color: '#8f959e' }
)

const { isDarkMode } = useTheme()

const sizeStyle = computed(() => ({
  width: typeof props.size === 'number' ? props.size + 'px' : props.size,
  height: typeof props.size === 'number' ? props.size + 'px' : props.size
}))

const src = computed(() => {
  const vars = isDarkMode.value ? DARK_VARS : LIGHT_VARS
  const fallback = isDarkMode.value ? LIGHT_VARS : DARK_VARS
  let color = props.color
  if (color.startsWith('var(--')) {
    const key = color.slice(4, -1)
    color = vars[key] || fallback[key] || '#8f959e'
  }
  const inner = (ICONS[props.name] || '').replace(/currentColor/g, color)
  if (!inner) return ''
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' +
    color +
    '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
    inner +
    '</svg>'
  return 'data:image/svg+xml;base64,' + toBase64(svg)
})

function toBase64(str: string): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  let out = ''
  for (let i = 0; i < str.length; i += 3) {
    const c1 = str.charCodeAt(i)
    const c2 = i + 1 < str.length ? str.charCodeAt(i + 1) : NaN
    const c3 = i + 2 < str.length ? str.charCodeAt(i + 2) : NaN
    out += chars[c1 >> 2]
    out += chars[((c1 & 3) << 4) | (isNaN(c2) ? 0 : c2 >> 4)]
    out += isNaN(c2) ? '=' : chars[((c2 & 15) << 2) | (isNaN(c3) ? 0 : c3 >> 6)]
    out += isNaN(c3) ? '=' : chars[c3 & 63]
  }
  return out
}
</script>

<style scoped>
.app-icon {
  flex-shrink: 0;
}
</style>
