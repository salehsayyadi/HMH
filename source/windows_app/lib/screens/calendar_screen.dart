import 'package:flutter/material.dart';
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
  String _monthName = 'آبان';
  int _jalaliYear = 1403;
  int _selectedWeekIndex = 1; // 0 to 4 (5 week tabs per Part 13.2)

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getCalendarWeek();
      setState(() {
        _monthName = data['jalali_month_name'] ?? 'آبان';
        _jalaliYear = data['jalali_year'] ?? 1405;
        _timeSlots = (data['time_slots'] as List? ?? []).map((s) => TimeSlotModel.fromJson(s)).toList();
        _days = (data['days'] as List? ?? []).map((d) => CalendarDayModel.fromJson(d)).toList();
      });
    } catch (_) {
      // Clean fallback week with all slots available (no dummy reservations)
      final fallbackSlots = [
        TimeSlotModel(id: 1, slotNumber: 1, title: '۰۸:۰۰ تا ۱۰:۰۰', startTime: '08:00', endTime: '10:00'),
        TimeSlotModel(id: 2, slotNumber: 2, title: '۱۰:۰۰ تا ۱۲:۰۰', startTime: '10:00', endTime: '12:00'),
        TimeSlotModel(id: 3, slotNumber: 3, title: '۱۲:۳۰ تا ۱۴:۳۰', startTime: '12:30', endTime: '14:30'),
        TimeSlotModel(id: 4, slotNumber: 4, title: '۱۵:۰۰ تا ۱۷:۰۰', startTime: '15:00', endTime: '17:00'),
        TimeSlotModel(id: 5, slotNumber: 5, title: '۱۸:۰۰ تا ۲۰:۰۰', startTime: '18:00', endTime: '20:00'),
      ];

      final dayConfigs = [
        {'dayName': 'شنبه', 'num': '۹', 'date': '2026-10-31', 'jDate': '۹ آبان ۱۴۰۵', 'isToday': false, 'isHol': false},
        {'dayName': 'یکشنبه', 'num': '۱۰', 'date': '2026-11-01', 'jDate': '۱۰ آبان ۱۴۰۵', 'isToday': false, 'isHol': false},
        {'dayName': 'دوشنبه', 'num': '۱۱', 'date': '2026-11-02', 'jDate': '۱۱ آبان ۱۴۰۵', 'isToday': true, 'isHol': false},
        {'dayName': 'سه‌شنبه', 'num': '۱۲', 'date': '2026-11-03', 'jDate': '۱۲ آبان ۱۴۰۵', 'isToday': false, 'isHol': false},
        {'dayName': 'چهارشنبه', 'num': '۱۳', 'date': '2026-11-04', 'jDate': '۱۳ آبان ۱۴۰۵', 'isToday': false, 'isHol': false},
        {'dayName': 'پنجشنبه', 'num': '۱۴', 'date': '2026-11-05', 'jDate': '۱۴ آبان ۱۴۰۵', 'isToday': false, 'isHol': false},
        {'dayName': 'جمعه', 'num': '۱۵', 'date': '2026-11-06', 'jDate': '۱۵ آبان ۱۴۰۵', 'isToday': false, 'isHol': true, 'hTitle': 'تعطیل هفتگی جمعه'},
      ];

      final fallbackDays = dayConfigs.map((cfg) {
        final isHol = cfg['isHol'] as bool;
        return CalendarDayModel(
          date: cfg['date'] as String,
          jalaliDate: cfg['jDate'] as String,
          dayName: cfg['dayName'] as String,
          dayNumber: cfg['num'] as String,
          isToday: cfg['isToday'] as bool,
          isHoliday: isHol,
          holidayTitle: cfg['hTitle'] as String?,
          slots: fallbackSlots.map((ts) => CalendarCellModel(
            date: cfg['date'] as String,
            jalaliDate: cfg['jDate'] as String,
            jalaliDayName: cfg['dayName'] as String,
            dayOfWeek: dayConfigs.indexOf(cfg),
            timeSlotId: ts.id,
            timeSlotTitle: ts.title,
            status: isHol ? 'holiday' : 'available',
            isHoliday: isHol,
            holidayTitle: cfg['hTitle'] as String?,
            isBlocked: false,
          )).toList(),
        );
      }).toList();

      setState(() {
        _monthName = 'آبان';
        _jalaliYear = 1405;
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
                // Month selector (Enlarged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        '$_monthName $_jalaliYear',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_left, size: 20, color: AppColors.primaryGreen),
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
