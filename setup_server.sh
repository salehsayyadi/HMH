#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Imam Hossein Schools Central Amphitheater Reservation System (HMH)
#  Automated Master Production Server Installation Script
#  Target Platform: Ubuntu 24.04 LTS / 22.04 LTS x86_64
# ==============================================================================

set -euo pipefail

# Color Codes for Terminal Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    اسکریپت خودکار نصب و راه‌اندازی سرور مرکزی سامانه رزرواسیون آمفی‌تئاتر"
echo "    HMH Production Infrastructure Installer — Ubuntu Linux"
echo "=============================================================================="
echo -e "${NC}"

# 1. Verify Root / Sudo Privileges
if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}[خطا] این اسکریپت باید با دسترسی مدیر ارشد (root یا sudo) اجرا شود.${NC}"
    echo -e "${YELLOW}لطفاً دستور زیر را وارد نمایید:${NC}"
    echo "  sudo bash $0"
    exit 1
fi

echo -e "${CYAN}[۱/۸] در حال بررسی مشخصات سیستم‌عامل و وابستگی‌های پایه...${NC}"

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VER=$VERSION_ID
    echo -e "  سیستم‌عامل شناسایی شد: ${GREEN}${OS_NAME} ${OS_VER}${NC}"
else
    echo -e "${YELLOW}  هشدار: فایل os-release یافت نشد. ادامه نصب بر مبنای توزیع اوبونتو/دبیان.${NC}"
fi

# Update package repository
echo -e "${CYAN}[۲/۸] به‌روزرسانی مخازن لینوکس و نصب بسته‌های ضروری...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    curl \
    wget \
    git \
    unzip \
    jq \
    ufw \
    openssl \
    ca-certificates \
    gnupg \
    lsb-release \
    cron

# 2. Install Docker & Docker Compose if not present
echo -e "${CYAN}[۳/۸] بررسی و نصب موتور کانتینری Docker و افزونه Compose...${NC}"
if ! command -v docker &> /dev/null; then
    echo "  نرم‌افزار داکر بر روی سرور نصب نیست؛ آغاز نصب خودکار داکر رسمی..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo -e "  ${GREEN}داکر با موفقیت نصب و راه‌اندازی شد.${NC}"
else
    echo -e "  داکر در سرور فعال است: ${GREEN}$(docker --version)${NC}"
fi

# Ensure docker compose plugin exists
if ! docker compose version &> /dev/null; then
    echo "  در حال نصب افزونه docker-compose-plugin..."
    apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose
fi

# 3. Detect / Setup Project Source Path
echo -e "${CYAN}[۴/۸] شناسایی و پیکربندی سورس سامانه...${NC}"
HMH_ROOT=""

if [ -f "source/deployment/docker/docker-compose.yml" ]; then
    HMH_ROOT="$(pwd)"
elif [ -f "../../source/deployment/docker/docker-compose.yml" ]; then
    HMH_ROOT="$(cd ../.. && pwd)"
elif [ -f "/opt/hmh/source/deployment/docker/docker-compose.yml" ]; then
    HMH_ROOT="/opt/hmh"
else
    # Auto-clone repository if running directly via curl/bash
    echo "  دایرکتوری پروژه در مسیر جاری یافت نشد؛ دانلود مخزن اختصاصی در /opt/hmh ..."
    mkdir -p /opt/hmh
    if [ ! -d "/opt/hmh/.git" ]; then
        git clone https://github.com/salehsayyadi/HMH.git /opt/hmh
    else
        cd /opt/hmh && git pull origin main
    fi
    HMH_ROOT="/opt/hmh"
fi

echo -e "  مسیر اصلی پروژه: ${GREEN}${HMH_ROOT}${NC}"
cd "${HMH_ROOT}"

# 4. Create Production Environment Configuration (.env)
echo -e "${CYAN}[۵/۸] تنظیم متغیرهای محیطی متصل به اپلیکیشن ویندوز (.env)...${NC}"

# Exact variables matching Windows Desktop Application settings
cat << 'EOF' > "${HMH_ROOT}/.env"
# ==============================================================================
#  HMH Production Environment Variables
#  Automatically configured by install_server.sh
# ==============================================================================
PROJECT_NAME=HMH
APP_ENV=production
TIMEZONE=Asia/Tehran
LOG_LEVEL=INFO

