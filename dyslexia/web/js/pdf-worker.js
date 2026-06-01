// In web/js/pdf-worker.js

let pdfjsLib = null;

async function getPdfjs() {
    if (pdfjsLib) {
        return pdfjsLib;
    }
    
    // Dynamically import the library.
    const pdfjsModule = await import('./pdfjs/pdf.min.js');
    
    // The actual library object may be on the .default property
    // if it's a CJS/UMD module wrapped in an ES module.
    pdfjsLib = pdfjsModule.default || pdfjsModule;

    if (!pdfjsLib || !pdfjsLib.GlobalWorkerOptions) {
        throw new Error('Failed to load pdf.js library correctly.');
    }

    pdfjsLib.GlobalWorkerOptions.workerSrc = './js/pdfjs/pdf.worker.min.js';
    return pdfjsLib;
}

self.onmessage = async (event) => {
    const pdfData = event.data;

    if (!pdfData || !(pdfData instanceof Uint8Array)) {
        self.postMessage({ type: 'error', message: 'Invalid or no PDF data received.' });
        return;
    }

    try {
        const pdfjs = await getPdfjs();
        const pdf = await pdfjs.getDocument({ data: pdfData }).promise;
        const totalPages = pdf.numPages;
        let fullText = '';

        for (let i = 1; i <= totalPages; i++) {
            const page = await pdf.getPage(i);
            const textContent = await page.getTextContent();
            const pageText = textContent.items.map(item => item.str).join(' ');
            fullText += pageText + '\\n\\n';

            self.postMessage({ type: 'progress', current: i, total: totalPages });
        }

        self.postMessage({ type: 'result', text: fullText.trim() });

    } catch (error) {
        self.postMessage({ type: 'error', message: error.message || 'An unknown error occurred while processing the PDF.' });
    }
};
