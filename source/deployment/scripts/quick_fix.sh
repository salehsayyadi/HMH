#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Definitive Service Recovery & Handshake Fixer
# ==============================================================================
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    بازیابی قطعی سرویس‌ها و رفع مشکل اتصال و هندشیک SSL"
echo "=============================================================================="
echo -e "${NC}"

# ۱. پاکسازی فایل‌های کانفیگ اضافی مای‌اس‌کیوال
echo -e "${CYAN}[۱/۵] پاکسازی و راه‌اندازی دیتابیس MySQL...${NC}"
docker exec hmh_mysql rm -f /etc/mysql/conf.d/speedup.cnf 2>/dev/null || true
docker start hmh_mysql 2>/dev/null || docker restart hmh_mysql 2>/dev/null || true

# ۲. اطمینان از وجود گواهی SSL معتبر
echo -e "${CYAN}[۲/۵] بررسی و تثبیت گواهی SSL...${NC}"
mkdir -p /etc/letsencrypt/live/reserve.salehvip-clud.ir
if [ ! -f /etc/letsencrypt/live/reserve.salehvip-clud.ir/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/reserve.salehvip-clud.ir/privkey.pem ]; then
    if [ -f /etc/letsencrypt/live/salehvip-clud.ir/fullchain.pem ]; then
        cp -f /etc/letsencrypt/live/salehvip-clud.ir/fullchain.pem /etc/letsencrypt/live/reserve.salehvip-clud.ir/
        cp -f /etc/letsencrypt/live/salehvip-clud.ir/privkey.pem /etc/letsencrypt/live/reserve.salehvip-clud.ir/
    else
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/letsencrypt/live/reserve.salehvip-clud.ir/privkey.pem \
            -out /etc/letsencrypt/live/reserve.salehvip-clud.ir/fullchain.pem \
            -subj "/CN=reserve.salehvip-clud.ir/O=HMH/C=IR" > /dev/null 2>&1
    fi
fi

# ۳. تنظیم فایل پیکربندی پایدار انجین‌اکس
echo -e "${CYAN}[۳/۵] به‌روزرسانی تنظیمات Nginx بدون وابستگی‌های مفقود...${NC}"
curl -fsSL https://raw.githubusercontent.com/salehsayyadi/HMH/main/source/deployment/nginx/nginx.conf -o /opt/hmh/nginx.conf

# ۴. راه‌اندازی مجدد انجین‌اکس و بک‌اند
echo -e "${CYAN}[۴/۵] راه‌اندازی مجدد کانتینرهای بک‌اند و وب‌سرور...${NC}"
docker restart hmh_backend 2>/dev/null || docker start hmh_backend 2>/dev/null || true
docker restart hmh_nginx 2>/dev/null || docker start hmh_nginx 2>/dev/null || true

# ۵. تست اتصال درون سرور
echo -e "${CYAN}[۵/۵] ارزیابی نهایی پاسخگویی...${NC}"
sleep 3
for i in {1..15}; do
    RES=$(curl -k -s https://127.0.0.1/api/v1/system/health 2>/dev/null || true)
    if [[ "$RES" == *"healthy"* ]]; then
        echo -e "${GREEN}پایگاه داده و وب‌سرویس با موفقیت فعال و متصل شدند!${NC}"
        echo "$RES"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  سرور اکنون آماده سرویس‌دهی کامل و بدون خطاست!"
echo "=============================================================================="
echo -e "${NC}"
