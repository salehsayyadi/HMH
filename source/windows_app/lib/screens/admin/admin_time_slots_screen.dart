import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminTimeSlotsScreen extends StatefulWidget {
  const AdminTimeSlotsScreen({super.key});

  @override
  State<AdminTimeSlotsScreen> createState() => _AdminTimeSlotsScreenState();
}

class _AdminTimeSlotsScreenState extends State<AdminTimeSlotsScreen> {
  final List<Map<String, dynamic>> _slots = [
    {
      'id': 1,
      'number': 1,
      'title': 'صبح اول',
      'startTime': '08:00',
      'endTime': '10:00',
      'description': 'ویژه برنامه‌های آغازین مدارس، همایش‌های صبحگاهی و مراسم آغاز سال تحصیلی',
      'isActive': true,
    },
    {
      'id': 2,
      'number': 2,
      'title': 'صبح دوم',
      'startTime': '10:00',
      'endTime': '12:00',
      'description': 'ویژه مسابقات قرآنی، سرود، تئاتر و جشن‌های رسمی دانش‌آموزی',
      'isActive': true,
    },
    {
      'id': 3,
      'number': 3,
      'title': 'ظهر',
      'startTime': '12:30',
      'endTime': '14:30',
      'description': 'ویژه نماز جماعت، گردهمایی‌های کادر آموزشی و جلسات هم‌اندیشی',
      'isActive': true,
    },
    {
      'id': 4,
      'number': 4,
      'title': 'عصر اول',
      'startTime': '15:00',
      'endTime': '17:00',
      'description': 'ویژه جلسات انجمن اولیا و مربیان، کارگاه‌های مشاوره و هدایت تحصیلی',
      'isActive': true,
    },
    {
      'id': 5,
      'number': 5,
      'title': 'عصر دوم',
      'startTime': '18:00',
      'endTime': '20:00',
      'description': 'ویژه مراسم‌های ویژه شبانه، جشن‌های فارغ‌التحصیلی و همایش‌های استانی',
      'isActive': true,
    },
  ];

  void _showEditDialog(Map<String, dynamic> slot) {
    final titleCtrl = TextEditingController(text: slot['title'] as String);
    final startCtrl = TextEditingController(text: slot['startTime'] as String);
    final endCtrl = TextEditingController(text: slot['endTime'] as String);
    final descCtrl = TextEditingController(text: slot['description'] as String);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ویرایش بازه زمانی: ${slot['title']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'عنوان بازه زمانی',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: InputDecoration(
                          labelText: 'ساعت شروع (مثال ۰۸:۰۰)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: InputDecoration(
                          labelText: 'ساعت پایان (مثال ۱۰:۰۰)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'توضیحات و کاربرد بازه',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  slot['title'] = titleCtrl.text.trim();
                  slot['startTime'] = startCtrl.text.trim();
                  slot['endTime'] = endCtrl.text.trim();
                  slot['description'] = descCtrl.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تغییرات بازه زمانی با موفقیت ثبت شد.'), backgroundColor: AppColors.primaryGreen),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('ذخیره تغییرات'),
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
            child: const Row(
              children: [
                Icon(Icons.access_time_filled_rounded, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت ساعت‌ها و سانس‌های سالن آمفی‌تئاتر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('تنظیم ۵ بازه زمانی استاندارد روزانه، تغییر ساعات شروع و پایان، و فعال/غیرفعال‌سازی', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Slots List
          Expanded(
            child: ListView.separated(
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final slot = _slots[i];
                final isActive = slot['isActive'] as bool;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isActive ? AppColors.cardBorder : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.veryLightGreen : AppColors.holidayRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '#${slot['number']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.primaryGreen : AppColors.holidayRedText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  slot['title'] as String,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.pastelGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${slot['startTime']}  الی  ${slot['endTime']}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot['description'] as String,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'ویرایش سانس',
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen, size: 20),
                        onPressed: () => _showEditDialog(slot),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            slot['isActive'] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
