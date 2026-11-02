import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminRestrictionsScreen extends StatefulWidget {
  const AdminRestrictionsScreen({super.key});

  @override
  State<AdminRestrictionsScreen> createState() => _AdminRestrictionsScreenState();
}

class _AdminRestrictionsScreenState extends State<AdminRestrictionsScreen> {
  bool _isSystemLocked = false;

  final List<Map<String, dynamic>> _rules = [
    {
      'id': 1,
      'title': 'مسدودسازی ایام برگزاری امتحانات نوبت اول (دی‌ماه)',
      'period': '۱۲ دی تا ۳۰ دی ۱۴۰۵',
      'reason': 'برگزاری آزمون‌های کتبی و آماده‌سازی فضای سالن جهت حوزه‌های امتحانی مدارس',
      'isActive': true,
    },
    {
      'id': 2,
      'title': 'سرویس دوره‌ای سیستم‌های صوت و تصویر و نورپردازی سالن',
      'period': '۲۹ آبان ۱۴۰۵ — سانس ظهر',
      'reason': 'کالیبراسیون پروژکتورهای لیزری و تعویض لامپ‌های صحنه',
      'isActive': true,
    },
    {
      'id': 3,
      'title': 'محدودیت سقف مجاز رزرو برای هر مدرسه (حداکثر ۴ سانس در ماه)',
      'period': 'اعمال سراسری در طول سال تحصیلی',
      'reason': 'رعایت عدالت و توزیع متوازن سانس‌های سالن آمفی‌تئاتر بین کلیه مدارس ۶ گانه',
      'isActive': true,
    },
    {
      'id': 4,
      'title': 'حداقل فاصله زمانی مجاز برای لغو رزرو (۴۸ ساعت قبل)',
      'period': 'قانون سراسری سامانه',
      'reason': 'امکان برنامه‌ریزی مجدد و اختصاص سانس آزادشده به سایر متقاضیان',
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              children: [
                Icon(Icons.gpp_bad_rounded, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت محدودیت‌ها و قوانین رزرواسیون', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('تعریف بازه‌های مسدودی، قوانین سقف رزرو مدارس و کلید اضطراری سامانه', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Global Lock Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isSystemLocked ? AppColors.holidayRed : AppColors.veryLightGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isSystemLocked ? const Color(0xFFF7C3C9) : AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _isSystemLocked ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
                  color: _isSystemLocked ? AppColors.holidayRedText : AppColors.primaryGreen,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSystemLocked ? 'سامانه در وضعیت قفل اضطراری قرار دارد' : 'کلید اضطراری مسدودسازی ثبت رزرو در کل سامانه',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isSystemLocked ? AppColors.holidayRedText : AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isSystemLocked
                            ? 'امکان ثبت رزرو جدید برای کلیه مدارس به صورت موقت مسدود شده است.'
                            : 'با فعال‌سازی این کلید، تقویم رزرو برای تمامی مدارس مسدود شده و امکان رزرو جدید نخواهد بود.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isSystemLocked ? AppColors.holidayRedText : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isSystemLocked,
                  activeColor: AppColors.holidayRedText,
                  onChanged: (val) {
                    setState(() {
                      _isSystemLocked = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'کلید اضطراری فعال و رزرو کل سامانه مسدود شد.' : 'کلید اضطراری غیرفعال و ثبت رزرو آزاد گردید.'),
                        backgroundColor: val ? AppColors.holidayRedText : AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rules List
          Expanded(
            child: ListView.separated(
              itemCount: _rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final rule = _rules[i];
                final isActive = rule['isActive'] as bool;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isActive ? AppColors.cardBorder : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.veryLightGreen : AppColors.holidayRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 22,
                          color: isActive ? AppColors.primaryGreen : AppColors.holidayRedText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule['title'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rule['reason'] as String,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.veryLightGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rule['period'] as String,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            rule['isActive'] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
