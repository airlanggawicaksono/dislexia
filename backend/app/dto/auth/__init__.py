"""Authentication DTOs"""

from app.dto.auth.auth import GenerateResponseDTO, LoginRequestDTO
from app.dto.auth.userdata import UserResponseDTO, TokenResponseDTO
from app.dto.auth.admin import (
    AdminLoginRequestDTO,
    AdminChangePasswordRequestDTO,
    AdminResponseDTO,
    AdminTokenResponseDTO,
    AdminCreateResponseDTO,
)

__all__ = [
    "GenerateResponseDTO",
    "LoginRequestDTO",
    "UserResponseDTO",
    "TokenResponseDTO",
    "AdminLoginRequestDTO",
    "AdminChangePasswordRequestDTO",
    "AdminResponseDTO",
    "AdminTokenResponseDTO",
    "AdminCreateResponseDTO",
]
