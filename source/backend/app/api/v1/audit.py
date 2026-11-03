from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import AuditLog, User
from app.schemas import AuditLogResponse
from app.core.persian_date import format_jalali_date

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])

@router.get("", response_model=List[AuditLogResponse])
@router.get("/", response_model=List[AuditLogResponse])
async def list_audit_logs(
    action: Optional[str] = None,
    limit: int = 100,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    query = select(AuditLog)
    if action:
        query = query.where(AuditLog.action == action)
    query = query.order_by(AuditLog.timestamp.desc()).limit(limit)

    res = await db.execute(query)
    logs = res.scalars().all()

    return [
        AuditLogResponse(
            id=l.id,
            actor_id=l.actor_id,
            actor_name=l.actor_name,
            action=l.action,
            target_type=l.target_type,
            target_id=l.target_id,
            before_state=l.before_state,
            after_state=l.after_state,
            ip_address=l.ip_address,
            status=l.status,
            timestamp=l.timestamp,
            jalali_timestamp=format_jalali_date(l.timestamp.date()) + f" {l.timestamp.strftime('%H:%M')}"
        )
        for l in logs
    ]
