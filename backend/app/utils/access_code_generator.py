import random
import string
import hashlib


class AccessCodeGenerator:
    """
    Generate 7-digit alphanumeric access codes
    """

    def __init__(self, code_length: int = 7):
        self.code_length = code_length

    def generate(self) -> str:
        """
        Generate random 7-character alphanumeric access code
        """
        chars = string.ascii_uppercase + string.digits
        return "".join(random.choice(chars) for _ in range(self.code_length))


def hash_access_code(access_code: str) -> str:
    """
    Create MD5 hash of access code for URL routing
    Format: domain/{md5_hash}/{feature}/history
    """
    return hashlib.md5(access_code.encode()).hexdigest()
