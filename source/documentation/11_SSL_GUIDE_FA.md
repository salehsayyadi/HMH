# راهنمای پیکربندی گواهی امنیتی SSL و پروکسی معکوس Nginx
## دامنه رسمی: reserve.salehvip-clud.ir

**سیستم‌عامل سرور:** Ubuntu 24.04 LTS  
**وب‌سرور و پروکسی:** Nginx 1.26+  
**مرجع صادرکننده:** Let's Encrypt (Certbot)  

---

### ۱. نیازمندی‌های اولیه
- ثبت رکورد A دامنه `reserve.salehvip-clud.ir` به سمت IP استاتیک سرور اوبونتو.
- باز بودن پورت‌های 80 (HTTP) و 443 (HTTPS) روی فایروال سرور:
  ```bash
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw reload
  ```

---

### ۲. دریافت خودکار گواهینامه با `setup_ssl.sh`
اسکریپت آماده در مسیر `deployment/scripts/setup_ssl.sh` موجود است:
```bash
cd /opt/hmh/deployment/scripts
chmod +x setup_ssl.sh
sudo ./setup_ssl.sh reserve.salehvip-clud.ir admin@salehvip-clud.ir
```
این اسکریپت ابزار Certbot را نصب کرده، گواهی رمزنگاری TLS 1.3 معتبر را از Let's Encrypt دریافت و در مسیر `/etc/letsencrypt/live/reserve.salehvip-clud.ir/` ذخیره می‌نماید.

---

### ۳. پیکربندی Nginx Reverse Proxy
فایل پیکربندی اصلی سرور در مسیر `deployment/nginx/nginx.conf` قرار داشته و شامل موارد زیر است:
- ریدایرکت خودکار تمامی ترافیک‌های ناامن پورت ۸۰ به پورت امن ۴۴۳ (HTTPS Redirection).
- رمزنگاری پیشرفته TLS 1.2 و TLS 1.3 با پروتکل‌های ECDHE و AES-GCM.
- هدایت ترافیک `/api/` و `/docs` به سرویس بک‌اند پایتون (FastAPI) روی پورت ۸۰۰۰.
- پروکسی سوکت‌های وب در مسیر `/ws/` با پشتیبانی کامل از `Upgrade` و `Connection` هدرها.
- میزبانی فایل‌های ایستا (Static Assets) پنل وب مدیریت ارشد با تنظیمات کش مرورگر و فشرده‌سازی Gzip/Brotli.
- اعمال هدرهای امنیتی نظیر `Strict-Transport-Security (HSTS)`، `X-Frame-Options: SAMEORIGIN` و `X-Content-Type-Options: nosniff`.

---

### ۴. تمدید خودکار گواهی (Automatic Renewal)
سرویس تمدید زمان‌بندی‌شده به صورت خودکار توسط Certbot سیستم پیکربندی می‌شود. برای تست دستی اعتبار تمدید:
```bash
sudo certbot renew --dry-run
```
پس از هر تمدید موفق، کانتینر Nginx به صورت خودکار پیکربندی جدید را مجدداً لود خواهد کرد.
