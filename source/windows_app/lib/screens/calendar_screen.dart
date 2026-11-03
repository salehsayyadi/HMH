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

  String get _currentMonthTitle => _persianMonthNames[(_jalaliMonth - 1).clamp(0, 11)];

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _jalaliYear = now.year;
    _jalaliMonth = now.month;
    _selectedWeekIndex = ((now.day - 1) ~/ 7).clamp(0, 4);
    _loadCalendar();
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
      _selectedWeekIndex = 0;
    });
    _loadCalendar();
  }

  void _selectMonth(int monthIndex) {
    setState(() {
      _jalaliMonth = monthIndex + 1;
      _selectedWeekIndex = 0;
    });
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dayNum = ((_selectedWeekIndex * 7) + 1).clamp(1, 29);
    final jTarget = Jalali(_jalaliYear, _jalaliMonth, dayNum);
    final gTarget = jTarget.toDateTime();
    final targetDateStr = '${gTarget.year}-${gTarget.month.toString().padLeft(2, '0')}-${gTarget.day.toString().padLeft(2, '0')}';

    try {
      final data = await ApiService.getCalendarWeek(targetDate: targetDateStr);
      setState(() {
        _jalaliYear = data['jalali_year'] ?? _jalaliYear;
        _timeSlots = (data['time_slots'] as List? ?? []).map((s) => TimeSlotModel.fromJson(s)).toList();
        _days = (data['days'] as List? ?? []).map((d) => CalendarDayModel.fromJson(d)).toList();
      });
    } catch (_) {
      // Dynamic fallback calculated from selected Jalali week
      final fallbackSlots = [
        TimeSlotModel(id: 1, slotNumber: 1, title: '۰۸:۰۰ تا ۱۰:۰۰', startTime: '08:00', endTime: '10:00'),
        TimeSlotModel(id: 2, slotNumber: 2, title: '۱۰:۰۰ تا ۱۲:۰۰', startTime: '10:00', endTime: '12:00'),
        TimeSlotModel(id: 3, slotNumber: 3, title: '۱۲:۰۰ تا ۱۴:۰۰', startTime: '12:00', endTime: '14:00'),
        TimeSlotModel(id: 4, slotNumber: 4, title: '۱۴:۰۰ تا ۱۶:۰۰', startTime: '14:00', endTime: '16:00'),
        TimeSlotModel(id: 5, slotNumber: 5, title: '۱۶:۰۰ تا ۱۸:۰۰', startTime: '16:00', endTime: '18:00'),
      ];

      // Find Saturday of this Jalali week
      // Jalali weekday: Saturday=1, Sunday=2 ... Friday=7
      final satOffset = jTarget.weekDay - 1;
      final saturday = jTarget - satOffset;

      final weekDays = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
      final fallbackDays = List.generate(7, (i) {
        final currentJDay = saturday + i;
        final currentGDay = currentJDay.toDateTime();
        final dateStr = '${currentGDay.year}-${currentGDay.month.toString().padLeft(2, '0')}-${currentGDay.day.toString().padLeft(2, '0')}';
        final isFri = (i == 6);
        return CalendarDayModel(
          date: dateStr,
          jalaliDate: '${currentJDay.day} ${_persianMonthNames[currentJDay.month - 1]} ${currentJDay.year}',
          dayName: weekDays[i],
          dayNumber: currentJDay.day.toString(),
          isToday: currentJDay == Jalali.now(),
          isHoliday: isFri,
          holidayTitle: isFri ? 'تعطیل هفتگی جمعه' : null,
          slots: fallbackSlots.map((ts) => CalendarCellModel(
            date: dateStr,
            jalaliDate: '${currentJDay.day} ${_persianMonthNames[currentJDay.month - 1]} ${currentJDay.year}',
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCellClicked(CalendarCellModel cell) {
    if (cell.status == 'blocked') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'این سانس مسدود است: ${cell.blockReason ?? "سرویس دوره‌ای سالن"}',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.disabledText,
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
      // Available or holiday (holiday is bookable per Part 13.3)
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Calendar Control Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
                // Interactive Month selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.primaryGreen),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'ماه بعد',
                        onPressed: () => _changeMonth(1),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<int>(
                        tooltip: 'انتخاب ماه',
                        initialValue: _jalaliMonth - 1,
                        onSelected: _selectMonth,
                        child: Row(
                          children: [
                            Text(
                              '$_currentMonthTitle $_jalaliYear',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.primaryGreen),
                          ],
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
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.primaryGreen),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'ماه قبل',
                        onPressed: () => _changeMonth(-1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 5 Week Tabs (Enlarged)
                ...List.generate(5, (index) {
                  final weekLabels = ['هفته اول', 'هفته دوم', 'هفته سوم', 'هفته چهارم', 'هفته پنجم'];
                  final isSelected = _selectedWeekIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedWeekIndex = index;
                        });
                        _loadCalendar();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen : AppColors.veryLightGreen,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected ? null : Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
                        ),
                        child: Text(
                          weekLabels[index],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppColors.white : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Today Pill (Enlarged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.today, size: 16, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'امروز: دوشنبه، ۱۱ آبان ۱۴۰۵',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Calendar Table
          Expanded(
            child: Container(
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      child: Row(
                        children: [
                          // Right Date Column Header
                          const SizedBox(
                            width: 146,
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
                                children: [
                                  const Icon(Icons.access_time, size: 15, color: AppColors.secondaryText),
                                  const SizedBox(width: 6),
                                  Text(
                                    ts.title,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.mainText),
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
                          return SizedBox(
                            height: 76,
                            child: Row(
                              children: [
                                // Day & Jalali Date Box (Right column)
                                Container(
                                  width: 160,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  color: day.isToday ? AppColors.pastelGreen.withOpacity(0.4) : Colors.transparent,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day.dayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: day.isHoliday ? AppColors.holidayRedText : AppColors.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${day.dayNumber} $_monthName',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: day.isHoliday ? AppColors.holidayRedText : AppColors.secondaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 5 Cells for this day
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
      line2 = cell.holidayTitle ?? 'تعطیل رسمی';
      cellIcon = Icons.add_circle_outline;
    } else {
      bgColor = AppColors.pastelGreen;
      textColor = AppColors.darkGreen;
      line1 = '+ آزاد';
      line2 = 'قابل رزرو';
      cellIcon = Icons.add_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onCellClicked(cell),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cellIcon != null) Icon(cellIcon, size: 15, color: textColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        line1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  line2,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
