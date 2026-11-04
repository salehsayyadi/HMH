from datetime import date, datetime
from typing import List, Optional, Tuple, Dict
import urllib.request
import json
import jdatetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
from app.models import Holiday
from app.schemas import HolidayCreate, HolidayUpdate, HolidayResponse
from app.core.persian_date import format_jalali_date, jalali_to_gregorian

# Comprehensive Official Iran National Solar Holidays (Month, Day, Title)
FIXED_IRAN_SOLAR_HOLIDAYS = [
    (1, 1, "جشن نوروز / سال نو"),
    (1, 2, "عید نوروز"),
    (1, 3, "عید نوروز"),
    (1, 4, "عید نوروز"),
    (1, 12, "روز جمهوری اسلامی ایران"),
    (1, 13, "روز طبیعت (سیزده بدر)"),
    (3, 14, "رحلت حضرت امام خمینی (ره)"),
    (3, 15, "قیام خونین ۱۵ خرداد"),
    (11, 22, "پیروزی انقلاب اسلامی ایران"),
    (12, 29, "روز ملی شدن صنعت نفت ایران")
]

# Official Lunar/Religious Holidays in Iranian Calendar by Jalali Year
YEAR_SPECIFIC_LUNAR_HOLIDAYS: Dict[int, List[Tuple[int, int, str]]] = {
    1403: [
        (1, 23, "عید سعید فطر"),
        (1, 24, "تعطیلی عید سعید فطر"),
        (2, 15, "شهادت امام جعفر صادق (ع)"),
        (3, 28, "عید سعید قربان"),
        (4, 5, "عید سعید غدیر خم"),
        (4, 25, "تاسوعای حسینی"),
        (4, 26, "عاشورای حسینی"),
        (6, 4, "اربعین حسینی"),
        (6, 12, "رحلت رسول اکرم (ص) و شهادت امام حسن مجتبی (ع)"),
        (6, 14, "شهادت امام رضا (ع)"),
        (6, 22, "شهادت امام حسن عسکری (ع)"),
        (6, 31, "میلاد رسول اکرم (ص) و امام جعفر صادق (ع)"),
        (9, 15, "شهادت حضرت فاطمه زهرا (س)"),
        (10, 25, "ولادت امام علی (ع)"),
        (11, 9, "مبعث حضرت رسول اکرم (ص)"),
        (11, 26, "ولادت حضرت قائم (عج)")
    ],
    1404: [
        (1, 11, "عید سعید فطر"),
        (1, 12, "تعطیلی عید سعید فطر"),
        (2, 4, "شهادت امام جعفر صادق (ع)"),
        (3, 16, "عید سعید قربان"),
        (3, 24, "عید سعید غدیر خم"),
        (4, 14, "تاسوعای حسینی"),
        (4, 15, "عاشورای حسینی"),
        (5, 24, "اربعین حسینی"),
        (6, 1, "رحلت حضرت رسول اکرم (ص)"),
        (6, 3, "شهادت امام رضا (ع)"),
        (6, 11, "شهادت امام حسن عسکری (ع)"),
        (6, 20, "میلاد رسول اکرم (ص)"),
        (9, 4, "شهادت حضرت فاطمه زهرا (س)"),
        (10, 14, "ولادت امام علی (ع)"),
        (10, 28, "مبعث حضرت رسول اکرم (ص)"),
        (11, 16, "ولادت حضرت قائم (عج)")
    ],
    1405: [
        (1, 31, "عید سعید فطر"),
        (2, 1, "تعطیلی عید سعید فطر"),
        (2, 24, "شهادت امام جعفر صادق (ع)"),
        (3, 6, "عید سعید قربان"),
        (4, 4, "تاسوعای حسینی"),
        (4, 5, "عاشورای حسینی"),
        (5, 13, "اربعین حسینی"),
        (5, 21, "رحلت رسول اکرم (ص)"),
        (5, 23, "شهادت امام رضا (ع)"),
        (5, 31, "شهادت امام حسن عسکری (ع)"),
        (6, 9, "میلاد رسول اکرم (ص)"),
        (8, 23, "شهادت حضرت فاطمه زهرا (س)"),
        (10, 3, "ولادت امام علی (ع)"),
        (10, 17, "مبعث حضرت رسول اکرم (ص)"),
        (11, 5, "ولادت حضرت قائم (عج)")
    ],
    1406: [
        (1, 20, "عید سعید فطر"),
        (1, 21, "تعطیلی عید سعید فطر"),
        (2, 13, "شهادت امام جعفر صادق (ع)"),
        (3, 26, "عید سعید قربان"),
        (4, 3, "عید سعید غدیر خم"),
        (4, 23, "تاسوعای حسینی"),
        (4, 24, "عاشورای حسینی"),
        (5, 2, "اربعین حسینی"),
        (5, 10, "رحلت رسول اکرم (ص)"),
        (5, 12, "شهادت امام رضا (ع)"),
        (5, 20, "شهادت امام حسن عسکری (ع)"),
        (5, 29, "میلاد رسول اکرم (ص)"),
        (8, 12, "شهادت حضرت فاطمه زهرا (س)"),
        (9, 23, "ولادت امام علی (ع)"),
        (10, 7, "مبعث حضرت رسول اکرم (ص)"),
        (10, 25, "ولادت حضرت قائم (عج)")
    ],
    1407: [
        (1, 9, "عید سعید فطر"),
        (1, 10, "تعطیلی عید سعید فطر"),
        (2, 2, "شهادت امام جعفر صادق (ع)"),
        (3, 15, "عید سعید قربان"),
        (3, 23, "عید سعید غدیر خم"),
        (4, 12, "تاسوعای حسینی"),
        (4, 13, "عاشورای حسینی")
    ]
}

