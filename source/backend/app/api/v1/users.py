from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.deps import get_current_admin, get_current_user
from app.core.security import get_password_hash
from app.models import User, School, Position
from app.schemas import UserCreate, UserUpdate, UserResponse, UserSelfUpdate
from app.services.audit_service import log_action

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("", response_model=List[UserResponse])
async def list_users(
    school_id: Optional[int] = None,
    position_id: Optional[int] = None,
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    query = select(User).options(
        selectinload(User.school),
        selectinload(User.position)
    )

    if school_id:
        query = query.where(User.school_id == school_id)
    if position_id:
        query = query.where(User.position_id == position_id)
    if is_active is not None:
        query = query.where(User.is_active == is_active)
    if search:
        search_filter = f"%{search}%"
        query = query.where(
            or_(
                User.first_name.ilike(search_filter),
                User.last_name.ilike(search_filter),
                User.username.ilike(search_filter),
                User.phone_number.ilike(search_filter)
            )
        )

    query = query.order_by(User.created_at.desc())
    result = await db.execute(query)
    return [UserResponse.model_validate(u) for u in result.scalars().all()]

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    # Check username uniqueness
    existing = await db.execute(select(User).where(User.username == data.username))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="این نام کاربری قبلاً ثبت شده است.")

    raw_pwd = data.initial_password or data.password or "12345678"
    new_user = User(
        username=data.username,
        password_hash=get_password_hash(raw_pwd),
        first_name=data.first_name,
        last_name=data.last_name,
        phone_number=data.phone_number,
        school_id=data.school_id,
        position_id=data.position_id,
        role=data.role or "user",
        is_active=True,
        must_change_password=False
    )
    db.add(new_user)
    await log_action(
        db,
        action="USER_CREATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="User",
        after_state={"username": data.username, "school_id": data.school_id, "role": data.role}
    )
    await db.commit()

    # Re-fetch with relations
    res = await db.execute(
        select(User).options(selectinload(User.school), selectinload(User.position)).where(User.id == new_user.id)
    )
    return UserResponse.model_validate(res.scalars().first())

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_detail(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if current_user.role != "super_admin" and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="دسترسی غیرمجاز")

    res = await db.execute(
        select(User).options(selectinload(User.school), selectinload(User.position)).where(User.id == user_id)
    )
    user = res.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="کاربر یافت نشد.")
    return UserResponse.model_validate(user)

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    data: UserUpdate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(
        select(User).options(selectinload(User.school), selectinload(User.position)).where(User.id == user_id)
    )
    user = res.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="کاربر یافت نشد.")

    if data.first_name is not None:
        user.first_name = data.first_name
    if data.last_name is not None:
        user.last_name = data.last_name
    if data.phone_number is not None:
        user.phone_number = data.phone_number
    if data.school_id is not None:
        user.school_id = data.school_id
    if data.position_id is not None:
        user.position_id = data.position_id
    if data.role is not None:
        user.role = data.role
    if data.is_active is not None:
        user.is_active = data.is_active
    if data.reset_password:
        user.password_hash = get_password_hash(data.reset_password)
        user.must_change_password = True

    await log_action(
        db,
        action="USER_UPDATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="User",
        target_id=str(user.id),
        after_state={"is_active": user.is_active, "school_id": user.school_id}
    )
    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)

@router.patch("/me/profile", response_model=UserResponse)
async def update_self_profile(
    data: UserSelfUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if data.first_name is not None:
        current_user.first_name = data.first_name
    if data.last_name is not None:
        current_user.last_name = data.last_name
    if data.phone_number is not None:
        current_user.phone_number = data.phone_number

    await db.commit()
    await db.refresh(current_user)
    return UserResponse.model_validate(current_user)

@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    if admin.id == user_id:
        raise HTTPException(status_code=400, detail="مدیر ارشد نمی‌تواند حساب کاربری خود را حذف نماید.")

    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="کاربر یافت نشد.")

    # Remove active sessions and user
    from app.models import RefreshSession, LoginAttempt, Reservation
    await db.execute(select(RefreshSession).where(RefreshSession.user_id == user_id))
    
    await db.delete(user)
    await log_action(
        db,
        action="USER_DELETE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="User",
        target_id=str(user_id)
    )
    await db.commit()
    return {"message": "کاربر با موفقیت حذف گردید.", "id": user_id}
