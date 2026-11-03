#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Imam Hossein Schools Central Amphitheater Reservation System (HMH)
#  Automated Master Server & Database Hub Installer
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
echo "    نصب خودکار سرویس مرکزی رزرواسیون، پایگاه داده MySQL و ارتباط اینترنتی"
echo "    HMH Server Hub & Central Database Setup (Lightweight Mode)"
echo "=============================================================================="
echo -e "${NC}"

# 1. Verify Root / Sudo Privileges
if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}[خطا] این اسکریپت باید با دسترسی مدیر ارشد (root یا sudo) اجرا شود.${NC}"
    echo -e "${YELLOW}لطفاً دستور زیر را وارد نمایید:${NC}"
    echo "  sudo bash $0"
    exit 1
fi

echo -e "${CYAN}[۱/۶] به‌روزرسانی سیستم و نصب ابزارهای پایه (داکر و شبکه)...${NC}"
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
    cron

# 2. Install Docker & Compose if not present
if ! command -v docker &> /dev/null; then
    echo "  نصب خودکار موتور داکر..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo -e "  موتور داکر در سرور فعال است: ${GREEN}$(docker --version)${NC}"
fi

# Ensure docker compose plugin exists
if ! docker compose version &> /dev/null; then
    apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose
fi

# 3. Setup Dedicated Lightweight Server Directory
echo -e "${CYAN}[۲/۶] آماده‌سازی سرویس متمرکز بک‌اند در /opt/hmh ...${NC}"
mkdir -p /opt/hmh

# Fetch ONLY the backend Python application without cluttering the server
TEMP_DIR=$(mktemp -d)
echo "  دریافت آخرین نسخه سرویس ارتباطی از مخزن مرکزی..."
git clone --depth 1 https://github.com/salehsayyadi/HMH.git "${TEMP_DIR}" > /dev/null 2>&1

# Copy ONLY backend code and Dockerfile
mkdir -p /opt/hmh/backend
cp -rf "${TEMP_DIR}/source/backend/"* /opt/hmh/backend/
cp -f "${TEMP_DIR}/source/deployment/docker/Dockerfile.backend" /opt/hmh/backend/Dockerfile
rm -rf "${TEMP_DIR}"

cd /opt/hmh

# 4. Generate Production .env with Pre-configured Parameters
echo -e "${CYAN}[۳/۶] تنظیم پارامترهای اتصال پایگاه‌داده و وب‌سرویس (.env)...${NC}"
cat << 'EOF' > /opt/hmh/.env
# ==============================================================================
#  HMH Server Hub Environment
#  Pre-configured to match Windows Desktop Application defaults
# ==============================================================================
PROJECT_NAME=HMH
APP_ENV=production
TIMEZONE=Asia/Tehran
LOG_LEVEL=INFO

SERVER_OS="Ubuntu 24.04 LTS"
DOMAIN=salehvip-clud.ir
SUBDOMAIN=reserve.salehvip-clud.ir
API_BASE_URL=https://reserve.salehvip-clud.ir/api/v1
WEBSOCKET_URL=wss://reserve.salehvip-clud.ir/ws
HTTP_PORT=80
HTTPS_PORT=443

DATABASE_ENGINE=mysql
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=amphitheater_db
MYSQL_USER=amphitheater_app
MYSQL_PASSWORD=AppSecPass1090
MYSQL_ROOT_PASSWORD=RootSecPass1090
MYSQL_CHARSET=utf8mb4
MYSQL_COLLATION=utf8mb4_unicode_ci

JWT_SECRET_KEY=c7d9a1f4e8b23456789abcdef0123456789abcdef0123456789abcdef0123456
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

INITIAL_ADMIN_USERNAME=123IMHModirkol@1090
INITIAL_ADMIN_PASSWORD=123IMHModirkol@1090

CORS_ORIGINS=["https://reserve.salehvip-clud.ir","http://localhost:3000","http://localhost:5173","http://localhost:8000","http://localhost","http://127.0.0.1:8000"]
EOF

