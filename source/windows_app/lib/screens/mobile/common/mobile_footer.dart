import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MobileFooter extends StatelessWidget {
  final bool compact;

  const MobileFooter({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          compact
              ? 'طراحی و توسعه: محمد صالح صیادی · IMH'
              : 'طراحی و توسعه‌یافته توسط دانش‌آموز: محمد صالح صیادی · پایه یازدهم فنی',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
