import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import '../models/calendar_day.dart';
import 'booking_modal.dart';
import 'reservation_details_modal.dart';

class CalendarScreen extends StatefulWidget {
  final UserModel currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CalendarDayModel> _days = [];
  List<TimeSlotModel> _timeSlots = [];

  late int _jalaliYear;
  late int _jalaliMonth;
  int _selectedWeekIndex = 0; // 0 to 4 (5 week tabs)

  static const List<String> _persianMonthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<int> _availableYears = [1403, 1404, 1405, 1406, 1407];

  String get _currentMonthTitle => _persianMonthNames[(_jalaliMonth - 1).clamp(0, 11)];
  String get _monthName => _currentMonthTitle;

  int get _totalWeeksInMonth {
    final firstDay = Jalali(_jalaliYear, _jalaliMonth, 1);
    final prevDaysCount = firstDay.weekDay - 1; // 0 for Saturday, 6 for Friday
    final totalDays = prevDaysCount + firstDay.monthLength;
    return ((totalDays - 1) ~/ 7) + 1;
  }

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _jalaliYear = now.year;
    _jalaliMonth = now.month;
    _selectedWeekIndex = _computeCurrentWeekIndex(_jalaliYear, _jalaliMonth);
    _loadCalendar();
  }

  int _computeCurrentWeekIndex(int year, int month) {
    final now = Jalali.now();
    final firstDay = Jalali(year, month, 1);
    final prevDaysCount = firstDay.weekDay - 1;
    final totalDays = prevDaysCount + firstDay.monthLength;
    final totalWeeks = ((totalDays - 1) ~/ 7) + 1;

    if (now.year != year || now.month != month) {
      return 0; // Default to Week 1 for other months
    }
    final week1Sat = firstDay - prevDaysCount;
    for (int w = 0; w < totalWeeks; w++) {
      final wSat = week1Sat + (w * 7);
      final wFri = wSat + 6;
      if (now >= wSat && now <= wFri) {
        return w;
      }
    }
    return 0;
  }

  void _changeMonth(int delta) {
    setState(() {
      _jalaliMonth += delta;
      if (_jalaliMonth > 12) {
        _jalaliMonth = 1;
        _jalaliYear++;
      } else if (_jalaliMonth < 1) {
        _jalaliMonth = 12;
        _jalaliYear--;
      }
      _selectedWeekIndex = _computeCurrentWeekIndex(_jalaliYear, _jalaliMonth).clamp(0, _totalWeeksInMonth - 1);
    });
    _loadCalendar();
  }

  void _selectMonth(int monthIndex) {
    setState(() {
      _jalaliMonth = monthIndex + 1;
      _selectedWeekIndex = _computeCurrentWeekIndex(_jalaliYear, _jalaliMonth).clamp(0, _totalWeeksInMonth - 1);
    });
    _loadCalendar();
  }

  void _selectYear(int year) {
    setState(() {
      _jalaliYear = year;
      _selectedWeekIndex = _computeCurrentWeekIndex(_jalaliYear, _jalaliMonth).clamp(0, _totalWeeksInMonth - 1);
    });
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Calculate Saturday of Week 1
    final firstDayOfMonth = Jalali(_jalaliYear, _jalaliMonth, 1);
    final prevDaysCount = firstDayOfMonth.weekDay - 1; // Days from prev month in week 1
    final week1Sat = firstDayOfMonth - prevDaysCount;

    // 2. Calculate Saturday of selected week
    final currentWeekSat = week1Sat + (_selectedWeekIndex * 7);

    // Pick a sample day in this week to query backend API
    Jalali sampleDay = currentWeekSat;
    for (int d = 0; d < 7; d++) {
      final candidate = currentWeekSat + d;
      if (candidate.year == _jalaliYear && candidate.month == _jalaliMonth) {
        sampleDay = candidate;
        break;
      }
    }
    final gTarget = sampleDay.toDateTime();
    final targetDateStr = '${gTarget.year}-${gTarget.month.toString().padLeft(2, '0')}-${gTarget.day.toString().padLeft(2, '0')}';

    final weekDays = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];

    try {
      final data = await ApiService.getCalendarWeek(targetDate: targetDateStr);
      final rawSlots = (data['time_slots'] as List? ?? []).map((s) => TimeSlotModel.fromJson(s)).toList();
      final rawDays = (data['days'] as List? ?? []).map((d) => CalendarDayModel.fromJson(d)).toList();

      // Build calibrated 7-day model ensuring exact month boundaries
      final calibratedDays = List.generate(7, (i) {
        final currentJDay = currentWeekSat + i;
        final currentGDay = currentJDay.toDateTime();
        final dateStr = '${currentGDay.year}-${currentGDay.month.toString().padLeft(2, '0')}-${currentGDay.day.toString().padLeft(2, '0')}';

        // Check if day is out of month in later weeks
        final isAfterMonthEnd = (_selectedWeekIndex >= 3) &&
            (currentJDay.year > _jalaliYear || (currentJDay.year == _jalaliYear && currentJDay.month > _jalaliMonth));

        // Check if day belongs to previous month in week 1
        final isBeforeMonthStart = (_selectedWeekIndex == 0) &&
            (currentJDay.year < _jalaliYear || (currentJDay.year == _jalaliYear && currentJDay.month < _jalaliMonth));

        final monthNameDisplay = _persianMonthNames[currentJDay.month - 1];

        if (isAfterMonthEnd || isBeforeMonthStart) {
          // Out of current month: display as blank / out of range
          return CalendarDayModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            dayName: weekDays[i],
            dayNumber: '—',
            monthNameDisplay: isBeforeMonthStart ? 'ماه قبل' : 'پایان ماه',
            isToday: false,
            isHoliday: false,
            isOutOfMonth: true,
            slots: [],
          );
        }

        // Match with backend data for this date
        CalendarDayModel? matchedDay;
        for (final rd in rawDays) {
          if (rd.date == dateStr) {
            matchedDay = rd;
            break;
          }
        }

        final isToday = (currentJDay == Jalali.now());
        final isFri = (i == 6);

        if (matchedDay != null) {
          return CalendarDayModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            dayName: weekDays[i],
            dayNumber: currentJDay.day.toString(),
            monthNameDisplay: monthNameDisplay,
            isToday: isToday,
            isHoliday: matchedDay.isHoliday || isFri,
            holidayTitle: matchedDay.holidayTitle ?? (isFri ? 'تعطیل هفتگی جمعه' : null),
            isOutOfMonth: false,
            slots: matchedDay.slots,
          );
        }

        // Fallback slots if not in backend response
        return CalendarDayModel(
          date: dateStr,
          jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
          dayName: weekDays[i],
          dayNumber: currentJDay.day.toString(),
          monthNameDisplay: monthNameDisplay,
          isToday: isToday,
          isHoliday: isFri,
          holidayTitle: isFri ? 'تعطیل هفتگی جمعه' : null,
          isOutOfMonth: false,
          slots: rawSlots.map((ts) => CalendarCellModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            jalaliDayName: weekDays[i],
            dayOfWeek: i,
            timeSlotId: ts.id,
            timeSlotTitle: ts.title,
            status: isFri ? 'holiday' : 'available',
            isHoliday: isFri,
            holidayTitle: isFri ? 'تعطیل هفتگی جمعه' : null,
            isBlocked: false,
          )).toList(),
        );
      });

      setState(() {
        _timeSlots = rawSlots;
        _days = calibratedDays;
      });
    } catch (_) {
      // Offline fallback
      final fallbackSlots = [
        TimeSlotModel(id: 1, slotNumber: 1, title: '۰۸:۰۰ تا ۱۰:۰۰', startTime: '08:00', endTime: '10:00'),
        TimeSlotModel(id: 2, slotNumber: 2, title: '۱۰:۰۰ تا ۱۲:۰۰', startTime: '10:00', endTime: '12:00'),
        TimeSlotModel(id: 3, slotNumber: 3, title: '۱۲:۰۰ تا ۱۴:۰۰', startTime: '12:00', endTime: '14:00'),
        TimeSlotModel(id: 4, slotNumber: 4, title: '۱۴:۰۰ تا ۱۶:۰۰', startTime: '14:00', endTime: '16:00'),
        TimeSlotModel(id: 5, slotNumber: 5, title: '۱۶:۰۰ تا ۱۸:۰۰', startTime: '16:00', endTime: '18:00'),
      ];

      final fallbackDays = List.generate(7, (i) {
        final currentJDay = currentWeekSat + i;
        final currentGDay = currentJDay.toDateTime();
        final dateStr = '${currentGDay.year}-${currentGDay.month.toString().padLeft(2, '0')}-${currentGDay.day.toString().padLeft(2, '0')}';

        final isAfterMonthEnd = (_selectedWeekIndex >= 3) &&
            (currentJDay.year > _jalaliYear || (currentJDay.year == _jalaliYear && currentJDay.month > _jalaliMonth));

        final isBeforeMonthStart = (_selectedWeekIndex == 0) &&
            (currentJDay.year < _jalaliYear || (currentJDay.year == _jalaliYear && currentJDay.month < _jalaliMonth));

        final monthNameDisplay = _persianMonthNames[currentJDay.month - 1];

        if (isAfterMonthEnd || isBeforeMonthStart) {
          return CalendarDayModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            dayName: weekDays[i],
            dayNumber: '—',
            monthNameDisplay: isBeforeMonthStart ? 'ماه قبل' : 'پایان ماه',
            isToday: false,
            isHoliday: false,
            isOutOfMonth: true,
            slots: [],
          );
        }

        final isToday = (currentJDay == Jalali.now());
        final isFri = (i == 6);

        return CalendarDayModel(
          date: dateStr,
          jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
          dayName: weekDays[i],
          dayNumber: currentJDay.day.toString(),
          monthNameDisplay: monthNameDisplay,
          isToday: isToday,
          isHoliday: isFri,
          holidayTitle: isFri ? 'تعطیل هفتگی جمعه' : null,
          isOutOfMonth: false,
          slots: fallbackSlots.map((ts) => CalendarCellModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            jalaliDayName: weekDays[i],
            dayOfWeek: i,
            timeSlotId: ts.id,
            timeSlotTitle: ts.title,
            status: isFri ? 'holiday' : 'available',
            isHoliday: isFri,
            holidayTitle: isFri ? 'تعطیل هفتگی جمعه' : null,
            isBlocked: false,
          )).toList(),
        );
      });

      setState(() {
        _timeSlots = fallbackSlots;
        _days = fallbackDays;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCellClicked(CalendarCellModel cell) {
    if (cell.status == 'blocked') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'این سانس مسدود است: ${cell.blockReason ?? "تعطیلی یا سرویس سالن"}',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.holidayRedText,
        ),
      );
    } else if (cell.status == 'reserved') {
      showDialog(
        context: context,
        builder: (_) => ReservationDetailsModal(
          cell: cell,
          currentUser: widget.currentUser,
          onCancelSuccess: _loadCalendar,
        ),
      );
    } else {
      // Available or bookable holiday
      showDialog(
        context: context,
        builder: (_) => BookingModal(
          cell: cell,
          currentUser: widget.currentUser,
          onBookingSuccess: _loadCalendar,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = Jalali.now();
    final todayStr = 'امروز: ${now.formatter.wN}، ${now.day} ${_persianMonthNames[now.month - 1]} ${now.year}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Calendar Control Header (Always visible for seamless navigation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(color: AppColors.darkGreen.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Interactive Month and Year selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.primaryGreen),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'ماه بعد',
                        mouseCursor: SystemMouseCursors.click,
                        onPressed: () => _changeMonth(1),
                      ),
                      const SizedBox(width: 4),

                      // Month Picker Popup
                      PopupMenuButton<int>(
                        tooltip: 'انتخاب ماه',
                        initialValue: _jalaliMonth - 1,
                        onSelected: _selectMonth,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentMonthTitle,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryGreen),
                              ],
                            ),
                          ),
                        ),
                        itemBuilder: (ctx) => List.generate(12, (i) => PopupMenuItem(
                          value: i,
                          child: Text(
                            _persianMonthNames[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (i + 1 == _jalaliMonth) ? FontWeight.bold : FontWeight.normal,
                              color: (i + 1 == _jalaliMonth) ? AppColors.primaryGreen : AppColors.mainText,
                            ),
                          ),
                        )),
                      ),

                      const SizedBox(width: 4),

                      // Year Picker Popup
                      PopupMenuButton<int>(
                        tooltip: 'انتخاب سال',
                        initialValue: _jalaliYear,
                        onSelected: _selectYear,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_jalaliYear',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryGreen),
                              ],
                            ),
                          ),
                        ),
                        itemBuilder: (ctx) => _availableYears.map((yr) => PopupMenuItem(
                          value: yr,
                          child: Text(
                            '$yr',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (yr == _jalaliYear) ? FontWeight.bold : FontWeight.normal,
                              color: (yr == _jalaliYear) ? AppColors.primaryGreen : AppColors.mainText,
                            ),
                          ),
                        )).toList(),
                      ),

                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.primaryGreen),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'ماه قبل',
                        mouseCursor: SystemMouseCursors.click,
                        onPressed: () => _changeMonth(-1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Dynamic Week Tabs (Scrollable & Responsive, never overflows!)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_totalWeeksInMonth, (index) {
                        const weekLabels = [
                          'هفته اول',
                          'هفته دوم',
                          'هفته سوم',
                          'هفته چهارم',
                          'هفته پنجم',
                          'هفته ششم',
                          'هفته هفتم',
                        ];
                        final isSelected = _selectedWeekIndex == index;
                        final label = index < weekLabels.length ? weekLabels[index] : 'هفته ${index + 1}';
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Material(
                            color: isSelected ? AppColors.primaryGreen : AppColors.veryLightGreen,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              onTap: () {
                                if (_selectedWeekIndex == index && !_isLoading) return;
                                setState(() {
                                  _selectedWeekIndex = index;
                                });
                                _loadCalendar();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected ? null : Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppColors.white : AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Dynamic Today Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        todayStr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Calendar Content Area (Responsive Loading & Error states)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 54, color: AppColors.holidayRedText),
                            const SizedBox(height: 14),
                            Text(_errorMessage!, style: const TextStyle(fontSize: 14, color: AppColors.mainText)),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _loadCalendar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('تلاش مجدد', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(color: AppColors.darkGreen.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // Column Headers (Day/Date column on Right, then 5 Time Slots)
                    Container(
                      color: AppColors.veryLightGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          // Right Date Column Header
                          const SizedBox(
                            width: 145,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: AppColors.primaryGreen),
                                SizedBox(width: 8),
                                Text(
                                  'روز و تاریخ',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                ),
                              ],
                            ),
                          ),
                          // 5 Time Slot Headers
                          ..._timeSlots.map((ts) => Expanded(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: AppColors.secondaryText),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        ts.title,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),

                    // Calendar Rows (7 Weekdays: Saturday to Friday)
                    Expanded(
                      child: ListView.separated(
                        itemCount: _days.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                        itemBuilder: (context, dayIdx) {
                          final day = _days[dayIdx];
                          final isOutOfMonth = day.isOutOfMonth;

                          return SizedBox(
                            height: 76,
                            child: Row(
                              children: [
                                // Day & Jalali Date Box (Right column)
                                Container(
                                  width: 145,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  color: day.isToday
                                      ? AppColors.pastelGreen.withOpacity(0.4)
                                      : (isOutOfMonth ? Colors.grey.shade50 : Colors.transparent),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day.dayName,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfMonth
                                              ? Colors.grey.shade400
                                              : (day.isHoliday ? AppColors.holidayRedText : AppColors.darkGreen),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isOutOfMonth
                                            ? 'خارج از محدوده ماه'
                                            : '${day.dayNumber} ${day.monthNameDisplay ?? _monthName}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isOutOfMonth
                                              ? Colors.grey.shade400
                                              : (day.isHoliday ? AppColors.holidayRedText : AppColors.secondaryText),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Cells for this day (5 time slot columns)
                                if (isOutOfMonth)
                                  ...List.generate(_timeSlots.length, (sIdx) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '—',
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ))
                                else
                                  ...day.slots.map((cell) => Expanded(
                                    child: _buildCalendarCell(cell),
                                  )),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(CalendarCellModel cell) {
    Color bgColor;
    Color textColor;
    String line1 = '';
    String line2 = '';
    IconData? cellIcon;

    if (cell.status == 'blocked') {
      bgColor = AppColors.disabledGray;
      textColor = AppColors.disabledText;
      line1 = 'مسدود';
      line2 = cell.blockReason ?? 'توسط مدیریت';
      cellIcon = Icons.lock_outline;
    } else if (cell.status == 'reserved') {
      bgColor = AppColors.reservationBlue;
      textColor = AppColors.reservationBlueText;
      line1 = cell.schoolName ?? 'رزرو شده';
      line2 = cell.userFullName ?? 'متقاضی';
      cellIcon = Icons.event_available;
    } else if (cell.isHoliday) {
      bgColor = AppColors.holidayRed;
      textColor = AppColors.holidayRedText;
      line1 = '+ آزاد';
      line2 = cell.holidayTitle ?? 'تعطیل رسمی (مجاز)';
      cellIcon = Icons.add_circle_outline;
    } else {
      bgColor = AppColors.pastelGreen;
      textColor = AppColors.darkGreen;
      line1 = '+ آزاد';
      line2 = 'قابل رزرو';
      cellIcon = Icons.add_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => _onCellClicked(cell),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cellIcon != null) Icon(cellIcon, size: 14, color: textColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          line1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    line2,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
