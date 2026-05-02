import React, { useState } from 'react'
import { FONTS, COLORS } from '../constants'
import styles from './Reader.module.css'

function syllabify(word) {
  if (word.length <= 3) return word
  const vowels = 'aeiouAEIOU'
  let out = ''
  let prevWasVowel = false
  for (let i = 0; i < word.length; i++) {
    const isVowel = vowels.includes(word[i])
    if (isVowel && !prevWasVowel && i > 0 && i < word.length - 1) {
      out += '·'
    }
    out += word[i]
    prevWasVowel = isVowel
  }
  return out
}

export default function Reader({
  text,
  font, fontSize, lineHeight, letterSpacing, wordSpacing,
  colorId,
  ruler, rulerY,
  syllables,
  loading, progress,
  pdfName, pdfPages,
  onPdfFile,
  onClearPdf,
}) {
  const [dragging, setDragging] = useState(false)

  const cf = FONTS.find((f) => f.id === font)
  const cc = COLORS.find((c) => c.id === colorId)

  const paragraphs = text ? text.split(/\n+/).filter((p) => p.trim()) : []
  const wordCount  = text ? text.trim().split(/\s+/).filter(Boolean).length : 0

  const onDragOver = (e) => { e.preventDefault(); setDragging(true) }
  const onDragLeave = () => setDragging(false)
  const onDrop = (e) => {
    e.preventDefault()
    setDragging(false)
    const file = e.dataTransfer.files[0]
    if (file && file.type === 'application/pdf') onPdfFile(file)
  }

  return (
    <div className={styles.col}>
      {/* PDF banner */}
      {pdfName && !loading && (
        <div className={styles.pdfBanner}>
          <span className={styles.pdfIcon}>📄</span>
          <span className={styles.pdfName}>{pdfName}</span>
          <span className={styles.pdfPages}>{pdfPages} page{pdfPages !== 1 ? 's' : ''}</span>
          <button className={styles.pdfClear} onClick={onClearPdf}>✕ Clear</button>
        </div>
      )}

      {/* Reading ruler */}
      {ruler && (
        <div className={styles.ruler} style={{ top: rulerY }} />
      )}

      {/* Main reading area */}
      <div
        className={styles.readerWrap}
        style={{ background: cc.bg }}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
      >
        {dragging && (
          <div className={styles.dropOverlay}>
            <div className={styles.dropIcon}>📄</div>
            <div className={styles.dropText}>Drop your PDF here</div>
          </div>
        )}

        {loading ? (
          <div className={styles.loadingWrap}>
            <div className={styles.loadingLabel} style={{ color: cc.text }}>
              Extracting text… {progress}%
            </div>
            <div className={styles.loadingBg}>
              <div className={styles.loadingFill} style={{ width: `${progress}%` }} />
            </div>
          </div>
        ) : paragraphs.length > 0 ? (
          <div className={styles.inner}>
            {paragraphs.map((para, pi) => (
              <p
                key={pi}
                className={styles.para}
                style={{
                  fontFamily: cf.css,
                  fontSize: `${fontSize}px`,
                  lineHeight,
                  letterSpacing: `${letterSpacing}px`,
                  wordSpacing: `${wordSpacing}px`,
                  color: cc.text,
                }}
              >
                {para.split(/\s+/).map((word, wi) => (
                  <span key={wi} className={styles.word}>
                    {syllables ? syllabify(word) : word}{' '}
                  </span>
                ))}
              </p>
            ))}
          </div>
        ) : (
          <div className={styles.empty}>
            <div className={styles.emptyIcon}>📖</div>
            <div className={styles.emptyTitle}>Nothing to read yet</div>
            <div className={styles.emptySub}>
              Paste text above and press Format, load the sample, or open a PDF.
            </div>
            <div className={styles.emptyHint}>
              You can also drag a PDF directly onto this area
            </div>
          </div>
        )}
      </div>

      {!loading && text && (
        <div className={styles.wordCount}>
          {wordCount.toLocaleString()} words
        </div>
      )}
    </div>
  )
}
