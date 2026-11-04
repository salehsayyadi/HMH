import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/calendar_day.dart';
import '../../../models/user.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_top_bar.dart';
import 'mobile_reservation_details_sheet.dart';

class MobileUserHistoryScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;

  const MobileUserHistoryScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MobileUserHistoryScreen> createState() => _MobileUserHistoryScreenState();
}

class _MobileUserHistoryScreenState extends State<MobileUserHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myReservations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getMyReservations();
      if (!mounted) return;
      setState(() {
        _myReservations = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _openDetails(Map<String, dynamic> res) {
    final cell = CalendarCellModel(
      date: res['reservation_date'] ?? '',
      jalaliDate: res['reservation_date_jalali'] ?? res['jalali_date'] ?? '',
      jalaliDayName: res['day_name'] ?? '',
      dayOfWeek: 0,
      timeSlotId: res['time_slot_id'] ?? 0,
      timeSlotTitle: res['time_slot']?['title'] ?? res['time_slot_title'] ?? '',
      status: res['status'] ?? 'reserved',
      reservationId: res['id'],
      schoolName: res['school_name'] ?? widget.currentUser.school?.name,
      userFullName: res['user_full_name'] ?? widget.currentUser.fullName,
    );

    MobileReservationDetailsSheet.show(
      context,
      cell: cell,
      currentUser: widget.currentUser,
      onCancelled: _loadHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: SafeArea(
          child: Column(
            children: [
              MobileTopBar(onLogout: widget.onLogout),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtitle & Title
                      const Text(
                        'سامانه رزرو سالن آمفی‌تئاتر',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'سوابق رزروهای من',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'لیست جلسات و برنامه‌های رزرو شده توسط شما',
                        style: TextStyle(fontSize: 11.5, color: AppColors.secondaryGreen, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                        )
                      else if (_myReservations.isEmpty) ...[
                        // Empty State Card (user-13.png)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_note_rounded,
                                  size: 48,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'تاکنون رزروی توسط شما ثبت نشده است.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Reservations list items (user-12.png)
                        ..._myReservations.map((res) {
                          final isConfirmed = (res['status'] == 'confirmed');
                          final dateStr = res['reservation_date_jalali'] ?? res['jalali_date'] ?? '';
                          final timeStr = res['time_slot']?['title'] ?? res['time_slot_title'] ?? '';
                          final titleStr = res['description'] ?? 'برنامه سالن آمفی‌تئاتر';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openDetails(res),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Right: Calendar icon
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.veryLightGreen,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_outlined,
                                          color: AppColors.primaryGreen,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Middle: Date, Time, Title
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$dateStr — $timeStr',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.darkGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              titleStr,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.secondaryText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Left: Status Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                                          borderRadius: BorderRadius.circular(8),
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),

                      // Refresh Button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loadHistory,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('به‌روزرسانی سوابق', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.cardBorder),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const MobileFooter(compact: true),
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
