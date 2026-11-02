import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data
from app.core.security import decode_token
from app.websocket.manager import manager

# Import routers
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.schools import router as schools_router
from app.api.v1.reservations import router as reservations_router
from app.api.v1.calendar import router as calendar_router
from app.api.v1.time_slots import router as time_slots_router
from app.api.v1.holidays import router as holidays_router
from app.api.v1.restrictions import router as restrictions_router
from app.api.v1.reports import router as reports_router
from app.api.v1.audit import router as audit_router
from app.api.v1.system import router as system_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("hmh.main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing database schema...")
    # Robust retry loop: wait for MySQL to complete initialization
    connected = False
    for attempt in range(1, 61):
        try:
            logger.info(f"Connecting to database (attempt {attempt}/60)...")
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            connected = True
            logger.info("Database connection established and schema initialized.")
            break
        except Exception as e:
            logger.warning(f"Database not ready yet ({e}), retrying in 2 seconds...")
            await asyncio.sleep(2)

    if connected:
        try:
            async with AsyncSessionLocal() as session:
                logger.info("Seeding initial database data...")
                await init_database_data(session)
                logger.info("Initial data seeded successfully.")
        except Exception as e:
            logger.error(f"Error seeding initial database data: {e}")
    else:
        logger.error("Could not connect to database after 60 attempts. Serving in degraded mode.")

    yield
    logger.info("Shutting down application...")

app = FastAPI(
    title="سامانه مدیریت و رزرواسیون آمفی‌تئاتر مدارس امام حسین (ع) یزد",
    description="HMH Amphitheater Reservation Central Backend API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "اطلاعات ورودی نامعتبر است.", "errors": exc.errors()}
    )

# Include v1 API Routers
api_v1_prefix = "/api/v1"
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(users_router, prefix=api_v1_prefix)
app.include_router(schools_router, prefix=api_v1_prefix)
app.include_router(reservations_router, prefix=api_v1_prefix)
app.include_router(calendar_router, prefix=api_v1_prefix)
app.include_router(time_slots_router, prefix=api_v1_prefix)
app.include_router(holidays_router, prefix=api_v1_prefix)
app.include_router(restrictions_router, prefix=api_v1_prefix)
app.include_router(reports_router, prefix=api_v1_prefix)
app.include_router(audit_router, prefix=api_v1_prefix)
app.include_router(system_router, prefix=api_v1_prefix)

# WebSocket Endpoint per Part 35
@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(None)
):
    user_id = None
    if token:
        try:
            payload = decode_token(token)
            user_id = int(payload.get("sub"))
        except Exception:
            pass

    await manager.connect(websocket, user_id=user_id)
    try:
        while True:
            # Client heartbeat / message listener
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id=user_id)
    except Exception as e:
        logger.warning(f"WebSocket connection closed with error: {e}")
        manager.disconnect(websocket, user_id=user_id)

@app.get("/")
async def root():
    return {
        "organization": "موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد",
        "system": "سامانه مدیریت رزرواسیون سالن آمفی‌تئاتر",
        "status": "online",
        "api_docs": "/docs",
        "version": "1.0.0"
    }
