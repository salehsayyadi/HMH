import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_confirm_dialog.dart';

class MobileAdminHolidaysScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminHolidaysScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminHolidaysScreen> createState() => _MobileAdminHolidaysScreenState();
}

class _MobileAdminHolidaysScreenState extends State<MobileAdminHolidaysScreen> {
  final primaryTeal = const Color(0xFF00594C);
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _holidays = [];

  static const List<String> _persianMonths = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر',
    'دی', 'بهمن', 'اسفند'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allHolidays = await ApiService.getHolidays();
      // Strictly filter to manual institute holidays only!
      final manualHolidays = allHolidays.where((h) {
        final isManual = h['is_manual'] == true;
        final isOfficial = h['is_official'] == true;
        final src = (h['source'] ?? '').toString();
        if (isOfficial || src.contains('iran_') || src == 'iran_official_calendar') {
          return false;
        }
        return isManual;
      }).toList();

      if (mounted) {
        setState(() {
          _holidays = manualHolidays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddHolidaySheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final nowJalali = Jalali.now();
    int selectedYear = nowJalali.year;
    if (selectedYear < 1405) selectedYear = 1405;
    if (selectedYear > 1407) selectedYear = 1407;
    int selectedMonth = nowJalali.month;
    int selectedDay = nowJalali.day;
    bool allowBooking = false;
    bool isSubmitting = false;

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
                          'ثبت مناسبت یا تعطیلی جدید',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                        ),
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
                        const Text('عنوان مناسبت یا تعطیلی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'تعطیلی داخلی موسسه',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('انتخاب تاریخ شمسی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Year (1405 to 1407 rolling)
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAF9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFD6E3DE)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: selectedYear,
                                    items: [1405, 1406, 1407].map((y) {
                                      return DropdownMenuItem<int>(
                                        value: y,
                                        child: Text('$y', style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setSheetState(() => selectedYear = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Month
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAF9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFD6E3DE)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: selectedMonth,
                                    items: List.generate(12, (i) {
                                      return DropdownMenuItem<int>(
                                        value: i + 1,
                                        child: Text(_persianMonths[i], style: const TextStyle(fontSize: 13)),
                                      );
                                    }),
                                    onChanged: (val) {
                                      if (val != null) setSheetState(() => selectedMonth = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Day
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAF9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFD6E3DE)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: selectedDay,
                                    items: List.generate(31, (i) {
                                      return DropdownMenuItem<int>(
                                        value: i + 1,
                                        child: Text('${i + 1}', style: const TextStyle(fontSize: 13)),
                                      );
                                    }),
                                    onChanged: (val) {
                                      if (val != null) setSheetState(() => selectedDay = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('توضیحات تکمیلی (اختیاری)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            hintText: 'توضیحات اختیاری...',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Allow Booking Switch (admin-18)
                        Row(
                          children: [
                            Switch(
                              value: allowBooking,
                              activeColor: primaryTeal,
                              onChanged: (val) => setSheetState(() => allowBooking = val),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'امکان ثبت رزرو در این روز',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    allowBooking
                                        ? 'بله – امکان ثبت رزرو برای مدارس فعال خواهد بود.'
                                        : 'خیر – تمامی سانس‌های این روز مسدود می‌شوند.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: allowBooking ? const Color(0xFF00796B) : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.event_note_outlined, color: Color(0xFF8BA09B)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final title = titleCtrl.text.trim();
                                    if (title.isEmpty) return;
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final jDate = Jalali(selectedYear, selectedMonth, selectedDay);
                                      final gDate = jDate.toGregorian();
                                      final gDateStr =
                                          '${gDate.year}-${gDate.month.toString().padLeft(2, '0')}-${gDate.day.toString().padLeft(2, '0')}';

                                      await ApiService.createHoliday({
                                        'holiday_date': gDateStr,
                                        'title': title,
                                        'is_official': false,
                                        'is_booking_allowed': allowBooking,
                                        'description': descCtrl.text.trim(),
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _loadData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('مناسبت با موفقیت در تقویم ثبت شد.'),
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
                                : const Text('ثبت تعطیلی در تقویم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _confirmDeleteHoliday(Map<String, dynamic> holiday) {
    final title = holiday['title'] ?? 'تعطیلی';
    showDialog(
      context: context,
      builder: (ctx) => MobileConfirmDialog(
        title: 'حذف مناسبت یا تعطیلی',
        message: 'آیا از حذف مناسبت «$title» اطمینان دارید؟ این عملیات قابل بازگشت نیست.',
        confirmLabel: 'حذف قطعی',
        cancelLabel: 'انصراف',
        isDanger: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await ApiService.deleteHoliday(holiday['id']);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('مناسبت با موفقیت حذف گردید.'),
                  backgroundColor: Color(0xFF00796B),
                ),
              );
            }
          } catch (e) {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadData, child: const Text('تلاش مجدد')),
                              ],
                            ),
                          )
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
                                        'تقویم تعطیلات و مناسبت‌ها',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('مناسبت‌های اختصاصی موسسه', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Holidays List Container (admin-17)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2EBE8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _holidays.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: Text(
                                              'هیچ مناسبت اختصاصی ثبت نشده است.',
                                              style: TextStyle(color: Color(0xFF7A928D)),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: List.generate(_holidays.length, (index) {
                                            final h = _holidays[index];
                                            final isLast = index == _holidays.length - 1;
                                            final title = h['title'] ?? 'مناسبت';
                                            final jalaliDate = h['jalali_date'] ?? '';
                                            final allowBooking = h['is_booking_allowed'] == true;

                                            return Column(
                                              children: [
                                                ListTile(
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0F7F5),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.event_outlined,
                                                      color: primaryTeal,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1B2E2B),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '$jalaliDate · ثبت اختصاصی مدیریت',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A928D)),
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: allowBooking
                                                              ? const Color(0xFFE8F5F1)
                                                              : const Color(0xFFFFEBEE),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          allowBooking ? 'رزرو مجاز' : 'غیرقابل رزرو',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: allowBooking
                                                                ? const Color(0xFF00796B)
                                                                : const Color(0xFFC62828),
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828), size: 20),
                                                        onPressed: () => _confirmDeleteHoliday(h),
                                                      ),
                                                    ],
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                ),
                                                if (!isLast)
                                                  const Divider(
                                                    height: 1,
                                                    indent: 16,
                                                    endIndent: 16,
                                                    color: Color(0xFFEBF2F0),
                                                  ),
                                              ],
                                            );
                                          }),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _showAddHolidaySheet,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTeal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ ثبت تعطیلی جدید',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _loadData,
                                    icon: const Icon(Icons.refresh_rounded, size: 20),
                                    label: const Text(
                                      'به‌روزرسانی',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryTeal,
                                      side: const BorderSide(color: Color(0xFF00594C)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Notice Card (admin-17)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F7F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFD6E3DE)),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'تعطیلات رسمی کشور مستقیماً در تقویم نمایش داده می‌شوند.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B2E2B),
                                      ),
                                    ),
                                  ),
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
}
