import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminTimeSlotsScreen extends StatefulWidget {
  const AdminTimeSlotsScreen({super.key});

  @override
  State<AdminTimeSlotsScreen> createState() => _AdminTimeSlotsScreenState();
}

class _AdminTimeSlotsScreenState extends State<AdminTimeSlotsScreen> {
  bool _isLoading = false;

  List<Map<String, dynamic>> _slots = [
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

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    try {
      final rawSlots = await ApiService.getTimeSlots();
      if (rawSlots.isNotEmpty && mounted) {
        setState(() {
          _slots = rawSlots.map<Map<String, dynamic>>((s) {
            return {
              'id': s['id'] ?? 0,
              'number': s['slot_number'] ?? s['number'] ?? 1,
              'title': s['title'] ?? 'سانس ${s['slot_number']}',
              'startTime': s['start_time'] ?? '08:00',
              'endTime': s['end_time'] ?? '10:00',
              'description': s['description'] ?? 'سانس آمفی‌تئاتر',
              'isActive': s['is_active'] ?? true,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('ویرایش بازه زمانی: ${slot['title']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'عنوان بازه زمانی',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'ساعت شروع (مثال ۰۸:۰۰)',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'ساعت پایان (مثال ۱۰:۰۰)',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'توضیحات و کاربرد بازه',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ذخیره تغییرات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                const Icon(Icons.access_time_filled_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت ساعت‌ها و سانس‌های سالن آمفی‌تئاتر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('تنظیم ۵ بازه زمانی استاندارد روزانه، تعیین ساعات شروع و پایان، و مدیریت وضعیت سانس‌های سالن', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadSlots,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('به‌روزرسانی سانس‌ها', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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

          // Slots List
          Expanded(
            child: ListView.separated(
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final slot = _slots[i];
                final isActive = slot['isActive'] as bool;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isActive ? AppColors.cardBorder : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.veryLightGreen : AppColors.holidayRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '#${slot['number']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.primaryGreen : AppColors.holidayRedText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  slot['title'] as String,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.pastelGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${slot['startTime']}  الی  ${slot['endTime']}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slot['description'] as String,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'ویرایش سانس',
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen, size: 22),
                        onPressed: () => _showEditDialog(slot),
                      ),
                      const SizedBox(width: 10),
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
