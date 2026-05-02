import { useState, useCallback } from 'react'

// Dynamically import pdfjs so it doesn't block initial render
let pdfjsLib = null
async function getPdfjs() {
  if (pdfjsLib) return pdfjsLib
  pdfjsLib = await import('pdfjs-dist')
  // Use the bundled worker via a CDN so Vite doesn't need to copy the worker file
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js`
  return pdfjsLib
}

export function usePdfExtract() {
  const [loading, setLoading]   = useState(false)
  const [progress, setProgress] = useState(0)   // 0–100
  const [pdfName, setPdfName]   = useState('')
  const [pdfPages, setPdfPages] = useState(0)
  const [error, setError]       = useState('')

  const extract = useCallback(async (file) => {
    if (!file || file.type !== 'application/pdf') return null

    setLoading(true)
    setProgress(0)
    setError('')
    setPdfName(file.name)

    try {
      const lib = await getPdfjs()
      const arrayBuffer = await file.arrayBuffer()
      const pdf = await lib.getDocument({ data: arrayBuffer }).promise
      const total = pdf.numPages
      setPdfPages(total)

      let fullText = ''
      for (let i = 1; i <= total; i++) {
        const page    = await pdf.getPage(i)
        const content = await page.getTextContent()
        const pageText = content.items.map((item) => item.str).join(' ')
        fullText += pageText + '\n\n'
        setProgress(Math.round((i / total) * 100))
      }

      const cleaned = fullText
        .replace(/[ \t]+/g, ' ')
        .replace(/\n{3,}/g, '\n\n')
        .trim()

      setLoading(false)
      return cleaned
    } catch (err) {
      console.error(err)
      setError('Could not extract text from this PDF. It may be scanned or image-based.')
      setPdfName('')
      setPdfPages(0)
      setLoading(false)
      return null
    }
  }, [])

  const reset = useCallback(() => {
    setPdfName('')
    setPdfPages(0)
    setError('')
    setProgress(0)
  }, [])

  return { extract, loading, progress, pdfName, pdfPages, error, reset }
}
