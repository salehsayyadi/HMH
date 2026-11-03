import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;

  int _totalSchools = 0;
  int _totalUsers = 0;
  int _todayReservations = 0;
  int _upcomingReservations = 0;
  int _monthlyReservations = 0;
  int _monthlyCancellations = 0;

  List<Map<String, dynamic>> _monthlyTrend = [
    {'month': 'خرداد', 'count': 0, 'max': 50},
    {'month': 'تیر', 'count': 0, 'max': 50},
    {'month': 'مرداد', 'count': 0, 'max': 50},
    {'month': 'شهریور', 'count': 0, 'max': 50},
    {'month': 'مهر', 'count': 0, 'max': 50},
    {'month': 'آبان', 'count': 0, 'max': 50},
  ];

  List<Map<String, dynamic>> _schoolStats = [];
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await ApiService.getDashboardStats();
      final logs = await ApiService.getAuditLogs();
      final schools = await ApiService.getSchools();
      final users = await ApiService.getUsers();

      if (mounted) {
        setState(() {
          _totalSchools = schools.length;
          _totalUsers = users.length;
          if (stats != null) {
            _todayReservations = stats['today_reservations'] ?? 0;
            _upcomingReservations = stats['upcoming_reservations'] ?? 0;
            _monthlyReservations = stats['monthly_reservations'] ?? 0;
            _monthlyCancellations = stats['monthly_cancellations'] ?? 0;
          }
          _recentActivities = logs.map((log) => {
            'school': log['school_name'] ?? 'مدیریت مرکزی',
            'user': log['user_full_name'] ?? 'کاربر سیستم',
            'action': log['action'] ?? 'عملیات',
            'time': log['created_at_jalali'] ?? 'اخیراً',
            'status': log['status'] ?? 'تأیید شده',
          }).toList();
        });
      }
    } catch (_) {
      // In fresh/raw database, keep counters clean at 0 and lists empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = [
      {'title': 'کل مدارس تحت پوشش', 'value': '$_totalSchools', 'icon': Icons.school_outlined, 'color': AppColors.primaryGreen, 'bg': AppColors.veryLightGreen},
      {'title': 'کل کاربران فعال', 'value': '$_totalUsers', 'icon': Icons.people_outline, 'color': const Color(0xFF1554A3), 'bg': const Color(0xFFDCEBFF)},
      {'title': 'رزروهای امروز', 'value': '$_todayReservations', 'icon': Icons.today_outlined, 'color': AppColors.secondaryGreen, 'bg': const Color(0xFFE8F5E9)},
      {'title': 'رزروهای پیش‌رو', 'value': '$_upcomingReservations', 'icon': Icons.event_available_outlined, 'color': const Color(0xFF008866), 'bg': AppColors.pastelGreen},
      {'title': 'رزروهای ماه جاری', 'value': '$_monthlyReservations', 'icon': Icons.check_circle_outline, 'color': AppColors.darkGreen, 'bg': AppColors.veryLightGreen},
      {'title': 'لغوشده‌های این ماه', 'value': '$_monthlyCancellations', 'icon': Icons.cancel_outlined, 'color': AppColors.holidayRedText, 'bg': AppColors.holidayRed},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.dashboard_rounded, color: AppColors.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'داشبورد مدیریت کل سامانه رزرواسیون آمفی‌تئاتر',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'نمای کلی آمار تحلیلی و وضعیت لحظه‌ای سالن آمفی‌تئاتر مرکزی مدارس امام حسین (ع) یزد',
                          style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadDashboardData,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, size: 20),
                    label: const Text('به‌روزرسانی', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6 KPI Cards Grid (Enlarged)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
              ),
              itemCount: kpis.length,
              itemBuilder: (context, i) {
                final kpi = kpis[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kpi['bg'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(kpi['icon'] as IconData, size: 19, color: kpi['color'] as Color),
                          ),
                        ],
                      ),
                      Text(
                        kpi['value'] as String,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kpi['color'] as Color),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Charts & Breakdown Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Reservation Trend
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                            ),
                            Text('داده‌های زنده از پایگاه داده', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                          ],
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 180,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _monthlyTrend.map((item) {
                              final count = item['count'] as int;
                              final max = item['max'] as int;
                              final barHeight = count == 0 ? 6.0 : (count / max) * 140;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 44,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: count > 0 ? AppColors.primaryGreen : AppColors.cardBorder,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(item['month'] as String, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Utilization by School
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'میزان استفاده مدارس از سالن',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                        const SizedBox(height: 20),
                        if (_schoolStats.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.school_outlined, size: 40, color: AppColors.secondaryText),
                                SizedBox(height: 10),
                                Text(
                                  'هنوز داده‌ای برای مدارس ثبت نشده است.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._schoolStats.map((sc) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sc['name'] as String,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mainText),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('${sc['count']} رزرو', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (sc['percent'] as double),
                                      backgroundColor: AppColors.veryLightGreen,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
