#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Ultra-Fast Master Server & Database Hub Installer (Optimized for 10Gbps Networks)
#  Target Platform: Ubuntu 24.04 LTS / 22.04 LTS x86_64
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
echo "    نصب خودکار، پرسرعت و بهینه‌سازی‌شده سامانه مرکزی (دامنه kirkir)"
echo "=============================================================================="
echo -e "${NC}"

if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}[خطا] این اسکریپت باید با دسترسی روت (root یا sudo) اجرا شود.${NC}"
    exit 1
fi

# ۱. نصب هوشمند و فوری پیش‌نیازهای پایه (فقط موارد ناموجود)
echo -e "${CYAN}[۱/۶] بررسی سریع ابزارهای پایه...${NC}"
MISSING_PKGS=()
for pkg in curl wget openssl ufw cron tar; do
    if ! command -v "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  نصب موارد ناموجود: ${MISSING_PKGS[*]}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq -o Acquire::ForceIPv4=true
    apt-get install -y -qq --no-install-recommends "${MISSING_PKGS[@]}"
fi

# ۲. اطمینان از فعال بودن موتور داکر
if ! command -v docker &> /dev/null; then
    echo "  نصب خودکار و پرسرعت موتور داکر..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
else
    echo -e "  موتور داکر آماده است: ${GREEN}$(docker --version)${NC}"
fi

# تشخیص داکر کامپوز
if docker compose version &>/dev/null; then
    DC="docker compose"
elif command -v docker-compose &>/dev/null; then
    DC="docker-compose"
else
    apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose || true
    DC="docker compose"
fi

HMH_DIR="/opt/hmh"
mkdir -p "${HMH_DIR}/backend"
cd "${HMH_DIR}"

# ۳. دریافت فوری کدهای منبع با تاربال مستقیم از گیت‌هاب (زیر ۱ ثانیه)
echo -e "${CYAN}[۲/۶] بارگذاری صاعقه‌ای کدهای منبع از مخزن مرکزی...${NC}"
TEMP_TAR=$(mktemp -d)
curl -fsSL https://github.com/salehsayyadi/HMH/archive/refs/heads/main.tar.gz | tar -xz -C "${TEMP_TAR}" --strip-components=1
cp -rf "${TEMP_TAR}/source/backend/"* "${HMH_DIR}/backend/"
cp -f "${TEMP_TAR}/source/deployment/docker/Dockerfile.backend" "${HMH_DIR}/backend/Dockerfile"
rm -rf "${TEMP_TAR}"

# ۴. تولید فایل متغیرهای محیطی .env
echo -e "${CYAN}[۳/۶] تنظیم پارامترهای ارتباطی و امنیتی (.env)...${NC}"
cat << 'EOF' > /opt/hmh/.env
PROJECT_NAME=HMH
APP_ENV=production
TIMEZONE=Asia/Tehran
LOG_LEVEL=INFO

SERVER_OS="Ubuntu 24.04 LTS"
DOMAIN=salehvip-clud.ir
SUBDOMAIN=kirkir.salehvip-clud.ir
API_BASE_URL=https://kirkir.salehvip-clud.ir/api/v1
WEBSOCKET_URL=wss://kirkir.salehvip-clud.ir/ws
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

CORS_ORIGINS=["https://kirkir.salehvip-clud.ir","https://reserve.salehvip-clud.ir","http://localhost:3000","http://localhost:5173","http://localhost:8000","http://localhost","http://127.0.0.1:8000"]
EOF

# ۵. تولید فایل پیکربندی docker-compose.yml با اعمال skip-name-resolve در MySQL
cat << 'EOF' > /opt/hmh/docker-compose.yml
services:
  mysql:
    image: mysql:8.0
    container_name: hmh_mysql
    restart: always
    command: --skip-name-resolve --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
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
      JWT_SECRET_KEY: ${JWT_SECRET_KEY:-c7d9a1f4e8b23456789abcdef0123456789abcdef0123456789abcdef0123456}
      INITIAL_ADMIN_USERNAME: ${INITIAL_ADMIN_USERNAME:-123IMHModirkol@1090}
      INITIAL_ADMIN_PASSWORD: ${INITIAL_ADMIN_PASSWORD:-123IMHModirkol@1090}
      DOMAIN: ${DOMAIN:-salehvip-clud.ir}
      SUBDOMAIN: ${SUBDOMAIN:-kirkir.salehvip-clud.ir}
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

