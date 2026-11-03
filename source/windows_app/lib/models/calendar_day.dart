class CalendarCellModel {
  final String date;
  final String jalaliDate;
  final String jalaliDayName;
  final int dayOfWeek;
  final int timeSlotId;
  final String timeSlotTitle;
  final String status; // 'available', 'reserved', 'holiday', 'blocked'
  final bool isHoliday;
  final String? holidayTitle;
  final bool isBlocked;
  final String? blockReason;
  final int? reservationId;
  final String? schoolName;
  final String? userFullName;

  CalendarCellModel({
    required this.date,
    required this.jalaliDate,
    required this.jalaliDayName,
    required this.dayOfWeek,
    required this.timeSlotId,
    required this.timeSlotTitle,
    required this.status,
    required this.isHoliday,
    this.holidayTitle,
    required this.isBlocked,
    this.blockReason,
    this.reservationId,
    this.schoolName,
    this.userFullName,
  });

  factory CalendarCellModel.fromJson(Map<String, dynamic> json) {
    return CalendarCellModel(
      date: json['date'] ?? '',
      jalaliDate: json['jalali_date'] ?? '',
      jalaliDayName: json['jalali_day_name'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 0,
      timeSlotId: json['time_slot_id'] ?? 0,
      timeSlotTitle: json['time_slot_title'] ?? '',
      status: json['status'] ?? 'available',
      isHoliday: json['is_holiday'] ?? false,
      holidayTitle: json['holiday_title'],
      isBlocked: json['is_blocked'] ?? false,
      blockReason: json['block_reason'],
      reservationId: json['reservation_id'],
      schoolName: json['school_name'],
      userFullName: json['user_full_name'],
    );
  }
}

class CalendarDayModel {
  final String date;
  final String jalaliDate;
  final String dayName;
  final String dayNumber;
  final String? monthNameDisplay;
  final bool isToday;
  final bool isHoliday;
  final String? holidayTitle;
  final bool isOutOfMonth;
  final List<CalendarCellModel> slots;

  CalendarDayModel({
    required this.date,
    required this.jalaliDate,
    required this.dayName,
    required this.dayNumber,
    this.monthNameDisplay,
    required this.isToday,
    required this.isHoliday,
    this.holidayTitle,
    this.isOutOfMonth = false,
    required this.slots,
  });

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayModel(
      date: json['date'] ?? '',
      jalaliDate: json['jalali_date'] ?? '',
      dayName: json['day_name'] ?? '',
      dayNumber: json['day_number'] ?? '',
      monthNameDisplay: json['month_name_display'],
      isToday: json['is_today'] ?? false,
      isHoliday: json['is_holiday'] ?? false,
      holidayTitle: json['holiday_title'],
      isOutOfMonth: json['is_out_of_month'] ?? false,
      slots: (json['slots'] as List? ?? []).map((s) => CalendarCellModel.fromJson(s)).toList(),
    );
  }
}

class TimeSlotModel {
  final int id;
  final int slotNumber;
  final String title;
  final String startTime;
  final String endTime;

  TimeSlotModel({
    required this.id,
    required this.slotNumber,
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] ?? 0,
      slotNumber: json['slot_number'] ?? 0,
      title: json['title'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }
}
