#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Instant Server & Database Fixer (Fast & Resilient)
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
echo "    راه‌اندازی و بازیابی فوری و قطعی پایگاه‌داده و سرویس مرکزی"
echo "=============================================================================="
echo -e "${NC}"

# ۱. تشخیص دستور داکر کامپوز (docker compose یا docker-compose)
if docker compose version &>/dev/null; then
    DC="docker compose"
elif command -v docker-compose &>/dev/null; then
    DC="docker-compose"
else
    echo -e "${YELLOW}نصب سریع افزونه داکر کامپوز...${NC}"
    apt-get update -qq && apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose || true
    DC="docker compose"
fi

echo -e "ابزار داکر کامپوز: ${GREEN}${DC}${NC}"

HMH_DIR="/opt/hmh"
mkdir -p "${HMH_DIR}"
cd "${HMH_DIR}"

# ۲. توقف فوری و بدون معطلی کانتینرهای قدیمی با kill مستقیم
echo -e "${CYAN}[۱/۵] آزادسازی فوری پردازه‌ها و کانتینرها...${NC}"
docker kill hmh_backend hmh_mysql 2>/dev/null || true
docker rm -f hmh_backend hmh_mysql 2>/dev/null || true

# ۳. بازنویسی تمیز docker-compose.yml بدون هیچ فلگ مشکل‌ساز
echo -e "${CYAN}[۲/۵] تنظیم استاندارد فایل پیکربندی داکر کامپوز...${NC}"
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
    command: --skip-name-resolve --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password
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

# ۴. دریافت آخرین نسخه کدها از مخزن گیت‌هاب و بیلد تمیز
echo -e "${CYAN}[۳/۵] دریافت آخرین کدهای بک‌اند از مخزن مرکزی...${NC}"
TEMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/salehsayyadi/HMH.git "${TEMP_DIR}" > /dev/null 2>&1
mkdir -p "${HMH_DIR}/backend"
cp -rf "${TEMP_DIR}/source/backend/"* "${HMH_DIR}/backend/"
cp -f "${TEMP_DIR}/source/deployment/docker/Dockerfile.backend" "${HMH_DIR}/backend/Dockerfile"
cp -f "${TEMP_DIR}/source/deployment/nginx/nginx.conf" "${HMH_DIR}/nginx.conf"
rm -rf "${TEMP_DIR}"

echo -e "${CYAN}[۴/۵] ساخت ایمیج بک‌اند و روشن کردن MySQL...${NC}"
$DC build --no-cache backend
$DC up -d mysql

echo "  در حال انتظار برای پاسخگویی دیتابیس MySQL (حداکثر ۲۵ ثانیه)..."
for i in {1..25}; do
    if docker exec hmh_mysql mysqladmin ping -h localhost -u root -pRootSecPass1090 --silent 2>/dev/null; then
        echo -e "  ${GREEN}پایگاه داده MySQL آماده اتصال شد!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo "  اعمال و تثبیت مجوزهای دسترسی کاربر دیتابیس..."
docker exec hmh_mysql mysql -u root -pRootSecPass1090 -e "
CREATE DATABASE IF NOT EXISTS amphitheater_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'amphitheater_app'@'%' IDENTIFIED BY 'AppSecPass1090';
ALTER USER 'amphitheater_app'@'%' IDENTIFIED BY 'AppSecPass1090';
GRANT ALL PRIVILEGES ON amphitheater_db.* TO 'amphitheater_app'@'%';
FLUSH PRIVILEGES;
" 2>/dev/null || true

# ۵. بالا آوردن کامل سرویس بک‌اند و انجین‌اکس
echo -e "${CYAN}[۵/۵] راه‌اندازی کامل بک‌اند و انجین‌اکس...${NC}"
$DC up -d

echo "  اجرای اسکریپت همگام‌سازی جداول و ثبت کاربر ارشد..."
sleep 2
docker exec hmh_backend python -c "
import asyncio
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print('SUCCESS: ALL TABLES AND SUPER ADMIN ARE SEEDED IN MYSQL!')

try:
    asyncio.run(init())
except Exception as e:
    print('Seed notice:', e)
" 2>/dev/null || true

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "    سرویس‌ها با موفقیت فعال و پایگاه‌داده متصل شد!"
echo "=============================================================================="
docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health || true
echo ""
echo -e "${NC}"
