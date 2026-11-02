from datetime import date, datetime
from typing import List, Optional
import jdatetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
from app.models import Holiday
from app.schemas import HolidayCreate, HolidayUpdate, HolidayResponse
from app.core.persian_date import format_jalali_date, jalali_to_gregorian

# Standard Iran national holidays in Jalali (Month, Day, Title)
DEFAULT_IRAN_HOLIDAYS_JALALI = [
    (1, 1, "جشن نوروز / سال نو"),
    (1, 2, "عید نوروز"),
    (1, 3, "عید نوروز"),
    (1, 4, "عید نوروز"),
    (1, 12, "روز جمهوری اسلامی ایران"),
    (1, 13, "روز طبیعت (سیزده بدر)"),
    (3, 14, "رحلت امام خمینی (ره)"),
    (3, 15, "قیام خونین ۱۵ خرداد"),
    (11, 22, "پیروزی انقلاب اسلامی ایران"),
    (12, 29, "روز ملی شدن صنعت نفت ایران")
]

async def seed_default_holidays_if_empty(db: AsyncSession, year: int = 1403):
    """
    Seeds standard national holidays for the current and adjacent Persian years if database is empty.
    """
    res = await db.execute(select(Holiday).limit(1))
    if res.scalars().first():
        return

    holidays_to_add = []
    for target_year in [year - 1, year, year + 1]:
        for month, day, title in DEFAULT_IRAN_HOLIDAYS_JALALI:
            try:
                g_date = jalali_to_gregorian(target_year, month, day)
                holidays_to_add.append(
                    Holiday(
                        holiday_date=g_date,
                        title=f"{title} ({target_year})",
                        is_official=True,
                        is_manual=False,
                        source="iran_official_calendar"
                    )
                )
            except Exception:
                continue

    db.add_all(holidays_to_add)
    await db.commit()

async def get_all_holidays(db: AsyncSession) -> List[HolidayResponse]:
    res = await db.execute(select(Holiday).order_by(Holiday.holiday_date.asc()))
    records = res.scalars().all()
    return [
        HolidayResponse(
            id=h.id,
            holiday_date=h.holiday_date,
            jalali_date=format_jalali_date(h.holiday_date),
            title=h.title,
            is_official=h.is_official,
            is_manual=h.is_manual,
            source=h.source,
            created_at=h.created_at
        )
        for h in records
    ]

async def add_manual_holiday(db: AsyncSession, data: HolidayCreate) -> HolidayResponse:
    # Check if holiday exists on this date
    existing = await db.execute(select(Holiday).where(Holiday.holiday_date == data.holiday_date))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="برای این تاریخ قبلاً عنوان تعطیلی ثبت شده است.")

    new_h = Holiday(
        holiday_date=data.holiday_date,
        title=data.title,
        is_official=data.is_official,
        is_manual=True,
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