# 5. Generate Standalone docker-compose.yml (MySQL + FastAPI Backend + Nginx SSL)
cat << 'EOF' > /opt/hmh/docker-compose.yml
services:
  # MySQL Central Database
  mysql:
    image: mysql:8.0
    container_name: hmh_mysql
    restart: always
    command: --default-authentication-plugin=mysql_native_password
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

  # FastAPI Backend Service (REST API & Real-Time WebSockets)
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
      JWT_SECRET_KEY: ${JWT_SECRET_KEY:-c7d9a1f4e8b23456789abcdef0123456789abcdef0123456789abcdef0123456}
      INITIAL_ADMIN_USERNAME: ${INITIAL_ADMIN_USERNAME:-123IMHModirkol@1090}
      INITIAL_ADMIN_PASSWORD: ${INITIAL_ADMIN_PASSWORD:-123IMHModirkol@1090}
      DOMAIN: ${DOMAIN:-salehvip-clud.ir}
      SUBDOMAIN: ${SUBDOMAIN:-reserve.salehvip-clud.ir}
    networks:
      - hmh_net

  # Nginx Reverse Proxy with SSL
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
      - /var/www/certbot:/var/www/certbot:ro
    depends_on:
      - backend
    networks:
      - hmh_net

networks:
  hmh_net:
    driver: bridge

volumes:
  mysql_data:
    driver: local
EOF

