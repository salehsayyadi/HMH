import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainScreen({super.key, required this.currentUser});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentNavIndex = 0; // 0: Calendar, 1: History, 2: Profile, 3: About

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: Row(
          children: [
            // Right Sidebar matching design reference image
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(left: BorderSide(color: AppColors.cardBorder, width: 1.2)),
              ),
              child: Column(
                children: [
                  // User Profile Box matching design reference
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
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
                          widget.currentUser.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentUser.positionTitle ?? 'معاون اجرایی',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.currentUser.schoolName ?? 'مدرسه پسرانه دوره دوم',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Navigation Menu (4 items per Part 12)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      child: Column(
                        children: [
                          _buildNavItem(0, 'صفحه اصلی', Icons.calendar_month_outlined),
                          const SizedBox(height: 6),
                          _buildNavItem(1, 'سوابق رزروها', Icons.history_edu_outlined),
                          const SizedBox(height: 6),
                          _buildNavItem(2, 'پروفایل کاربری', Icons.person_outline),
                          const SizedBox(height: 6),
                          _buildNavItem(3, 'درباره برنامه', Icons.info_outline),
                        ],
                      ),
                    ),
                  ),

                  // Logout Button at bottom matching reference design
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.holidayRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF7C3C9)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: AppColors.holidayRedText, size: 17),
                            SizedBox(width: 8),
                            Text(
                              'خروج از حساب',
                              style: TextStyle(
                                fontSize: 12,
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
                padding: const EdgeInsets.all(22.0),
                child: _buildCurrentScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.mainText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentNavIndex) {
      case 0:
        return CalendarScreen(currentUser: widget.currentUser);
      case 1:
        return const HistoryScreen();
      case 2:
        return ProfileScreen(currentUser: widget.currentUser);
      case 3:
        return const AboutScreen();
      default:
        return CalendarScreen(currentUser: widget.currentUser);
    }
  }
}