# ۶. تولید پیکربندی پرسرعت و پایدار Nginx
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

    server {
        listen 80;
        server_name salehvip-clud.ir kirkir.salehvip-clud.ir reserve.salehvip-clud.ir;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        server_name salehvip-clud.ir kirkir.salehvip-clud.ir reserve.salehvip-clud.ir;

        ssl_certificate /etc/letsencrypt/live/kirkir.salehvip-clud.ir/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/kirkir.salehvip-clud.ir/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";

        location /api/v1/ {
            proxy_pass http://backend:8000/api/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 90;
        }

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

# ۷. آماده‌سازی فوری گواهی امنیتی SSL
echo -e "${CYAN}[۴/۶] آماده‌سازی گواهی امنیتی SSL...${NC}"
CERT_DIR="/etc/letsencrypt/live/kirkir.salehvip-clud.ir"
mkdir -p "${CERT_DIR}"
mkdir -p /var/www/certbot

if [ ! -f "${CERT_DIR}/fullchain.pem" ] || [ ! -f "${CERT_DIR}/privkey.pem" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${CERT_DIR}/privkey.pem" \
        -out "${CERT_DIR}/fullchain.pem" \
        -subj "/CN=kirkir.salehvip-clud.ir/O=HMH/C=IR" > /dev/null 2>&1
fi

# پیکربندی فایروال
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp > /dev/null 2>&1 || true
    ufw allow 80/tcp > /dev/null 2>&1 || true
    ufw allow 443/tcp > /dev/null 2>&1 || true
fi

# ۸. ساخت موازی و راه‌اندازی کانتینرها با BuildKit (بسیار پرسرعت)
echo -e "${CYAN}[۵/۶] بیلد و راه‌اندازی پرسرعت کانتینرها...${NC}"
export DOCKER_BUILDKIT=1
$DC down -v --remove-orphans > /dev/null 2>&1 || true
$DC build backend
$DC up -d

# ۹. بررسی برقراری اتصال با سرعت بالا
echo -e "${CYAN}[۶/۶] پایش اتصال پایگاه داده و سرویس...${NC}"
echo -n "  در حال انتظار برای MySQL"
for i in {1..25}; do
    if docker exec hmh_mysql mysqladmin ping -h 127.0.0.1 -u root -pRootSecPass1090 --silent > /dev/null 2>&1 || \
       docker exec hmh_mysql mysqladmin ping -h 127.0.0.1 -u amphitheater_app -pAppSecPass1090 --silent > /dev/null 2>&1; then
        echo -e "\n  ${GREEN}پایگاه داده MySQL آماده شد!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo -n "  در حال بررسی سرویس بک‌اند"
HEALTH=""
for i in {1..20}; do
    RES=$(docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health 2>/dev/null || true)
    if [[ "$RES" =~ "healthy" ]] || [[ "$RES" =~ "status" ]]; then
        HEALTH="$RES"
        echo -e "\n  ${GREEN}سرویس بک‌اند با موفقیت پاسخگو شد: $HEALTH${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# تنظیم بکاپ روزانه
mkdir -p /var/backups/hmh
cat << 'EOF' > /etc/cron.daily/hmh_backup
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec hmh_mysql mysqldump -u amphitheater_app -pAppSecPass1090 amphitheater_db | gzip > "/var/backups/hmh/backup_${DATE}.sql.gz" 2>/dev/null || true
find /var/backups/hmh -type f -name "*.sql.gz" -mtime +30 -delete 2>/dev/null || true
EOF
chmod +x /etc/cron.daily/hmh_backup 2>/dev/null || true

# بنر نهایی موفقیت
echo ""
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo -e "${GREEN}${BOLD}  نصب سامانه با حداکثر سرعت با موفقیت انجام شد! 🎉${NC}"
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo ""
echo -e "  ${BOLD}مشخصات اتصال:${NC}"
echo -e "  • آدرس وب‌سرویس:        ${CYAN}https://kirkir.salehvip-clud.ir/api/v1${NC}"
echo -e "  • وضعیت سلامت:          ${GREEN}${HEALTH}${NC}"
echo -e "  • وب‌سوکت تقویم:        ${CYAN}wss://kirkir.salehvip-clud.ir/ws${NC}"
echo -e "  • مستندات وب‌سرویس:     ${CYAN}https://kirkir.salehvip-clud.ir/docs${NC}"
echo ""
echo -e "  ${BOLD}اطلاعات حساب پیش‌فرض مدیر ارشد:${NC}"
echo -e "  • نام کاربری: ${YELLOW}123IMHModirkol@1090${NC}"
echo -e "  • رمز عبور:   ${YELLOW}123IMHModirkol@1090${NC}"
echo ""
echo -e "${GREEN}==============================================================================${NC}"
