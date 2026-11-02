import hashlib
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models import User, RefreshSession, LoginAttempt, School, Position
from app.schemas import LoginRequest, ChangePasswordRequest, TokenResponse, UserResponse
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token
from app.core.config import settings
from app.services.audit_service import log_action

async def authenticate_user(
    db: AsyncSession,
    login_data: LoginRequest,
    ip_address: Optional[str] = None
) -> Tuple[User, str, str]:
    # Record login attempt
    attempt = LoginAttempt(
        username=login_data.username,
        ip_address=ip_address,
        success=False
    )
    db.add(attempt)

    # Find user with eager loading of school and position
    result = await db.execute(
        select(User)
        .options(selectinload(User.school), selectinload(User.position))
        .where(User.username == login_data.username)
    )
    user = result.scalars().first()

    if not user:
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="نام کاربری یا رمز عبور اشتباه است."
        )

    if not user.is_active:
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="حساب کاربری شما غیرفعال شده است. لطفاً با مدیر سیستم تماس بگیرید."
        )

    if not verify_password(login_data.password, user.password_hash):
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="نام کاربری یا رمز عبور اشتباه است."
        )

    # Success
    attempt.success = True
    user.last_login = datetime.now(timezone.utc)

    # Generate tokens
    access_token = create_access_token(
        subject=user.id,
        extra_claims={
            "username": user.username,
            "role": user.role,
            "school_id": user.school_id,
            "must_change_password": user.must_change_password
        }
    )
    refresh_token = create_refresh_token(subject=user.id)

    # Hash refresh token for DB storage
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    session = RefreshSession(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=expires_at,
        ip_address=ip_address
    )
    db.add(session)

    await log_action(
        db,
        action="AUTH_LOGIN",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="User",
        target_id=str(user.id),
        ip_address=ip_address,
        status="success"
    )

    await db.commit()
    await db.refresh(user)

    return user, access_token, refresh_token

async def rotate_refresh_token(
    db: AsyncSession,
    old_refresh_token: str,
    ip_address: Optional[str] = None
) -> Tuple[User, str, str]:
    token_hash = hashlib.sha256(old_refresh_token.encode()).hexdigest()
    result = await db.execute(
        select(RefreshSession).where(
            RefreshSession.token_hash == token_hash,
            RefreshSession.is_revoked == False
        )
    )
    session = result.scalars().first()

    if not session or session.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="نشست کاربری نامعتبر یا منقضی شده است."
        )

    # Revoke old session (Rotation)
    session.is_revoked = True

    # Get user
    user_res = await db.execute(
        select(User)
        .options(selectinload(User.school), selectinload(User.position))
        .where(User.id == session.user_id)
    )
    user = user_res.scalars().first()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="حساب کاربری فعال نیست."
        )

    new_access_token = create_access_token(
        subject=user.id,
        extra_claims={
            "username": user.username,
            "role": user.role,
            "school_id": user.school_id,
            "must_change_password": user.must_change_password
        }
    )
    new_refresh_token = create_refresh_token(subject=user.id)
    new_token_hash = hashlib.sha256(new_refresh_token.encode()).hexdigest()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    new_session = RefreshSession(
        user_id=user.id,
        token_hash=new_token_hash,
        expires_at=expires_at,
        ip_address=ip_address
    )
    db.add(new_session)
    await db.commit()

    return user, new_access_token, new_refresh_token

async def change_user_password(
    db: AsyncSession,
    user: User,
    data: ChangePasswordRequest,
    ip_address: Optional[str] = None
):
    if not verify_password(data.current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="رمز عبور فعلی نادرست است."
        )

    if data.current_password == data.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="رمز عبور جدید نمی‌تواند مشابه رمز عبور فعلی باشد."
        )

    user.password_hash = get_password_hash(data.new_password)
    user.must_change_password = False

    await log_action(
        db,
        action="PASSWORD_CHANGE",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="User",
        target_id=str(user.id),
        ip_address=ip_address,
        status="success"
    )

    await db.commit()
    await db.refresh(user)
    return user
