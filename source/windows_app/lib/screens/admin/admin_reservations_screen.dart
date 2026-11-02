import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final _searchController = TextEditingController();
  String _selectedSchool = 'همه مدارس';
  String _selectedStatus = 'همه وضعیت‌ها';

  final List<Map<String, dynamic>> _reservations = [
    {
      'id': 101,
      'date': '۱۱ آبان ۱۴۰۵',
      'day': 'دوشنبه',
      'timeSlot': 'عصر اول (۱۵:۰۰ تا ۱۷:۰۰)',
      'school': 'دبیرستان پسرانه دوره دوم امام حسین (ع)',
      'user': 'محمدمحسن کارستان',
      'phone': '09132510001',
      'title': 'همایش هدایت تحصیلی و کنکور دانش‌آموزان پایه دوازدهم',
      'status': 'تأیید شده',
    },
    {
      'id': 102,
      'date': '۱۲ آبان ۱۴۰۵',
      'day': 'سه‌شنبه',
      'timeSlot': 'صبح اول (۰۸:۰۰ تا ۱۰:۰۰)',
      'school': 'دبستان دخترانه امام حسین (ع)',
      'user': 'فاطمه کریمی',
      'phone': '09132510002',
      'title': 'جشن قرآن و تجلیل از دانش‌آموزان حافظ قرآن کریم',
      'status': 'تأیید شده',
    },
    {
      'id': 103,
      'date': '۱۴ آبان ۱۴۰۵',
      'day': 'پنجشنبه',
      'timeSlot': 'ظهر (۱۲:۳۰ تا ۱۴:۳۰)',
      'school': 'دبیرستان دخترانه دوره اول امام حسین (ع)',
      'user': 'مریم حسینی',
      'phone': '09132510004',
      'title': 'جلسه هم‌اندیشی انجمن اولیا و مربیان',
      'status': 'تأیید شده',
    },
    {
      'id': 104,
      'date': '۱۵ آبان ۱۴۰۵',
      'day': 'جمعه',
      'timeSlot': 'صبح دوم (۱۰:۰۰ تا ۱۲:۰۰)',
      'school': 'دبستان پسرانه امام حسین (ع)',
      'user': 'علی رضایی',
      'phone': '09132510003',
      'title': 'مسابقات سرود و تئاتر دانش‌آموزی',
      'status': 'تأیید شده',
    },
    {
      'id': 105,
      'date': '۱۷ آبان ۱۴۰۵',
      'day': 'یکشنبه',
      'timeSlot': 'عصر دوم (۱۸:۰۰ تا ۲۰:۰۰)',
      'school': 'دبیرستان پسرانه دوره اول امام حسین (ع)',
      'user': 'حسین احمدی',
      'phone': '09132510005',
      'title': 'مراسم شبی با قرآن همکاران و اساتید',
      'status': 'لغو شده',
      'cancelReason': 'تغییر زمان برنامه و هماهنگی با تاریخ جدید',
    },
    {
      'id': 106,
      'date': '۱۹ آبان ۱۴۰۵',
      'day': 'سه‌شنبه',
      'timeSlot': 'صبح دوم (۱۰:۰۰ تا ۱۲:۰۰)',
      'school': 'دبیرستان دخترانه دوره دوم امام حسین (ع)',
      'user': 'زهرا اکبری',
      'phone': '09132510006',
      'title': 'کارگاه مهارت‌های زندگی و انگیزشی کنکور',
      'status': 'تأیید شده',
    },
  ];

  void _showCancelDialog(Map<String, dynamic> item) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('لغو رزرو شماره ${item['id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.holidayRedText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مدرسه: ${item['school']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('تاریخ و زمان: ${item['date']} — ${item['timeSlot']}', style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText)),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'علت لغو رزرو (الزامی)',
                  hintText: 'دلیل لغو این رزرو توسط مدیریت را مرقوم فرمایید...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    item['status'] = 'لغو شده';
                    item['cancelReason'] = reasonCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('رزرو شماره ${item['id']} لغو و زمان آن آزاد شد.'), backgroundColor: AppColors.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.holidayRedText, foregroundColor: Colors.white),
              child: const Text('تأیید لغو رزرو'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text('جزئیات کامل رزرو شماره ${item['id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('مدرسه متقاضی:', item['school'] as String),
                _detailRow('کاربر ثبت‌کننده:', '${item['user']} (${item['phone']})'),
                _detailRow('تاریخ رزرو:', '${item['day']}، ${item['date']}'),
                _detailRow('بازه زمانی:', item['timeSlot'] as String),
                _detailRow('عنوان رویداد:', item['title'] as String),
                _detailRow('وضعیت فعلی:', item['status'] as String),
                if (item['cancelReason'] != null)
                  _detailRow('علت لغو:', item['cancelReason'] as String, isRed: true),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 11.5, color: isRed ? AppColors.holidayRedText : AppColors.mainText, fontWeight: isRed ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _reservations.where((r) {
      final matchesSearch = (r['school'] as String).toLowerCase().contains(search) ||
          (r['user'] as String).toLowerCase().contains(search) ||
          (r['title'] as String).toLowerCase().contains(search);
      final matchesSchool = _selectedSchool == 'همه مدارس' || (r['school'] as String).contains(_selectedSchool);
      final matchesStatus = _selectedStatus == 'همه وضعیت‌ها' || (r['status'] as String) == _selectedStatus;
      return matchesSearch && matchesSchool && matchesStatus;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت کلیه رزروهای آمفی‌تئاتر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('بررسی، پیگیری، تأیید و لغو سانس‌های رزرو شده سالن توسط مدارس', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                Text('تعداد کل: ${filtered.length} رزرو', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
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
                    hintText: 'جستجو بر اساس عنوان برنامه، مدرسه یا کاربر ثبت‌کننده...',
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
                  value: _selectedSchool,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'همه مدارس',
                    'دبستان دخترانه',
                    'دبستان پسرانه',
                    'دبیرستان دخترانه دوره اول',
                    'دبیرستان پسرانه دوره اول',
                    'دبیرستان دخترانه دوره دوم',
                    'دبیرستان پسرانه دوره دوم',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSchool = val);
                  },
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
                  value: _selectedStatus,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: ['همه وضعیت‌ها', 'تأیید شده', 'لغو شده']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reservations Table
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
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(1.8),
                      2: FlexColumnWidth(2.6),
                      3: FlexColumnWidth(1.5),
                      4: FlexColumnWidth(2.6),
                      5: FlexColumnWidth(1.1),
                      6: FlexColumnWidth(1.4),
                    },
                    border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppColors.veryLightGreen),
                        children: [
                          Padding(padding: EdgeInsets.all(12), child: Text('تاریخ رزرو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('بازه زمانی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('مدرسه متقاضی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('ثبت‌کننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('عنوان و موضوع برنامه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('وضعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                        ],
                      ),
                      ...filtered.map((item) {
                        final isConfirmed = item['status'] == 'تأیید شده';
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(12), child: Text('${item['day']} ${item['date']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkGreen))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(item['timeSlot'] as String, style: const TextStyle(fontSize: 10.5))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(item['school'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(item['user'] as String, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(item['title'] as String, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['status'] as String,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isConfirmed ? AppColors.darkGreen : AppColors.holidayRedText),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'مشاهده جزئیات',
                                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryGreen),
                                    onPressed: () => _showDetailsDialog(item),
                                  ),
                                  if (isConfirmed)
                                    IconButton(
                                      tooltip: 'لغو رزرو',
                                      icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.holidayRedText),
                                      onPressed: () => _showCancelDialog(item),
                                    ),
                                ],
                              ),
                            ),
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
