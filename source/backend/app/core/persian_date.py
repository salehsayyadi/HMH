from datetime import date, datetime, timedelta
import jdatetime

PERSIAN_WEEKDAYS = [
    "شنبه",
    "یکشنبه",
    "دوشنبه",
    "سه‌شنبه",
    "چهارشنبه",
    "پنجشنبه",
    "جمعه"
]

PERSIAN_MONTHS = [
    "",
    "فروردین",
    "اردیبهشت",
    "خرداد",
    "تیر",
    "مرداد",
    "شهریور",
    "مهر",
    "آبان",
    "آذر",
    "دی",
    "بهمن",
    "اسفند"
]

PERSIAN_DIGITS_MAP = {
    '0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴',
    '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹'
}

def to_persian_digits(value: str) -> str:
    if value is None:
        return ""
    result = str(value)
    for en, fa in PERSIAN_DIGITS_MAP.items():
        result = result.replace(en, fa)
    return result

def to_english_digits(value: str) -> str:
    if value is None:
        return ""
    result = str(value)
    for en, fa in PERSIAN_DIGITS_MAP.items():
        result = result.replace(fa, en)
    return result

def gregorian_to_jalali(g_date: date) -> jdatetime.date:
    return jdatetime.date.fromgregorian(date=g_date)

def jalali_to_gregorian(j_year: int, j_month: int, j_day: int) -> date:
    j_d = jdatetime.date(j_year, j_month, j_day)
    return j_d.togregorian()

def format_jalali_date(g_date: date, with_month_name: bool = True) -> str:
    j_d = gregorian_to_jalali(g_date)
    if with_month_name:
        month_name = PERSIAN_MONTHS[j_d.month]
        return f"{to_persian_digits(str(j_d.day))} {month_name} {to_persian_digits(str(j_d.year))}"
    return f"{to_persian_digits(str(j_d.year))}/{to_persian_digits(f'{j_d.month:02d}')}/{to_persian_digits(f'{j_d.day:02d}')}"

def get_persian_weekday_name(g_date: date) -> str:
    """
    Python weekday(): Monday=0, Tuesday=1, Wednesday=2, Thursday=3, Friday=4, Saturday=5, Sunday=6
    In Persian calendar:
    Saturday (5) -> index 0 (شنبه)
    Sunday (6)   -> index 1 (یکشنبه)
    Monday (0)   -> index 2 (دوشنبه)
    Tuesday (1)  -> index 3 (سه‌شنبه)
    Wednesday (2)-> index 4 (چهارشنبه)
    Thursday (3) -> index 5 (پنجشنبه)
    Friday (4)   -> index 6 (جمعه)
    """
    py_wd = g_date.weekday()
    persian_idx = (py_wd + 2) % 7
    return PERSIAN_WEEKDAYS[persian_idx]

def get_persian_weekday_index(g_date: date) -> int:
    py_wd = g_date.weekday()
    return (py_wd + 2) % 7

def get_week_range_for_date(g_date: date) -> tuple[date, date]:
    """
    Returns (saturday_date, friday_date) covering the week containing g_date.
    Week starts on Saturday.
    """
    persian_idx = get_persian_weekday_index(g_date)
    saturday = g_date - timedelta(days=persian_idx)
    friday = saturday + timedelta(days=6)
    return saturday, friday
