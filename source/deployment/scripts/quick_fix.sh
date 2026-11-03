#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Quick Restart & Database Lock Release Script
# ==============================================================================
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    راه‌اندازی مجدد و آزادسازی قفل‌های پایگاه‌داده"
echo "=============================================================================="
echo -e "${NC}"

echo -e "${CYAN}[۱/۳] ری‌استارت کانتینرهای پایگاه‌داده و بک‌اند...${NC}"
docker restart hmh_mysql hmh_backend

echo -e "${CYAN}[۲/۳] صبوری ۵ ثانیه جهت آماده‌باش کامل MySQL...${NC}"
sleep 5

echo -e "${CYAN}[۳/۳] همگام‌سازی جداول، ثبت کاربر مدیر و تعطیلات رسمی (چند ثانیه صبوری فرمایید)...${NC}"
docker exec hmh_backend python -c "
import asyncio
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print('SUCCESS: ALL TABLES AND INITIAL DATA ARE READY!')

asyncio.run(init())
"

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  عملیات با موفقیت انجام شد! وضعیت نهایی سرور:"
echo "=============================================================================="
docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health || true
echo ""
echo -e "${NC}"
