import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Date, Time, Text, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class School(Base):
    __tablename__ = "schools"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(190), nullable=False, unique=True, index=True)
    code = Column(String(50), nullable=True, unique=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    users = relationship("User", back_populates="school")
    reservations = relationship("Reservation", back_populates="school")


class Position(Base):
    __tablename__ = "positions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(100), nullable=False, unique=True)
    is_system = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    users = relationship("User", back_populates="position")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(100), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    school_id = Column(Integer, ForeignKey("schools.id", ondelete="RESTRICT"), nullable=True, index=True)
    position_id = Column(Integer, ForeignKey("positions.id", ondelete="RESTRICT"), nullable=True, index=True)
    role = Column(String(30), default="user", nullable=False) # 'super_admin' or 'user'
    phone_number = Column(String(20), nullable=True)
    profile_image = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    must_change_password = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    last_login = Column(DateTime(timezone=True), nullable=True)

    school = relationship("School", back_populates="users")
    position = relationship("Position", back_populates="users")
    reservations = relationship("Reservation", back_populates="user", foreign_keys="Reservation.user_id")
    refresh_sessions = relationship("RefreshSession", back_populates="user", cascade="all, delete-orphan")

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"


class TimeSlot(Base):
    __tablename__ = "time_slots"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    slot_number = Column(Integer, nullable=False, unique=True)
    title = Column(String(100), nullable=False) # e.g. "۰۸:۰۰ تا ۱۰:۰۰"
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    reservations = relationship("Reservation", back_populates="time_slot")
    active_slots = relationship("ActiveReservationSlot", back_populates="time_slot")


class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True)
    school_id = Column(Integer, ForeignKey("schools.id", ondelete="RESTRICT"), nullable=False, index=True)
    time_slot_id = Column(Integer, ForeignKey("time_slots.id", ondelete="RESTRICT"), nullable=False, index=True)
    reservation_date = Column(Date, nullable=False, index=True) # Gregorian storage per spec Part 32
    description = Column(Text, nullable=True)
    status = Column(String(30), default="confirmed", nullable=False, index=True) # confirmed, cancelled, completed
    created_by_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    cancelled_by_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", foreign_keys=[user_id], back_populates="reservations")
    created_by = relationship("User", foreign_keys=[created_by_id])
    cancelled_by = relationship("User", foreign_keys=[cancelled_by_id])
    school = relationship("School", back_populates="reservations")
    time_slot = relationship("TimeSlot", back_populates="reservations")
    active_slot = relationship("ActiveReservationSlot", back_populates="reservation", uselist=False)

    __table_args__ = (
        Index("idx_reservation_date_slot", "reservation_date", "time_slot_id"),
        Index("idx_reservation_school_date", "school_id", "reservation_date"),
    )


class ActiveReservationSlot(Base):
    """
    Critical double-booking prevention table.
    Enforces atomic uniqueness of (reservation_date, time_slot_id).
    Released upon cancellation or slot unblocking.
    """
    __tablename__ = "active_reservation_slots"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    reservation_date = Column(Date, nullable=False)
    time_slot_id = Column(Integer, ForeignKey("time_slots.id", ondelete="RESTRICT"), nullable=False)
    reservation_id = Column(Integer, ForeignKey("reservations.id", ondelete="CASCADE"), nullable=False, unique=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    reservation = relationship("Reservation", back_populates="active_slot")
    time_slot = relationship("TimeSlot", back_populates="active_slots")

    __table_args__ = (
        UniqueConstraint("reservation_date", "time_slot_id", name="uq_active_slot_date_timeslot"),
        Index("idx_active_date_slot", "reservation_date", "time_slot_id"),
    )


class Holiday(Base):
    __tablename__ = "holidays"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    holiday_date = Column(Date, nullable=False, unique=True, index=True)
    title = Column(String(200), nullable=False)
    is_official = Column(Boolean, default=True, nullable=False)
    is_manual = Column(Boolean, default=False, nullable=False)
    source = Column(String(100), default="iran_calendar_adapter", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class BlockedSlot(Base):
    __tablename__ = "blocked_slots"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    restriction_type = Column(String(30), nullable=False) # 'slot', 'day', 'week', 'month', 'global'
    start_date = Column(Date, nullable=False, index=True)
    end_date = Column(Date, nullable=False, index=True)
    time_slot_id = Column(Integer, ForeignKey("time_slots.id", ondelete="RESTRICT"), nullable=True)
    reason = Column(String(255), nullable=False)
    created_by_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    time_slot = relationship("TimeSlot")
    created_by = relationship("User")


class SystemSetting(Base):
    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    key = Column(String(100), nullable=False, unique=True, index=True)
    value = Column(Text, nullable=True)
    description = Column(String(255), nullable=True)
    is_secret = Column(Boolean, default=False, nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    actor_id = Column(Integer, nullable=True, index=True)
    actor_name = Column(String(150), nullable=True)
    action = Column(String(100), nullable=False, index=True)
    target_type = Column(String(100), nullable=True)
    target_id = Column(String(100), nullable=True)
    before_state = Column(Text, nullable=True)
    after_state = Column(Text, nullable=True)
    ip_address = Column(String(60), nullable=True)
    status = Column(String(20), default="success", nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)


class RefreshSession(Base):
    __tablename__ = "refresh_sessions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(255), nullable=False, unique=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)
    ip_address = Column(String(60), nullable=True)
    user_agent = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User", back_populates="refresh_sessions")


class LoginAttempt(Base):
    __tablename__ = "login_attempts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(100), nullable=False, index=True)
    ip_address = Column(String(60), nullable=True)
    success = Column(Boolean, default=False, nullable=False)
    attempted_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)


class SystemEvent(Base):
    __tablename__ = "system_events"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_type = Column(String(100), nullable=False, index=True)
    payload = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
