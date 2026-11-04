import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/calendar_day.dart';
import '../../../models/user.dart';
import '../common/mobile_footer.dart';

class MobileBookingSheet extends StatefulWidget {
  final CalendarCellModel cell;
  final UserModel currentUser;
  final VoidCallback onSuccess;

  const MobileBookingSheet({
    super.key,
    required this.cell,
    required this.currentUser,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required CalendarCellModel cell,
    required UserModel currentUser,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MobileBookingSheet(
        cell: cell,
        currentUser: currentUser,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<MobileBookingSheet> createState() => _MobileBookingSheetState();
}

class _MobileBookingSheetState extends State<MobileBookingSheet> {
  final _descriptionCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submitBooking() async {
    final desc = _descriptionCtrl.text.trim();
    if (desc.isEmpty) {
      setState(() => _errorMessage = 'لطفاً توضیحات و عنوان برنامه را وارد نمایید.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createReservation({
        'reservation_date': widget.cell.date,
        'time_slot_id': widget.cell.timeSlotId,
        'description': desc,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رزرو سالن آمفی‌تئاتر با موفقیت ثبت گردید.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isHoliday = widget.cell.isHoliday;
    final holidayTitle = widget.cell.holidayTitle ?? 'تعطیل رسمی';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + 16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
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
                isHoliday ? 'ثبت رزرو در روز تعطیل' : 'ثبت رزرو آمفی‌تئاتر',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isHoliday
                    ? 'مناسبت تقویمی: $holidayTitle'
                    : 'تاریخ، ساعت و مشخصات شما خودکار ثبت می‌شوند.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Festive holiday banner if holiday (user-08.png)
              if (isHoliday) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.holidayRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.celebration_rounded, color: AppColors.holidayRedText, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'رزرو سالن برای مراسم و برنامه‌های مدارس مجاز است.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.holidayRedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Summary Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('تاریخ رزرو', widget.cell.jalaliDate),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildSummaryRow('بازه زمانی', widget.cell.timeSlotTitle),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildSummaryRow('نام مدرسه', widget.currentUser.school?.name ?? 'مدرسه نامشخص'),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildSummaryRow('نام رزروکننده', widget.currentUser.fullName),
                    const Divider(height: 18, color: AppColors.mainBackground),
                    _buildSummaryRow('سمت سازمانی', widget.currentUser.position?.title ?? 'معاون اجرایی'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Event description field
              const Text(
                'توضیحات و عنوان برنامه *',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'برای چه برنامه‌ای سالن را رزرو می‌کنید؟ (مثال: جشن آغاز سال تحصیلی)',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.holidayRedText, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ثبت رزرو در سامانه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
              ),

              const MobileFooter(compact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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
