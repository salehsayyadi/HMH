import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/user.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_saved_accounts_sheet.dart';
import '../common/mobile_save_login_prompt.dart';
import '../common/mobile_server_settings_sheet.dart';
import 'mobile_user_main_screen.dart';
import '../admin/mobile_admin_main_screen.dart';

class MobileUserLoginScreen extends StatefulWidget {
  const MobileUserLoginScreen({super.key});

  @override
  State<MobileUserLoginScreen> createState() => _MobileUserLoginScreenState();
}

class _MobileUserLoginScreenState extends State<MobileUserLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_accounts_list');
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        setState(() {
          _savedAccounts = list.map((e) => Map<String, String>.from(e)).toList();
          if (_savedAccounts.isNotEmpty) {
            _usernameCtrl.text = _savedAccounts.first['username'] ?? '';
            _passwordCtrl.text = _savedAccounts.first['password'] ?? '';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAccount(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = _savedAccounts.where((a) => a['username'] != username).toList();
      existing.insert(0, {'username': username, 'password': password});
      await prefs.setString('saved_accounts_list', jsonEncode(existing));
      setState(() => _savedAccounts = existing);
    } catch (_) {}
  }

  Future<void> _deleteSavedAccount(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = _savedAccounts.where((a) => a['username'] != username).toList();
      await prefs.setString('saved_accounts_list', jsonEncode(updated));
      setState(() {
        _savedAccounts = updated;
        if (_usernameCtrl.text == username) {
          _usernameCtrl.clear();
          _passwordCtrl.clear();
        }
      });
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    final user = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'لطفاً نام کاربری و رمز عبور را وارد فرمایید.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ApiService.login(user, pass);
      final meData = await ApiService.getMe();
      final currentUser = UserModel.fromJson(meData);

      if (!mounted) return;

      // Ask to save credentials if not already saved
      final alreadySaved = _savedAccounts.any((a) => a['username'] == user);
      if (!alreadySaved) {
        final shouldSave = await MobileSaveLoginPrompt.show(context);
        if (shouldSave == true) {
          await _saveAccount(user, pass);
        }
      }

      if (!mounted) return;

      // Role-based navigation: super_admin -> Admin Shell, user -> User Shell
      if (currentUser.role == 'super_admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MobileAdminMainScreen(currentUser: currentUser)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MobileUserMainScreen(currentUser: currentUser)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Top Official Logo & Title
                  Image.asset(
                    'assets/images/logo.png',
                    width: 74,
                    height: 74,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primaryGreen,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'موسسه خیریه فرهنگی آموزشی',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'حضرت امام حسین (ع) یزد',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Brand Title
                  const Text(
                    'IMH',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'سامانه رزرو سالن',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryGreen,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'سامانه متمرکز رزرواسیون\nسالن آمفی‌تئاتر',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ورود کاربران سازمانی و مدیریت مدارس',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardBorder.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Saved Accounts quick selector button if any
                        if (_savedAccounts.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => MobileSavedAccountsSheet.show(
                                context,
                                accounts: _savedAccounts,
                                onSelect: (acc) {
                                  setState(() {
                                    _usernameCtrl.text = acc['username'] ?? '';
                                    _passwordCtrl.text = acc['password'] ?? '';
                                  });
                                },
                                onDelete: _deleteSavedAccount,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history_rounded, size: 16, color: AppColors.primaryGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      'حساب‌های ذخیره‌شده',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Username Field
                        const Text(
                          'نام کاربری',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameCtrl,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'نام کاربری سازمانی خود را وارد کنید',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        const SizedBox(height: 16),

                        // Password Field
                        const Text(
                          'رمز عبور',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'رمز عبور خود را وارد کنید',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.holidayRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.holidayRedText, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.holidayRedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'ورود به سامانه',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Server Connection Settings Button Card (user-01.png)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () => MobileServerSettingsSheet.show(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: const Icon(Icons.chevron_left_rounded, color: AppColors.secondaryText),
                      title: const Text(
                        'تنظیمات اتصال سرور',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.dns_outlined, color: AppColors.primaryGreen, size: 20),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const MobileFooter(compact: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
