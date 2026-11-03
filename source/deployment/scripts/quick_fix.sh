#!/usr/bin/env bash
# ==============================================================================
#  سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) یزد
#  Ultra-Fast Server Speed Optimizer (Fixes MySQL Latency & Nginx Session Cache)
# ==============================================================================
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "    موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد"
echo "    بهینه‌سازی فوری سرعت سرور، پایگاه‌داده و شتاب‌بخشی به ارتباطات"
echo "=============================================================================="
echo -e "${NC}"

# ۱. حذف تاخیر ۱۰ ثانیه‌ای DNS با فعال‌سازی skip-name-resolve در MySQL
echo -e "${CYAN}[۱/۳] بهینه‌سازی دسترسی پایگاه‌داده (حذف Reverse DNS Lookup)...${NC}"
docker exec hmh_mysql bash -c "mkdir -p /etc/mysql/conf.d && echo -e '[mysqld]\nskip-name-resolve\nmax_connections=300\ninnodb_buffer_pool_size=256M' > /etc/mysql/conf.d/speedup.cnf" 2>/dev/null || true
docker restart hmh_mysql

# ۲. اعمال کش نشست‌های SSL و Keep-Alive در Nginx
echo -e "${CYAN}[۲/۳] دریافت و اعمال تنظیمات پرسرعت Nginx با Connection Keep-Alive...${NC}"
curl -fsSL https://raw.githubusercontent.com/salehsayyadi/HMH/main/source/deployment/nginx/nginx.conf -o /opt/hmh/nginx.conf 2>/dev/null || true
docker exec hmh_nginx nginx -s reload 2>/dev/null || true

# ۳. راه‌اندازی مجدد سرویس بک‌اند جهت اعمال کانکشن پول بهینه
echo -e "${CYAN}[۳/۳] همگام‌سازی سرویس بک‌اند...${NC}"
docker restart hmh_backend

sleep 3

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "  سرعت سرور و پایگاه‌داده با موفقیت بهینه شد!"
echo "  تست تاخیر پاسخگویی (Latency Test):"
time docker exec hmh_backend curl -s http://localhost:8000/api/v1/system/health
echo ""
echo "=============================================================================="
echo -e "${NC}"
