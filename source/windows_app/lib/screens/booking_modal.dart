import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import '../models/calendar_day.dart';

class BookingModal extends StatefulWidget {
  final CalendarCellModel cell;
  final UserModel currentUser;
  final VoidCallback onBookingSuccess;

  const BookingModal({
    super.key,
    required this.cell,
    required this.currentUser,
    required this.onBookingSuccess,
  });

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createReservation(
        date: widget.cell.date,
        timeSlotId: widget.cell.timeSlotId,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onBookingSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            'رزرو آمفی‌تئاتر با موفقیت ثبت شد.',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
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
              // Header matching design reference
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pastelGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available, color: AppColors.primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ثبت رزرو آمفی‌تئاتر',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'مشخصات انتخابی شده و اطلاعات حساب کاربری شما',
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
              const SizedBox(height: 20),

              // Holiday Notice Banner
              if (widget.cell.isHoliday) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.holidayRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF7C3C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_rounded, color: AppColors.holidayRedText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'مناسبت تقویمی: ${widget.cell.holidayTitle ?? "تعطیل رسمی"} (رزرو سالن برای مراسم و برنامه‌های مدارس مجاز است)',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.holidayRedText, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Info notice banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.pastelGreen),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.secondaryGreen, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تاریخ، ساعت و مشخصات شما به‌صورت خودکار ثبت می‌شوند.',
                        style: TextStyle(fontSize: 11, color: AppColors.mainText, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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

              // Auto-populated Fields Row 1 (Date & Time Slot)
              Row(
                children: [
                  Expanded(
                    child: _buildReadOnlyField(
                      label: 'تاریخ رزرو',
                      value: '${widget.cell.jalaliDayName}، ${widget.cell.jalaliDate}',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildReadOnlyField(
                      label: 'بازه زمانی',
                      value: widget.cell.timeSlotTitle,
                      icon: Icons.access_time_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Auto-populated Field (School)
              _buildReadOnlyField(
                label: 'نام مدرسه',
                value: widget.currentUser.schoolName ?? 'مدرسه امام حسین (ع)',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 14),

              // Auto-populated Fields Row 2 (Name & Position)
              Row(
                children: [
                  Expanded(
                    child: _buildReadOnlyField(
                      label: 'نام رزروکننده',
                      value: widget.currentUser.fullName,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildReadOnlyField(
                      label: 'سمت سازمانی',
                      value: widget.currentUser.positionTitle ?? 'معاون اجرایی',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Multiline Description (The ONLY editable field per Part 15!)
              const Text(
                'توضیحات و عنوان برنامه *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mainText),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'برای چه برنامه‌ای آمفی‌تئاتر را رزرو می‌کنید؟ توضیحات خود را اینجا بنویسید...',
                  hintStyle: TextStyle(fontSize: 11, color: AppColors.secondaryText.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.veryLightGreen,
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
              const SizedBox(height: 22),

              // Action Buttons (Enlarged)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('انصراف', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ثبت رزرو در سامانه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.veryLightGreen,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGreen),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
