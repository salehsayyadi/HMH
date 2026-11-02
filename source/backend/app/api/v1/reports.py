from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import User
from app.schemas import DashboardStatsResponse
from app.services.report_service import get_dashboard_stats, generate_reservations_excel

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("/dashboard", response_model=DashboardStatsResponse)
async def dashboard_statistics(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await get_dashboard_stats(db)

@router.get("/reservations/excel")
async def export_reservations_excel(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    school_id: Optional[int] = None,
    status_filter: Optional[str] = None,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    excel_bytes = await generate_reservations_excel(
        db,
        start_date=start_date,
        end_date=end_date,
        school_id=school_id,
        status_filter=status_filter
    )
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=amphitheater_reservations.xlsx"}
    )
