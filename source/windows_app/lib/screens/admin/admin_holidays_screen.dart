import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  final List<Map<String, dynamic>> _holidays = [
    {'id': 1, 'title': 'آغاز سال نو و عید نوروز', 'jalaliDate': '۱ تا ۴ فروردین', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 2, 'title': 'روز جمهوری اسلامی ایران', 'jalaliDate': '۱۲ فروردین', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 3, 'title': 'روز طبیعت (سیزده‌بدر)', 'jalaliDate': '۱۳ فروردین', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 4, 'title': 'رحلت حضرت امام خمینی (ره)', 'jalaliDate': '۱۴ خرداد', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 5, 'title': 'قیام خونین ۱۵ خرداد', 'jalaliDate': '۱۵ خرداد', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 6, 'title': 'تاسوعای حسینی', 'jalaliDate': '۶ مرداد', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 7, 'title': 'عاشورای حسینی', 'jalaliDate': '۷ مرداد', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 8, 'title': 'اربعین حسینی', 'jalaliDate': '۱۵ شهریور', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 9, 'title': 'شهادت امام رضا (ع)', 'jalaliDate': '۲۵ شهریور', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
    {'id': 10, 'title': 'پیروزی شکوهمند انقلاب اسلامی', 'jalaliDate': '۲۲ بهمن', 'isOfficial': true, 'source': 'تقویم رسمی کشور'},
  ];

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('افزودن مناسبت یا تعطیلی جدید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'عنوان مناسبت (مثال: عید مبعث)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: 'تاریخ شمسی (مثال: ۲۷ رجب / ۲۸ آبان)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && dateCtrl.text.isNotEmpty) {
                  setState(() {
                    _holidays.add({
                      'id': _holidays.length + 1,
                      'title': titleCtrl.text.trim(),
                      'jalaliDate': dateCtrl.text.trim(),
                      'isOfficial': false,
                      'source': 'ثبت دستی مدیریت',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعطیلی جدید با موفقیت اضافه شد.'), backgroundColor: AppColors.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('ثبت تعطیلی'),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت تقویم تعطیلات و مناسبت‌ها', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('مشاهده تعطیلات رسمی کشور و افزودن مناسبت‌های خاص موسسه امام حسین (ع)', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('افزودن تعطیلی جدید', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Holidays List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _holidays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                  itemBuilder: (context, i) {
                    final h = _holidays[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.holidayRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.celebration_outlined, size: 18, color: AppColors.holidayRedText),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['title'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                                const SizedBox(height: 2),
                                Text(h['source'] as String, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.veryLightGreen,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              h['jalaliDate'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.holidayRedText),
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
