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
  int _selectedWeekIndex = 0;
  int _selectedDayIndex = 0; // 0 (Sat) to 6 (Fri)

  bool _isLoading = true;
  List<TimeSlotModel> _timeSlots = [];
  List<CalendarDayModel> _days = [];

  static const List<String> _persianMonthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> _weekDayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
  ];

  List<int> get _availableYears {
    final curYear = Jalali.now().year;
    return List.generate(3, (i) => curYear + i);
  }

  int _getPersianWeekdayIndex(Jalali j) => (j.toDateTime().weekday + 1) % 7;

  int _computeTotalWeeks(int year, int month) {
    final daysInMonth = (month <= 6) ? 31 : (month <= 11) ? 30 : Jalali(year, month).monthLength;
    final firstDay = Jalali(year, month, 1);
    final firstWd = _getPersianWeekdayIndex(firstDay);
    return ((firstWd + daysInMonth + 6) / 7).floor();
  }

  int _computeCurrentWeekIndex(int year, int month) {
    final now = Jalali.now();
    if (now.year != year || now.month != month) return 0;
    final firstDay = Jalali(year, month, 1);
    final firstWd = _getPersianWeekdayIndex(firstDay);
    return ((firstWd + now.day - 1) / 7).floor();
  }

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _jalaliYear = now.year;
    _jalaliMonth = now.month;
    _selectedWeekIndex = _computeCurrentWeekIndex(_jalaliYear, _jalaliMonth);
    _selectedDayIndex = _getPersianWeekdayIndex(now);
    TaghvimHolidayService.initialize();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);

    await TaghvimHolidayService.syncMonthFromTaghvim(_jalaliYear, _jalaliMonth);

    final firstDayOfMonth = Jalali(_jalaliYear, _jalaliMonth, 1);
    final firstDayWd = _getPersianWeekdayIndex(firstDayOfMonth);
    final monthSat = firstDayOfMonth - firstDayWd;
    final currentWeekSat = monthSat + (_selectedWeekIndex * 7);

    // Midweek target date for backend query
    final targetG = (currentWeekSat + 3).toDateTime();
    final targetDateStr = '${targetG.year}-${targetG.month.toString().padLeft(2, '0')}-${targetG.day.toString().padLeft(2, '0')}';

    try {
      final data = await ApiService.getCalendarWeek(targetDate: targetDateStr);
      final rawSlots = (data['time_slots'] as List? ?? []).map((s) => TimeSlotModel.fromJson(s)).toList();
      final rawDays = (data['days'] as List? ?? []).map((d) => CalendarDayModel.fromJson(d)).toList();

      final calibratedDays = List.generate(7, (i) {
        final currentJDay = currentWeekSat + i;
        final currentGDay = currentJDay.toDateTime();
        final dateStr = '${currentGDay.year}-${currentGDay.month.toString().padLeft(2, '0')}-${currentGDay.day.toString().padLeft(2, '0')}';

        final isToday = (currentJDay == Jalali.now());
        final isFri = (i == 6);
        final taghvimHoliday = TaghvimHolidayService.getHolidayTitle(currentJDay.year, currentJDay.month, currentJDay.day);
        final effectiveIsHoliday = (taghvimHoliday != null) || isFri;
        final effectiveHolidayTitle = taghvimHoliday ?? (isFri ? 'تعطیل هفتگی جمعه' : null);

        CalendarDayModel? matchedDay;
        for (final rd in rawDays) {
          if (rd.date == dateStr) {
            matchedDay = rd;
            break;
          }
        }

        final monthNameDisplay = _persianMonthNames[currentJDay.month - 1];

        if (matchedDay != null) {
          final slotsWithHolidays = matchedDay.slots.map((s) {
            if (s.status == 'reserved') return s;
            final blockReasonStr = s.blockReason ?? '';
            final isBlockedByOldHoliday = s.status == 'blocked' && (
              blockReasonStr.contains('تعطیل') ||
              blockReasonStr.contains('مبعث') ||
              blockReasonStr.contains('ولادت') ||
              blockReasonStr.contains('نوروز') ||
              blockReasonStr.contains('رسمی')
            );
            if (effectiveIsHoliday || isBlockedByOldHoliday) {
              return s.copyWith(
                status: 'available',
                isHoliday: effectiveIsHoliday,
                holidayTitle: effectiveHolidayTitle,
                isBlocked: false,
                blockReason: null,
              );
            }
            return s;
          }).toList();

          return CalendarDayModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            dayName: _weekDayNames[i],
            dayNumber: currentJDay.day.toString(),
            monthNameDisplay: monthNameDisplay,
            isToday: isToday,
            isHoliday: effectiveIsHoliday,
            holidayTitle: effectiveHolidayTitle,
            isOutOfMonth: false,
            slots: slotsWithHolidays,
          );
        }

        return CalendarDayModel(
          date: dateStr,
          jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
          dayName: _weekDayNames[i],
          dayNumber: currentJDay.day.toString(),
          monthNameDisplay: monthNameDisplay,
          isToday: isToday,
          isHoliday: effectiveIsHoliday,
          holidayTitle: effectiveHolidayTitle,
          isOutOfMonth: false,
          slots: rawSlots.map((ts) => CalendarCellModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} $monthNameDisplay ${currentJDay.year}',
            jalaliDayName: _weekDayNames[i],
            dayOfWeek: i,
            timeSlotId: ts.id,
            timeSlotTitle: ts.title,
            status: 'available',
            isHoliday: effectiveIsHoliday,
            holidayTitle: effectiveHolidayTitle,
            isBlocked: false,
          )).toList(),
        );
      });

      if (!mounted) return;
      setState(() {
        _timeSlots = rawSlots;
        _days = calibratedDays;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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

    // Available or Holiday -> Bookable
    MobileBookingSheet.show(
      context,
      cell: cell,
      currentUser: widget.currentUser,
      onSuccess: _loadCalendar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalWeeks = _computeTotalWeeks(_jalaliYear, _jalaliMonth);
    final selectedDay = (_days.length > _selectedDayIndex) ? _days[_selectedDayIndex] : null;

    final weekTitles = ['هفته اول', 'هفته دوم', 'هفته سوم', 'هفته چهارم', 'هفته پنجم', 'هفته ششم'];

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
                      if (selectedDay != null)
                        Text(
                          '${selectedDay.dayName} ${selectedDay.dayNumber} ${_persianMonthNames[_jalaliMonth - 1]} $_jalaliYear',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryGreen, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 14),

                      // Month & Year Selector Card
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
                            // Left: Month navigation arrows
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryGreen),
                                  onPressed: () => _changeMonth(1),
                                  tooltip: 'ماه بعد',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGreen),
                                  onPressed: () => _changeMonth(-1),
                                  tooltip: 'ماه قبل',
                                ),
                              ],
                            ),

                            // Right: Dropdowns for Year & Month
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Year Dropdown
                                PopupMenuButton<int>(
                                  initialValue: _jalaliYear,
                                  onSelected: (y) {
                                    setState(() => _jalaliYear = y);
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
                                const SizedBox(width: 8),

                                // Month Dropdown
                                PopupMenuButton<int>(
                                  initialValue: _jalaliMonth,
                                  onSelected: (m) {
                                    setState(() => _jalaliMonth = m);
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Week Selector Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalWeeks, (wIdx) {
                            final isSel = wIdx == _selectedWeekIndex;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedWeekIndex = wIdx);
                                  _loadCalendar();
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
                                    weekTitles[wIdx.clamp(0, 5)],
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

                      // Day Chips Strip (Saturday to Friday)
                      if (_days.isNotEmpty)
                        Row(
                          children: List.generate(7, (dIdx) {
                            final d = _days[dIdx];
                            final isSel = dIdx == _selectedDayIndex;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedDayIndex = dIdx),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.primaryGreen : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.primaryGreen
                                            : (d.isHoliday ? const Color(0xFFFCA5A5) : AppColors.cardBorder),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          d.dayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSel
                                                ? Colors.white
                                                : (d.isHoliday ? AppColors.holidayRedText : AppColors.secondaryText),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d.dayNumber,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: isSel
                                                ? Colors.white
                                                : (d.isHoliday ? AppColors.holidayRedText : AppColors.darkGreen),
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

                      // Holiday Banner if selected day is holiday (user-06.png)
                      if (selectedDay != null && selectedDay.isHoliday) ...[
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
                                      selectedDay.holidayTitle ?? 'تعطیل رسمی',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.holidayRedText),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'رزرو سالن برای برنامه‌های مدارس مجاز است',
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

                      // Time Slots for Selected Day
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                        )
                      else if (selectedDay != null && selectedDay.slots.isNotEmpty) ...[
                        ...selectedDay.slots.map((slot) {
                          return _buildSlotCard(slot);
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

                      // Color Legend at bottom (user-05.png)
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

  Widget _buildSlotCard(CalendarCellModel slot) {
    Color cardBg;
    Color borderColor;
    Color textColor;
    String badgeText;
    Color badgeColor;
    Color badgeTextColor;
    String subtitle;

    final isHoliday = slot.isHoliday;

    if (slot.status == 'blocked') {
      cardBg = AppColors.disabledGray;
      borderColor = const Color(0xFFD1D5DB);
      textColor = AppColors.disabledText;
      badgeText = 'مسدود';
      badgeColor = const Color(0xFFE5E7EB);
      badgeTextColor = AppColors.disabledText;
      subtitle = slot.blockReason ?? 'توسط مدیریت';
    } else if (slot.status == 'reserved') {
      cardBg = AppColors.reservationBlue;
      borderColor = const Color(0xFFBFDBFE);
      textColor = AppColors.reservationBlueText;
      badgeText = slot.schoolName ?? 'رزرو شده';
      badgeColor = Colors.white;
      badgeTextColor = AppColors.reservationBlueText;
      subtitle = slot.userFullName ?? 'ثبت شده';
    } else if (isHoliday) {
      cardBg = AppColors.holidayRed;
      borderColor = const Color(0xFFFCA5A5);
      textColor = AppColors.holidayRedText;
      badgeText = '+ آزاد';
      badgeColor = Colors.white;
      badgeTextColor = AppColors.holidayRedText;
      subtitle = slot.holidayTitle ?? 'تعطیل رسمی (قابل رزرو)';
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
          onTap: () => _onSlotTapped(slot),
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
                        slot.timeSlotTitle,
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
