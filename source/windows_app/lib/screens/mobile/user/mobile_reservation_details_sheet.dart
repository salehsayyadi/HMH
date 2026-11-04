import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/calendar_day.dart';
import '../../../models/user.dart';
import '../common/mobile_confirm_dialog.dart';
import '../common/mobile_footer.dart';

class MobileReservationDetailsSheet extends StatefulWidget {
  final CalendarCellModel cell;
  final UserModel currentUser;
  final VoidCallback onCancelled;

  const MobileReservationDetailsSheet({
    super.key,
    required this.cell,
    required this.currentUser,
    required this.onCancelled,
  });

  static Future<void> show(
    BuildContext context, {
    required CalendarCellModel cell,
    required UserModel currentUser,
    required VoidCallback onCancelled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MobileReservationDetailsSheet(
        cell: cell,
        currentUser: currentUser,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<MobileReservationDetailsSheet> createState() => _MobileReservationDetailsSheetState();
}

class _MobileReservationDetailsSheetState extends State<MobileReservationDetailsSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final resId = widget.cell.reservationId;
    if (resId == null) {
      setState(() {
        _isLoading = false;
        _details = {
          'school_name': widget.cell.schoolName ?? 'نامشخص',
          'user_full_name': widget.cell.userFullName ?? 'نامشخص',
          'reservation_date_jalali': widget.cell.jalaliDate,
          'time_slot_title': widget.cell.timeSlotTitle,
          'can_cancel': false,
        };
      });
      return;
    }

    try {
      final data = await ApiService.getReservationDetail(resId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _details = data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _details = {
          'id': resId,
          'school_name': widget.cell.schoolName ?? 'نامشخص',
          'user_full_name': widget.cell.userFullName ?? 'نامشخص',
          'reservation_date_jalali': widget.cell.jalaliDate,
          'time_slot_title': widget.cell.timeSlotTitle,
          'user_id': -1,
        };
      });
    }
  }

  Future<void> _handleCancel() async {
    final resId = widget.cell.reservationId ?? _details?['id'];
    if (resId == null) return;

    final confirmed = await MobileConfirmDialog.show(
      context,
      title: 'تأیید لغو رزرو',
      message: 'آیا از لغو این رزرو اطمینان دارید؟ با لغو، این سانس بلافاصله برای سایر مدارس آزاد خواهد شد.',
      confirmText: 'بله، لغو شود',
      cancelText: 'انصراف',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      await ApiService.cancelReservation(resId);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCancelled();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رزرو با موفقیت لغو شد و زمان آن برای سایر مدارس آزاد گردید.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.holidayRedText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.currentUser.role == 'super_admin';
    final ownerId = _details?['user_id'];
    final isOwner = ownerId == widget.currentUser.id;
    final canCancel = (isOwner || isSuperAdmin) && (_details?['status'] != 'cancelled');

    final schoolName = _details?['school_name'] ?? widget.cell.schoolName ?? 'دبستان پسرانه امام حسین (ع)';
    final applicantName = _details?['user_full_name'] ?? widget.cell.userFullName ?? 'کاربر متقاضی';
    final dateStr = _details?['reservation_date_jalali'] ?? _details?['jalali_date'] ?? widget.cell.jalaliDate;
    final timeStr = _details?['time_slot']?['title'] ?? widget.cell.timeSlotTitle;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              canCancel ? 'جزئیات رزرو سالن' : 'جزئیات رزرو دیگران',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'اطلاعات مدرسه و متقاضی رزرو',
              style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              )
            else ...[
              // Details Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildRow('مدرسه رزروکننده', schoolName),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildRow('نام متقاضی', applicantName),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildRow('تاریخ', dateStr),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildRow('بازه زمانی', timeStr),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Cancel button if user has permission (user-09.png)
              if (canCancel) ...[
                OutlinedButton(
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.holidayRedText,
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                    backgroundColor: AppColors.holidayRed.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'لغو این رزرو',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Close Window Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'بستن پنجره',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            const MobileFooter(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
        ),
      ],
    );
  }
}
