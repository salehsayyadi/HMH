import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final rawHolidays = await ApiService.getHolidays();
      final mapped = rawHolidays.map<Map<String, dynamic>>((h) {
        return {
          'id': h['id'] ?? 0,
          'title': h['title'] ?? 'تعطیل رسمی',
          'jalaliDate': h['holiday_date_jalali'] ?? h['holiday_date'] ?? '-',
          'isOfficial': h['is_official'] ?? true,
          'source': h['description'] ?? (h['is_official'] == true ? 'تقویم رسمی کشور' : 'ثبت مدیریت'),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _holidays = mapped;
        });
      }
    } catch (_) {
      // In clean database, keep empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
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
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'عنوان مناسبت (مثال: عید مبعث یا تعطیلی مدارس)',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'تاریخ شمسی (مثال: ۱۴۰۵/۰۸/۲۸ یا ۲۸ آبان)',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (titleCtrl.text.isNotEmpty && dateCtrl.text.isNotEmpty) {
                    setDlgState(() => isSaving = true);
                    final newH = {
                      'id': _holidays.length + 1,
                      'title': titleCtrl.text.trim(),
                      'jalaliDate': dateCtrl.text.trim(),
                      'isOfficial': false,
                      'source': 'ثبت دستی مدیریت',
                    };
                    try {
                      await ApiService.createHoliday({
                        'title': titleCtrl.text.trim(),
                        'holiday_date': dateCtrl.text.trim(),
                        'is_official': false,
                      });
                    } catch (_) {}
                    setState(() {
                      _holidays.add(newH);
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعطیلی جدید با موفقیت اضافه شد.'), backgroundColor: AppColors.primaryGreen),
                      );
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
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
                                    const SizedBox(width: 14),
                                    IconButton(
                                      tooltip: 'حذف تعطیلی',
                                      icon: const Icon(Icons.delete_outline, size: 22, color: AppColors.holidayRedText),
                                      onPressed: () {
                                        setState(() {
                                          _holidays.removeAt(i);
                                        });
                                      },
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
