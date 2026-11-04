import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/user.dart';
import '../common/mobile_confirm_dialog.dart';
import 'mobile_user_calendar_screen.dart';
import 'mobile_user_history_screen.dart';
import 'mobile_user_login_screen.dart';
import 'mobile_user_profile_screen.dart';

class MobileUserMainScreen extends StatefulWidget {
  final UserModel currentUser;

  const MobileUserMainScreen({super.key, required this.currentUser});

  @override
  State<MobileUserMainScreen> createState() => _MobileUserMainScreenState();
}

class _MobileUserMainScreenState extends State<MobileUserMainScreen> {
  int _currentTabIndex = 0;

  Future<void> _handleLogout() async {
    final confirmed = await MobileConfirmDialog.show(
      context,
      title: 'خروج از حساب کاربری',
      message: 'آیا مایل به خروج از سامانه رزرو هستید؟',
      confirmText: 'خروج',
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
      MobileUserCalendarScreen(
        currentUser: widget.currentUser,
        onLogout: _handleLogout,
      ),
      MobileUserHistoryScreen(
        currentUser: widget.currentUser,
        onLogout: _handleLogout,
      ),
      MobileUserProfileScreen(
        currentUser: widget.currentUser,
        onLogout: _handleLogout,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: IndexedStack(
          index: _currentTabIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (idx) => setState(() => _currentTabIndex = idx),
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.secondaryText,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded, size: 22),
                activeIcon: Icon(Icons.calendar_month_rounded, size: 24),
                label: 'تقویم',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded, size: 22),
                activeIcon: Icon(Icons.manage_history_rounded, size: 24),
                label: 'سوابق رزروها',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 24),
                label: 'پروفایل',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
