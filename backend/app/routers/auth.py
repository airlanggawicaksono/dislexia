from typing import Optional

from fastapi import APIRouter, Depends, Header, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.user_service import UserService
from app.dto.auth.auth import GenerateResponseDTO, LoginRequestDTO
from app.dto.auth.userdata import TokenResponseDTO, UserResponseDTO
from app.openapi import AUTH_RESPONSES
from app.utils.lenient_json_route import LenientJSONRoute

_TRUTHY = {"1", "true", "yes", "on"}


def _is_truthy(value: Optional[str]) -> bool:
    return value is not None and value.strip().lower() in _TRUTHY

TAG = {
    "name": "Authentication",
    "description": (
        "Account login. Accounts are created by admins — contact your administrator to get your 6-digit code."
    ),
}

router = APIRouter(prefix="/api/v1/auth", tags=[TAG["name"]], route_class=LenientJSONRoute)


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(db)


@router.post(
    "/generate",
    response_model=GenerateResponseDTO,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
async def generate(user_service: UserService = Depends(get_user_service)):
    return await user_service.generate()


@router.post(
    "/login",
    response_model=TokenResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Log in with account number",
    responses={
        200: {"description": "Login successful. Use the returned access_token as Bearer credential."},
        **AUTH_RESPONSES,
        401: {"description": "Invalid account number."},
    },
)
async def login(
    request: LoginRequestDTO,
    user_service: UserService = Depends(get_user_service),
    x_long_session: Optional[str] = Header(
        default=None,
        alias="X-Long-Session",
        description="Truthy (`true`/`1`/`yes`) to request an effectively-permanent session. "
        "Intended for the native mobile app; web/admin clients omit it and get the default short session.",
    ),
):
    """
    Log in using your 6-digit account number.

    Account numbers are issued by an administrator — you cannot self-register.
    Returns an access token and your user profile.

    Send `X-Long-Session: true` to get a long-lived (effectively permanent) token —
    the mobile app uses this so users stay signed in. Without the header the token
    expires normally (JWT_ACCESS_TOKEN_EXPIRE_MINUTES).
    """
    return await user_service.login(request.account_number, long_session=_is_truthy(x_long_session))


@router.get(
    "/me",
    response_model=UserResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Current user (session validation)",
    responses=AUTH_RESPONSES,
)
async def me(user: UserResponseDTO = Depends(get_current_user)):
    """
    Return the authenticated user — a cheap "whoami".

    Clients (the mobile app) call this on load to validate a restored session:
    it runs the normal token check, so a token whose account was deleted or
    deactivated returns **401** and the client can log the user out.

    ```
    GET /auth/me   (Authorization: Bearer <token>)
    → 200 { user profile }        # session valid
    → 401                         # token invalid / account gone / inactive
    ```
    """
    return user
