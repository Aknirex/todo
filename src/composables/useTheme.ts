import { computed, ref } from 'vue'

const STORAGE_KEY = 'aknirex-theme'

export interface ThemeVars {
  [key: string]: string
}

export const LIGHT_VARS: ThemeVars = {
  '--bg': '#f2f3f5',
  '--card': '#ffffff',
  '--card-hover': '#f7f8fa',
  '--text': '#1a1a1a',
  '--text-2': '#555666',
  '--text-3': '#8f959e',
  '--border': '#e5e6eb',
  '--border-light': '#f0f1f2',
  '--primary': '#2563eb',
  '--primary-hover': '#1d4ed8',
  '--primary-light': '#eff6ff',
  '--primary-bg': 'rgba(37,99,235,0.08)',
  '--danger': '#ef4444',
  '--danger-light': 'rgba(239,68,68,0.08)',
  '--warning': '#f59e0b',
  '--warning-light': 'rgba(245,158,11,0.08)',
  '--success': '#22c55e',
  '--success-light': 'rgba(34,197,94,0.08)',
  '--input-bg': '#f2f3f5',
  '--checkbox-border': '#c9cdd4',
  '--scrollbar-thumb': '#d1d5db',
  '--overlay': 'rgba(0,0,0,0.3)',
  '--dropdown-bg': '#ffffff',
  '--dropdown-shadow': '0 8px 24px rgba(0,0,0,0.12)',
  '--sidebar-bg': 'rgba(255,255,255,0.45)',
  '--sidebar-hover': 'rgba(242,243,245,0.4)',
  '--sidebar-active': '#eff6ff',
  '--sidebar-active-text': '#2563eb',
  '--search-blur': 'rgba(242,243,245,0.85)',
  '--shadow': '0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)',
  '--shadow-lg': '0 4px 12px rgba(0,0,0,0.08)'
}

export const DARK_VARS: ThemeVars = {
  '--bg': '#111113',
  '--card': '#1c1c1e',
  '--card-hover': '#252528',
  '--text': '#e5e5e7',
  '--text-2': '#a1a1aa',
  '--text-3': '#71717a',
  '--border': '#2e2e32',
  '--border-light': '#232326',
  '--primary': '#3b82f6',
  '--primary-hover': '#60a5fa',
  '--primary-light': 'rgba(59,130,246,0.12)',
  '--primary-bg': 'rgba(59,130,246,0.1)',
  '--danger': '#f87171',
  '--danger-light': 'rgba(248,113,113,0.12)',
  '--warning': '#fbbf24',
  '--warning-light': 'rgba(251,191,36,0.12)',
  '--success': '#4ade80',
  '--success-light': 'rgba(74,222,128,0.12)',
  '--input-bg': '#27272a',
  '--checkbox-border': '#52525b',
  '--scrollbar-thumb': '#3f3f46',
  '--overlay': 'rgba(0,0,0,0.5)',
  '--dropdown-bg': '#27272a',
  '--dropdown-shadow': '0 8px 24px rgba(0,0,0,0.4)',
  '--sidebar-bg': 'rgba(24,24,27,0.45)',
  '--sidebar-hover': 'rgba(39,39,42,0.4)',
  '--sidebar-active': 'rgba(59,130,246,0.12)',
  '--sidebar-active-text': '#3b82f6',
  '--search-blur': 'rgba(17,17,19,0.88)',
  '--shadow': '0 1px 3px rgba(0,0,0,0.2), 0 1px 2px rgba(0,0,0,0.1)',
  '--shadow-lg': '0 4px 12px rgba(0,0,0,0.3)'
}

const isDark = ref(uni.getStorageSync(STORAGE_KEY) === 'dark')

export function useTheme() {
  const themeVars = computed(() => (isDark.value ? DARK_VARS : LIGHT_VARS))
  const isDarkMode = computed(() => isDark.value)

  function setDark(v: boolean) {
    isDark.value = v
    uni.setStorageSync(STORAGE_KEY, v ? 'dark' : 'light')
    // #ifdef H5
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', v ? 'dark' : 'light')
    }
    // #endif
  }

  function toggleTheme() {
    setDark(!isDark.value)
  }

  return { themeVars, isDarkMode, setDark, toggleTheme }
}
