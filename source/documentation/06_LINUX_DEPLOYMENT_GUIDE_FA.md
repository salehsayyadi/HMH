# راهنمای استقرار سرور لینوکس Ubuntu 24.04 LTS
## سامانه متمرکز رزرواسیون آمفی‌تئاتر مدارس امام حسین (ع)

### ۱. مشخصات معماری سرور
- **سیستم‌عامل:** Ubuntu 24.04 LTS (Noble Numbat)
- **موتور کانتینری:** Docker Community Edition با Compose v2
- **وب‌سرور:** Nginx Reverse Proxy با گواهی SSL Let's Encrypt
- **دیتابیس:** MySQL 9.7 LTS با انجین InnoDB و کاراکترست utf8mb4
- **بک‌اند:** FastAPI / Python 3.13 با پروتکل ناهمگام و سوکت بلادرنگ

### ۲. آماده‌سازی سرور اوبونتو
```bash
# به‌روزرسانی مخازن سیستم‌عامل
sudo apt update && sudo apt upgrade -y

# نصب ابزارهای پایه و داکر
sudo apt install -y curl git ufw fail2ban
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# فعال‌سازی فایروال UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Let's Encrypt / Redirect)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### ۳. استقرار استک کانتینری
```bash
# ایجاد دایرکتوری سامانه
sudo mkdir -p /opt/hmh
sudo chown -R $USER:$USER /opt/hmh
cd /opt/hmh

# کپی فایل‌های پروژه و تنظیم محیط
cp app/Server-Deployment/.env.example .env
# ویرایش و تعیین کلمات عبور اختصاصی
nano .env

# اجرای استقرار
chmod +x app/Server-Deployment/scripts/*.sh
./app/Server-Deployment/scripts/deploy.sh
```

### ۴. راه‌اندازی گواهی SSL
```bash
# پس از اتصال دامنه به IP سرور:
./app/Server-Deployment/scripts/setup_ssl.sh
```
