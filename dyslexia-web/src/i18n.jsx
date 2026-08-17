import React, { createContext, useContext, useState, useCallback } from 'react'

// Minimal i18n: no dependency. All user-facing strings live here as a
// per-locale catalog (best practice: one source of truth per language,
// switched at runtime). Add a language by adding a key block below.
export const LANGS = [
  { code: 'en', label: 'English' },
  { code: 'id', label: 'Bahasa Indonesia' },
]

const STRINGS = {
  en: {
    'input.placeholder': 'Paste text and press Format…',
    'btn.format': 'Format',
    'btn.openPdf': 'Open PDF',
    'btn.sample': 'Sample',
    'btn.selectAll': 'Select all',
    'section.font': 'Font',
    'section.typography': 'Typography',
    'section.background': 'Background',
    'section.accessibility': 'Accessibility',
    'section.language': 'Language',
    'ctrl.size': 'Size',
    'ctrl.lineHeight': 'Line Height',
    'ctrl.letterSpacing': 'Letter Spacing',
    'ctrl.wordSpacing': 'Word Spacing',
    'a11y.ruler': 'Reading Ruler',
    'a11y.syllables': 'Syllable Dots',
  },
  id: {
    'input.placeholder': 'Tempel teks lalu tekan Format…',
    'btn.format': 'Format',
    'btn.openPdf': 'Buka PDF',
    'btn.sample': 'Contoh',
    'btn.selectAll': 'Pilih semua',
    'section.font': 'Huruf',
    'section.typography': 'Tipografi',
    'section.background': 'Latar Belakang',
    'section.accessibility': 'Aksesibilitas',
    'section.language': 'Bahasa',
    'ctrl.size': 'Ukuran',
    'ctrl.lineHeight': 'Tinggi Baris',
    'ctrl.letterSpacing': 'Jarak Huruf',
    'ctrl.wordSpacing': 'Jarak Kata',
    'a11y.ruler': 'Penggaris Baca',
    'a11y.syllables': 'Titik Suku Kata',
  },
}

const STORAGE_KEY = 'app_locale'
const DEFAULT = 'en'

function initialLocale() {
  const saved = typeof localStorage !== 'undefined' && localStorage.getItem(STORAGE_KEY)
  return STRINGS[saved] ? saved : DEFAULT
}

const I18nContext = createContext({ locale: DEFAULT, setLocale: () => {}, t: (k) => k })

export function I18nProvider({ children }) {
  const [locale, setLocaleState] = useState(initialLocale)

  const setLocale = useCallback((code) => {
    if (!STRINGS[code]) return
    setLocaleState(code)
    try { localStorage.setItem(STORAGE_KEY, code) } catch { /* ignore */ }
  }, [])

  // Fall back to English, then the raw key, so a missing translation never
  // renders blank.
  const t = useCallback(
    (key) => STRINGS[locale]?.[key] ?? STRINGS.en[key] ?? key,
    [locale],
  )

  return (
    <I18nContext.Provider value={{ locale, setLocale, t }}>
      {children}
    </I18nContext.Provider>
  )
}

export const useI18n = () => useContext(I18nContext)
