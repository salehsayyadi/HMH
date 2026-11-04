import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/user.dart';
import '../common/mobile_confirm_dialog.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_top_bar.dart';

class MobileUserProfileScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;

  const MobileUserProfileScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MobileUserProfileScreen> createState() => _MobileUserProfileScreenState();
}

class _MobileUserProfileScreenState extends State<MobileUserProfileScreen> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isChangingPassword = false;
  String? _errorMessage;

  Future<void> _handleChangePassword() async {
    final oldPass = _oldPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'لطفاً تمامی فیلدهای رمز عبور را تکمیل فرمایید.');
      return;
    }

    if (newPass.length < 8) {
      setState(() => _errorMessage = 'کلمه عبور جدید باید حداقل ۸ کاراکتر باشد.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'کلمه عبور جدید و تکرار آن یکسان نمی‌باشند.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _errorMessage = null;
    });

    try {
      await ApiService.changePassword(oldPass, newPass);
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کلمه عبور با موفقیت به‌روزرسانی گردید.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final posTitle = widget.currentUser.position?.title ?? 'معاون اجرایی';
    final schName = widget.currentUser.school?.name ?? 'مدرسه نامشخص';

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
                        'پروفایل کاربری و امنیت',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'مشاهده مشخصات و تغییر رمز عبور',
                        style: TextStyle(fontSize: 11.5, color: AppColors.secondaryGreen, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // Profile Info Card (user-14.png)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.veryLightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 42,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.currentUser.fullName,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$posTitle — $schName',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'نام کاربری: ${widget.currentUser.username}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: AppColors.secondaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Change Password Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'تغییر کلمه عبور',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Old password
                            _buildLabel('کلمه عبور فعلی'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _oldPassCtrl,
                              obscureText: true,
                              textDirection: TextDirection.ltr,
                              decoration: _inputDecoration(),
                            ),
                            const SizedBox(height: 12),

                            // New password
                            _buildLabel('کلمه عبور جدید (حداقل ۸ کاراکتر)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _newPassCtrl,
                              obscureText: true,
                              textDirection: TextDirection.ltr,
                              decoration: _inputDecoration(),
                            ),
                            const SizedBox(height: 12),

                            // Confirm password
                            _buildLabel('تکرار کلمه عبور جدید'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPassCtrl,
                              obscureText: true,
                              textDirection: TextDirection.ltr,
                              decoration: _inputDecoration(),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.holidayRedText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isChangingPassword ? null : _handleChangePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isChangingPassword
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'ثبت رمز عبور جدید',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.darkGreen,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
    );
  }
}
