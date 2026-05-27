import secrets


class AccountNumberGenerator:
    @staticmethod
    def generate() -> str:
        return str(secrets.randbelow(10 ** 16)).zfill(16)
