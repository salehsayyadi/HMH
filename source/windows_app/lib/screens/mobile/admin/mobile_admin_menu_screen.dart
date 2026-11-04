import 'package:flutter/material.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';
import 'mobile_admin_users_screen.dart';
import 'mobile_admin_schools_screen.dart';
import 'mobile_admin_reservations_screen.dart';
import 'mobile_admin_time_slots_screen.dart';
import 'mobile_admin_holidays_screen.dart';
import 'mobile_admin_reports_screen.dart';
import 'mobile_admin_settings_screen.dart';

class MobileAdminMenuScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final Function(int)? onSelectTab;

  const MobileAdminMenuScreen({
    super.key,
    required this.onLogout,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = const Color(0xFF00594C);

    final menuItems = [
      {
        'title': 'داشبورد مدیریتی',
        'icon': Icons.grid_view_rounded,
        'action': () => onSelectTab?.call(0),
      },
      {
        'title': 'مدیریت کاربران',
        'icon': Icons.person_outline_rounded,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminUsersScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'مدیریت مدارس',
        'icon': Icons.school_outlined,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminSchoolsScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'مدیریت رزروها',
        'icon': Icons.calendar_today_outlined,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminReservationsScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'مدیریت ساعت‌ها',
        'icon': Icons.access_time_rounded,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminTimeSlotsScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'مدیریت تعطیلات',
        'icon': Icons.event_busy_outlined,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminHolidaysScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'گزارش‌ها و آمار',
        'icon': Icons.bar_chart_rounded,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminReportsScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'تنظیمات سامانه',
        'icon': Icons.settings_outlined,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MobileAdminSettingsScreen(onLogout: onLogout)),
            ),
      },
      {
        'title': 'تقویم رزرو سالن (نمای مدارس)',
        'icon': Icons.calendar_month_outlined,
        'action': () => onSelectTab?.call(2),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              MobileTopBar(onLogout: onLogout),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'مدیریت کل سامانه',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5A726D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بخش‌های مدیریت',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'منوی نسخه مدیر کل',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5A726D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        child: Column(
                          children: List.generate(menuItems.length, (index) {
                            final item = menuItems[index];
                            final isLast = index == menuItems.length - 1;
                            return Column(
                              children: [
                                ListTile(
                                  onTap: item['action'] as VoidCallback,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F7F5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: primaryTeal,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B2E2B),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Color(0xFF8BA09B),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                ),
                                if (!isLast)
                                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEBF2F0)),
                              ],
                            );
                          }),
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
