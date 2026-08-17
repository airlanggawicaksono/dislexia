"""Shared prompt fragments injected into feature system prompts."""


def language_directive(output_language: str) -> str:
    """Explicit output-language instruction. The user picks the language via
    `output_language`, so this OVERRIDES any input-language detection. When the
    language is English we pin it to British (UK) spelling — testers reported
    US English leaking through."""
    directive = (
        f"OUTPUT LANGUAGE: Write the ENTIRE response in {output_language}. "
        "Never switch languages mid-reply."
    )
    if output_language == "English":
        directive += (
            " Use British (UK) English spelling and conventions "
            "(e.g. 'colour', 'organise', 'realise', 'centre', 'analyse'), "
            "not American English."
        )
    return directive


DYSLEXIA_OUTPUT_RULES = (
    "Output rules:\n"
    "- Use simple, common vocabulary. Avoid jargon, idioms, and complicated words. "
    "Prefer short sentences. This output is for readers with dyslexia.\n"
    "- Do not use special Unicode decoration: no em-dashes in non-English text, "
    "no smart quotes, no fancy bullets, no zero-width or invisible characters. "
    "In English, em-dashes are allowed sparingly, only when they aid clarity.\n"
    "- Use plain punctuation: periods, commas, regular hyphens, plain ASCII bullets like '-'.\n"
)
