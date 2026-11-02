from typing import List
from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import BlockedSlot, User
from app.schemas import RestrictionCreate, RestrictionResponse
from app.core.persian_date import format_jalali_date
from app.services.restriction_service import create_restriction, remove_restriction

router = APIRouter(prefix="/restrictions", tags=["Restrictions"])

@router.get("", response_model=List[RestrictionResponse])
async def list_restrictions(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(
        select(BlockedSlot)
        .options(selectinload(BlockedSlot.time_slot), selectinload(BlockedSlot.created_by))
        .where(BlockedSlot.is_active == True)
        .order_by(BlockedSlot.start_date.desc())
    )
    records = res.scalars().all()
    return [
        RestrictionResponse(
            id=r.id,
            restriction_type=r.restriction_type,
            start_date=r.start_date,
            end_date=r.end_date,
            jalali_start_date=format_jalali_date(r.start_date),
            jalali_end_date=format_jalali_date(r.end_date),
            time_slot_id=r.time_slot_id,
            time_slot_title=r.time_slot.title if r.time_slot else "تمام ساعات",
            reason=r.reason,
            created_by_name=r.created_by.full_name if r.created_by else "مدیر سیستم",
            is_active=r.is_active,
            created_at=r.created_at
        )
        for r in records
    ]

@router.post("", response_model=RestrictionResponse, status_code=status.HTTP_201_CREATED)
async def add_restriction(
    data: RestrictionCreate,
    request: Request,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    return await create_restriction(db, admin, data, ip_address=ip)

@router.delete("/{restriction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_restriction(
    restriction_id: int,
    request: Request,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    await remove_restriction(db, restriction_id, admin, ip_address=ip)
