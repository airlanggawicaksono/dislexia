PERSONA = (
    "You are a warm, empathetic dyslexia screening assistant. "
    "Conduct a natural, supportive conversation. Never diagnose. "
    "Rephrase the given question in your own words — do not quote it verbatim."
)

# Few-shot style template — shows expected Human/AI exchange pattern.
# Human = user's casual answer. AI = warm natural rephrasing of the next question.
STYLE_TEMPLATE = """
Conversation style example:
  Human: "Yeah I guess I read slower than most people around me."
  AI: "Thanks for sharing that. I'm curious — in your day-to-day life, whether at work \
or just getting through emails, how much reading do you find yourself doing?"

Follow this pattern: acknowledge warmly, then ask the next question naturally.
"""

QUESTIONS: list[str] = [
    "How would you rate your current reading speed compared with other adults?",
    "How much reading is required in your work or daily tasks?",
    "Did you have difficulty learning spelling in elementary school?",
    "How would you rate your current spelling ability compared with other adults?",
    "Did anyone ever consider having you repeat a grade because of school problems?",
    "Do you have difficulty remembering names of people or places?",
    "Do you have difficulty remembering addresses, phone numbers, or dates?",
    "Do you have difficulty remembering complex spoken instructions?",
    "Do you currently reverse letters or numbers when reading or writing?",
    "How many books do you read for pleasure each year?",
    "How many magazines do you read for pleasure each month?",
    "How often do you read a weekday newspaper?",
    "How often do you read a Sunday newspaper?",
    "What was your attitude toward school as a child?",
    "Did you have difficulty learning to read in elementary school?",
    "Did you need extra help when learning to read?",
    "Did you reverse letters or numbers when you were a child?",
    "Did you have difficulty learning letter names or color names as a child?",
    "How was your reading ability in elementary school compared with your classmates?",
    "How difficult was schoolwork for you compared with your classmates?",
    "Did you have difficulty with English or language classes in high school or college?",
    "What is your current attitude toward reading?",
    "How much reading do you do for pleasure now?",
]


def build_system_prompt(idx: int) -> str:
    if idx < len(QUESTIONS):
        return (
            f"{PERSONA}"
            f"{STYLE_TEMPLATE}"
            f"\nNow ask the user this question in your own warm, natural words:\n{QUESTIONS[idx]}"
        )
    return (
        f"{PERSONA}"
        f"{STYLE_TEMPLATE}"
        "\nAll questions have been covered. "
        "Give a brief, warm summary of what the user shared throughout this conversation."
    )


def build_gate_prompt(current_q: str | None, next_q: str | None) -> str:
    """System prompt for the per-reply 'answered gate'.

    The model both (a) judges whether the user's latest message satisfies the
    CURRENT topic and (b) writes the next assistant message. It must return
    strict JSON: {"answered": bool, "message": str}. The server advances to the
    next topic only when answered=true — so a vague reply keeps the same topic.
    """
    if current_q is None:
        return (
            f"{PERSONA}{STYLE_TEMPLATE}\n"
            "All topics have been covered. Return STRICT JSON ONLY "
            "(no prose, no code fences):\n"
            '{"answered": true, "message": "<a brief, warm closing summary of '
            'what the user shared>"}'
        )

    if next_q is not None:
        followup = f'naturally ask the next topic in your own warm words: "{next_q}"'
    else:
        followup = (
            "give a brief, warm closing summary of what they shared "
            "(this was the final topic)"
        )

    return (
        f"{PERSONA}{STYLE_TEMPLATE}\n"
        f'You are currently on this topic:\n"{current_q}"\n\n'
        "The user's latest message is their answer to THIS topic. Decide whether "
        "it sufficiently answers the topic. A brief but clear answer counts as "
        "answered; a vague, off-topic, or non-committal reply (e.g. 'not sure' "
        "with no detail) does NOT.\n\n"
        "Return STRICT JSON ONLY — no prose, no markdown code fences:\n"
        '{"answered": true|false, "message": "..."}\n'
        f"- If answered is true: message warmly acknowledges their answer, then {followup}.\n"
        "- If answered is false: message gently notes what is unclear and re-asks "
        "the CURRENT topic in different, simpler words. Do NOT move to a new topic."
    )


def build_extraction_prompt() -> str:
    """System prompt for the ARHQ post-process extraction call.

    Instructs the model to emit strict JSON with two arrays aligned to the
    QUESTIONS order. Comments capped so the joined output stays small.
    """
    from app.policies import SCORE_MIN, SCORE_MAX

    numbered = "\n".join(f"  {i}. {q}" for i, q in enumerate(QUESTIONS))
    return (
        "You are an ARHQ (Adult Reading History Questionnaire) scorer. "
        f"Analyze the conversation and produce ONE score ({SCORE_MIN}-{SCORE_MAX}) "
        "and ONE short comment for each of the questions below, in the SAME ORDER.\n\n"
        f"Questions ({len(QUESTIONS)} items):\n{numbered}\n\n"
        f"Score rubric: {SCORE_MIN} = no dyslexia indication, {SCORE_MAX} = strong indication. "
        "If the user did not clearly answer a question, use 0 and set the comment to \"no answer\".\n\n"
        "Output STRICT JSON only (no prose, no markdown fences, no leading text). Schema:\n"
        "{\n"
        f"  \"scores\": [int, ...]   // exactly {len(QUESTIONS)} ints, each {SCORE_MIN}-{SCORE_MAX}\n"
        f"  \"comments\": [str, ...] // exactly {len(QUESTIONS)} strings, each <= 80 chars, NO commas inside\n"
        "}\n\n"
        "Do NOT include commas inside any comment (we join them comma-separated). "
        "Do NOT wrap the JSON in code fences. Emit the JSON object as the entire response."
    )
