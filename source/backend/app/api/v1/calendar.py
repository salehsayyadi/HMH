from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models import User
from app.schemas import CalendarWeekResponse
from app.services.calendar_service import get_calendar_week

router = APIRouter(prefix="/calendar", tags=["Calendar"])

@router.get("/week", response_model=CalendarWeekResponse)
async def get_week_view(
    target_date: Optional[date] = Query(None, description="Date within target week (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return await get_calendar_week(db, target_date=target_date, current_user=current_user)
