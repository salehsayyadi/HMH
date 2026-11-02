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
        _jalaliYear = data['jalali_year'] ?? 1403;
        _timeSlots = (data['time_slots'] as List).map((s) => TimeSlotModel.fromJson(s)).toList();
        _days = (data['days'] as List).map((d) => CalendarDayModel.fromJson(d)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
          backgroundColor: AppColors.disabledText,
          content: Text(
            'این سانس توسط مدیریت مسدود شده است: ${cell.blockReason ?? "نامشخص"}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
      return;
    }

    if (cell.status == 'reserved') {
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
            const Icon(Icons.cloud_off, size: 48, color: AppColors.holidayRedText),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppColors.mainText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCalendar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('تلاش مجدد'),
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
          // Top Calendar Control Header matching reference design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(color: AppColors.darkGreen.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Month selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '$_monthName $_jalaliYear',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_left, size: 18, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // 5 Week Tabs per Part 13.2
                ...List.generate(5, (index) {
                  final weekLabels = ['هفته اول', 'هفته دوم', 'هفته سوم', 'هفته چهارم', 'هفته پنجم'];
                  final isSelected = _selectedWeekIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedWeekIndex = index;
                        });
                        _loadCalendar();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen : AppColors.veryLightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          weekLabels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.white : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Today Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.today, size: 14, color: AppColors.primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        'امروز: دوشنبه، ۱۱ آبان ۱۴۰۵',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Weekly Calendar Table matching exact design layout
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          // Right Date Column Header
                          const SizedBox(
                            width: 130,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: AppColors.primaryGreen),
                                SizedBox(width: 6),
                                Text(
                                  'روز و تاریخ',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
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
                                  const Icon(Icons.access_time, size: 13, color: AppColors.secondaryText),
                                  const SizedBox(width: 4),
                                  Text(
                                    ts.title,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mainText),
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
                            height: 68,
                            child: Row(
                              children: [
                                // Day & Jalali Date Box (Right column)
                                Container(
                                  width: 146,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  color: day.isToday ? AppColors.pastelGreen.withOpacity(0.4) : Colors.transparent,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day.dayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: day.isHoliday ? AppColors.holidayRedText : AppColors.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${day.dayNumber} $_monthName',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: day.isHoliday ? AppColors.holidayRedText : AppColors.secondaryText,
                                          fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _onCellClicked(cell),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cellIcon != null) Icon(cellIcon, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        line1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  line2,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: textColor.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
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
