import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'server_settings_modal.dart';
import 'server_database_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_schools_screen.dart';
import 'admin/admin_reservations_screen.dart';
import 'admin/admin_time_slots_screen.dart';
import 'admin/admin_holidays_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_activity_screen.dart';

class MainScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainScreen({super.key, required this.currentUser});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentNavIndex = 0;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _currentNavIndex = 0;

    // اگر برنامه در حالت آفلاین بالا آمده، در صورت سلامت بودن سرور و دیتابیس به صورت خودکار آنلاین می‌شود
    if (ApiService.isOfflineEmergencyMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoOnlineConnection();
      });
    }
  }

  Future<void> _checkAutoOnlineConnection() async {
    final res = await ApiService.reconnectOnline();
    if (res['success'] == true && mounted) {
      setState(() {
        ApiService.isOfflineEmergencyMode = false;
        if (res['user'] != null) {
          _currentUser = UserModel.fromJson(res['user']);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ارتباط پایدار با سرور و پایگاه‌داده برقرار گردید (ورود به صورت خودکار آنلاین شد).'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('خروج از حساب کاربری', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: const Text('آیا مایل به خروج از سامانه رزرو هستید؟', style: TextStyle(fontSize: 12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.holidayRedText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ApiService.clearTokens();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ApiService.isOfflineEmergencyMode;
    final isSuperAdmin = _currentUser.role == 'super_admin';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sidebarWidth = constraints.maxWidth < 1150 ? 245.0 : 270.0;
            return Row(
              children: [
                // Right Sidebar matching HMH visual identity
                Container(
                  width: sidebarWidth,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(left: BorderSide(color: AppColors.cardBorder, width: 1.2)),
                  ),
              child: Column(
                children: [
                  // Official Institute Logo Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // User Profile Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: const BoxDecoration(
                      color: AppColors.veryLightGreen,
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Column(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentUser.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.positionTitle ?? (isSuperAdmin ? 'مدیر ارشد سیستم' : 'معاون اجرایی'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUser.schoolName ?? (isSuperAdmin ? 'مدیریت مرکزی موسسه' : 'مدرسه امام حسین (ع)'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Navigation Menu
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Column(
                        children: isSuperAdmin ? _buildSuperAdminNavItems() : _buildSchoolUserNavItems(),
                      ),
                    ),
                  ),

                  // Logout Button at bottom
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.holidayRed,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF7C3C9)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: AppColors.holidayRedText, size: 19),
                            SizedBox(width: 10),
                            Text(
                              'خروج از حساب مدیریت',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.holidayRedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Offline subtle notification banner
                    if (isOffline) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'حالت پیکربندی آفلاین مدیر کل: سرور در «${ApiService.baseUrl}» در دسترس نیست. می‌توانید اطلاعات سرور و دیتابیس را در بخش «تنظیمات سامانه» تنظیم و آزمایش فرمایید.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('در حال بررسی اتصال به سرور و احراز هویت با پایگاه‌داده...'), duration: Duration(seconds: 1)),
                                  );
                                  final res = await ApiService.reconnectOnline();
                                  if (res['success'] == true) {
                                    setState(() {
                                      ApiService.isOfflineEmergencyMode = false;
                                      if (res['user'] != null) {
                                        _currentUser = UserModel.fromJson(res['user']);
                                      }
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'اتصال آنلاین با موفقیت برقرار شد.'),
                                          backgroundColor: AppColors.primaryGreen,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['error'] ?? 'سرور یا پایگاه داده هنوز در دسترس نیست.'),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('اتصال مجدد آنلاین', style: TextStyle(fontSize: 10.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _currentNavIndex = 7); // Settings index
                                },
                                icon: const Icon(Icons.settings, size: 14),
                                label: const Text('تنظیمات سرور', style: TextStyle(fontSize: 10.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    Expanded(child: _buildCurrentScreen(isSuperAdmin)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  ),
);
  }

  /// 8 Section Super Administrator Menu + Calendar View
  List<Widget> _buildSuperAdminNavItems() {
    return [
      _buildNavItem(0, 'داشبورد مدیریتی', Icons.dashboard_rounded),
      const SizedBox(height: 4),
      _buildNavItem(1, 'مدیریت کاربران', Icons.people_alt_rounded),
      const SizedBox(height: 4),
      _buildNavItem(2, 'مدیریت مدارس', Icons.school_rounded),
      const SizedBox(height: 4),
      _buildNavItem(3, 'مدیریت رزروها', Icons.event_available_rounded),
      const SizedBox(height: 4),
      _buildNavItem(4, 'مدیریت ساعت‌ها', Icons.access_time_filled_rounded),
      const SizedBox(height: 4),
      _buildNavItem(5, 'مدیریت تعطیلات', Icons.event_busy_rounded),
      const SizedBox(height: 4),
      _buildNavItem(6, 'گزارش‌ها و آمار', Icons.bar_chart_rounded),
      const SizedBox(height: 4),
      _buildNavItem(7, 'تنظیمات سامانه', Icons.settings_rounded),
      const SizedBox(height: 8),
      const Divider(height: 1, color: AppColors.cardBorder),
      const SizedBox(height: 8),
      _buildNavItem(8, 'تقویم رزرو سالن (نمای مدارس)', Icons.calendar_month_rounded, isSecondary: true),
    ];
  }

  /// 4 Section Ordinary School User Menu
  List<Widget> _buildSchoolUserNavItems() {
    return [
      _buildNavItem(0, 'صفحه اصلی (تقویم)', Icons.calendar_month_outlined),
      const SizedBox(height: 6),
      _buildNavItem(1, 'سوابق رزروها', Icons.history_edu_outlined),
      const SizedBox(height: 6),
      _buildNavItem(2, 'پروفایل کاربری', Icons.person_outline),
      const SizedBox(height: 6),
      _buildNavItem(3, 'درباره برنامه', Icons.info_outline),
    ];
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isSecondary = false}) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : (isSecondary ? AppColors.veryLightGreen : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isSecondary && !isSelected ? Border.all(color: AppColors.cardBorder) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected
                  ? Colors.white
                  : (isSecondary ? AppColors.primaryGreen : AppColors.secondaryText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isSecondary ? AppColors.darkGreen : AppColors.mainText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(bool isSuperAdmin) {
    if (isSuperAdmin) {
      switch (_currentNavIndex) {
        case 0:
          return const AdminDashboardScreen();
        case 1:
          return const AdminUsersScreen();
        case 2:
          return const AdminSchoolsScreen();
        case 3:
          return const AdminReservationsScreen();
        case 4:
          return const AdminTimeSlotsScreen();
        case 5:
          return const AdminHolidaysScreen();
        case 6:
          return const AdminReportsScreen();
        case 7:
          return const ServerDatabaseScreen();
        case 8:
          return CalendarScreen(currentUser: _currentUser);
        default:
          return const AdminDashboardScreen();
      }
    } else {
      switch (_currentNavIndex) {
        case 0:
          return CalendarScreen(currentUser: _currentUser);
        case 1:
          return const HistoryScreen();
        case 2:
          return ProfileScreen(currentUser: _currentUser);
        case 3:
          return const AboutScreen();
        default:
          return CalendarScreen(currentUser: _currentUser);
      }
    }
  }
}