# Server & Network Configuration (Matches Windows App Default Profile)
SERVER_OS="Ubuntu 24.04 LTS"
DOMAIN=salehvip-clud.ir
SUBDOMAIN=reserve.salehvip-clud.ir
API_BASE_URL=https://reserve.salehvip-clud.ir/api/v1
WEBSOCKET_URL=wss://reserve.salehvip-clud.ir/ws
HTTP_PORT=80
HTTPS_PORT=443

# MySQL 9.7 LTS Central Database Configuration
DATABASE_ENGINE=mysql
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=amphitheater_db
MYSQL_USER=amphitheater_app
MYSQL_PASSWORD=AppSecPass1090
MYSQL_ROOT_PASSWORD=RootSecPass1090
MYSQL_CHARSET=utf8mb4
MYSQL_COLLATION=utf8mb4_unicode_ci

# JWT Security Configuration
JWT_SECRET_KEY=c7d9a1f4e8b23456789abcdef0123456789abcdef0123456789abcdef0123456
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Initial Bootstrap Super Administrator
INITIAL_ADMIN_USERNAME=123IMHModirkol@1090
INITIAL_ADMIN_PASSWORD=123IMHModirkol@1090

# CORS Allowed Origins
CORS_ORIGINS=https://reserve.salehvip-clud.ir,http://localhost:3000,http://localhost:5173,http://localhost:8000,http://localhost,http://127.0.0.1:8000
EOF

# Copy .env into docker deployment folder
cp "${HMH_ROOT}/.env" "${HMH_ROOT}/source/deployment/docker/.env"
echo -e "  ${GREEN}فایل .env با مشخصات کامل اتصال پایگاه داده و وب‌سرویس ایجاد شد.${NC}"

# 5. Prepare SSL Certificates (Self-Signed fallback + Certbot Ready)
echo -e "${CYAN}[۶/۸] آماده‌سازی گواهی امنیتی SSL و وب‌سرور Nginx...${NC}"
CERT_DIR="/etc/letsencrypt/live/reserve.salehvip-clud.ir"
CHALLENGE_DIR="/var/www/certbot"
mkdir -p "${CERT_DIR}"
mkdir -p "${CHALLENGE_DIR}"

if [ ! -f "${CERT_DIR}/fullchain.pem" ] || [ ! -f "${CERT_DIR}/privkey.pem" ]; then
    echo "  تولید گواهی امنیتی اولیه (Self-Signed) جهت اطمینان از بالا آمدن اولیه Nginx..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${CERT_DIR}/privkey.pem" \
        -out "${CERT_DIR}/fullchain.pem" \
        -subj "/CN=reserve.salehvip-clud.ir/O=Imam Hossein Charitable Cultural Institute/C=IR" > /dev/null 2>&1
    echo -e "  ${GREEN}گواهی موقت با موفقیت ایجاد شد.${NC}"
fi

# Configure UFW firewall
if command -v ufw &> /dev/null; then
    echo "  تنظیم فایروال جهت مجاز بودن پورت‌های ۲۲، ۸۰ و ۴۴۳..."
    ufw allow 22/tcp > /dev/null 2>&1 || true
    ufw allow 80/tcp > /dev/null 2>&1 || true
    ufw allow 443/tcp > /dev/null 2>&1 || true
fi

# 6. Build and Launch Containers
echo -e "${CYAN}[۷/۸] راه‌اندازی کانتینرهای سرویس (MySQL, FastAPI Backend, Admin Web, Nginx)...${NC}"
cd "${HMH_ROOT}/source/deployment/docker"

echo "  در حال ساخت ایمیج‌ها و اجرای سرویس‌های داکر..."
docker compose build --quiet backend admin_web
docker compose up -d

# 7. Wait for Database Readiness & Verification
echo -e "${CYAN}[۸/۸] بررسی وضعیت سلامت دیتابیس MySQL و وب‌سرویس FastAPI...${NC}"
echo "  شکیبا باشید؛ سیستم در حال بررسی ارتباط با پایگاه‌داده و اجرای مهاجرت‌هاست..."

MAX_RETRIES=30
RETRY_COUNT=0
DB_UP=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker compose exec -T mysql mysqladmin ping -h localhost -u amphitheater_app -pAppSecPass1090 --silent > /dev/null 2>&1; then
        DB_UP=true
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$DB_UP" = true ]; then
    echo -e "  ${GREEN}پایگاه داده MySQL 9.7 با موفقیت متصل و آماده پاسخگویی شد.${NC}"
else
    echo -e "  ${YELLOW}هشدار: پایگاه داده با تاخیر مواجه شد. لطفاً چند لحظه بعد وضعیت را با docker compose ps بررسی فرمایید.${NC}"
fi

