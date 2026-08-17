import React from 'react'
import { FONTS, COLORS } from '../constants'
import { useI18n, LANGS } from '../i18n'
import styles from './Sidebar.module.css'

function Toggle({ on, onClick }) {
  return (
    <button
      className={`${styles.tog} ${on ? styles.togOn : ''}`}
      onClick={onClick}
      aria-pressed={on}
    />
  )
}

export default function Sidebar({
  font, setFont,
  fontSize, setFontSize,
  lineHeight, setLineHeight,
  letterSpacing, setLetterSpacing,
  wordSpacing, setWordSpacing,
  colorId, setColorId,
  ruler, setRuler,
  syllables, setSyllables,
}) {
  const { t, locale, setLocale } = useI18n()

  const sliders = [
    { key: 'ctrl.size',          val: fontSize,      set: setFontSize,      min: 14,  max: 36,  step: 1,   unit: 'px' },
    { key: 'ctrl.lineHeight',    val: lineHeight,     set: setLineHeight,    min: 1.2, max: 3.0, step: 0.1, unit: ''   },
    { key: 'ctrl.letterSpacing', val: letterSpacing,  set: setLetterSpacing, min: 0,   max: 6,   step: 0.5, unit: 'px' },
    { key: 'ctrl.wordSpacing',   val: wordSpacing,    set: setWordSpacing,   min: 0,   max: 20,  step: 1,   unit: 'px' },
  ]

  return (
    <aside className={styles.sidebar}>
      {/* Font */}
      <div className={styles.section}>
        <div className={styles.label}>{t('section.font')}</div>
        <div className={styles.fontList}>
          {FONTS.map((f) => (
            <div
              key={f.id}
              className={`${styles.fontItem} ${font === f.id ? styles.fontSel : ''}`}
              style={{ fontFamily: f.css }}
              onClick={() => setFont(f.id)}
            >
              {f.label}
            </div>
          ))}
        </div>
      </div>

      {/* Typography */}
      <div className={styles.section}>
        <div className={styles.label}>{t('section.typography')}</div>
        {sliders.map((ctrl) => (
          <div className={styles.ctrl} key={ctrl.key}>
            <div className={styles.ctrlRow}>
              <strong>{t(ctrl.key)}</strong>
              <span>{+ctrl.val.toFixed(1)}{ctrl.unit}</span>
            </div>
            <input
              type="range"
              min={ctrl.min}
              max={ctrl.max}
              step={ctrl.step}
              value={ctrl.val}
              onChange={(e) => ctrl.set(+e.target.value)}
            />
          </div>
        ))}
      </div>

      {/* Background */}
      <div className={styles.section}>
        <div className={styles.label}>{t('section.background')}</div>
        <div className={styles.colorGrid}>
          {COLORS.map((c) => (
            <div
              key={c.id}
              className={`${styles.swatch} ${colorId === c.id ? styles.swatchSel : ''}`}
              style={{ background: c.bg }}
              title={c.label}
              onClick={() => setColorId(c.id)}
            />
          ))}
        </div>
      </div>

      {/* Accessibility */}
      <div className={styles.section}>
        <div className={styles.label}>{t('section.accessibility')}</div>
        <div className={styles.togRow}>
          <span>{t('a11y.ruler')}</span>
          <Toggle on={ruler} onClick={() => setRuler((v) => !v)} />
        </div>
        <div className={styles.togRow}>
          <span>{t('a11y.syllables')}</span>
          <Toggle on={syllables} onClick={() => setSyllables((v) => !v)} />
        </div>
      </div>

      {/* Language */}
      <div className={styles.section}>
        <div className={styles.label}>{t('section.language')}</div>
        <div className={styles.fontList}>
          {LANGS.map((l) => (
            <div
              key={l.code}
              className={`${styles.fontItem} ${locale === l.code ? styles.fontSel : ''}`}
              onClick={() => setLocale(l.code)}
              role="button"
              aria-pressed={locale === l.code}
            >
              {l.label}
            </div>
          ))}
        </div>
      </div>
    </aside>
  )
}
