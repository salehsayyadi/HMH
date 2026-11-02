import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _kpis = [
    {'title': 'کل مدارس تحت پوشش', 'value': '۶', 'icon': Icons.school_outlined, 'color': AppColors.primaryGreen, 'bg': AppColors.veryLightGreen},
    {'title': 'کل کاربران فعال', 'value': '۷', 'icon': Icons.people_outline, 'color': Color(0xFF1554A3), 'bg': Color(0xFFDCEBFF)},
    {'title': 'رزروهای امروز', 'value': '۲', 'icon': Icons.today_outlined, 'color': AppColors.secondaryGreen, 'bg': Color(0xFFE8F5E9)},
    {'title': 'رزروهای پیش‌رو', 'value': '۱۴', 'icon': Icons.event_available_outlined, 'color': Color(0xFF008866), 'bg': AppColors.pastelGreen},
    {'title': 'رزروهای ماه جاری', 'value': '۴۸', 'icon': Icons.check_circle_outline, 'color': AppColors.darkGreen, 'bg': AppColors.veryLightGreen},
    {'title': 'لغوشده‌های این ماه', 'value': '۳', 'icon': Icons.cancel_outlined, 'color': AppColors.holidayRedText, 'bg': AppColors.holidayRed},
  ];

  final List<Map<String, dynamic>> _monthlyTrend = [
    {'month': 'خرداد', 'count': 32, 'max': 60},
    {'month': 'تیر', 'count': 18, 'max': 60},
    {'month': 'مرداد', 'count': 24, 'max': 60},
    {'month': 'شهریور', 'count': 39, 'max': 60},
    {'month': 'مهر', 'count': 54, 'max': 60},
    {'month': 'آبان', 'count': 48, 'max': 60},
  ];

  final List<Map<String, dynamic>> _schoolStats = [
    {'name': 'دبیرستان پسرانه دوره دوم امام حسین (ع)', 'count': 15, 'percent': 0.85},
    {'name': 'دبستان پسرانه امام حسین (ع)', 'count': 14, 'percent': 0.78},
    {'name': 'دبیرستان دخترانه دوره اول امام حسین (ع)', 'count': 12, 'percent': 0.68},
    {'name': 'دبستان دخترانه امام حسین (ع)', 'count': 11, 'percent': 0.62},
    {'name': 'دبیرستان دخترانه دوره دوم امام حسین (ع)', 'count': 8, 'percent': 0.45},
    {'name': 'دبیرستان پسرانه دوره اول امام حسین (ع)', 'count': 7, 'percent': 0.38},
  ];

  final List<Map<String, dynamic>> _recentActivities = [
    {'school': 'دبیرستان پسرانه دوره دوم', 'user': 'محمدمحسن کارستان', 'time': '۱۰ دقیقه پیش', 'action': 'ثبت رزرو همایش کنکور', 'status': 'تأیید شده'},
    {'school': 'دبستان دخترانه', 'user': 'فاطمه کریمی', 'time': '۳۵ دقیقه پیش', 'action': 'درخواست جشن قرآن', 'status': 'تأیید شده'},
    {'school': 'دبیرستان دخترانه دوره اول', 'user': 'مریم حسینی', 'time': '۱ ساعت پیش', 'action': 'جلسه انجمن اولیا و مربیان', 'status': 'تأیید شده'},
    {'school': 'دبستان پسرانه', 'user': 'علی رضایی', 'time': '۲ ساعت پیش', 'action': 'مسابقه سرود دانش‌آموزی', 'status': 'تأیید شده'},
    {'school': 'دبیرستان پسرانه دوره اول', 'user': 'حسین احمدی', 'time': 'دیروز', 'action': 'لغو سانس عصر دوم', 'status': 'لغو شده'},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_rounded, color: AppColors.primaryGreen, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'داشبورد مدیریت کل سامانه رزرواسیون آمفی‌تئاتر',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'نمای کلی آمار تحلیلی و وضعیت لحظه‌ای سالن آمفی‌تئاتر مرکزی مدارس امام حسین (ع) یزد',
                          style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('اطلاعات داشبورد به‌روزرسانی شد.'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('به‌روزرسانی', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 6 KPI Cards Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _kpis.length,
              itemBuilder: (context, i) {
                final kpi = _kpis[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              kpi['title'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kpi['bg'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(kpi['icon'] as IconData, size: 16, color: kpi['color'] as Color),
                          ),
                        ],
                      ),
                      Text(
                        kpi['value'] as String,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kpi['color'] as Color),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Charts & Breakdown Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Reservation Trend
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'روند ماهانه رزروهای سالن آمفی‌تئاتر',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                            ),
                            Text('سال تحصیلی ۱۴۰۳-۱۴۰۴', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _monthlyTrend.map((item) {
                              final count = item['count'] as int;
                              final max = item['max'] as int;
                              final barHeight = (count / max) * 140;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 38,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item['month'] as String, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Utilization by School
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'میزان استفاده مدارس از سالن',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                        const SizedBox(height: 16),
                        ..._schoolStats.map((sc) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sc['name'] as String,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mainText),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text('${sc['count']} رزرو', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (sc['percent'] as double),
                                    backgroundColor: AppColors.veryLightGreen,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Recent Activities Table
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آخرین رخدادها و رزروهای ثبت‌شده',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(2.5),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppColors.veryLightGreen),
                        children: [
                          Padding(padding: EdgeInsets.all(10), child: Text('مدرسه متقاضی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('کاربر ثبت‌کننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('عنوان و موضوع برنامه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('زمان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('وضعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                        ],
                      ),
                      ..._recentActivities.map((act) {
                        final isConfirmed = act['status'] == 'تأیید شده';
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(10), child: Text(act['school'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.darkGreen, fontWeight: FontWeight.w600))),
                            Padding(padding: const EdgeInsets.all(10), child: Text(act['user'] as String, style: const TextStyle(fontSize: 11.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text(act['action'] as String, style: const TextStyle(fontSize: 11.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text(act['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText))),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  act['status'] as String,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isConfirmed ? AppColors.darkGreen : AppColors.holidayRedText),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
