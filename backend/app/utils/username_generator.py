import petname


class UsernameGenerator:
    """
    Generate unique usernames using petname library
    Generates Adjective + Animal combinations like BraveTiger
    """

    def generate(self, separator: str = "") -> str:
        """Generate random username: AdjectiveAnimal"""
        name = petname.generate(words=2, separator=separator)

        if not separator:
            return "".join(word.capitalize() for word in name.split("-"))

        return name
