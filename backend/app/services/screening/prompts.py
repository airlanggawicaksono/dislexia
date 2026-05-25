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
