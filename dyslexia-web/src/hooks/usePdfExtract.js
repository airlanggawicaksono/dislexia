import { useState, useCallback } from 'react'

export function usePdfExtract() {
  const [loading, setLoading]   = useState(false)
  const [progress, setProgress] = useState(0)
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
      const pdfjsLib = await import('pdfjs-dist')
      pdfjsLib.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjsLib.version}/build/pdf.worker.min.js`
      
      const arrayBuffer = await file.arrayBuffer()
      const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise
      const total = pdf.numPages
      setPdfPages(total)

      let fullText = ''
      for (let i = 1; i <= total; i++) {
        const page = await pdf.getPage(i)
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
      console.error('PDF ERROR:', err)
      setError('Could not extract text from this PDF.')
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