def get_official_holidays_for_year(year: int) -> List[Tuple[int, int, str]]:
    """
    Returns full official holidays (Solar + Lunar) for a given Jalali year.
    """
    holidays = list(FIXED_IRAN_SOLAR_HOLIDAYS)
    if year in YEAR_SPECIFIC_LUNAR_HOLIDAYS:
        holidays.extend(YEAR_SPECIFIC_LUNAR_HOLIDAYS[year])
    return holidays

async def seed_default_holidays_if_empty(
    db: AsyncSession,
    start_year: int = 1405,
    end_year: int = 1407,
    year: Optional[int] = None
):
    """
    Seeds standard national holidays for 3 active years (1405 through 1407).
    Holidays are bookable by default so schools can hold special events and celebrations.
    """
    if year is not None:
        start_year = year
        end_year = year
    # Fetch all existing holiday dates
    existing_res = await db.execute(select(Holiday.holiday_date))
    seen_dates = set(existing_res.scalars().all())

    holidays_to_add = []
    for year in range(start_year, end_year + 1):
        year_holidays = get_official_holidays_for_year(year)
        for month, day, title in year_holidays:
            try:
                g_date = jalali_to_gregorian(year, month, day)
                if g_date in seen_dates:
                    continue
                seen_dates.add(g_date)
                holidays_to_add.append(
                    Holiday(
                        holiday_date=g_date,
                        title=f"{title}",
                        is_official=True,
                        is_manual=False,
                        is_booking_allowed=True,
                        source="iran_official_calendar"
                    )
                )
            except Exception:
                continue

    if holidays_to_add:
        db.add_all(holidays_to_add)
        await db.commit()

async def get_all_holidays(db: AsyncSession) -> List[HolidayResponse]:
    # Only return holidays from the current active academic era (1405 onwards: >= 2026-03-21)
    res = await db.execute(
        select(Holiday)
        .where(Holiday.holiday_date >= date(2026, 3, 20))
        .order_by(Holiday.holiday_date.asc())
    )
    records = res.scalars().all()
    return [
        HolidayResponse(
            id=h.id,
            holiday_date=h.holiday_date,
            jalali_date=format_jalali_date(h.holiday_date),
            title=h.title,
            is_official=h.is_official,
            is_manual=h.is_manual,
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
