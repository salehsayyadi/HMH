from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models import User
from app.schemas import LoginRequest, TokenResponse, RefreshRequest, ChangePasswordRequest, UserResponse
from app.services.auth_service import authenticate_user, rotate_refresh_token, change_user_password

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    user, access_token, refresh_token = await authenticate_user(db, login_data, ip_address=ip)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=900,
        must_change_password=user.must_change_password,
        user=UserResponse.model_validate(user)
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    data: RefreshRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    user, access_token, refresh_token = await rotate_refresh_token(db, data.refresh_token, ip_address=ip)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=900,
        must_change_password=user.must_change_password,
        user=UserResponse.model_validate(user)
    )

@router.post("/change-password", response_model=UserResponse)
async def change_password(
    data: ChangePasswordRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    updated_user = await change_user_password(db, current_user, data, ip_address=ip)
    return UserResponse.model_validate(updated_user)

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)
