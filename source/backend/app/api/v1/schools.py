from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.core.deps import get_current_admin, get_current_user
from app.models import School, User, Reservation, Position
from app.schemas import SchoolCreate, SchoolUpdate, SchoolResponse, PositionSimple
from app.services.audit_service import log_action

router = APIRouter(prefix="/schools", tags=["Schools"])

@router.get("", response_model=List[SchoolResponse])
async def list_schools(
    include_inactive: bool = False,
    db: AsyncSession = Depends(get_db)
):
    query = select(School)
    if not include_inactive:
        query = query.where(School.is_active == True)
    query = query.order_by(School.id.asc())

    res = await db.execute(query)
    schools = res.scalars().all()

    result = []
    for s in schools:
        # Get counts
        u_count = await db.scalar(select(func.count(User.id)).where(User.school_id == s.id))
        r_count = await db.scalar(select(func.count(Reservation.id)).where(Reservation.school_id == s.id))
        result.append(SchoolResponse(
            id=s.id,
            name=s.name,
            code=s.code,
            description=s.description,
            is_active=s.is_active,
            user_count=u_count or 0,
            reservation_count=r_count or 0,
            created_at=s.created_at
        ))
    return result

@router.post("", response_model=SchoolResponse, status_code=status.HTTP_201_CREATED)
async def create_school(
    data: SchoolCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    existing = await db.execute(select(School).where(School.name == data.name))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="مدرسه‌ای با این نام قبلاً ثبت شده است.")

    new_school = School(
        name=data.name,
        code=data.code,
        description=data.description,
        is_active=data.is_active
    )
    db.add(new_school)
    await log_action(
        db,
        action="SCHOOL_CREATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="School",
        after_state={"name": data.name, "code": data.code}
    )
    await db.commit()
    await db.refresh(new_school)

    return SchoolResponse(
        id=new_school.id,
        name=new_school.name,
        code=new_school.code,
        description=new_school.description,
        is_active=new_school.is_active,
        user_count=0,
        reservation_count=0,
        created_at=new_school.created_at
    )

@router.patch("/{school_id}", response_model=SchoolResponse)
async def update_school(
    school_id: int,
    data: SchoolUpdate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(select(School).where(School.id == school_id))
    school = res.scalars().first()
    if not school:
        raise HTTPException(status_code=404, detail="مدرسه مورد نظر یافت نشد.")

    if data.name is not None:
        school.name = data.name
    if data.code is not None:
        school.code = data.code
    if data.description is not None:
        school.description = data.description
    if data.is_active is not None:
        school.is_active = data.is_active

    await log_action(
        db,
        action="SCHOOL_UPDATE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="School",
        target_id=str(school.id),
        after_state={"name": school.name, "is_active": school.is_active}
    )
    await db.commit()
    await db.refresh(school)

    u_count = await db.scalar(select(func.count(User.id)).where(User.school_id == school.id))
    r_count = await db.scalar(select(func.count(Reservation.id)).where(Reservation.school_id == school.id))

    return SchoolResponse(
        id=school.id,
        name=school.name,
        code=school.code,
        description=school.description,
        is_active=school.is_active,
        user_count=u_count or 0,
        reservation_count=r_count or 0,
        created_at=school.created_at
    )

@router.get("/positions/list", response_model=List[PositionSimple])
async def list_positions(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(Position).where(Position.is_active == True).order_by(Position.id.asc()))
    return [PositionSimple.model_validate(p) for p in res.scalars().all()]

@router.delete("/{school_id}")
async def delete_school(
    school_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    res = await db.execute(select(School).where(School.id == school_id))
    school = res.scalars().first()
    if not school:
        raise HTTPException(status_code=404, detail="مدرسه مورد نظر یافت نشد.")

    await db.delete(school)
    await log_action(
        db,
        action="SCHOOL_DELETE",
        actor_id=admin.id,
        actor_name=admin.full_name,
        target_type="School",
        target_id=str(school_id)
    )
    await db.commit()
    return {"message": "مدرسه با موفقیت حذف گردید.", "id": school_id}
