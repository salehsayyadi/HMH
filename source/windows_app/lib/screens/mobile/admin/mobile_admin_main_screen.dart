import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../models/user.dart';
import '../common/mobile_confirm_dialog.dart';
import '../user/mobile_user_login_screen.dart';
import 'mobile_admin_dashboard_screen.dart';
import 'mobile_admin_menu_screen.dart';
import 'mobile_admin_calendar_screen.dart';

class MobileAdminMainScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback? onLogout;

  const MobileAdminMainScreen({
    super.key,
    required this.currentUser,
    this.onLogout,
  });

  @override
  State<MobileAdminMainScreen> createState() => _MobileAdminMainScreenState();
}

class _MobileAdminMainScreenState extends State<MobileAdminMainScreen> {
  int _currentIndex = 0;
  final primaryTeal = const Color(0xFF00594C);

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _handleLogout() async {
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }

    final confirmed = await MobileConfirmDialog.show(
      context,
      title: 'خروج از حساب مدیریت',
      message: 'آیا از خروج از حساب مدیریت کل سامانه اطمینان دارید؟',
      confirmText: 'خروج از حساب',
      cancelText: 'انصراف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileUserLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MobileAdminDashboardScreen(
        currentUser: widget.currentUser,
        onLogout: _handleLogout,
      ),
      MobileAdminMenuScreen(onLogout: _handleLogout, onSelectTab: _onSelectTab),
      MobileAdminCalendarScreen(onLogout: _handleLogout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: Colors.white,
            selectedItemColor: primaryTeal,
            unselectedItemColor: const Color(0xFF8BA09B),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'داشبورد',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_rounded),
                activeIcon: Icon(Icons.menu_rounded),
                label: 'بخش‌های مدیریت',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_outlined),
                label: 'تقویم مدارس',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
