#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Automated Server & Backend Synchronizer / Updater
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    به‌روزرسانی خودکار سرویس بک‌اند، پایگاه داده و تنظیمات سامانه مرکزی"
echo "=============================================================================="
echo -e "${NC}"

if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}[خطا] این اسکریپت باید با دسترسی root یا sudo اجرا شود.${NC}"
    exit 1
fi

HMH_DIR="/opt/hmh"
if [ ! -d "${HMH_DIR}" ]; then
    echo -e "${YELLOW}پوشه /opt/hmh یافت نشد. آماده‌سازی پوشه جدید...${NC}"
    mkdir -p "${HMH_DIR}"
fi

cd "${HMH_DIR}"

TEMP_DIR=$(mktemp -d)
echo -e "${CYAN}[۱/۴] دریافت آخرین نسخه کدهای بک‌اند از مخزن گیت‌هاب...${NC}"
git clone --depth 1 https://github.com/salehsayyadi/HMH.git "${TEMP_DIR}" > /dev/null 2>&1

mkdir -p "${HMH_DIR}/backend"
cp -rf "${TEMP_DIR}/source/backend/"* "${HMH_DIR}/backend/"
cp -f "${TEMP_DIR}/source/deployment/docker/Dockerfile.backend" "${HMH_DIR}/backend/Dockerfile"
rm -rf "${TEMP_DIR}"

echo -e "${CYAN}[۲/۴] بازسازی (Build) ایمیج بک‌اند بدون کش...${NC}"
docker compose build --no-cache backend

echo -e "${CYAN}[۳/۴] راه‌اندازی و اجرای مجدد سرویس‌ها...${NC}"
docker compose up -d

echo -e "${CYAN}[۴/۴] اجرای اولیه پایگاه داده و ایجاد جداول و کاربر مدیر...${NC}"
sleep 3
docker compose exec -T backend python -c "
import asyncio
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print('Database schema and seed data initialized successfully.')

try:
    asyncio.run(init())
except Exception as e:
    print('Init warning:', e)
"

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  به‌روزرسانی سرور با موفقیت به پایان رسید!"
echo "  وضعیت سلامت سرور:"
docker compose exec -T backend curl -s http://localhost:8000/api/v1/system/health || true
echo ""
echo "=============================================================================="
echo -e "${NC}"
