import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/taghvim_holiday_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';
import '../user/mobile_reservation_details_sheet.dart';

class MobileAdminCalendarScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminCalendarScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminCalendarScreen> createState() => _MobileAdminCalendarScreenState();
}

class _MobileAdminCalendarScreenState extends State<MobileAdminCalendarScreen> {
  final primaryTeal = const Color(0xFF00594C);

  late Jalali _selectedJalaliDate;
  int _selectedWeekIndex = 0; // 0 to 4
  int _selectedDayIndex = 0; // 0 to 6 in current week
  bool _isLoading = true;

  List<dynamic> _reservations = [];
  List<dynamic> _timeSlots = [];
  List<dynamic> _schools = [];
  Map<int, Map<int, TaghvimEvent>> _taghvimHolidays = {};
  List<dynamic> _customHolidays = [];

  static const List<String> _persianMonths = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر',
    'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> _weekDayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه',
    'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
  ];

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    int currentY = now.year;
    if (currentY < 1405) currentY = 1405;
    if (currentY > 1407) currentY = 1407;
    _selectedJalaliDate = Jalali(currentY, now.month, 1);
    _calculateInitialDay();
    _loadAllData();
  }

  void _calculateInitialDay() {
    final now = Jalali.now();
    if (now.year == _selectedJalaliDate.year && now.month == _selectedJalaliDate.month) {
      final day = now.day;
      _selectedWeekIndex = (day - 1) ~/ 7;
      if (_selectedWeekIndex > 4) _selectedWeekIndex = 4;
      _selectedDayIndex = (day - 1) % 7;
    } else {
      _selectedWeekIndex = 0;
      _selectedDayIndex = 0;
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getReservations(),
        ApiService.getTimeSlots(),
        ApiService.getSchools(),
        ApiService.getHolidays(),
        TaghvimHolidayService.getEventsForMonth(_selectedJalaliDate.month),
      ]);

      if (mounted) {
        setState(() {
          _reservations = results[0] as List<dynamic>;
          _timeSlots = results[1] as List<dynamic>;
          _schools = results[2] as List<dynamic>;
          _customHolidays = results[3] as List<dynamic>;
          _taghvimHolidays[_selectedJalaliDate.month] = results[4] as Map<int, TaghvimEvent>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _daysInSelectedMonth {
    if (_selectedJalaliDate.month <= 6) return 31;
    if (_selectedJalaliDate.month <= 11) return 30;
    return _selectedJalaliDate.isLeapYear() ? 30 : 29;
  }

  List<Jalali> get _currentWeekDays {
    final startDay = (_selectedWeekIndex * 7) + 1;
    final days = <Jalali>[];
    for (int i = 0; i < 7; i++) {
      final dayNum = startDay + i;
      if (dayNum <= _daysInSelectedMonth) {
        days.add(Jalali(_selectedJalaliDate.year, _selectedJalaliDate.month, dayNum));
      }
    }
    return days;
  }

  Jalali? get _activeDay {
    final week = _currentWeekDays;
    if (_selectedDayIndex < week.length) {
      return week[_selectedDayIndex];
    }
    return week.isNotEmpty ? week.last : null;
  }

  TaghvimEvent? _getHolidayForDay(Jalali day) {
    final monthEvents = _taghvimHolidays[day.month];
    if (monthEvents != null && monthEvents.containsKey(day.day)) {
      return monthEvents[day.day];
    }
    return null;
  }

  bool _isDayHoliday(Jalali day) {
    if (day.weekDay == 7) return true; // Friday
    final tEvent = _getHolidayForDay(day);
    if (tEvent != null && tEvent.isHoliday) return true;
    return false;
  }

  String _formatGregorian(Jalali j) {
    final g = j.toGregorian();
    return '${g.year}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}';
  }

  dynamic _findReservation(Jalali day, int slotId) {
    final gStr = _formatGregorian(day);
    for (final r in _reservations) {
      final rDate = r['reservation_date'] ?? '';
      final rSlot = r['time_slot_id'] ?? (r['time_slot'] is Map ? r['time_slot']['id'] : null);
      final status = (r['status'] ?? 'approved').toString().toLowerCase();
      if (rDate == gStr && rSlot == slotId && status != 'cancelled' && status != 'canceled') {
        return r;
      }
    }
    return null;
  }

  void _showAdminBookingSheet(Jalali day, dynamic slot) {
    final eventTitleCtrl = TextEditingController();
    int? selectedSchoolId = _schools.isNotEmpty ? _schools.first['id'] : null;
    bool isSubmitting = false;
    final slotTitle = slot['title'] ?? 'سانس';
    final jalaliDateStr = '${day.day} ${_persianMonths[day.month - 1]} ${day.year}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 16,
              right: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const Text('مدیریت کل سامانه', style: TextStyle(fontSize: 12, color: Color(0xFF5A726D))),
                        const SizedBox(height: 4),
                        Text(
                          'ثبت رزرو توسط مدیر کل',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                        ),
                        const SizedBox(height: 4),
                        Text('$jalaliDateStr · $slotTitle', style: const TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EBE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('انتخاب واحد آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD6E3DE)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedSchoolId,
                              items: _schools.map<DropdownMenuItem<int>>((s) {
                                return DropdownMenuItem<int>(
                                  value: s['id'],
                                  child: Text(s['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setSheetState(() => selectedSchoolId = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('عنوان یا موضوع رویداد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: eventTitleCtrl,
                          decoration: InputDecoration(
                            hintText: 'مثلاً: جشن فارغ‌التحصیلی یا نشست اولیا',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final title = eventTitleCtrl.text.trim();
                                    if (title.isEmpty || selectedSchoolId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('لطفاً تمامی موارد را تکمیل فرمایید.')),
                                      );
                                      return;
                                    }
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final gStr = _formatGregorian(day);
                                      await ApiService.createReservation({
                                        'school_id': selectedSchoolId,
                                        'time_slot_id': slot['id'],
                                        'reservation_date': gStr,
                                        'description': title,
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _loadAllData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('رزرو سالن با موفقیت برای مدرسه ثبت گردید.'),
                                            backgroundColor: Color(0xFF00796B),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSubmitting = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: Colors.red[700],
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('ثبت قطعی رزرو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F4F2),
                              foregroundColor: const Color(0xFF5A726D),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('انصراف'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDay = _activeDay;
    final currentWeek = _currentWeekDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              MobileTopBar(onLogout: widget.onLogout),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  const Text('مدیریت کل سامانه', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                                  const SizedBox(height: 4),
                                  Text(
                                    'تقویم رزرو سالن',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('نمای مدارس برای مدیر کل', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Year & Month Picker Container (admin-22)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2EBE8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF00594C)),
                                    onPressed: () {
                                      int newMonth = _selectedJalaliDate.month - 1;
                                      int newYear = _selectedJalaliDate.year;
                                      if (newMonth < 1) {
                                        newMonth = 12;
                                        newYear--;
                                      }
                                      if (newYear >= 1405) {
                                        setState(() {
                                          _selectedJalaliDate = Jalali(newYear, newMonth, 1);
                                          _selectedWeekIndex = 0;
                                          _selectedDayIndex = 0;
                                        });
                                        _loadAllData();
                                      }
                                    },
                                  ),
                                  Row(
                                    children: [
                                      // Month Dropdown
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedJalaliDate.month,
                                          items: List.generate(12, (i) {
                                            return DropdownMenuItem<int>(
                                              value: i + 1,
                                              child: Text(
                                                _persianMonths[i],
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            );
                                          }),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedJalaliDate = Jalali(_selectedJalaliDate.year, val, 1);
                                                _selectedWeekIndex = 0;
                                                _selectedDayIndex = 0;
                                              });
                                              _loadAllData();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Year Dropdown (Strictly 3-Year Rolling: 1405, 1406, 1407)
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedJalaliDate.year,
                                          items: [1405, 1406, 1407].map((y) {
                                            return DropdownMenuItem<int>(
                                              value: y,
                                              child: Text(
                                                '$y',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedJalaliDate = Jalali(val, _selectedJalaliDate.month, 1);
                                                _selectedWeekIndex = 0;
                                                _selectedDayIndex = 0;
                                              });
                                              _loadAllData();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF00594C)),
                                    onPressed: () {
                                      int newMonth = _selectedJalaliDate.month + 1;
                                      int newYear = _selectedJalaliDate.year;
                                      if (newMonth > 12) {
                                        newMonth = 1;
                                        newYear++;
                                      }
                                      if (newYear <= 1407) {
                                        setState(() {
                                          _selectedJalaliDate = Jalali(newYear, newMonth, 1);
                                          _selectedWeekIndex = 0;
                                          _selectedDayIndex = 0;
                                        });
                                        _loadAllData();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Week Selector Pills (admin-22)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(5, (index) {
                                  final isSelected = _selectedWeekIndex == index;
                                  final weekTitles = ['هفته اول', 'هفته دوم', 'هفته سوم', 'هفته چهارم', 'هفته پنجم'];
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(weekTitles[index]),
                                      selected: isSelected,
                                      selectedColor: primaryTeal,
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF1B2E2B),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() {
                                            _selectedWeekIndex = index;
                                            _selectedDayIndex = 0;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Day Selector Horizontal Strip (admin-22)
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
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedDayIndex = index),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryTeal
                                            : isHoliday
                                                ? const Color(0xFFFFEBEE)
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? primaryTeal
                                              : isHoliday
                                                  ? const Color(0xFFFFCDD2)
                                                  : const Color(0xFFE2EBE8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            dayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isHoliday
                                                      ? const Color(0xFFC62828)
                                                      : const Color(0xFF7A928D),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${day.day}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isHoliday
                                                      ? const Color(0xFFC62828)
                                                      : const Color(0xFF1B2E2B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            // Slot Cards for Selected Day (admin-22)
                            if (activeDay != null) ...[
                              ..._timeSlots.map((slot) {
                                final slotId = slot['id'];
                                final slotTitle = slot['title'] ?? 'سانس';
                                final startTime = slot['start_time'] ?? '';
                                final endTime = slot['end_time'] ?? '';
                                final res = _findReservation(activeDay, slotId);
                                final tEvent = _getHolidayForDay(activeDay);
                                final isOfficialHoliday = tEvent != null && tEvent.isHoliday;

                                if (res != null) {
                                  // Booked (Light Blue Card)
                                  final schoolName = res['school_name'] ??
                                      (res['school'] is Map ? res['school']['name'] : 'مدرسه متقاضی');
                                  final userName = res['user_name'] ??
                                      (res['user'] is Map ? '${res['user']['first_name']} ${res['user']['last_name']}' : '');

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFBBDEFB)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              schoolName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1565C0),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              userName.isNotEmpty ? '$userName · $startTime – $endTime' : '$startTime – $endTime',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          slotTitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (isOfficialHoliday) {
                                  // Official Holiday: Pinkish celebration card, but BOOKABLE!
                                  return GestureDetector(
                                    onTap: () => _showAdminBookingSheet(activeDay, slot),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFFFCDD2)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text(
                                                    '+ آزاد',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFC62828),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    tEvent.title,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFFC62828),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$startTime – $endTime · قابل رزرو برای جشن‌ها',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF7A928D)),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            slotTitle,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B2E2B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Free Slot (Green Card)
                                return GestureDetector(
                                  onTap: () => _showAdminBookingSheet(activeDay, slot),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5F1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFC8E6C9)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '+ آزاد',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00796B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$startTime – $endTime · قابل رزرو',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF7A928D)),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          slotTitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B2E2B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 12),
                            // Legend (admin-22)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('آزاد', const Color(0xFF00796B)),
                                const SizedBox(width: 16),
                                _buildLegendItem('رزرو شده', const Color(0xFF1565C0)),
                                const SizedBox(width: 16),
                                _buildLegendItem('تعطیل', const Color(0xFFC62828)),
                                const SizedBox(width: 16),
                                _buildLegendItem('مسدود', const Color(0xFF7A928D)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const MobileFooter(),
                            const SizedBox(height: 16),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
