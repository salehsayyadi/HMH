import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/taghvim_holiday_service.dart';
import '../../../models/calendar_day.dart';
import '../../../models/user.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_top_bar.dart';
import 'mobile_booking_sheet.dart';
import 'mobile_reservation_details_sheet.dart';

class MobileUserCalendarScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;

  const MobileUserCalendarScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MobileUserCalendarScreen> createState() => _MobileUserCalendarScreenState();
}

class _MobileUserCalendarScreenState extends State<MobileUserCalendarScreen> {
  late int _jalaliYear;
  late int _jalaliMonth;
  int _selectedWeekIndex = 0; // 0 to 4 (5 weeks)
  int _selectedDayIndex = 0; // 0 to 6 in current week

  bool _isLoading = true;
  List<dynamic> _reservations = [];
  List<Map<String, dynamic>> _timeSlots = [];
  List<dynamic> _customHolidays = [];
  final Map<int, Map<int, TaghvimEvent>> _taghvimHolidays = {};

  static const List<String> _persianMonthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> _weekDayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
  ];

  List<int> get _availableYears {
    final curYear = Jalali.now().year;
    return List.generate(3, (i) => curYear + i);
  }

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _jalaliYear = now.year;
    _jalaliMonth = now.month;
    _calculateInitialDay();
    TaghvimHolidayService.initialize();
    _loadCalendar();
  }

  void _calculateInitialDay() {
    final now = Jalali.now();
    if (now.year == _jalaliYear && now.month == _jalaliMonth) {
      final day = now.day;
      _selectedWeekIndex = (day - 1) ~/ 7;
      if (_selectedWeekIndex > 4) _selectedWeekIndex = 4;
      _selectedDayIndex = (day - 1) % 7;
    } else {
      _selectedWeekIndex = 0;
      _selectedDayIndex = 0;
    }
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getReservations(),
        ApiService.getTimeSlots(),
        ApiService.getHolidays(),
        TaghvimHolidayService.getEventsForMonth(_jalaliMonth),
      ]);

      if (mounted) {
        setState(() {
          _reservations = results[0] as List<dynamic>;
          _timeSlots = (results[1] as List<dynamic>)
              .map((s) => s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s as Map))
              .toList();
          _customHolidays = results[2] as List<dynamic>;
          _taghvimHolidays[_jalaliMonth] = results[3] as Map<int, TaghvimEvent>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // Fallback default time slots if offline
        if (_timeSlots.isEmpty) {
          _timeSlots = [
            {'id': 1, 'title': '۰۸:۰۰ تا ۱۰:۰۰', 'start_time': '08:00', 'end_time': '10:00'},
            {'id': 2, 'title': '۱۰:۰۰ تا ۱۲:۰۰', 'start_time': '10:00', 'end_time': '12:00'},
            {'id': 3, 'title': '۱۲:۰۰ تا ۱۴:۰۰', 'start_time': '12:00', 'end_time': '14:00'},
            {'id': 4, 'title': '۱۴:۰۰ تا ۱۶:۰۰', 'start_time': '14:00', 'end_time': '16:00'},
            {'id': 5, 'title': '۱۶:۰۰ تا ۱۸:۰۰', 'start_time': '16:00', 'end_time': '18:00'},
          ];
        }
        setState(() => _isLoading = false);
      }
    }
  }

  int get _daysInSelectedMonth {
    if (_jalaliMonth <= 6) return 31;
    if (_jalaliMonth <= 11) return 30;
    return Jalali(_jalaliYear, _jalaliMonth).isLeapYear() ? 30 : 29;
  }

  /// Exact days of the selected week, strictly starting from day 1 of the month
  List<Jalali> get _currentWeekDays {
    final startDay = (_selectedWeekIndex * 7) + 1;
    final days = <Jalali>[];
    for (int i = 0; i < 7; i++) {
      final dayNum = startDay + i;
      if (dayNum <= _daysInSelectedMonth) {
        days.add(Jalali(_jalaliYear, _jalaliMonth, dayNum));
      }
    }
    return days;
  }

  Jalali? get _activeDay {
    final week = _currentWeekDays;
    if (_selectedDayIndex < week.length) {
      return week[_selectedDayIndex];
    }
    return week.isNotEmpty ? week.first : null;
  }

  String _formatGregorian(Jalali j) {
    final g = j.toGregorian();
    final y = g.year.toString().padLeft(4, '0');
    final m = g.month.toString().padLeft(2, '0');
    final d = g.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  TaghvimEvent? _getHolidayForDay(Jalali day) {
    final monthEvents = _taghvimHolidays[day.month];
    if (monthEvents != null && monthEvents.containsKey(day.day)) {
      return monthEvents[day.day];
    }
    final title = TaghvimHolidayService.getHolidayTitle(day.year, day.month, day.day);
    if (title != null) {
      return TaghvimEvent(day: day.day, title: title, isHoliday: true);
    }
    return null;
  }

  bool _isDayHoliday(Jalali day) {
    if (day.weekDay == 7) return true; // Friday
    final tEvent = _getHolidayForDay(day);
    if (tEvent != null && tEvent.isHoliday) return true;
    return false;
  }

  Map<String, dynamic>? _findReservation(Jalali day, int slotId) {
    final gStr = _formatGregorian(day);
    for (final r in _reservations) {
      final rDate = (r['reservation_date'] ?? '').toString();
      final rSlot = r['time_slot_id'];
      final rStatus = (r['status'] ?? '').toString();
      if (rDate.startsWith(gStr) && rSlot == slotId && rStatus == 'confirmed') {
        return r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map);
      }
    }
    return null;
  }

  void _changeMonth(int delta) {
    int m = _jalaliMonth + delta;
    int y = _jalaliYear;
    if (m > 12) {
      m = 1;
      y++;
    } else if (m < 1) {
      m = 12;
      y--;
    }
    final available = _availableYears;
    if (y < available.first || y > available.last) return; // Stay strictly within 3-year rolling window

    setState(() {
      _jalaliYear = y;
      _jalaliMonth = m;
      _selectedWeekIndex = 0;
      _selectedDayIndex = 0;
    });
    _loadCalendar();
  }

  void _onSlotTapped(CalendarCellModel cell) {
    if (cell.status == 'blocked') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('این سانس زمانی مسدود است: ${cell.blockReason ?? "توسط مدیریت"}'),
          backgroundColor: AppColors.disabledText,
        ),
      );
      return;
    }

    if (cell.status == 'reserved') {
      MobileReservationDetailsSheet.show(
        context,
        cell: cell,
        currentUser: widget.currentUser,
        onCancelled: _loadCalendar,
      );
      return;
    }

    // Available or Holiday -> Bookable!
    MobileBookingSheet.show(
      context,
      cell: cell,
      currentUser: widget.currentUser,
      onSuccess: _loadCalendar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDay = _activeDay;
    final currentWeek = _currentWeekDays;
    final weekTitles = ['هفته اول', 'هفته دوم', 'هفته سوم', 'هفته چهارم', 'هفته پنجم'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: SafeArea(
          child: Column(
            children: [
              MobileTopBar(onLogout: widget.onLogout),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtitle & Header
                      const Text(
                        'سامانه رزرو سالن آمفی‌تئاتر',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'تقویم رزرو سالن',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      if (activeDay != null)
                        Text(
                          '${_weekDayNames[(activeDay.weekDay - 1) % 7]} ${activeDay.day} ${_persianMonthNames[_jalaliMonth - 1]} $_jalaliYear',
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryGreen, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 14),

                      // Month & Year Selector Card (Strictly 3 rolling years)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Navigation arrows
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryGreen),
                                  onPressed: () => _changeMonth(-1),
                                  tooltip: 'ماه قبل',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGreen),
                                  onPressed: () => _changeMonth(1),
                                  tooltip: 'ماه بعد',
                                ),
                              ],
                            ),

                            // Dropdowns for Year & Month
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Month Dropdown
                                PopupMenuButton<int>(
                                  initialValue: _jalaliMonth,
                                  onSelected: (m) {
                                    setState(() {
                                      _jalaliMonth = m;
                                      _selectedWeekIndex = 0;
                                      _selectedDayIndex = 0;
                                    });
                                    _loadCalendar();
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _persianMonthNames[_jalaliMonth - 1],
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen, size: 18),
                                    ],
                                  ),
                                  itemBuilder: (_) => List.generate(12, (idx) => PopupMenuItem(
                                    value: idx + 1,
                                    child: Text(_persianMonthNames[idx]),
                                  )),
                                ),
                                const SizedBox(width: 8),

                                // Year Dropdown
                                PopupMenuButton<int>(
                                  initialValue: _jalaliYear,
                                  onSelected: (y) {
                                    setState(() {
                                      _jalaliYear = y;
                                      _selectedWeekIndex = 0;
                                      _selectedDayIndex = 0;
                                    });
                                    _loadCalendar();
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_jalaliYear',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen, size: 18),
                                    ],
                                  ),
                                  itemBuilder: (_) => _availableYears.map((yr) => PopupMenuItem(
                                    value: yr,
                                    child: Text('$yr'),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Week Selector Pills (هفته اول تا پنجم)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(5, (wIdx) {
                            final isSel = wIdx == _selectedWeekIndex;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedWeekIndex = wIdx;
                                    _selectedDayIndex = 0;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primaryGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? AppColors.primaryGreen : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    weekTitles[wIdx],
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                      color: isSel ? Colors.white : AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Day Selector Horizontal Strip (Strictly days of this month, starts with Day 1)
                      Row(
                        children: List.generate(7, (index) {
                          if (index >= currentWeek.length) {
                            return const Expanded(child: SizedBox());
                          }
                          final day = currentWeek[index];
                          final isSelected = _selectedDayIndex == index;
                          final isHoliday = _isDayHoliday(day);
                          final dayName = _weekDayNames[(day.weekDay - 1) % 7];

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: InkWell(
                                onTap: () => setState(() => _selectedDayIndex = index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : isHoliday
                                            ? const Color(0xFFFFEBEE)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : isHoliday
                                              ? const Color(0xFFFFCDD2)
                                              : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : isHoliday
                                                  ? const Color(0xFFC62828)
                                                  : AppColors.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : isHoliday
                                                  ? const Color(0xFFC62828)
                                                  : AppColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      // Holiday Banner if active day is holiday
                      if (activeDay != null && _isDayHoliday(activeDay)) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.holidayRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'تعطیل',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.holidayRedText),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getHolidayForDay(activeDay)?.title ?? (activeDay.weekDay == 7 ? 'تعطیل هفتگی جمعه' : 'تعطیل رسمی'),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.holidayRedText),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'رزرو سالن برای برنامه‌ها و جشن‌های مدارس مجاز است',
                                      style: TextStyle(fontSize: 10.5, color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.event_available_rounded, color: AppColors.primaryGreen, size: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Time Slots for Active Day
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                        )
                      else if (activeDay != null && _timeSlots.isNotEmpty) ...[
                        ..._timeSlots.map((slot) {
                          return _buildSlotCardForDay(activeDay, slot);
                        }),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'سانسی برای این تاریخ تعریف نشده است.',
                              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Color Legend at bottom
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem('آزاد', AppColors.primaryGreen),
                            _buildLegendItem('رزرو شده', AppColors.reservationBlueText),
                            _buildLegendItem('تعطیل', AppColors.holidayRedText),
                            _buildLegendItem('مسدود', AppColors.disabledText),
                          ],
                        ),
                      ),

                      const MobileFooter(compact: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCardForDay(Jalali day, Map<String, dynamic> slot) {
    final slotId = slot['id'] is int ? slot['id'] as int : int.tryParse(slot['id'].toString()) ?? 1;
    final slotTitle = slot['title']?.toString() ?? 'سانس $slotId';
    final startTime = slot['start_time']?.toString() ?? '08:00';
    final endTime = slot['end_time']?.toString() ?? '10:00';
    final gStr = _formatGregorian(day);
    final jStr = '${day.day} ${_persianMonthNames[day.month - 1]} ${day.year}';
    final jDayName = _weekDayNames[(day.weekDay - 1) % 7];

    final res = _findReservation(day, slotId);
    final isHoliday = _isDayHoliday(day);
    final tEvent = _getHolidayForDay(day);
    final holidayTitle = tEvent?.title ?? (day.weekDay == 7 ? 'تعطیل هفتگی جمعه' : 'تعطیل رسمی');

    String status = 'available';
    int? reservationId;
    String? schoolName;
    String? userFullName;

    if (res != null) {
      status = 'reserved';
      reservationId = res['id'] is int ? res['id'] as int : int.tryParse(res['id'].toString());
      schoolName = res['school_name']?.toString() ?? (res['school'] is Map ? res['school']['name']?.toString() : 'مدرسه متقاضی');
      userFullName = res['user_name']?.toString() ?? (res['user'] is Map ? '${res['user']['first_name']} ${res['user']['last_name']}' : 'متقاضی');
    }

    final cell = CalendarCellModel(
      date: gStr,
      jalaliDate: jStr,
      jalaliDayName: jDayName,
      dayOfWeek: (day.weekDay - 1) % 7,
      timeSlotId: slotId,
      timeSlotTitle: '$slotTitle ($startTime – $endTime)',
      status: status,
      isHoliday: isHoliday,
      holidayTitle: isHoliday ? holidayTitle : null,
      isBlocked: false,
      reservationId: reservationId,
      schoolName: schoolName,
      userFullName: userFullName,
    );

    Color cardBg;
    Color borderColor;
    Color textColor;
    String badgeText;
    Color badgeColor;
    Color badgeTextColor;
    String subtitle;

    if (cell.status == 'reserved') {
      cardBg = AppColors.reservationBlue;
      borderColor = const Color(0xFFBFDBFE);
      textColor = AppColors.reservationBlueText;
      badgeText = cell.schoolName ?? 'رزرو شده';
      badgeColor = Colors.white;
      badgeTextColor = AppColors.reservationBlueText;
      subtitle = cell.userFullName ?? 'ثبت شده';
    } else if (cell.isHoliday) {
      cardBg = AppColors.holidayRed;
      borderColor = const Color(0xFFFCA5A5);
      textColor = AppColors.holidayRedText;
      badgeText = '+ آزاد';
      badgeColor = Colors.white;
      badgeTextColor = AppColors.holidayRedText;
      subtitle = '$holidayTitle (قابل رزرو)';
    } else {
      cardBg = AppColors.pastelGreen;
      borderColor = const Color(0xFFA7F3D0);
      textColor = AppColors.darkGreen;
      badgeText = '+ آزاد';
      badgeColor = Colors.white;
      badgeTextColor = AppColors.primaryGreen;
      subtitle = 'قابل رزرو';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSlotTapped(cell),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Right Info: Title, Hours, Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cell.timeSlotTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Left Badge: Status (+ آزاد, school name, مسدود)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
