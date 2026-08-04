import { createI18n } from 'vue-i18n'
import zhHans from './zh-Hans'
import en from './en'

const STORAGE_KEY = 'aknirex-locale'

export const LOCALE_OPTIONS = [
  { value: 'zh-Hans', labelKey: 'settings.languageZh' },
  { value: 'en', labelKey: 'settings.languageEn' }
]

function initialLocale(): string {
  const stored = uni.getStorageSync(STORAGE_KEY)
  if (stored === 'zh-Hans' || stored === 'en') return stored
  const sys = uni.getLocale()
  return sys && sys.toLowerCase().startsWith('en') ? 'en' : 'zh-Hans'
}

const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: initialLocale(),
  fallbackLocale: 'zh-Hans',
  messages: { 'zh-Hans': zhHans, en }
})

export function setLocale(locale: string) {
  i18n.global.locale.value = locale as 'zh-Hans' | 'en'
  uni.setStorageSync(STORAGE_KEY, locale)
  uni.setLocale(locale)
}

export default i18n
