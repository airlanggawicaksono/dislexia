"""User model unit tests. No DB — instantiate model in-memory and check defaults."""

from app.models.user import User


def test_user_autogenerates_account_number_and_display_name():
    user = User()
    assert len(user.account_number) == 16
    assert user.account_number.isdigit()
    assert "-" in user.display_name
    assert len(user.display_name) > 3


def test_user_respects_explicit_display_name():
    user = User(display_name="amusing-bee")
    assert user.display_name == "amusing-bee"


def test_user_respects_explicit_account_number():
    user = User(account_number="1234567890123456")
    assert user.account_number == "1234567890123456"
    assert "-" in user.display_name  # still auto-generated


def test_two_users_get_different_display_names_most_of_the_time():
    names = {User().display_name for _ in range(50)}
    assert len(names) > 1  # petname has thousands of combinations
