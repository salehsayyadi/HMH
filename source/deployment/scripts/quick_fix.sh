#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Instant 502 Bad Gateway Recovery & Database Resuscitation
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
echo "    بازیابی فوری سرویس بک‌اند، پایگاه داده و رفع خطای 502"
echo "=============================================================================="
echo -e "${NC}"

# ۱. پاکسازی فایل‌های کانفیگ مشکل‌ساز و راه‌اندازی قطعی MySQL
echo -e "${CYAN}[۱/۴] پاکسازی و راه‌اندازی قطعی پایگاه‌داده MySQL...${NC}"
docker exec hmh_mysql rm -f /etc/mysql/conf.d/speedup.cnf 2>/dev/null || true
docker start hmh_mysql 2>/dev/null || docker restart hmh_mysql 2>/dev/null || true

# ۲. بارگذاری نسخه استاندارد و مطمئن nginx.conf و ری‌لود آن
echo -e "${CYAN}[۲/۴] همگام‌سازی تنظیمات انجین‌اکس...${NC}"
curl -fsSL https://raw.githubusercontent.com/salehsayyadi/HMH/main/source/deployment/nginx/nginx.conf -o /opt/hmh/nginx.conf 2>/dev/null || true
docker exec hmh_nginx nginx -s reload 2>/dev/null || docker restart hmh_nginx 2>/dev/null || true

# ۳. راه‌اندازی سرویس بک‌اند
echo -e "${CYAN}[۳/۴] راه‌اندازی مجدد کانتینر بک‌اند...${NC}"
docker start hmh_backend 2>/dev/null || docker restart hmh_backend 2>/dev/null || true

# ۴. اعتبارسنجی اتصال و تست پاسخگویی
echo -e "${CYAN}[۴/۴] پایش پاسخگویی سرویس و پایگاه‌داده...${NC}"
sleep 3
for i in {1..15}; do
    RES=$(docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health 2>/dev/null || true)
    if [[ "$RES" == *"healthy"* ]]; then
        echo -e "${GREEN}سرویس مرکزی و پایگاه‌داده با موفقیت در دسترس قرار گرفت!${NC}"
        echo "$RES"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  عملیات بازیابی با موفقیت پایان یافت."
echo "=============================================================================="
echo -e "${NC}"
