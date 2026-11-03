import pytest
import pytest_asyncio
import os
import asyncio
from pathlib import Path
from datetime import date, timedelta
from httpx import AsyncClient, ASGITransport

db_file = Path(__file__).parent / "test_suite.db"
os.environ["DATABASE_ENGINE"] = "sqlite"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{db_file.as_posix()}"
os.environ["PYTHONPATH"] = str(Path(__file__).parent.parent)

from app.main import app
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    yield

@pytest.mark.asyncio
async def test_bootstrap_admin_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/v1/auth/login", json={
            "username": "123IMHModirkol@1090",
            "password": "123IMHModirkol@1090"
        })
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert "access_token" in data
        assert data["must_change_password"] is True
        assert data["user"]["role"] == "super_admin"

@pytest.mark.asyncio
async def test_schools_list():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/api/v1/schools")
        assert resp.status_code == 200
        schools = resp.json()
        assert len(schools) == 6
        names = [s["name"] for s in schools]
        assert "مدرسه پسرانه دوره اول" in names
        assert "مدرسه ابتدایی دخترانه" in names

@pytest.mark.asyncio
async def test_reservation_and_double_booking_prevention():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post("/api/v1/auth/login", json={
            "username": "karestan",
            "password": "12345678"
        })
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        target_date = str(date.today() + timedelta(days=5))

        # 1. First reservation should succeed
        res1 = await client.post("/api/v1/reservations", json={
            "reservation_date": target_date,
            "time_slot_id": 2,
            "description": "برگزاری جلسه انجمن اولیا و مربیان"
        }, headers=headers)
        assert res1.status_code == 201, res1.text
        created_data = res1.json()
        assert created_data["status"] == "confirmed"
        res_id = created_data["id"]

        # 2. Second reservation on same date + slot MUST FAIL with 409 Conflict
        res2 = await client.post("/api/v1/reservations", json={
            "reservation_date": target_date,
            "time_slot_id": 2,
            "description": "درخواست رزرو همزمان دیگر"
        }, headers=headers)
        assert res2.status_code == 409
        assert "این زمان هم‌اکنون توسط کاربر دیگری رزرو شده است" in res2.json()["detail"]

        # 3. Privacy rule: user can see their own phone number
        detail_resp = await client.get(f"/api/v1/reservations/{res_id}", headers=headers)
        assert detail_resp.status_code == 200
        assert detail_resp.json()["phone_number"] == "09138765432"

        # 4. Cancellation by owner should succeed and release slot
        cancel_resp = await client.post(f"/api/v1/reservations/{res_id}/cancel", json={
            "reason": "لغو به دلیل تغییر برنامه مدرسه"
        }, headers=headers)
        assert cancel_resp.status_code == 200
        assert cancel_resp.json()["status"] == "cancelled"

        # 5. Slot is now free again, so new reservation on that slot succeeds!
        res3 = await client.post("/api/v1/reservations", json={
            "reservation_date": target_date,
            "time_slot_id": 2,
            "description": "رزرو مجدد پس از آزادسازی"
        }, headers=headers)
        assert res3.status_code == 201

@pytest.mark.asyncio
async def test_calendar_week_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post("/api/v1/auth/login", json={
            "username": "karestan",
            "password": "12345678"
        })
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        resp = await client.get("/api/v1/calendar/week", headers=headers)
        assert resp.status_code == 200
        cal = resp.json()
        assert len(cal["days"]) == 7 # شنبه تا جمعه
        assert len(cal["time_slots"]) == 5 # 5 بازه زمانی
        assert cal["days"][0]["day_name"] == "شنبه"
        assert cal["days"][6]["day_name"] == "جمعه"

@pytest.mark.asyncio
async def test_reports_and_system_health():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Admin login
        login_resp = await client.post("/api/v1/auth/login", json={
            "username": "123IMHModirkol@1090",
            "password": "123IMHModirkol@1090"
        })
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Dashboard stats
        stats_resp = await client.get("/api/v1/reports/dashboard", headers=headers)
        assert stats_resp.status_code == 200
        stats = stats_resp.json()
        assert stats["total_schools"] == 6

        # System connection info
        sys_resp = await client.get("/api/v1/system/status", headers=headers)
        assert sys_resp.status_code == 200
        assert sys_resp.json()["domain"] == "salehvip-clud.ir"

        # Health check
        health_resp = await client.get("/api/v1/system/health")
        assert health_resp.status_code == 200
        assert health_resp.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_test_user_login_and_reservation():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login with test / test credentials
        login_resp = await client.post("/api/v1/auth/login", json={
            "username": "test",
            "password": "test"
        })
        assert login_resp.status_code == 200, login_resp.text
        data = login_resp.json()
        assert "access_token" in data
        assert data["must_change_password"] is False
        assert data["user"]["role"] == "user"
        assert data["user"]["username"] == "test"

        token = data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Test user creates a reservation
        target_date = str(date.today() + timedelta(days=3))
        res = await client.post("/api/v1/reservations", json={
            "reservation_date": target_date,
            "time_slot_id": 1,
            "description": "آزمایش صفحه رزرو توسط کاربر عادی test"
        }, headers=headers)
        assert res.status_code == 201, res.text
        created = res.json()
        assert created["status"] == "confirmed"
        assert created["user_full_name"] == "کاربر تست"
        assert created["school_name"] == "مدرسه پسرانه دوره دوم"
