import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _reservations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.getMyHistory();
      setState(() {
        _reservations = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سوابق رزروهای من',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'لیست جلسات و برنامه‌های رزرو شده توسط شما در سالن آمفی‌تئاتر',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
                  onPressed: _loadHistory,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_reservations.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.secondaryText),
                      SizedBox(height: 12),
                      Text('تاکنون رزروی توسط شما ثبت نشده است.', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    itemCount: _reservations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (context, idx) {
                      final item = _reservations[idx];
                      final isConfirmed = item['status'] == 'confirmed';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isConfirmed ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: isConfirmed ? AppColors.darkGreen : AppColors.holidayRedText,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${item['jalali_date']} — ${item['time_slot']?['title'] ?? ""}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          item['description'] ?? 'بدون توضیحات تکمیلی',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isConfirmed ? 'تأیید شده' : 'لغو شده',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isConfirmed ? AppColors.darkGreen : AppColors.holidayRedText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
