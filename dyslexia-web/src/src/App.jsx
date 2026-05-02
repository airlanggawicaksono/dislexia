import React, { useState, useCallback } from 'react'
import Topbar from './components/Topbar'
import Sidebar from './components/Sidebar'
import Reader from './components/Reader'
import { usePdfExtract } from './hooks/usePdfExtract'
import { SAMPLE_TEXT } from './constants'
import './App.css'

export default function App() {
  // Text state
  const [inputVal, setInputVal]     = useState('')
  const [displayText, setDisplayText] = useState(SAMPLE_TEXT)

  // Typography
  const [font, setFont]                   = useState('lexend')
  const [fontSize, setFontSize]           = useState(20)
  const [lineHeight, setLineHeight]       = useState(1.85)
  const [letterSpacing, setLetterSpacing] = useState(0.5)
  const [wordSpacing, setWordSpacing]     = useState(4)

  // Theme
  const [colorId, setColorId] = useState('lavender')

  // Accessibility
  const [ruler, setRuler]         = useState(false)
  const [rulerY, setRulerY]       = useState(200)
  const [syllables, setSyllables] = useState(false)

  // PDF
  const { extract, loading, progress, pdfName, pdfPages, reset: resetPdf } = usePdfExtract()

  const onMouseMove = useCallback(
    (e) => { if (ruler) setRulerY(e.clientY - 15) },
    [ruler]
  )

  const handleFormat = () => {
    if (!inputVal.trim()) return
    setDisplayText(inputVal.trim())
    setInputVal('')
    resetPdf()
  }

  const handlePdfFile = async (file) => {
    const text = await extract(file)
    if (text) setDisplayText(text)
  }

  const handleSample = () => {
    setDisplayText(SAMPLE_TEXT)
    resetPdf()
  }

  const handleClearPdf = () => {
    setDisplayText(SAMPLE_TEXT)
    resetPdf()
  }

  return (
    <div className="app" onMouseMove={onMouseMove}>
      <Topbar
        inputVal={inputVal}
        setInputVal={setInputVal}
        onFormat={handleFormat}
        onPdfFile={handlePdfFile}
        onSample={handleSample}
      />

      <div className="main">
        <Sidebar
          font={font}               setFont={setFont}
          fontSize={fontSize}       setFontSize={setFontSize}
          lineHeight={lineHeight}   setLineHeight={setLineHeight}
          letterSpacing={letterSpacing} setLetterSpacing={setLetterSpacing}
          wordSpacing={wordSpacing} setWordSpacing={setWordSpacing}
          colorId={colorId}         setColorId={setColorId}
          ruler={ruler}             setRuler={setRuler}
          syllables={syllables}     setSyllables={setSyllables}
        />

        <Reader
          text={displayText}
          font={font}
          fontSize={fontSize}
          lineHeight={lineHeight}
          letterSpacing={letterSpacing}
          wordSpacing={wordSpacing}
          colorId={colorId}
          ruler={ruler}
          rulerY={rulerY}
          syllables={syllables}
          loading={loading}
          progress={progress}
          pdfName={pdfName}
          pdfPages={pdfPages}
          onPdfFile={handlePdfFile}
          onClearPdf={handleClearPdf}
        />
      </div>
    </div>
  )
}
