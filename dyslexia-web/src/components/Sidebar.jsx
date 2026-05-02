import React from 'react'
import { FONTS, COLORS } from '../constants'
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
  const sliders = [
    { label: 'Size',           val: fontSize,      set: setFontSize,      min: 14,  max: 36,  step: 1,   unit: 'px' },
    { label: 'Line Height',    val: lineHeight,     set: setLineHeight,    min: 1.2, max: 3.0, step: 0.1, unit: ''   },
    { label: 'Letter Spacing', val: letterSpacing,  set: setLetterSpacing, min: 0,   max: 6,   step: 0.5, unit: 'px' },
    { label: 'Word Spacing',   val: wordSpacing,    set: setWordSpacing,   min: 0,   max: 20,  step: 1,   unit: 'px' },
  ]

  return (
    <aside className={styles.sidebar}>
      {/* Font */}
      <div className={styles.section}>
        <div className={styles.label}>Font</div>
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
        <div className={styles.label}>Typography</div>
        {sliders.map((ctrl) => (
          <div className={styles.ctrl} key={ctrl.label}>
            <div className={styles.ctrlRow}>
              <strong>{ctrl.label}</strong>
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
        <div className={styles.label}>Background</div>
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
        <div className={styles.label}>Accessibility</div>
        <div className={styles.togRow}>
          <span>Reading Ruler</span>
          <Toggle on={ruler} onClick={() => setRuler((v) => !v)} />
        </div>
        <div className={styles.togRow}>
          <span>Syllable Dots</span>
          <Toggle on={syllables} onClick={() => setSyllables((v) => !v)} />
        </div>
      </div>
    </aside>
  )
}
