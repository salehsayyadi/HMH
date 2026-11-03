from datetime import datetime, time
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import TimeSlot, User
from app.schemas import TimeSlotCreate, TimeSlotUpdate, TimeSlotResponse
from app.services.audit_service import log_action

router = APIRouter(prefix="/time-slots", tags=["Time Slots"])

@router.get("", response_model=List[TimeSlotResponse])
async def list_time_slots(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(TimeSlot).order_by(TimeSlot.slot_number.asc()))
    slots = res.scalars().all()
    return [
        TimeSlotResponse(
            id=s.id,
            slot_number=s.slot_number,
            title=s.title,
            start_time=s.start_time.strftime("%H:%M"),
            end_time=s.end_time.strftime("%H:%M"),
            is_active=s.is_active
        )
        for s in slots
    ]

@router.post("", response_model=TimeSlotResponse, status_code=status.HTTP_201_CREATED)
async def create_time_slot(
    data: TimeSlotCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    try:
        st = datetime.strptime(data.start_time, "%H:%M").time()
        et = datetime.strptime(data.end_time, "%H:%M").time()
    except ValueError:
        raise HTTPException(status_code=400, detail="فرمت ساعت باید به صورت HH:MM باشد.")

    new_slot = TimeSlot(
        slot_number=data.slot_number,
        title=data.title,
        start_time=st,
        end_time=et,
        is_active=data.is_active
    )
    db.add(new_slot)
    await log_action(
        db,
        action="TIMESLOT_CREATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="TimeSlot",
        after_state={"title": data.title, "slot": data.slot_number}
    )
    await db.commit()
    await db.refresh(new_slot)

    return TimeSlotResponse(
        id=new_slot.id,
        slot_number=new_slot.slot_number,
        title=new_slot.title,
        start_time=new_slot.start_time.strftime("%H:%M"),
        end_time=new_slot.end_time.strftime("%H:%M"),
        is_active=new_slot.is_active
    )

@router.patch("/{slot_id}", response_model=TimeSlotResponse)
async def update_time_slot(
    slot_id: int,
    data: TimeSlotUpdate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(select(TimeSlot).where(TimeSlot.id == slot_id))
    slot = res.scalars().first()
    if not slot:
        raise HTTPException(status_code=404, detail="بازه زمانی یافت نشد.")

    if data.title is not None:
        slot.title = data.title
    if data.start_time is not None:
        slot.start_time = datetime.strptime(data.start_time, "%H:%M").time()
    if data.end_time is not None:
        slot.end_time = datetime.strptime(data.end_time, "%H:%M").time()
    if data.is_active is not None:
        slot.is_active = data.is_active

    await log_action(
        db,
        action="TIMESLOT_UPDATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="TimeSlot",
        target_id=str(slot.id),
        after_state={"is_active": slot.is_active}
    )
    await db.commit()
    await db.refresh(slot)

    return TimeSlotResponse(
        id=slot.id,
        slot_number=slot.slot_number,
        title=slot.title,
        start_time=slot.start_time.strftime("%H:%M"),
        end_time=slot.end_time.strftime("%H:%M"),
        is_active=slot.is_active
    )

@router.delete("/{slot_id}")
async def delete_time_slot(
    slot_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(select(TimeSlot).where(TimeSlot.id == slot_id))
    slot = res.scalars().first()
    if not slot:
        raise HTTPException(status_code=404, detail="بازه زمانی یافت نشد.")

    await db.delete(slot)
    await log_action(
        db,
        action="TIMESLOT_DELETE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="TimeSlot",
        target_id=str(slot_id)
    )
    await db.commit()
    return {"message": "سانس زمانی با موفقیت حذف گردید.", "id": slot_id}
