from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import User
from app.schemas import HolidayCreate, HolidayResponse
from app.services.holiday_service import get_all_holidays, add_manual_holiday, delete_holiday, resync_taghvim_holidays

router = APIRouter(prefix="/holidays", tags=["Holidays"])

@router.get("", response_model=List[HolidayResponse])
@router.get("/", response_model=List[HolidayResponse])
async def list_holidays(db: AsyncSession = Depends(get_db)):
    return await get_all_holidays(db)

@router.post("", response_model=HolidayResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=HolidayResponse, status_code=status.HTTP_201_CREATED)
async def create_holiday(
    data: HolidayCreate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await add_manual_holiday(db, data)

@router.delete("/{holiday_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_holiday(
    holiday_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    await delete_holiday(db, holiday_id)

@router.post("/sync-taghvim")
async def sync_taghvim(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await resync_taghvim_holidays(db)
