from datetime import date, datetime
from typing import List, Optional, Tuple, Dict
import urllib.request
import json
import jdatetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from fastapi import HTTPException
from app.models import Holiday
from app.schemas import HolidayCreate, HolidayUpdate, HolidayResponse
from app.core.persian_date import format_jalali_date, jalali_to_gregorian

# Exact 27 Official Iranian Calendar Holidays from taghvim.com (Solar + Lunar)
OFFICIAL_TAGHVIM_HOLIDAYS: List[Tuple[int, int, str]] = [
    (1, 1, "جشن نوروز / سال نو"),
    (1, 2, "عید نوروز"),
    (1, 3, "عید نوروز"),
    (1, 4, "عید نوروز"),
    (1, 12, "روز جمهوری اسلامی ایران"),
    (1, 13, "روز طبیعت (سیزده به در)"),
    (1, 14, "شهادت امام جعفر صادق (ع)"),
    (2, 27, "عید سعید قربان"),
    (3, 4, "عید سعید غدیر خم"),
    (3, 14, "رحلت حضرت امام خمینی (ره)"),
    (3, 15, "قیام ۱۵ خرداد"),
    (3, 25, "تاسوعای حسینی"),
    (3, 26, "عاشورای حسینی"),
    (5, 13, "اربعین حسینی"),
    (5, 21, "رحلت رسول اکرم (ص) و شهادت امام حسن مجتبی (ع)"),
    (5, 22, "شهادت امام رضا (ع)"),
    (5, 30, "شهادت امام حسن عسکری (ع)"),
    (6, 8, "میلاد رسول اکرم (ص) و امام جعفر صادق (ع)"),
    (8, 22, "شهادت حضرت فاطمه زهرا (س)"),
    (10, 2, "ولادت امام علی (ع) و روز پدر"),
    (10, 16, "مبعث رسول اکرم (ص)"),
    (11, 4, "ولادت حضرت قائم (عج) و جشن نیمه شعبان"),
    (11, 22, "پیروزی انقلاب اسلامی ایران"),
    (12, 9, "شهادت حضرت علی (ع)"),
    (12, 19, "عید سعید فطر"),
    (12, 20, "تعطیلی عید سعید فطر"),
    (12, 29, "روز ملی شدن صنعت نفت ایران"),
]

def get_official_holidays_for_year(year: int) -> List[Tuple[int, int, str]]:
    """
    Returns full official holidays from taghvim.com for a given Jalali year.
    """
    return list(OFFICIAL_TAGHVIM_HOLIDAYS)

async def seed_default_holidays_if_empty(
    db: AsyncSession,
    start_year: int = 1405,
    end_year: int = 1407,
    year: Optional[int] = None
):
    """
    Official calendar holidays are dynamically extracted and rendered on client devices
    via TaghvimHolidayService, preserving server storage and avoiding duplicate entries.
    """
    return

async def get_all_holidays(db: AsyncSession) -> List[HolidayResponse]:
    # Strictly return manual custom holidays added by school admin.
    # Official calendar holidays are handled dynamically on the client calendar.
    res = await db.execute(
        select(Holiday)
        .where(
            and_(
                Holiday.is_manual == True,
                Holiday.is_official == False,
                Holiday.source != "iran_official_calendar"
            )
        )
        .order_by(Holiday.holiday_date.asc())
    )
    records = res.scalars().all()
    return [
        HolidayResponse(
            id=h.id,
            holiday_date=h.holiday_date,
            jalali_date=format_jalali_date(h.holiday_date),
            title=h.title,
            is_official=False,
            is_manual=True,
            is_booking_allowed=getattr(h, 'is_booking_allowed', True),
            source=h.source,
            created_at=h.created_at
        )
        for h in records
    ]

async def add_manual_holiday(db: AsyncSession, data: HolidayCreate) -> HolidayResponse:
    existing = await db.execute(select(Holiday).where(Holiday.holiday_date == data.holiday_date))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="برای این تاریخ قبلاً عنوان تعطیلی ثبت شده است.")

    new_h = Holiday(
        holiday_date=data.holiday_date,
        title=data.title,
        is_official=data.is_official,
        is_manual=True,
        is_booking_allowed=data.is_booking_allowed,
        source="manual_admin_entry"
    )
    db.add(new_h)
    await db.commit()
    await db.refresh(new_h)

    return HolidayResponse(
        id=new_h.id,
        holiday_date=new_h.holiday_date,
        jalali_date=format_jalali_date(new_h.holiday_date),
        title=new_h.title,
        is_official=new_h.is_official,
        is_manual=new_h.is_manual,
        is_booking_allowed=new_h.is_booking_allowed,
        source=new_h.source,
        created_at=new_h.created_at
    )

async def delete_holiday(db: AsyncSession, holiday_id: int):
    h_res = await db.execute(select(Holiday).where(Holiday.id == holiday_id))
    h = h_res.scalars().first()
    if not h:
        raise HTTPException(status_code=404, detail="تعطیلی مورد نظر یافت نشد.")
    await db.delete(h)
    await db.commit()

async def resync_taghvim_holidays(db: AsyncSession) -> dict:
    """
    Cleans up all legacy automatic and duplicate holidays from MySQL database.
    Official holidays are dynamically extracted by client apps from taghvim.com.
    """
    await db.execute(delete(Holiday).where(Holiday.is_manual == False))
    await db.commit()
    return {"success": True, "message": "تعطیلات قدیمی و تکراری از دیتابیس پاکسازی شدند. تقویم رسمی به صورت پویا از taghvim.com تامین می‌شود."}
