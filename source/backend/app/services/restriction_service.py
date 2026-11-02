from datetime import date, timedelta
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models import BlockedSlot, Reservation, TimeSlot, User
from app.schemas import RestrictionCreate, RestrictionResponse
from app.core.persian_date import format_jalali_date
from app.services.audit_service import log_action
from app.websocket.manager import manager

async def create_restriction(
    db: AsyncSession,
    user: User,
    data: RestrictionCreate,
    ip_address: Optional[str] = None
) -> RestrictionResponse:
    start = data.start_date
    end = data.end_date or start

    # Calculate end date if restriction_type is week or month
    if data.restriction_type == "day":
        end = start
    elif data.restriction_type == "week":
        end = start + timedelta(days=6)
    elif data.restriction_type == "month":
        end = start + timedelta(days=29)

    # Check if active reservations already exist in this window per Part 27
    res_check = await db.execute(
        select(Reservation).where(
            Reservation.status == "confirmed",
            Reservation.reservation_date >= start,
            Reservation.reservation_date <= end,
            or_(
                Reservation.time_slot_id == data.time_slot_id,
                data.time_slot_id == None
            )
        )
    )
    conflict = res_check.scalars().first()
    if conflict:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"در این بازه زمانی، رزرو فعال وجود دارد (شماره رزرو {conflict.id}). ابتدا باید رزروهای موجود تعیین تکلیف یا لغو شوند."
        )

    slot_title = None
    if data.time_slot_id:
        st_res = await db.execute(select(TimeSlot).where(TimeSlot.id == data.time_slot_id))
        st = st_res.scalars().first()
        if st:
            slot_title = st.title

    new_block = BlockedSlot(
        restriction_type=data.restriction_type,
        start_date=start,
        end_date=end,
        time_slot_id=data.time_slot_id,
        reason=data.reason,
        created_by_id=user.id,
        is_active=True
    )
    db.add(new_block)

    await log_action(
        db,
        action="RESTRICTION_CREATE",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="BlockedSlot",
        after_state={"start": str(start), "end": str(end), "slot": data.time_slot_id, "reason": data.reason},
        ip_address=ip_address,
        status="success"
    )

    await db.commit()
    await db.refresh(new_block)

    # Broadcast WebSocket update
    await manager.broadcast_event(
        event_type="reservation.slot.blocked",
        data={
            "restriction_id": new_block.id,
            "start_date": str(new_block.start_date),
            "end_date": str(new_block.end_date),
            "time_slot_id": new_block.time_slot_id,
            "reason": new_block.reason
        }
    )

    return RestrictionResponse(
        id=new_block.id,
        restriction_type=new_block.restriction_type,
        start_date=new_block.start_date,
        end_date=new_block.end_date,
        jalali_start_date=format_jalali_date(new_block.start_date),
        jalali_end_date=format_jalali_date(new_block.end_date),
        time_slot_id=new_block.time_slot_id,
        time_slot_title=slot_title,
        reason=new_block.reason,
        created_by_name=user.full_name,
        is_active=new_block.is_active,
        created_at=new_block.created_at
    )

async def remove_restriction(
    db: AsyncSession,
    restriction_id: int,
    user: User,
    ip_address: Optional[str] = None
):
    b_res = await db.execute(select(BlockedSlot).where(BlockedSlot.id == restriction_id))
    b = b_res.scalars().first()
    if not b:
        raise HTTPException(status_code=404, detail="محدودیت مورد نظر یافت نشد.")

    b.is_active = False

    await log_action(
        db,
        action="RESTRICTION_REMOVE",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="BlockedSlot",
        target_id=str(b.id),
        ip_address=ip_address,
        status="success"
    )

    await db.commit()

    # Broadcast WebSocket update
    await manager.broadcast_event(
        event_type="reservation.slot.unblocked",
        data={
            "restriction_id": b.id,
            "start_date": str(b.start_date),
            "end_date": str(b.end_date),
            "time_slot_id": b.time_slot_id
        }
    )