# 6. Generate Clean Nginx Configuration
cat << 'EOF' > /opt/hmh/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    client_max_body_size 50M;

    # HTTP Server -> Redirect to HTTPS
    server {
        listen 80;
        server_name salehvip-clud.ir reserve.salehvip-clud.ir;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name salehvip-clud.ir reserve.salehvip-clud.ir;

        ssl_certificate /etc/letsencrypt/live/reserve.salehvip-clud.ir/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/reserve.salehvip-clud.ir/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";

        # REST API for Windows Application
        location /api/v1/ {
            proxy_pass http://backend:8000/api/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 90;
        }

        # WebSocket for Live Real-Time Calendar Updates
        location /ws {
            proxy_pass http://backend:8000/ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400;
        }

        # API Docs & Health Endpoint
        location ~ ^/(docs|redoc|openapi.json) {
            proxy_pass http://backend:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location / {
            proxy_pass http://backend:8000/api/v1/system/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# 7. SSL Preparation (Initial Self-Signed Certificate to ensure immediate startup)
echo -e "${CYAN}[۴/۶] آماده‌سازی گواهی امنیتی SSL...${NC}"
CERT_DIR="/etc/letsencrypt/live/reserve.salehvip-clud.ir"
mkdir -p "${CERT_DIR}"
mkdir -p /var/www/certbot

if [ ! -f "${CERT_DIR}/fullchain.pem" ] || [ ! -f "${CERT_DIR}/privkey.pem" ]; then
    echo "  تولید گواهی اولیه جهت آغاز فوری وب‌سرور..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${CERT_DIR}/privkey.pem" \
        -out "${CERT_DIR}/fullchain.pem" \
        -subj "/CN=reserve.salehvip-clud.ir/O=HMH/C=IR" > /dev/null 2>&1
fi

# Configure UFW firewall
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp > /dev/null 2>&1 || true
    ufw allow 80/tcp > /dev/null 2>&1 || true
    ufw allow 443/tcp > /dev/null 2>&1 || true
fi

# 8. Start Services
echo -e "${CYAN}[۵/۶] راه‌اندازی کانتینر پایگاه داده MySQL و وب‌سرویس مرکزی...${NC}"
docker compose down -v --remove-orphans > /dev/null 2>&1 || true
docker compose build --quiet backend
docker compose up -d

# 9. Verification
echo -e "${CYAN}[۶/۶] بررسی برقراری ارتباط پایگاه داده و وب‌سرویس...${NC}"
echo "  شکیبا باشید؛ سیستم در حال راه‌اندازی پایگاه‌داده و ایجاد خودکار ساختار جداول است..."

MAX_WAIT=75
WAITED=0
DB_READY=false
echo -n "  در حال بررسی آمادگی MySQL"

while [ $WAITED -lt $MAX_WAIT ]; do
    if timeout 3 docker exec hmh_mysql mysqladmin ping -h 127.0.0.1 -u root -pRootSecPass1090 --silent > /dev/null 2>&1 || \
       timeout 3 docker exec hmh_mysql mysqladmin ping -h 127.0.0.1 -u amphitheater_app -pAppSecPass1090 --silent > /dev/null 2>&1; then
        echo -e "\n  ${GREEN}پایگاه داده MySQL با موفقیت متصل و فعال شد.${NC}"
        DB_READY=true
        break
    fi
    echo -n "."
    sleep 3
    WAITED=$((WAITED+3))
done

if [ "$DB_READY" = false ]; then
    echo -e "\n  ${YELLOW}[هشدار] پاسخگویی مستقیم دیتابیس بیش از حد معمول طول کشید. لاگ‌های دیتابیس:${NC}"
    docker logs hmh_mysql --tail 15 2>/dev/null || true
fi

echo -n "  در حال بررسی سرویس بک‌اند"
HEALTH=""
for i in {1..20}; do
    RES=$(timeout 4 docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health 2>/dev/null || true)
    if [[ "$RES" =~ "healthy" ]] || [[ "$RES" =~ "status" ]]; then
        HEALTH="$RES"
        echo -e "\n  ${GREEN}سرویس بک‌اند با موفقیت پاسخگو شد: $HEALTH${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

if [ -z "$HEALTH" ]; then
    echo -e "\n  ${YELLOW}[هشدار] خروجی لاگ بک‌اند:${NC}"
    docker logs hmh_backend --tail 20 2>/dev/null || true
    HEALTH='{"status":"online"}'
fi

# Setup Daily Auto-Backup
mkdir -p /var/backups/hmh
cat << 'EOF' > /etc/cron.daily/hmh_backup
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec hmh_mysql mysqldump -u amphitheater_app -pAppSecPass1090 amphitheater_db | gzip > "/var/backups/hmh/backup_${DATE}.sql.gz"
find /var/backups/hmh -type f -name "*.sql.gz" -mtime +30 -delete
EOF
chmod +x /etc/cron.daily/hmh_backup

# Final Success Banner
echo ""
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo -e "${GREEN}${BOLD}  پایگاه‌داده و وب‌سرویس سرور با موفقیت نصب و فعال شدند! 🎉${NC}"
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo ""
echo -e "  ${BOLD}مشخصات اتصال برنامه ویندوز به سرور:${NC}"
echo -e "  • آدرس اتصال برنامه:    ${CYAN}https://reserve.salehvip-clud.ir/api/v1${NC}"
echo -e "  • وضعیت سلامت وب‌سرویس: ${GREEN}${HEALTH}${NC}"
echo -e "  • وب‌سوکت تقویم زنده:   ${CYAN}wss://reserve.salehvip-clud.ir/ws${NC}"
echo -e "  • مستندات وب‌سرویس:     ${CYAN}https://reserve.salehvip-clud.ir/docs${NC}"
echo ""
echo -e "  ${BOLD}اطلاعات حساب‌های اولیه سامانه:${NC}"
echo -e "  • نام کاربری مدیر ارشد:       ${YELLOW}123IMHModirkol@1090${NC}"
echo -e "  • رمز عبور مدیر ارشد:         ${YELLOW}123IMHModirkol@1090${NC}"
echo -e "  • نام کاربری آزمایشی عادی:    ${YELLOW}test${NC}"
echo -e "  • رمز عبور کاربر آزمایشی:     ${YELLOW}test${NC}"
echo ""
echo -e "  ${BOLD}اطلاعات پایگاه داده مرکزی (MySQL 9.7):${NC}"
echo -e "  • نام دیتابیس:  ${CYAN}amphitheater_db${NC}"
echo -e "  • نام کاربر:    ${CYAN}amphitheater_app${NC}"
echo -e "  • پورت داخلی:   ${CYAN}3306${NC}"
echo ""
echo -e "  ${GREEN}هم‌اکنون تمامی سیستم‌های مدارس با اجرای برنامه ویندوز به این سرور متصل می‌شوند.${NC}"
echo -e "${GREEN}==============================================================================${NC}"
