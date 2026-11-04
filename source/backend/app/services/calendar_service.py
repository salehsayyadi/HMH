from datetime import date, datetime, timedelta
from typing import List, Optional
import jdatetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload
from app.models import TimeSlot, Reservation, ActiveReservationSlot, Holiday, BlockedSlot, School, User
from app.schemas import CalendarWeekResponse, CalendarDay, CalendarCell, TimeSlotResponse
from app.core.persian_date import (
    gregorian_to_jalali,
    jalali_to_gregorian,
    format_jalali_date,
    get_persian_weekday_name,
    get_persian_weekday_index,
    get_week_range_for_date,
    PERSIAN_MONTHS,
    to_persian_digits
)

async def get_calendar_week(
    db: AsyncSession,
    target_date: Optional[date] = None,
    current_user: Optional[User] = None
) -> CalendarWeekResponse:
    if target_date is None:
        target_date = date.today()

    start_date, end_date = get_week_range_for_date(target_date)

    # 1. Fetch active time slots
    slots_res = await db.execute(
        select(TimeSlot)
        .where(TimeSlot.is_active == True)
        .order_by(TimeSlot.slot_number.asc())
    )
    time_slots = slots_res.scalars().all()

    # 2. Fetch active reservations in this week
    res_query = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.school),
            selectinload(Reservation.user),
            selectinload(Reservation.time_slot)
        )
        .where(
            Reservation.reservation_date >= start_date,
            Reservation.reservation_date <= end_date,
            Reservation.status == "confirmed"
        )
    )
    reservations = res_query.scalars().all()
    # Map by (date, time_slot_id)
    res_map = {(r.reservation_date, r.time_slot_id): r for r in reservations}

    # 3. Fetch holidays in this week (only manual management holidays to avoid stale automatic duplicates)
    holidays_res = await db.execute(
        select(Holiday).where(
            Holiday.holiday_date >= start_date,
            Holiday.holiday_date <= end_date,
            Holiday.is_manual == True
        )
    )
    holidays_map = {h.holiday_date: h for h in holidays_res.scalars().all()}

    # 4. Fetch administrative restrictions
    restrictions_res = await db.execute(
        select(BlockedSlot).where(
            BlockedSlot.is_active == True,
            BlockedSlot.start_date <= end_date,
            BlockedSlot.end_date >= start_date
        )
    )
    restrictions = restrictions_res.scalars().all()

    # Determine Jalali header values
    j_start = gregorian_to_jalali(start_date)
    jalali_month_name = PERSIAN_MONTHS[j_start.month]
    jalali_year = j_start.year

    today = date.today()
    days_list: List[CalendarDay] = []

    # Iterate through 7 days: Saturday (start_date) to Friday (end_date)
    for d_offset in range(7):
        cur_date = start_date + timedelta(days=d_offset)
        j_cur = gregorian_to_jalali(cur_date)
        day_name = get_persian_weekday_name(cur_date)
        day_number = to_persian_digits(str(j_cur.day))
        jalali_str = format_jalali_date(cur_date, with_month_name=True)

        holiday_obj = holidays_map.get(cur_date)
        is_holiday = holiday_obj is not None
        holiday_title = holiday_obj.title if holiday_obj else None

        # Friday is weekly official holiday
        if d_offset == 6 and not is_holiday:
            is_holiday = True
            holiday_title = "تعطیل هفتگی جمعه" 

        day_cells: List[CalendarCell] = []

        for ts in time_slots:
            # Check if this cell is blocked by restriction
            is_blocked = False
            block_reason = None
            for b in restrictions:
                if b.start_date <= cur_date <= b.end_date:
                    if b.time_slot_id is None or b.time_slot_id == ts.id:
                        is_blocked = True
                        block_reason = b.reason
                        break

            # Check if reserved
            existing_res = res_map.get((cur_date, ts.id))

            # Determine visual status:
            # Hierarchy:
            # 1. Blocked -> 'blocked' (Gray)
            # 2. Reserved -> 'reserved' (Pastel Blue)
            # 3. Holiday -> 'holiday' (Pastel Red, but bookable unless blocked)
            # 4. Available -> 'available' (Pastel Green)
            cell_status = "available"
            res_id = None
            school_name = None
            user_full_name = None

            if is_blocked:
                cell_status = "blocked"
            elif existing_res:
                cell_status = "reserved"
                res_id = existing_res.id
                school_name = existing_res.school.name if existing_res.school else None
                user_full_name = existing_res.user.full_name if existing_res.user else None
            elif is_holiday:
                if holiday_obj and not getattr(holiday_obj, 'is_booking_allowed', True):
                    cell_status = "blocked"
                    is_blocked = True
                    block_reason = f"تعطیل رسمی: {holiday_title} (غیرقابل رزرو)"
                else:
                    cell_status = "holiday"

            day_cells.append(CalendarCell(
                date=cur_date,
                jalali_date=jalali_str,
                jalali_day_name=day_name,
                day_of_week=d_offset,
                time_slot_id=ts.id,
                time_slot_title=ts.title,
                status=cell_status,
                is_holiday=is_holiday,
                holiday_title=holiday_title,
                is_blocked=is_blocked,
                block_reason=block_reason,
                reservation_id=res_id,
                school_name=school_name,
                user_full_name=user_full_name
            ))

        days_list.append(CalendarDay(
            date=cur_date,
            jalali_date=jalali_str,
            day_name=day_name,
            day_number=day_number,
            is_today=(cur_date == today),
            is_holiday=is_holiday,
            holiday_title=holiday_title,
            slots=day_cells
        ))

    time_slots_resp = [
        TimeSlotResponse(
            id=ts.id,
            slot_number=ts.slot_number,
            title=ts.title,
            start_time=ts.start_time.strftime("%H:%M"),
            end_time=ts.end_time.strftime("%H:%M"),
            is_active=ts.is_active
        )
        for ts in time_slots
    ]

    return CalendarWeekResponse(
        week_number=1, # Can be computed based on month
        jalali_month_name=jalali_month_name,
        jalali_year=jalali_year,
        start_date=start_date,
        end_date=end_date,
        days=days_list,
        time_slots=time_slots_resp
    )
