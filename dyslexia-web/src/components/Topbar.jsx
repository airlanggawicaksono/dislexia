import React, { useRef } from 'react'
import { useI18n } from '../i18n'
import styles from './Topbar.module.css'

export default function Topbar({ inputVal, setInputVal, onFormat, onPdfFile, onSample }) {
  const fileRef = useRef()
  const inputRef = useRef()
  const { t } = useI18n()

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') onFormat()
  }

  const handleSelectAll = () => {
    inputRef.current?.focus()
    inputRef.current?.select()
  }

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) onPdfFile(file)
    e.target.value = ''
  }

  return (
    <header className={styles.topbar}>
      <div className={styles.logo}>
        Dyslexia<em>Reader</em>
      </div>

      <div className={styles.pasteRow}>
        <input
          ref={inputRef}
          type="text"
          value={inputVal}
          onChange={(e) => setInputVal(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={t('input.placeholder')}
          className={styles.input}
        />
        <button
          className={styles.selBtn}
          onClick={handleSelectAll}
          disabled={!inputVal.length}
          title={t('btn.selectAll')}
        >
          {t('btn.selectAll')}
        </button>
        <button
          className={styles.fmtBtn}
          onClick={onFormat}
          disabled={!inputVal.trim()}
        >
          {t('btn.format')}
        </button>
        <button className={styles.pdfBtn} onClick={() => fileRef.current.click()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
            strokeLinecap="round" strokeLinejoin="round" width="14" height="14">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
            <polyline points="14 2 14 8 20 8" />
          </svg>
          {t('btn.openPdf')}
        </button>
        <input
          ref={fileRef}
          type="file"
          accept=".pdf,application/pdf"
          style={{ display: 'none' }}
          onChange={handleFileChange}
        />
      </div>

      <button className={styles.sampleBtn} onClick={onSample}>
        {t('btn.sample')}
      </button>
    </header>
  )
}
