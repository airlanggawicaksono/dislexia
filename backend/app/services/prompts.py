"""Shared prompt fragments injected into feature system prompts."""


DYSLEXIA_OUTPUT_RULES = (
    "Output rules:\n"
    "- Detect the language of the user's input and reply in that same language. "
    "If they wrote Bengali, reply in Bengali; if Indonesian, reply in Indonesian; "
    "if English, reply in English. Never switch languages mid-reply.\n"
    "- Use simple, common vocabulary. Avoid jargon, idioms, and complicated words. "
    "Prefer short sentences. This output is for readers with dyslexia.\n"
    "- Do not use special Unicode decoration: no em-dashes in non-English text, "
    "no smart quotes, no fancy bullets, no zero-width or invisible characters. "
    "In English, em-dashes are allowed sparingly, only when they aid clarity.\n"
    "- Use plain punctuation: periods, commas, regular hyphens, plain ASCII bullets like '-'.\n"
)
