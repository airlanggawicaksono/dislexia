// In web/js/syllabifier-worker.js

/**
 * Basic syllabification logic.
 * This is a simplified version, ideally a more robust library would be used.
 */
function syllabifyWord(word) {
    if (word.length <= 3) return word;
    const vowels = 'aeiouAEIOU';
    let out = '';
    let prevWasVowel = false;
    for (let i = 0; i < word.length; i++) {
        const isVowel = vowels.includes(word[i]);
        if (isVowel && !prevWasVowel && i > 0 && i < word.length - 1) {
            out += '-'; // Use hyphen for syllabification
        }
        out += word[i];
        prevWasVowel = isVowel;
    }
    return out;
}

/**
 * Syllabifies an entire text by splitting it into words and processing each.
 */
function syllabifyText(text) {
    const words = text.split(/(\\b)/); // Split by word boundary to preserve delimiters
    const syllabifiedWords = words.map(word => {
        // Only syllabify actual words, not spaces or punctuation
        if (word.match(/^[a-zA-Z0-9]+$/)) {
            return syllabifyWord(word);
        }
        return word;
    });
    return syllabifiedWords.join('');
}

/**
 * Listen for messages from the main Dart thread.
 */
self.onmessage = async (event) => {
    const textToSyllabify = event.data;

    if (typeof textToSyllabify !== 'string') {
        self.postMessage({ type: 'error', message: 'Invalid or no text data received for syllabification.' });
        return;
    }

    try {
        const syllabifiedText = syllabifyText(textToSyllabify);
        self.postMessage({ type: 'result', text: syllabifiedText });
    } catch (error) {
        self.postMessage({ type: 'error', message: error.message || 'An unknown error occurred during syllabification.' });
    }
};
