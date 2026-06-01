/// Adds middle dot (·) between syllables for words >= 4 chars.
String syllabify(String text) {
  if (text.isEmpty) return '';
  
  // Use a more efficient way to split and join, preserving newlines
  final lines = text.split('\n');
  final processedLines = lines.map((line) {
    if (line.trim().isEmpty) return line;
    
    final words = line.split(RegExp(r'\s+'));
    final processedWords = words.map((w) {
      if (w.length < 4 || w.contains('·')) return w;
      return _syllabifyWord(w);
    }).toList();
    
    return processedWords.join(' ');
  });
  
  return processedLines.join('\n');
}

String _syllabifyWord(String word) {
  final buffer = StringBuffer();
  int i = 0;
  
  // Simple heuristic-based syllabification for Indonesian/English
  while (i < word.length) {
    buffer.write(word[i]);
    
    // If current is vowel and next is consonant followed by vowel (V-CV)
    if (i < word.length - 2 && 
        _isVowel(word[i]) && 
        !_isVowel(word[i+1]) && 
        _isVowel(word[i+2])) {
      buffer.write('·');
    } 
    // If current is consonant and next is consonant (C-C)
    else if (i < word.length - 1 && 
             !_isVowel(word[i]) && 
             !_isVowel(word[i+1])) {
      // Don't split common digraphs like 'th', 'sh', 'ch', 'ng', 'ny'
      final digraph = (word[i] + word[i+1]).toLowerCase();
      if (!['th', 'sh', 'ch', 'ng', 'ny', 'kh', 'sy'].contains(digraph)) {
        buffer.write('·');
      }
    }
    
    i++;
  }
  return buffer.toString();
}

bool _isVowel(String c) {
  return 'aeiouAEIOU'.contains(c);
}

