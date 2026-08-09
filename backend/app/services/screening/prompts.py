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

# The 15 items of the Smythe & Everatt (2001) Adult Dyslexia Checklist, phrased
# for a natural spoken conversation. Order is significant — the weight table in
# `policies.ahrq.OPTION_WEIGHTS` is index-aligned to this list. Q1-10 map to a
# frequency scale, Q11-15 to a difficulty scale (see build_extraction_prompt).
QUESTIONS: list[str] = [
    "Do you confuse visually similar words, such as 'cat' and 'cot'?",
    "Do you lose your place or skip lines when you are reading?",
    "Do you mix up the names of objects — for example saying 'table' when you mean 'chair'?",
    "Do you have trouble telling left from right?",
    "Do you find map reading, or finding your way to an unfamiliar place, confusing?",
    "Do you often re-read paragraphs to understand them?",
    "Do you get confused when you are given several instructions at once?",
    "Do you make mistakes when taking down telephone messages?",
    "Do you find it hard to come up with the right word when you are speaking?",
    "How often do you come up with creative solutions to problems?",
    "How easy do you find it to sound out unfamiliar words, like 'e-le-phant'?",
    "When you write, how hard is it to organise your thoughts on paper?",
    "When you were learning, how easy were the multiplication tables for you?",
    "How easy do you find it to recite the alphabet in order?",
    "How hard do you find it to read aloud?",
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
    """System prompt for the Adult Dyslexia Checklist post-process call.

    The model reads the conversation and, for each of the 15 questions, picks
    the ONE answer column (1-4) that best matches what the user said — or 0 if
    they did not answer. It does NOT compute points: the weight table lives
    server-side (policies.ahrq.OPTION_WEIGHTS), so the model only classifies.
    `scores` therefore carries column indices, index-aligned to QUESTIONS.
    """
    numbered = "\n".join(f"  {i + 1}. {q}" for i, q in enumerate(QUESTIONS))
    return (
        "You are scoring the Smythe & Everatt Adult Dyslexia Checklist from a "
        "conversation. For EACH of the 15 questions below, choose the ONE answer "
        "column (1-4) that best matches what the user said. Use 0 if the user did "
        "not answer that question at all.\n\n"
        "Questions 1-10 use a FREQUENCY scale (how often it happens):\n"
        "  1 = Rarely   2 = Occasionally   3 = Often   4 = Most of the time\n"
        "Questions 11-15 use a DIFFICULTY scale (how hard it is):\n"
        "  1 = Easy   2 = Challenging   3 = Difficult   4 = Very difficult\n\n"
        "Direction matters: a HIGHER column always means the more dyslexia-"
        "indicative answer. Note Q10 (creative solutions) is scored so that MORE "
        "often = a higher column. Q11, Q13 and Q14 ask 'how easy' — map 'very "
        "easy' to 1 and 'very hard/impossible' to 4.\n\n"
        f"Questions ({len(QUESTIONS)} items):\n{numbered}\n\n"
        "Output STRICT JSON only (no prose, no markdown fences, no leading text). Schema:\n"
        "{\n"
        f"  \"scores\": [int, ...]   // exactly {len(QUESTIONS)} ints, each 0-4 (the chosen column, 0 = no answer)\n"
        f"  \"comments\": [str, ...] // exactly {len(QUESTIONS)} strings, each <= 80 chars, NO commas inside\n"
        "}\n\n"
        "Do NOT include commas inside any comment (we join them comma-separated). "
        "Do NOT wrap the JSON in code fences. Emit the JSON object as the entire response."
    )
