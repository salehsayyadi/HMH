# مستندات فنی و ساختار RESTful API سامانه HMH
## نسخه ۱.۰.۰

کلیه اندپوینت‌ها با پیشوند `/api/v1/` آدرس‌دهی می‌شوند. مستندات تعاملی Swagger UI در مسیر `/docs` در دسترس است.

### ۱. احراز هویت (Authentication)
- `POST /api/v1/auth/login`: ورود با نام کاربری و کلمه عبور و دریافت جفت توکن Access و Refresh
- `POST /api/v1/auth/refresh`: چرخش توکن تازه سازی (Refresh Token Rotation)
- `POST /api/v1/auth/change-password`: تغییر رمز عبور با تأیید رمز فعلی
- `GET /api/v1/auth/me`: دریافت اطلاعات و پروفایل کاربر جاری

### ۲. تقویم و رزرواسیون (Calendar & Reservations)
- `GET /api/v1/calendar/week?target_date=YYYY-MM-DD`: دریافت ماتریس ۷ روز و ۵ سانس تقویم هفتگی با رنگ‌ها و وضعیت‌ها
- `POST /api/v1/reservations`: ایجاد رزرو جدید با محافظت تراکنشی ضد رزرو همزمان
- `GET /api/v1/reservations`: لیست رزروها با فیلتر مدرسه، تاریخ و وضعیت
- `GET /api/v1/reservations/{id}`: جزئیات رزرو با اعمال قاعده حریم خصوصی شماره تماس
- `POST /api/v1/reservations/{id}/cancel`: لغو رزرو و آزادسازی آنی سانس

### ۳. مدیریت مدارس و کاربران (Schools & Users)
- `GET /api/v1/schools`: لیست مدارس و شعب
- `POST /api/v1/schools`: افزودن مدرسه جدید (مدیر کل)
- `PATCH /api/v1/schools/{id}`: ویرایش مدرسه
- `GET /api/v1/users`: لیست کاربران با فیلتر مدرسه و سمت
- `POST /api/v1/users`: تعریف کاربر جدید
- `PATCH /api/v1/users/{id}`: ویرایش یا تغییر وضعیت حساب

### ۴. ساعت‌ها، تعطیلات و محدودیت‌ها
- `GET /api/v1/time-slots`: ۵ سانس پیش‌فرض سالن
- `GET /api/v1/holidays`: تقویم روزهای تعطیل رسمی و دستی
- `POST /api/v1/restrictions`: ایجاد محدودیت و مسدودسازی سانس‌ها
- `DELETE /api/v1/restrictions/{id}`: رفع انسداد

### ۵. گزارش‌ها و آزمون سرور
- `GET /api/v1/reports/dashboard`: آمار عملکرد، روند ماهانه و توزیع مدارس
- `GET /api/v1/reports/reservations/excel`: فایل اکسل گزارش رزروها
- `GET /api/v1/system/status`: مشخصات کامل سرور و دیتابیس
- `POST /api/v1/system/test-connection`: آزمون آنلاین اتصال سرور، دیتابیس، API و SSL
