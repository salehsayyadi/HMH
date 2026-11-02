from datetime import date, time, datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict

# ================= AUTH SCHEMAS =================
class LoginRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=100)
    password: str = Field(..., min_length=4, max_length=100)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    must_change_password: bool = False
    user: "UserResponse"

class RefreshRequest(BaseModel):
    refresh_token: str

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)

# ================= USER SCHEMAS =================
class UserBase(BaseModel):
    first_name: str
    last_name: str
    username: str
    phone_number: Optional[str] = None
    school_id: Optional[int] = None
    position_id: Optional[int] = None
    role: str = "user"
    is_active: bool = True

class UserCreate(BaseModel):
    first_name: str
    last_name: str
    username: str
    initial_password: str = Field(..., min_length=6)
    phone_number: Optional[str] = None
    school_id: int
    position_id: Optional[int] = None
    role: str = "user"

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None
    school_id: Optional[int] = None
    position_id: Optional[int] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    reset_password: Optional[str] = None

class UserSelfUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None

class SchoolSimple(BaseModel):
    id: int
    name: str
    code: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class PositionSimple(BaseModel):
    id: int
    title: str
    model_config = ConfigDict(from_attributes=True)

class UserResponse(BaseModel):
    id: int
    username: str
    first_name: str
    last_name: str
    full_name: str
    phone_number: Optional[str] = None
    school_id: Optional[int] = None
    position_id: Optional[int] = None
    school: Optional[SchoolSimple] = None
    position: Optional[PositionSimple] = None
    role: str
    is_active: bool
    must_change_password: bool
    created_at: datetime
    last_login: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ================= SCHOOL SCHEMAS =================
class SchoolCreate(BaseModel):
    name: str
    code: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = True

class SchoolUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class SchoolResponse(BaseModel):
    id: int
    name: str
    code: Optional[str] = None
    description: Optional[str] = None
    is_active: bool
    user_count: Optional[int] = 0
    reservation_count: Optional[int] = 0
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# ================= TIME SLOT SCHEMAS =================
class TimeSlotCreate(BaseModel):
    slot_number: int
    title: str
    start_time: str # "HH:MM"
    end_time: str   # "HH:MM"
    is_active: bool = True

class TimeSlotUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    is_active: Optional[bool] = None

class TimeSlotResponse(BaseModel):
    id: int
    slot_number: int
    title: str
    start_time: str
    end_time: str
    is_active: bool
    model_config = ConfigDict(from_attributes=True)

# ================= RESERVATION SCHEMAS =================
class ReservationCreate(BaseModel):
    reservation_date: date
    time_slot_id: int
    description: Optional[str] = None
    # For super_admin making reservation on behalf of a school/user:
    on_behalf_user_id: Optional[int] = None

class ReservationCancel(BaseModel):
    reason: Optional[str] = None

class ReservationResponse(BaseModel):
    id: int
    reservation_date: date
    jalali_date: str
    time_slot_id: int
    time_slot: TimeSlotResponse
    school_id: int
    school_name: str
    user_id: int
    user_full_name: str
    position_title: Optional[str] = None
    phone_number: Optional[str] = None # Enforces privacy rule Part 16: masked if not owner / admin
    description: Optional[str] = None
    status: str
    can_cancel: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ================= CALENDAR SCHEMAS =================
class CalendarCell(BaseModel):
    date: date
    jalali_date: str
    jalali_day_name: str
    day_of_week: int # 0=Saturday, 6=Friday
    time_slot_id: int
    time_slot_title: str
    status: str # 'available', 'reserved', 'holiday', 'blocked'
    is_holiday: bool
    holiday_title: Optional[str] = None
    is_blocked: bool
    block_reason: Optional[str] = None
    reservation_id: Optional[int] = None
    school_name: Optional[str] = None
    user_full_name: Optional[str] = None

class CalendarDay(BaseModel):
    date: date
    jalali_date: str
    day_name: str
    day_number: str
    is_today: bool
    is_holiday: bool
    holiday_title: Optional[str] = None
    slots: List[CalendarCell]

class CalendarWeekResponse(BaseModel):
    week_number: int
    jalali_month_name: str
    jalali_year: int
    start_date: date
    end_date: date
    days: List[CalendarDay]
    time_slots: List[TimeSlotResponse]

# ================= HOLIDAY SCHEMAS =================
class HolidayCreate(BaseModel):
    holiday_date: date
    title: str
    is_official: bool = True
    is_manual: bool = True

class HolidayUpdate(BaseModel):
    title: Optional[str] = None
    is_official: Optional[bool] = None

class HolidayResponse(BaseModel):
    id: int
    holiday_date: date
    jalali_date: str
    title: str
    is_official: bool
    is_manual: bool
    source: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# ================= RESTRICTION SCHEMAS =================
class RestrictionCreate(BaseModel):
    restriction_type: str # 'single_slot', 'day', 'week', 'month', 'global'
    start_date: date
    end_date: Optional[date] = None
    time_slot_id: Optional[int] = None
    reason: str

class RestrictionResponse(BaseModel):
    id: int
    restriction_type: str
    start_date: date
    end_date: date
    jalali_start_date: str
    jalali_end_date: str
    time_slot_id: Optional[int] = None
    time_slot_title: Optional[str] = None
    reason: str
    created_by_name: str
    is_active: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# ================= SERVER SETTINGS SCHEMAS =================
class ServerInfoResponse(BaseModel):
    server_os: str
    domain: str
    subdomain: str
    public_ip: str
    api_base_url: str
    websocket_url: str
    https_status: str
    ssl_status: str
    server_port: int
    backend_version: str
    server_health_status: str
    database_engine: str
    database_status: str
    database_version: str
    database_name: str
    last_db_success: Optional[str] = None

class ConnectionTestRequest(BaseModel):
    test_type: str # 'server', 'database', 'api', 'websocket', 'ssl'

class ConnectionTestResponse(BaseModel):
    test_type: str
    success: bool
    status_text: str
    latency_ms: Optional[float] = None
    details: Optional[str] = None

# ================= AUDIT LOG SCHEMAS =================
class AuditLogResponse(BaseModel):
    id: int
    actor_id: Optional[int] = None
    actor_name: Optional[str] = None
    action: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    before_state: Optional[str] = None
    after_state: Optional[str] = None
    ip_address: Optional[str] = None
    status: str
    timestamp: datetime
    jalali_timestamp: str
    model_config = ConfigDict(from_attributes=True)

# ================= DASHBOARD STATS =================
class DashboardStatsResponse(BaseModel):
    total_users: int
    total_schools: int
    today_reservations: int
    upcoming_reservations: int
    available_slots_week: int
    reserved_slots_week: int
    blocked_slots_week: int
    monthly_reservations: int
    monthly_cancellations: int
    reservations_by_school: List[dict]
    monthly_trend: List[dict]
    status_distribution: List[dict]
    recent_activity: List[dict]
