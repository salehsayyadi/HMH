import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _holidays = [];

  static const List<String> _monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> _weekDayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
  ];

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final rawHolidays = await ApiService.getHolidays();
      final mapped = <Map<String, dynamic>>[];

      for (final h in rawHolidays) {
        final jDateStr = (h['jalali_date'] ?? h['holiday_date_jalali'] ?? h['holiday_date'] ?? '-').toString();
        // Omit past years (1403, 1404) per user requirement
        if (jDateStr.contains('1403') || jDateStr.contains('1404') ||
            jDateStr.contains('۱۴۰۳') || jDateStr.contains('۱۴۰۴')) {
          continue;
        }

        mapped.add({
          'id': h['id'] ?? 0,
          'title': h['title'] ?? 'مناسبت تقویمی',
          'jalaliDate': jDateStr,
          'isOfficial': h['is_official'] ?? true,
          'isBookingAllowed': h['is_booking_allowed'] ?? true, // Bookable by default per user request
          'source': h['description'] ?? (h['is_official'] == true ? 'تقویم رسمی سال جاری' : 'ثبت مدیریت'),
        });
      }

      if (mapped.isEmpty) {
        // Fallback to official 27 holidays from taghvim.com for 1405..1407
        final curYear = Jalali.now().year;
        const monthNames = [
          'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
          'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
        ];
        const taghvimHols = [
          [1, 1, 'جشن نوروز / سال نو'],
          [1, 2, 'عید نوروز'],
          [1, 3, 'عید نوروز'],
          [1, 4, 'عید نوروز'],
          [1, 12, 'روز جمهوری اسلامی ایران'],
          [1, 13, 'روز طبیعت (سیزده به در)'],
          [1, 14, 'شهادت امام جعفر صادق (ع)'],
          [2, 27, 'عید سعید قربان'],
          [3, 4, 'عید سعید غدیر خم'],
          [3, 14, 'رحلت حضرت امام خمینی (ره)'],
          [3, 15, 'قیام ۱۵ خرداد'],
          [3, 25, 'تاسوعای حسینی'],
          [3, 26, 'عاشورای حسینی'],
          [5, 13, 'اربعین حسینی'],
          [5, 21, 'رحلت رسول اکرم (ص) و شهادت امام حسن مجتبی (ع)'],
          [5, 22, 'شهادت امام رضا (ع)'],
          [5, 30, 'شهادت امام حسن عسکری (ع)'],
          [6, 8, 'میلاد رسول اکرم (ص) و امام جعفر صادق (ع)'],
          [8, 22, 'شهادت حضرت فاطمه زهرا (س)'],
          [10, 2, 'ولادت امام علی (ع) و روز پدر'],
          [10, 16, 'مبعث رسول اکرم (ص)'],
          [11, 4, 'ولادت حضرت قائم (عج) و جشن نیمه شعبان'],
          [11, 22, 'پیروزی انقلاب اسلامی ایران'],
          [12, 9, 'شهادت حضرت علی (ع)'],
          [12, 19, 'عید سعید فطر'],
          [12, 20, 'تعطیلی عید سعید فطر'],
          [12, 29, 'روز ملی شدن صنعت نفت ایران'],
        ];
        for (int y = curYear; y <= curYear + 2; y++) {
          for (final item in taghvimHols) {
            final m = item[0] as int;
            final d = item[1] as int;
            final title = item[2] as String;
            mapped.add({
              'id': y * 1000 + m * 100 + d,
              'title': title,
              'jalaliDate': '$d ${monthNames[m - 1]} $y',
              'isOfficial': true,
              'isBookingAllowed': true,
              'source': 'تقویم رسمی taghvim.com',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _holidays = mapped;
        });
      }
    } catch (_) {
      // In offline mode, keep taghvim official holidays
      if (mapped.isNotEmpty && mounted) {
        setState(() {
          _holidays = mapped;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final now = Jalali.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;
    int selectedDay = now.day;
    bool allowBooking = true; // Bookable by default per user request
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          int maxDaysInMonth = 30;
          if (selectedMonth <= 6) {
            maxDaysInMonth = 31;
          } else if (selectedMonth <= 11) {
            maxDaysInMonth = 30;
          } else {
            maxDaysInMonth = 29;
          }
          if (selectedDay > maxDaysInMonth) {
            selectedDay = maxDaysInMonth;
          }

          final jDate = Jalali(selectedYear, selectedMonth, selectedDay);
          final weekdayStr = _weekDayNames[(jDate.weekDay - 1).clamp(0, 6)];

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 10),
                  Text('ثبت مناسبت یا تعطیلی جدید در تقویم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'عنوان مناسبت یا تعطیلی',
                          hintText: 'مثال: عید مبعث، تعطیلی آلودگی هوا، روز معلم...',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'انتخاب تاریخ شمسی:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Year Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: InputDecoration(
                                labelText: 'سال',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: [now.year, now.year + 1, now.year + 2]
                                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                  .toList(),
                              onChanged: (y) {
                                if (y != null) setDlgState(() => selectedYear = y);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month Dropdown
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: InputDecoration(
                                labelText: 'ماه',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: List.generate(12, (idx) {
                                return DropdownMenuItem(
                                  value: idx + 1,
                                  child: Text('${idx + 1} - ${_monthNames[idx]}', style: const TextStyle(fontSize: 12.5)),
                                );
                              }),
                              onChanged: (m) {
                                if (m != null) setDlgState(() => selectedMonth = m);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Day Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: selectedDay,
                              decoration: InputDecoration(
                                labelText: 'روز',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: List.generate(maxDaysInMonth, (idx) {
                                return DropdownMenuItem(
                                  value: idx + 1,
                                  child: Text('${idx + 1}'),
                                );
                              }),
                              onChanged: (d) {
                                if (d != null) setDlgState(() => selectedDay = d);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Selected Date Card Preview
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primaryGreen),
                            const SizedBox(width: 10),
                            Text(
                              'تاریخ انتخابی: $weekdayStr $selectedDay ${_monthNames[selectedMonth - 1]} $selectedYear',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'توضیحات تکمیلی (اختیاری)',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: allowBooking,
                        title: const Text('امکان ثبت رزرو در این روز مجاز باشد؟', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          allowBooking
                              ? 'بله — مناسبت در تقویم نمایش داده می‌شود، اما ثبت رزرو توسط مدارس مجاز است.'
                              : 'خیر — تمامی سانس‌های این روز مسدود و غیرقابل رزرو خواهند بود.',
                          style: TextStyle(fontSize: 11.5, color: allowBooking ? AppColors.primaryGreen : AppColors.holidayRedText),
                        ),
                        activeColor: AppColors.primaryGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setDlgState(() => allowBooking = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('انصراف', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (titleCtrl.text.trim().isNotEmpty) {
                      setDlgState(() => isSaving = true);
                      final jTarget = Jalali(selectedYear, selectedMonth, selectedDay);
                      final gTarget = jTarget.toDateTime();
                      final gDateStr = '${gTarget.year}-${gTarget.month.toString().padLeft(2, '0')}-${gTarget.day.toString().padLeft(2, '0')}';
                      try {
                        await ApiService.createHoliday({
                          'title': titleCtrl.text.trim(),
                          'holiday_date': gDateStr,
                          'is_official': true,
                          'is_booking_allowed': allowBooking,
                          'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        });
                        await _loadHolidays();
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تعطیلی جدید با موفقیت اضافه شد.'), backgroundColor: AppColors.primaryGreen),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.holidayRedText),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ثبت تعطیلی در تقویم', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> holiday) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف مناسبت / تعطیلی', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.holidayRedText)),
          content: Text('آیا از حذف مناسبت «${holiday['title']}» (${holiday['jalaliDate']}) از تقویم اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final hId = holiday['id'];
                try {
                  if (hId != null && hId != 0) {
                    await ApiService.deleteHoliday(hId as int);
                  }
                  await _loadHolidays();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('مناسبت با موفقیت حذف گردید.'), backgroundColor: AppColors.primaryGreen),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.holidayRedText),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.holidayRedText, foregroundColor: Colors.white),
              child: const Text('حذف قطعی'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت تقویم تعطیلات و مناسبت‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('مشاهده و ثبت تعطیلات رسمی و مناسبت‌های اختصاصی موسسه امام حسین (ع)', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('ثبت تعطیلی جدید', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _loadHolidays,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('به‌روزرسانی', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Holidays List or Empty State
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : _holidays.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'مناسبت یا تعطیلی خاصی ثبت نگردیده است.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'جهت مسدودسازی روزهای تعطیل یا ثبت مناسبت‌های ویژه در تقویم، بر روی دکمه زیر کلیک فرمایید.',
                                    style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _showAddDialog,
                                    icon: const Icon(Icons.add_rounded, size: 20),
                                    label: const Text('افزودن اولین مناسبت / تعطیلی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _holidays.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                            itemBuilder: (context, i) {
                              final h = _holidays[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.holidayRed,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.celebration_outlined, size: 22, color: AppColors.holidayRedText),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(h['title'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                                          const SizedBox(height: 3),
                                          Text(h['source'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.veryLightGreen,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        h['jalaliDate'] as String,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: (h['isBookingAllowed'] == true) ? AppColors.pastelGreen : AppColors.holidayRed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (h['isBookingAllowed'] == true) ? 'رزرو مجاز' : 'غیرقابل رزرو',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: (h['isBookingAllowed'] == true) ? AppColors.darkGreen : AppColors.holidayRedText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    IconButton(
                                      tooltip: 'حذف تعطیلی',
                                      icon: const Icon(Icons.delete_outline, size: 22, color: AppColors.holidayRedText),
                                      onPressed: () => _showDeleteDialog(h),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