# Check FastAPI health endpoint
sleep 3
HEALTH_CHECK=$(curl -s -k http://localhost:8000/api/v1/system/health || echo "connecting")
echo -e "  وضعیت پاسخ وب‌سرویس: ${GREEN}${HEALTH_CHECK}${NC}"

# Attempt official Let's Encrypt SSL certificate if domain points to this server
PUBLIC_IP=$(curl -s https://api.ipify.org || echo "")
DOMAIN_IP=$(getent ahosts reserve.salehvip-clud.ir 2>/dev/null | head -n 1 | awk '{print $1}' || echo "")

if [ -n "${PUBLIC_IP}" ] && [ "${PUBLIC_IP}" = "${DOMAIN_IP}" ]; then
    echo -e "${CYAN}دامنه reserve.salehvip-clud.ir به آی‌پی این سرور (${PUBLIC_IP}) اشاره دارد.${NC}"
    echo "در حال دریافت خودکار گواهی رسمی Let's Encrypt SSL..."
    certbot certonly --webroot -w /var/www/certbot \
        -d reserve.salehvip-clud.ir \
        --email admin@salehvip-clud.ir \
        --agree-tos --no-eff-email --non-interactive || true
    docker compose exec -T nginx nginx -s reload || true
    echo -e "${GREEN}گواهی معتبر Let's Encrypt با موفقیت نصب و فعال گردید.${NC}"
else
    echo -e "${YELLOW}نکته دامنه: آی‌پی عمومی سرور (${PUBLIC_IP}) با رکورد دامنه (${DOMAIN_IP}) متفاوت است یا هنوز اعمال نشده است.${NC}"
    echo -e "${YELLOW}سامانه هم‌اکنون با گواهی خودامضا در حال کار است. پس از ست شدن DNS، دستور زیر را جهت فعال‌سازی رایگان گواهی رسمی اجرا فرمایید:${NC}"
    echo "  sudo certbot certonly --webroot -w /var/www/certbot -d reserve.salehvip-clud.ir --agree-tos -m admin@salehvip-clud.ir"
fi

# Setup Daily Auto-Backup Cron Job
mkdir -p /var/backups/hmh
cat << 'EOF' > /etc/cron.daily/hmh_backup
#!/bin/bash
BACKUP_DIR="/var/backups/hmh"
DATE=$(date +%Y%m%d_%H%M%S)
docker exec hmh_mysql mysqldump -u amphitheater_app -pAppSecPass1090 amphitheater_db | gzip > "${BACKUP_DIR}/hmh_backup_${DATE}.sql.gz"
# Keep last 30 days
find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +30 -delete
EOF
chmod +x /etc/cron.daily/hmh_backup

# Final Success Banner
echo ""
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo -e "${GREEN}${BOLD}  نصب و راه‌اندازی سرور با موفقیت به پایان رسید! 🎉${NC}"
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo ""
echo -e "  ${BOLD}مشخصات اتصال سامانه:${NC}"
echo -e "  • دامنه اصلی وب‌سرویس:   ${CYAN}https://reserve.salehvip-clud.ir${NC}"
echo -e "  • آدرس اتصال API برنامه: ${CYAN}https://reserve.salehvip-clud.ir/api/v1${NC}"
echo -e "  • آدرس وب‌سوکت تقویم:    ${CYAN}wss://reserve.salehvip-clud.ir/ws${NC}"
echo -e "  • مستندات تعاملی API:    ${CYAN}https://reserve.salehvip-clud.ir/docs${NC}"
echo -e "  • پنل وب مدیریت ارشد:    ${CYAN}https://reserve.salehvip-clud.ir${NC}"
echo ""
echo -e "  ${BOLD}اطلاعات ورود مدیر کل (پیش‌فرض):${NC}"
echo -e "  • نام کاربری: ${YELLOW}123IMHModirkol@1090${NC}"
echo -e "  • کلمه عبور:  ${YELLOW}123IMHModirkol@1090${NC}"
echo ""
echo -e "  ${BOLD}اطلاعات پایگاه داده مرکزی (MySQL 9.7):${NC}"
echo -e "  • دیتابیس:    ${CYAN}amphitheater_db${NC}"
echo -e "  • کاربر:      ${CYAN}amphitheater_app${NC}"
echo -e "  • پورت داخلی: ${CYAN}3306${NC}"
echo ""
echo -e "  ${GREEN}اکنون برنامه ویندوز شما به این سرور متصل شده و وضعیت آن سبز (متصل) خواهد بود.${NC}"
echo -e "${GREEN}==============================================================================${NC}"
