"""Shared prompt fragments injected into feature system prompts."""


def language_directive(input_language: str) -> str:
    """Output-language directive that FOLLOWS the detected input language.

    The caller is expected to detect the user's input language (e.g. via a
    lang-detect step or header) and pass it as `input_language`. The model
    is then instructed to reply in that same language, with one special
    rule for English: pin it to British (UK) spelling, because testers
    reported US English leaking through when the input is English.

    If `input_language` is empty / unknown, the model is told to detect
    and mirror the user's language on its own.
    """
    if not input_language:
        return (
            "OUTPUT LANGUAGE: Detect the user's language from their input "
            "and write the ENTIRE response in that same language. "
            "Never switch languages mid-reply."
        )

    if input_language.lower() in {"english", "en", "en-gb", "en-us"}:
        return (
            "OUTPUT LANGUAGE: The user's input is in English. Write the "
            "ENTIRE response in British (UK) English — use British spelling "
            "and conventions (e.g. 'colour', 'organise', 'realise', 'centre', "
            "'analyse'), not American English. Never switch languages mid-reply."
        )

    if input_language.lower() in {"indonesian", "id", "bahasa indonesia", "bahasa"}:
        return (
            "OUTPUT LANGUAGE: The user's input is in Indonesian. Write the "
            "ENTIRE response in Bahasa Indonesia that is natural, baku but "
            "accessible. Do not mix in English words unless they are established "
            "loanwords. Never switch languages mid-reply."
        )

    # Fallback for every other language (Japanese, Spanish, German, etc.)
    return (
        f"OUTPUT LANGUAGE: The user's input is in {input_language}. "
        "Write the ENTIRE response in that same language, using its standard "
        "spelling and conventions. Never switch languages mid-reply."
    )


DYSLEXIA_OUTPUT_RULES = (
    "Output rules (apply to any target language):\n"
    "- Use simple, common vocabulary appropriate to the target language. "
    "Avoid jargon, idioms, and complicated words. Prefer short sentences. "
    "This output is for readers with dyslexia.\n"
    "- Do not use special Unicode decoration: no smart quotes, no fancy "
    "bullets, no zero-width or invisible characters. Use plain punctuation: "
    "periods, commas, regular hyphens, and plain ASCII bullets like '-'.\n"
    "- Follow the punctuation conventions natural to the target language "
    "(e.g. em-dashes are allowed sparingly in English when they aid clarity; "
    "in other languages, use the local equivalent only if it is standard).\n"
)