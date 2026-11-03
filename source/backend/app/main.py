import asyncio
import logging
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.core.config import settings
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

async def init_schema_and_data(is_sqlite: bool = False) -> bool:
    try:
        from app.core.database import engine, AsyncSessionLocal, Base
        from app.core.init_db import init_database_data
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        async with AsyncSessionLocal() as session:
            await init_database_data(session)
        logger.info(f"Database schema & initial data initialized (mode: {'sqlite' if is_sqlite else 'mysql'}).")
        return True
    except Exception as e:
        logger.warning(f"Database initialization step failed ({'sqlite' if is_sqlite else 'mysql'}): {e}")
        return False

async def background_db_init():
    # Retry MySQL up to 15 times with 2-second sleep so warming-up MySQL succeeds
    for attempt in range(1, 16):
        try:
            logger.info(f"Connecting to MySQL database (attempt {attempt}/15)...")
            success = await init_schema_and_data(is_sqlite=False)
            if success:
                logger.info("MySQL connection established and schema initialized.")
                return
        except Exception as e:
            logger.warning(f"MySQL connection attempt {attempt} failed: {e}")
        await asyncio.sleep(2)

    # If MySQL is completely unavailable, switch to local SQLite fallback
    logger.warning("Could not connect to MySQL. Initializing resilient SQLite local database fallback...")
    try:
        import app.core.database as db_mod
        from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
        fallback_db = Path("/app/amphitheater_local.db")
        if not fallback_db.parent.exists():
            fallback_db = Path(__file__).resolve().parent.parent / "amphitheater_local.db"
        fallback_url = f"sqlite+aiosqlite:///{fallback_db.as_posix()}"
        fallback_engine = create_async_engine(fallback_url, echo=False, future=True)
        db_mod.engine = fallback_engine
        db_mod.AsyncSessionLocal = async_sessionmaker(
            bind=fallback_engine,
            class_=AsyncSession,
            expire_on_commit=False,
            autoflush=False,
            autocommit=False
        )
        await init_schema_and_data(is_sqlite=True)
        logger.info("Resilient SQLite fallback initialized successfully.")
    except Exception as fb_err:
        logger.error(f"Error initializing SQLite fallback: {fb_err}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Try quick initial connection
    try:
        from app.core.database import engine, Base, AsyncSessionLocal
        from app.core.init_db import init_database_data
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        async with AsyncSessionLocal() as session:
            await init_database_data(session)
        logger.info("Database connection established immediately on startup.")
    except Exception as e:
        logger.warning(f"Initial DB connection not ready yet ({e}); delegating to background retry...")
        asyncio.create_task(background_db_init())

    # Lifespan yields immediately so Uvicorn starts listening on port 8000 instantly!
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

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled error on {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "خطای داخلی در پردازش درخواست سرور", "error": str(exc)}
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
