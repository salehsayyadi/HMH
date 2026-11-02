from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.deps import get_current_user, get_current_admin
from app.models import Reservation, User, School, TimeSlot
from app.schemas import ReservationCreate, ReservationResponse, ReservationCancel
from app.services.reservation_service import create_reservation, cancel_reservation, serialize_reservation

router = APIRouter(prefix="/reservations", tags=["Reservations"])

@router.get("", response_model=List[ReservationResponse])
async def list_reservations(
    school_id: Optional[int] = None,
    user_id: Optional[int] = None,
    status_filter: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Reservation).options(
        selectinload(Reservation.user).selectinload(User.position),
        selectinload(Reservation.school),
        selectinload(Reservation.time_slot)
    )

    # Ordinary users only see either their own or school's or general overview
    if current_user.role != "super_admin" and user_id:
        query = query.where(Reservation.user_id == current_user.id)
    elif user_id:
        query = query.where(Reservation.user_id == user_id)

    if school_id:
        query = query.where(Reservation.school_id == school_id)
    if status_filter:
        query = query.where(Reservation.status == status_filter)
    if start_date:
        query = query.where(Reservation.reservation_date >= start_date)
    if end_date:
        query = query.where(Reservation.reservation_date <= end_date)
    if search:
        search_filter = f"%{search}%"
        query = query.join(Reservation.user).join(Reservation.school).where(
            or_(
                Reservation.description.ilike(search_filter),
                User.first_name.ilike(search_filter),
                User.last_name.ilike(search_filter),
                School.name.ilike(search_filter)
            )
        )

    query = query.order_by(Reservation.reservation_date.desc(), Reservation.time_slot_id.asc())
    res = await db.execute(query)
    reservations = res.scalars().all()

    return [serialize_reservation(r, current_user=current_user) for r in reservations]

@router.get("/my-history", response_model=List[ReservationResponse])
async def get_my_reservation_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Reservation).options(
        selectinload(Reservation.user).selectinload(User.position),
        selectinload(Reservation.school),
        selectinload(Reservation.time_slot)
    ).where(Reservation.user_id == current_user.id).order_by(Reservation.reservation_date.desc())

    res = await db.execute(query)
    reservations = res.scalars().all()
    return [serialize_reservation(r, current_user=current_user) for r in reservations]

@router.post("", response_model=ReservationResponse, status_code=status.HTTP_201_CREATED)
async def make_reservation(
    data: ReservationCreate,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    return await create_reservation(db, current_user, data, ip_address=ip)

@router.get("/{reservation_id}", response_model=ReservationResponse)
async def get_reservation_detail(
    reservation_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Reservation).options(
        selectinload(Reservation.user).selectinload(User.position),
        selectinload(Reservation.school),
        selectinload(Reservation.time_slot)
    ).where(Reservation.id == reservation_id)

    res = await db.execute(query)
    res_obj = res.scalars().first()
    if not res_obj:
        raise HTTPException(status_code=404, detail="رزرو یافت نشد.")

    return serialize_reservation(res_obj, current_user=current_user)

@router.post("/{reservation_id}/cancel", response_model=ReservationResponse)
async def cancel_existing_reservation(
    reservation_id: int,
    data: ReservationCancel,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ip = request.client.host if request.client else None
    return await cancel_reservation(
        db=db,
        reservation_id=reservation_id,
        user=current_user,
        reason=data.reason,
        ip_address=ip
    )
