from datetime import date, datetime, timezone
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models import Reservation, ActiveReservationSlot, TimeSlot, School, User, BlockedSlot, Holiday
from app.schemas import ReservationCreate, ReservationResponse, TimeSlotResponse
from app.core.persian_date import format_jalali_date, to_persian_digits
from app.services.audit_service import log_action
from app.websocket.manager import manager

def serialize_reservation(res: Reservation, current_user: Optional[User] = None) -> ReservationResponse:
    # Phone number privacy check per Part 16:
    # Only the reservation owner or super_admin can see the phone number.
    show_phone = False
    can_cancel = False
    if current_user:
        if current_user.role == "super_admin" or current_user.id == res.user_id:
            show_phone = True
            can_cancel = (res.status == "confirmed")

    phone = res.user.phone_number if (show_phone and res.user) else None

    time_slot_resp = TimeSlotResponse(
        id=res.time_slot.id,
        slot_number=res.time_slot.slot_number,
        title=res.time_slot.title,
        start_time=res.time_slot.start_time.strftime("%H:%M"),
        end_time=res.time_slot.end_time.strftime("%H:%M"),
        is_active=res.time_slot.is_active
    )

    pos_title = res.user.position.title if (res.user and res.user.position) else None

    return ReservationResponse(
        id=res.id,
        reservation_date=res.reservation_date,
        jalali_date=format_jalali_date(res.reservation_date),
        time_slot_id=res.time_slot_id,
        time_slot=time_slot_resp,
        school_id=res.school_id,
        school_name=res.school.name if res.school else "نامشخص",
        user_id=res.user_id,
        user_full_name=res.user.full_name if res.user else "نامشخص",
        position_title=pos_title,
        phone_number=phone,
        description=res.description,
        status=res.status,
        can_cancel=can_cancel,
        created_at=res.created_at
    )

async def create_reservation(
    db: AsyncSession,
    user: User,
    data: ReservationCreate,
    ip_address: Optional[str] = None
) -> ReservationResponse:
    """
    Transactional double-booking prevention per Part 33.
    """
    # 1. Determine effective reservation owner and school
    target_user_id = user.id
    target_school_id = user.school_id

    # If super_admin is reserving on behalf of another user/school:
    if user.role == "super_admin" and data.on_behalf_user_id:
        target_res = await db.execute(select(User).where(User.id == data.on_behalf_user_id))
        target_user = target_res.scalars().first()
        if not target_user:
            raise HTTPException(status_code=404, detail="کاربر مورد نظر یافت نشد.")
        target_user_id = target_user.id
        target_school_id = target_user.school_id
    else:
        if not target_school_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="کاربر به هیچ مدرسه‌ای انتساب داده نشده است."
            )

    # 2. Check if time slot exists and is active
    slot_res = await db.execute(select(TimeSlot).where(TimeSlot.id == data.time_slot_id, TimeSlot.is_active == True))
    time_slot = slot_res.scalars().first()
    if not time_slot:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="بازه زمانی انتخاب شده نامعتبر یا غیرفعال است.")

    # 3. Check for administrative restrictions (blocked slots, blocked days, etc.)
    restriction_check = await db.execute(
        select(BlockedSlot).where(
            BlockedSlot.is_active == True,
            BlockedSlot.start_date <= data.reservation_date,
            BlockedSlot.end_date >= data.reservation_date,
            or_(
                BlockedSlot.time_slot_id == None,
                BlockedSlot.time_slot_id == data.time_slot_id
            )
        )
    )
    blocked = restriction_check.scalars().first()
    if blocked:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"این زمان توسط مدیریت مسدود شده است: {blocked.reason}"
        )

    # 4. Check active_reservation_slots atomically with row lock
    existing_claim = await db.execute(
        select(ActiveReservationSlot)
        .where(
            ActiveReservationSlot.reservation_date == data.reservation_date,
            ActiveReservationSlot.time_slot_id == data.time_slot_id
        )
        .with_for_update()
    )
    if existing_claim.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="این زمان هم‌اکنون توسط کاربر دیگری رزرو شده است."
        )

    # 5. Create reservation record
    new_res = Reservation(
        user_id=target_user_id,
        school_id=target_school_id,
        time_slot_id=data.time_slot_id,
        reservation_date=data.reservation_date,
        description=data.description,
        status="confirmed",
        created_by_id=user.id
    )
    db.add(new_res)
    await db.flush() # obtain new_res.id

    # 6. Create active slot claim
    active_claim = ActiveReservationSlot(
        reservation_date=data.reservation_date,
        time_slot_id=data.time_slot_id,
        reservation_id=new_res.id
    )
    db.add(active_claim)

    await log_action(
        db,
        action="RESERVATION_CREATE",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="Reservation",
        target_id=str(new_res.id),
        after_state={"date": str(data.reservation_date), "slot": data.time_slot_id, "school": target_school_id},
        ip_address=ip_address,
        status="success"
    )

    try:
        await db.commit()
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="این زمان هم‌اکنون توسط کاربر دیگری رزرو شده است."
        )

    # 7. Re-fetch full reservation for response
    full_res = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.user).selectinload(User.position),
            selectinload(Reservation.school),
            selectinload(Reservation.time_slot)
        )
        .where(Reservation.id == new_res.id)
    )
    res_obj = full_res.scalars().first()
    serialized = serialize_reservation(res_obj, current_user=user)

    # 8. Broadcast real-time WebSocket update to all connected users
    await manager.broadcast_event(
        event_type="reservation.created",
        data={
            "reservation_id": res_obj.id,
            "date": str(res_obj.reservation_date),
            "time_slot_id": res_obj.time_slot_id,
            "school_name": res_obj.school.name,
            "user_full_name": res_obj.user.full_name,
            "status": "reserved"
        }
    )

    return serialized

