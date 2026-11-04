import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MobileTopBar extends StatelessWidget {
  final VoidCallback? onLogout;
  final bool showLogout;

  const MobileTopBar({
    super.key,
    this.onLogout,
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.mainBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: IMH Brand and Logout Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IMH',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              if (showLogout && onLogout != null)
                InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Text(
                      'خروج',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.holidayRedText,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Right: Official Organization Branding and Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'موسسه خیریه فرهنگی آموزشی',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'حضرت امام حسین (ع) یزد',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primaryGreen,
                  size: 34,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
