import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import '../models/calendar_day.dart';

class ReservationDetailsModal extends StatefulWidget {
  final CalendarCellModel cell;
  final UserModel currentUser;
  final VoidCallback onCancelSuccess;

  const ReservationDetailsModal({
    super.key,
    required this.cell,
    required this.currentUser,
    required this.onCancelSuccess,
  });

  @override
  State<ReservationDetailsModal> createState() => _ReservationDetailsModalState();
}

class _ReservationDetailsModalState extends State<ReservationDetailsModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('تأیید لغو رزرو', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.holidayRedText)),
          content: const Text(
            'آیا از لغو این رزرو اطمینان دارید؟ با لغو، این سانس بلافاصله برای سایر مدارس آزاد خواهد شد.',
            style: TextStyle(fontSize: 12),
          ),
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
              child: const Text('بله، لغو شود'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.cell.reservationId != null) {
        await ApiService.cancelReservation(widget.cell.reservationId!);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCancelSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            'رزرو با موفقیت لغو شد و سانس آزاد گردید.',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = widget.currentUser.role == 'super_admin' || 
                      (widget.cell.userFullName == widget.currentUser.fullName);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.reservationBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.reservationBlueText, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'جزئیات رزرو سالن آمفی‌تئاتر',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'اطلاعات مدرسه و متقاضی رزرو',
                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 11, color: AppColors.holidayRedText, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // School and Date Cards
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildRow(Icons.school, 'مدرسه رزروکننده:', widget.cell.schoolName ?? 'نامشخص'),
                    const Divider(height: 16, color: AppColors.cardBorder),
                    _buildRow(Icons.person, 'نام متقاضی:', widget.cell.userFullName ?? 'نامشخص'),
                    const Divider(height: 16, color: AppColors.cardBorder),
                    _buildRow(Icons.calendar_today, 'تاریخ:', '${widget.cell.jalaliDayName}، ${widget.cell.jalaliDate}'),
                    const Divider(height: 16, color: AppColors.cardBorder),
                    _buildRow(Icons.access_time, 'بازه زمانی:', widget.cell.timeSlotTitle),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canCancel)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.holidayRed,
                        foregroundColor: AppColors.holidayRedText,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFF7C3C9)),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 19),
                      label: const Text('لغو این رزرو', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox.shrink(),

                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('بستن پنجره', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
      ],
    );
  }
}
