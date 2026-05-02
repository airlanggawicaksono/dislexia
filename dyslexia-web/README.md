# DyslexiaReader — Web

A dyslexia-friendly reading app for the web. Paste text or open a PDF and read it with full control over font, spacing, background colour, and accessibility tools.

## Features

- 11 fonts including OpenDyslexic, Lexend, Comic Sans MS, and more
- 10 background colour themes (Peach, Sage, Lime, Light Sage, Lavender, Moss, Stone, Amber, Dark Mode, White)
- Font size, line height, letter spacing, and word spacing controls
- PDF upload with text extraction (drag & drop or file picker)
- Reading ruler that follows your cursor
- Syllable dots to help decode longer words

## Getting Started

### Requirements
- Node.js 18+
- npm or yarn

### Install & run

```bash
npm install
npm run dev
```

Then open http://localhost:5173 in your browser.

### Build for production

```bash
npm run build
```

Output goes to the `dist/` folder. Deploy that folder to any static host:
- **Vercel**: `vercel --prod`
- **Netlify**: drag the `dist/` folder into the Netlify dashboard
- **GitHub Pages**: push `dist/` to the `gh-pages` branch

## Project Structure

```
src/
  components/
    Topbar.jsx        # Top bar — paste input, PDF button, sample button
    Topbar.module.css
    Sidebar.jsx       # Settings panel — fonts, sliders, colours, toggles
    Sidebar.module.css
    Reader.jsx        # Main reading area — text display, drag & drop, ruler
    Reader.module.css
  hooks/
    usePdfExtract.js  # PDF.js text extraction hook
  constants.js        # FONTS, COLORS, SAMPLE_TEXT
  App.jsx             # Root component — all state lives here
  App.css
  index.css           # Global reset
  main.jsx            # React entry point
index.html
vite.config.js
package.json
```

## Notes

- PDFs must have a real text layer for extraction to work. Scanned/image PDFs require OCR and are not currently supported.
- Sassoon and Weezer fonts are not available on Google Fonts — if you have the font files, add them via `@font-face` in `index.css`.
