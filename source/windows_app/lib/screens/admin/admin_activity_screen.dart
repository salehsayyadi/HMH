import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final _searchController = TextEditingController();
  String _selectedAction = 'همه عملیات‌ها';

  final List<Map<String, dynamic>> _logs = [
    {
      'id': 501,
      'user': 'مدیر ارشد سامانه',
      'school': 'مدیریت مرکزی موسسه',
      'action': 'ورود به سامانه',
      'ip': '192.168.1.10',
      'time': '۱۱ آبان ۱۴۰۵ — ۱۱:۴۵',
      'details': 'ورود موفق مدیر ارشد در حالت پیکربندی سیستم',
    },
    {
      'id': 502,
      'user': 'محمدمحسن کارستان',
      'school': 'دبیرستان پسرانه دوره دوم',
      'action': 'ثبت رزرو جدید',
      'ip': '192.168.1.105',
      'time': '۱۱ آبان ۱۴۰۵ — ۱۰:۳۰',
      'details': 'ثبت سانس عصر اول (۱۵:۰۰ تا ۱۷:۰۰) برای همایش کنکور',
    },
    {
      'id': 503,
      'user': 'فاطمه کریمی',
      'school': 'دبستان دخترانه',
      'action': 'ثبت رزرو جدید',
      'ip': '192.168.1.112',
      'time': '۱۱ آبان ۱۴۰۵ — ۰۹:۱۵',
      'details': 'ثبت سانس صبح اول برای جشن قرآن دانش‌آموزان',
    },
    {
      'id': 504,
      'user': 'مریم حسینی',
      'school': 'دبیرستان دخترانه دوره اول',
      'action': 'لغو رزرو',
      'ip': '192.168.1.118',
      'time': '۱۰ آبان ۱۴۰۵ — ۱۶:۰۰',
      'details': 'لغو سانس ظهر به علت تداخل با جلسه اداری',
    },
    {
      'id': 505,
      'user': 'مدیر ارشد سامانه',
      'school': 'مدیریت مرکزی موسسه',
      'action': 'تغییر تنظیمات سرور',
      'ip': '192.168.1.10',
      'time': '۰۹ آبان ۱۴۰۵ — ۱۴:۲۰',
      'details': 'به‌روزرسانی تنظیمات دیتابیس MySQL 9.7 و پورت سرور',
    },
    {
      'id': 506,
      'user': 'علی رضایی',
      'school': 'دبستان پسرانه',
      'action': 'ثبت رزرو جدید',
      'ip': '192.168.1.110',
      'time': '۰۸ آبان ۱۴۰۵ — ۱۱:۰۰',
      'details': 'ثبت سانس صبح دوم جهت مسابقه سرود',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _logs.where((l) {
      final matchesSearch = (l['user'] as String).toLowerCase().contains(search) ||
          (l['details'] as String).toLowerCase().contains(search) ||
          (l['action'] as String).toLowerCase().contains(search);
      final matchesAction = _selectedAction == 'همه عملیات‌ها' || l['action'] == _selectedAction;
      return matchesSearch && matchesAction;
    }).toList();

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
                Icon(Icons.history_rounded, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاریخچه فعالیت‌ها و لاگ امنیتی سیستم (Audit Trail)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('ردیابی تغییرات، رخدادهای ورود، ثبت و لغو رزروها با ثبت زمان و آدرس IP کاربر', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'جستجو در لاگ‌ها بر اساس کاربر، عملیات یا جزئیات رویداد...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedAction,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'همه عملیات‌ها',
                    'ورود به سامانه',
                    'ثبت رزرو جدید',
                    'لغو رزرو',
                    'تغییر تنظیمات سرور',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAction = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Audit Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.8),
                      1: FlexColumnWidth(1.4),
                      2: FlexColumnWidth(1.8),
                      3: FlexColumnWidth(1.1),
                      4: FlexColumnWidth(1.8),
                      5: FlexColumnWidth(3),
                    },
                    border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppColors.veryLightGreen),
                        children: [
                          Padding(padding: EdgeInsets.all(12), child: Text('کاربر اقدام‌کننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('مدرسه مربوطه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('نوع عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('آدرس IP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('تاریخ و ساعت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('شرح و جزئیات رویداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                        ],
                      ),
                      ...filtered.map((log) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(12), child: Text(log['user'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(log['school'] as String, style: const TextStyle(fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(log['action'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen), textAlign: TextAlign.center),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Text(log['ip'] as String, style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: AppColors.secondaryText))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(log['time'] as String, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(log['details'] as String, style: const TextStyle(fontSize: 11))),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
