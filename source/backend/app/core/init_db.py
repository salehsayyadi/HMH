import datetime
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import School, Position, TimeSlot, User, Holiday, SystemSetting
from app.core.security import get_password_hash
from app.core.config import settings
from app.services.holiday_service import seed_default_holidays_if_empty

logger = logging.getLogger("hmh.init")

INITIAL_SCHOOLS = [
    {"name": "مدرسه پسرانه دوره اول", "code": "SCH-B1", "description": "دبیرستان پسرانه دوره اول حضرت امام حسین (ع)"},
    {"name": "مدرسه پسرانه دوره دوم", "code": "SCH-B2", "description": "دبیرستان پسرانه دوره دوم حضرت امام حسین (ع)"},
    {"name": "مدرسه دخترانه دوره اول", "code": "SCH-G1", "description": "دبیرستان دخترانه دوره اول حضرت امام حسین (ع)"},
    {"name": "مدرسه دخترانه دوره دوم", "code": "SCH-G2", "description": "دبیرستان دخترانه دوره دوم حضرت امام حسین (ع)"},
    {"name": "مدرسه ابتدایی پسرانه", "code": "SCH-P-B", "description": "دبستان ابتدایی پسرانه حضرت امام حسین (ع)"},
    {"name": "مدرسه ابتدایی دخترانه", "code": "SCH-P-G", "description": "دبستان ابتدایی دخترانه حضرت امام حسین (ع)"},
]

INITIAL_POSITIONS = [
    {"title": "معاون اجرایی", "is_system": True},
    {"title": "معاون آموزشی", "is_system": True},
    {"title": "معاون پرورشی", "is_system": True},
    {"title": "مدیر", "is_system": True},
    {"title": "معاون فناوری", "is_system": True},
    {"title": "مسئول اجرایی", "is_system": True},
    {"title": "سایر موارد", "is_system": True},
]

INITIAL_SLOTS = [
    {"slot_number": 1, "title": "۰۸:۰۰ تا ۱۰:۰۰", "start_time": datetime.time(8, 0), "end_time": datetime.time(10, 0)},
    {"slot_number": 2, "title": "۱۰:۰۰ تا ۱۲:۰۰", "start_time": datetime.time(10, 0), "end_time": datetime.time(12, 0)},
    {"slot_number": 3, "title": "۱۲:۰۰ تا ۱۴:۰۰", "start_time": datetime.time(12, 0), "end_time": datetime.time(14, 0)},
    {"slot_number": 4, "title": "۱۴:۰۰ تا ۱۶:۰۰", "start_time": datetime.time(14, 0), "end_time": datetime.time(16, 0)},
    {"slot_number": 5, "title": "۱۶:۰۰ تا ۱۸:۰۰", "start_time": datetime.time(16, 0), "end_time": datetime.time(18, 0)},
]

async def init_database_data(db: AsyncSession):
    """
    Seeds initial schools, positions, time slots, super admin bootstrap, and holidays.
    """
    # 1. Seed Schools
    for s_info in INITIAL_SCHOOLS:
        existing = await db.execute(select(School).where(School.name == s_info["name"]))
        if not existing.scalars().first():
            db.add(School(**s_info, is_active=True))
    await db.commit()

    # 2. Seed Positions
    for p_info in INITIAL_POSITIONS:
        existing = await db.execute(select(Position).where(Position.title == p_info["title"]))
        if not existing.scalars().first():
            db.add(Position(**p_info, is_active=True))
    await db.commit()

    # 3. Seed Time Slots
    for slot_info in INITIAL_SLOTS:
        existing = await db.execute(select(TimeSlot).where(TimeSlot.slot_number == slot_info["slot_number"]))
        if not existing.scalars().first():
            db.add(TimeSlot(**slot_info, is_active=True))
    await db.commit()

    # 4. Bootstrap Super Administrator per Part 9
    admin_res = await db.execute(select(User).where(User.username == settings.INITIAL_ADMIN_USERNAME))
    admin_user = admin_res.scalars().first()
    if not admin_user:
        # Fetch first school for admin profile association
        sch_res = await db.execute(select(School).limit(1))
        first_sch = sch_res.scalars().first()

        pos_res = await db.execute(select(Position).where(Position.title == "مدیر"))
        admin_pos = pos_res.scalars().first()

        new_admin = User(
            username=settings.INITIAL_ADMIN_USERNAME,
            password_hash=get_password_hash(settings.INITIAL_ADMIN_PASSWORD),
            first_name="مدیر کل",
            last_name="سامانه",
            school_id=first_sch.id if first_sch else None,
            position_id=admin_pos.id if admin_pos else None,
            role="super_admin",
            phone_number="09131234567",
            is_active=True,
            must_change_password=True # Forces password change during first login per Part 9
        )
        db.add(new_admin)
        await db.commit()
        logger.info("Initial super administrator bootstrap user created successfully.")

    # 5. Create school sample user matching the reference design in Part 4:
    # "محمدحسین کارستان" - معاون اجرایی - مدرسه امام حسین (ع) پسرانه دوره دوم
    sample_user_res = await db.execute(select(User).where(User.username == "karestan"))
    if not sample_user_res.scalars().first():
        sch2_res = await db.execute(select(School).where(School.name == "مدرسه پسرانه دوره دوم"))
        sch2 = sch2_res.scalars().first()
        pos_ejraei = (await db.execute(select(Position).where(Position.title == "معاون اجرایی"))).scalars().first()

        sample_user = User(
            username="karestan",
            password_hash=get_password_hash("12345678"),
            first_name="محمدحسین",
            last_name="کارستان",
            school_id=sch2.id if sch2 else None,
            position_id=pos_ejraei.id if pos_ejraei else None,
            role="user",
            phone_number="09138765432",
            is_active=True,
            must_change_password=False
        )
        db.add(sample_user)
        await db.commit()

    # 6. Create standard test user (test / test) for testing reservations and ordinary user access
    test_user_res = await db.execute(select(User).where(User.username == "test"))
    if not test_user_res.scalars().first():
        sch_res = await db.execute(select(School).where(School.name == "مدرسه پسرانه دوره دوم"))
        sch_test = sch_res.scalars().first()
        if not sch_test:
            sch_test = (await db.execute(select(School).limit(1))).scalars().first()
        pos_res = await db.execute(select(Position).where(Position.title == "معاون اجرایی"))
        pos_test = pos_res.scalars().first()
        if not pos_test:
            pos_test = (await db.execute(select(Position).limit(1))).scalars().first()

        test_user = User(
            username="test",
            password_hash=get_password_hash("test"),
            first_name="کاربر",
            last_name="تست",
            school_id=sch_test.id if sch_test else None,
            position_id=pos_test.id if pos_test else None,
            role="user",
            phone_number="09131234567",
            is_active=True,
            must_change_password=False
        )
        db.add(test_user)
        await db.commit()
        logger.info("Standard test user (test / test) created successfully.")

    # 7. Seed Holidays
    await seed_default_holidays_if_empty(db, year=1403)
