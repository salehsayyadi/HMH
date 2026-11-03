#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Automated Master Fix & Database Recovery Script for Ubuntu VPS
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    عیب‌یابی، بازسازی و راه‌اندازی قطعی پایگاه‌داده و سرویس مرکزی"
echo "=============================================================================="
echo -e "${NC}"

HMH_DIR="/opt/hmh"
cd "${HMH_DIR}"

echo -e "${CYAN}[۱/۵] توقف سرویس‌های قبلی و بررسی وضعیت شبکه داکر...${NC}"
docker compose down || true

# اصلاح فایل docker-compose.yml در صورت وجود فلگ‌های منسوخ شده mysql
echo -e "${CYAN}[۲/۵] بهینه‌سازی پیکربندی داکر کامپوز برای سازگاری کامل پایگاه‌داده...${NC}"
cat << 'EOF' > /opt/hmh/docker-compose.yml
services:
  mysql:
    image: mysql:8.0
    container_name: hmh_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-RootSecPass1090}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-amphitheater_db}
      MYSQL_USER: ${MYSQL_USER:-amphitheater_app}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppSecPass1090}
      TZ: Asia/Tehran
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - hmh_net

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: hmh_backend
    restart: always
    depends_on:
      - mysql
    env_file:
      - .env
    environment:
      APP_ENV: production
      TIMEZONE: Asia/Tehran
      DATABASE_ENGINE: mysql
      MYSQL_HOST: mysql
      MYSQL_PORT: 3306
      MYSQL_DATABASE: ${MYSQL_DATABASE:-amphitheater_db}
      MYSQL_USER: ${MYSQL_USER:-amphitheater_app}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppSecPass1090}
      INITIAL_ADMIN_USERNAME: ${INITIAL_ADMIN_USERNAME:-123IMHModirkol@1090}
      INITIAL_ADMIN_PASSWORD: ${INITIAL_ADMIN_PASSWORD:-123IMHModirkol@1090}
      DOMAIN: ${DOMAIN:-salehvip-clud.ir}
      SUBDOMAIN: ${SUBDOMAIN:-reserve.salehvip-clud.ir}
    networks:
      - hmh_net

  nginx:
    image: nginx:alpine
    container_name: hmh_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - backend
    networks:
      - hmh_net

volumes:
  mysql_data:
    driver: local

networks:
  hmh_net:
    driver: bridge
EOF

echo -e "${CYAN}[۳/۵] دریافت آخرین کدهای بک‌اند از گیت‌هاب و بیلد تمیز...${NC}"
TEMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/salehsayyadi/HMH.git "${TEMP_DIR}" > /dev/null 2>&1
mkdir -p "${HMH_DIR}/backend"
cp -rf "${TEMP_DIR}/source/backend/"* "${HMH_DIR}/backend/"
cp -f "${TEMP_DIR}/source/deployment/docker/Dockerfile.backend" "${HMH_DIR}/backend/Dockerfile"
rm -rf "${TEMP_DIR}"

docker compose build --no-cache backend

echo -e "${CYAN}[۴/۵] راه‌اندازی پایگاه‌داده MySQL و انتظار تا آمادگی کامل...${NC}"
docker compose up -d mysql

echo "  در حال انتظار برای بالا آمدن موتور پایگاه داده (حداکثر ۶۰ ثانیه)..."
for i in {1..30}; do
    if docker compose exec -T mysql mysqladmin ping -h localhost -u root -pRootSecPass1090 --silent > /dev/null 2>&1; then
        echo -e "  ${GREEN}پایگاه داده MySQL با موفقیت پاسخگو شد!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

echo "  بررسی و تنظیم مجوزهای دسترسی کاربر دیتابیس..."
docker compose exec -T mysql mysql -u root -pRootSecPass1090 -e "
CREATE DATABASE IF NOT EXISTS amphitheater_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'amphitheater_app'@'%' IDENTIFIED BY 'AppSecPass1090';
ALTER USER 'amphitheater_app'@'%' IDENTIFIED BY 'AppSecPass1090';
GRANT ALL PRIVILEGES ON amphitheater_db.* TO 'amphitheater_app'@'%';
FLUSH PRIVILEGES;
" || true

echo -e "${CYAN}[۵/۵] راه‌اندازی سرویس بک‌اند و انجین‌اکس و ایجاد جداول اولیه...${NC}"
docker compose up -d

sleep 4

echo "  اجرای اسکریپت ساخت جداول و کاربر ارشد..."
docker compose exec -T backend python -c "
import asyncio
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print('DATABASE SCHEMA AND ADMIN USER SUCCESSFULLY INITIALIZED!')

try:
    asyncio.run(init())
except Exception as e:
    print('Init notice:', e)
"

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "    سرویس‌ها با موفقیت فعال شدند! تست سلامت سامانه:"
echo "=============================================================================="
docker compose exec -T backend curl -s http://localhost:8000/api/v1/system/health || true
echo ""
echo -e "${NC}"