async def cancel_reservation(
    db: AsyncSession,
    reservation_id: int,
    user: User,
    reason: Optional[str] = None,
    ip_address: Optional[str] = None
) -> ReservationResponse:
    res_query = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.user).selectinload(User.position),
            selectinload(Reservation.school),
            selectinload(Reservation.time_slot)
        )
        .where(Reservation.id == reservation_id)
    )
    res_obj = res_query.scalars().first()

    if not res_obj:
        raise HTTPException(status_code=404, detail="رزرو مورد نظر یافت نشد.")

    if res_obj.status == "cancelled":
        raise HTTPException(status_code=400, detail="این رزرو قبلاً لغو شده است.")

    # Permissions check: only owner or super_admin
    if user.role != "super_admin" and res_obj.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="شما مجاز به لغو رزرو کاربران دیگر نیستید."
        )

    # Mark reservation as cancelled (NEVER physically delete)
    res_obj.status = "cancelled"
    res_obj.cancelled_by_id = user.id
    res_obj.cancelled_at = datetime.now(timezone.utc)
    if reason:
        res_obj.description = (res_obj.description or "") + f" [دلیل لغو: {reason}]"

    # Release from active_reservation_slots
    claim_query = await db.execute(
        select(ActiveReservationSlot).where(ActiveReservationSlot.reservation_id == reservation_id)
    )
    claim = claim_query.scalars().first()
    if claim:
        await db.delete(claim)

    await log_action(
        db,
        action="RESERVATION_CANCEL",
        actor_id=user.id,
        actor_name=user.full_name,
        target_type="Reservation",
        target_id=str(res_obj.id),
        before_state={"status": "confirmed"},
        after_state={"status": "cancelled", "reason": reason},
        ip_address=ip_address,
        status="success"
    )

    await db.commit()
    await db.refresh(res_obj)

    serialized = serialize_reservation(res_obj, current_user=user)

    # Broadcast WebSocket update
    await manager.broadcast_event(
        event_type="reservation.cancelled",
        data={
            "reservation_id": res_obj.id,
            "date": str(res_obj.reservation_date),
            "time_slot_id": res_obj.time_slot_id,
            "status": "available"
        }
    )

    return serialized
