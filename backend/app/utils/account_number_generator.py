import secrets


class AccountNumberGenerator:
    @staticmethod
    def generate() -> str:
        return str(secrets.randbelow(10 ** 6)).zfill(6)
