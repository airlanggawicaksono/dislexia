import React, { useRef } from 'react'
import styles from './Topbar.module.css'

export default function Topbar({ inputVal, setInputVal, onFormat, onPdfFile, onSample }) {
  const fileRef = useRef()

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') onFormat()
  }

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) onPdfFile(file)
    e.target.value = ''
  }

  return (
    <header className={styles.topbar}>
      <div className={styles.logo}>
        Clear<em>Read</em>
      </div>

      <div className={styles.pasteRow}>
        <input
          type="text"
          value={inputVal}
          onChange={(e) => setInputVal(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Paste text and press Format…"
          className={styles.input}
        />
        <button
          className={styles.fmtBtn}
          onClick={onFormat}
          disabled={!inputVal.trim()}
        >
          Format
        </button>
        <button className={styles.pdfBtn} onClick={() => fileRef.current.click()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
            strokeLinecap="round" strokeLinejoin="round" width="14" height="14">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
            <polyline points="14 2 14 8 20 8" />
          </svg>
          Open PDF
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
        Sample
      </button>
    </header>
  )
}
