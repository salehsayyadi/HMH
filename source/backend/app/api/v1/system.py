from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models import User
from app.schemas import ServerInfoResponse, ConnectionTestRequest, ConnectionTestResponse
from app.services.connection_test_service import get_server_connection_info, run_connection_test

router = APIRouter(prefix="/system", tags=["System & Server"])

@router.get("/health")
async def health_check():
    db_connected = False
    db_error = None
    try:
        from sqlalchemy import text
        from app.core.database import AsyncSessionLocal
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
            db_connected = True
    except Exception as e:
        db_error = str(e)

    return {
        "status": "healthy" if db_connected else "degraded",
        "database": "connected" if db_connected else "disconnected",
        "database_error": db_error,
        "service": "HMH Amphitheater Reservation System",
        "version": "1.0.0-prod",
        "environment": "production"
    }

@router.get("/status", response_model=ServerInfoResponse)
async def system_status(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await get_server_connection_info(db)

@router.post("/test-connection", response_model=ConnectionTestResponse)
async def test_connection(
    data: ConnectionTestRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await run_connection_test(data.test_type, db)
