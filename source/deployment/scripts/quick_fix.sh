#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Instant Latency Reducer: Eliminates Reverse DNS Timeout (Drops Latency to < 200ms)
# ==============================================================================
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    حذف تاخیر Reverse DNS پایگاه‌داده و شتاب‌بخشی به ارتباطات"
echo "=============================================================================="
echo -e "${NC}"

# ۱. تزریق دقیق skip-name-resolve به تنظیمات MySQL بدون استفاده از دستورات حساس به شل
echo -e "${CYAN}[۱/۴] اعمال skip-name-resolve در پایگاه‌داده MySQL...${NC}"
docker exec hmh_mysql sh -c 'mkdir -p /etc/mysql/conf.d && printf "[mysqld]\nskip-name-resolve\n" > /etc/mysql/conf.d/skip_name_resolve.cnf'

echo -e "${CYAN}[۲/۴] راه‌اندازی مجدد MySQL جهت اعمال حذف معطلی DNS...${NC}"
docker restart hmh_mysql
sleep 3

# ۲. به‌روزرسانی Nginx با کش نشست‌های SSL
echo -e "${CYAN}[۳/۴] به‌روزرسانی تنظیمات Nginx با کش نشست‌های SSL...${NC}"
curl -fsSL https://raw.githubusercontent.com/salehsayyadi/HMH/main/source/deployment/nginx/nginx.conf -o /opt/hmh/nginx.conf
if docker exec hmh_nginx nginx -t 2>/dev/null; then
    docker exec hmh_nginx nginx -s reload 2>/dev/null || docker restart hmh_nginx 2>/dev/null || true
else
    echo -e "${YELLOW}هشدار: تست Nginx با خطا مواجه شد؛ حفظ تنظیمات پیشین.${NC}"
fi

# ۳. راه‌اندازی مجدد بک‌اند
echo -e "${CYAN}[۴/۴] راه‌اندازی مجدد سرویس بک‌اند...${NC}"
docker restart hmh_backend
sleep 2

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  شتاب‌بخشی با موفقیت انجام شد! بررسی زمان پاسخگویی پایگاه‌داده:"
echo "=============================================================================="
time docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health
echo ""
echo "=============================================================================="
echo -e "${NC}"
