import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String? _savedUsername;
  String? _savedPassword;

  @override
  void initState() {
    super.initState();
    _usernameController.text = '';
    _passwordController.text = '';
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final u = prefs.getString('saved_login_username');
      final p = prefs.getString('saved_login_password');
      if (u != null && u.isNotEmpty && p != null && p.isNotEmpty) {
        setState(() {
          _savedUsername = u;
          _savedPassword = p;
        });
      }
    } catch (_) {}
  }

  Future<void> _applySavedCredentials() async {
    if (_savedUsername != null && _savedPassword != null) {
      setState(() {
        _usernameController.text = _savedUsername!;
        _passwordController.text = _savedPassword!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اطلاعات حساب «$_savedUsername» در فرم جای‌گذاری شد.'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _forgetSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_login_username');
      await prefs.remove('saved_login_password');
      setState(() {
        _savedUsername = null;
        _savedPassword = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اطلاعات ذخیره‌شده با موفقیت از سیستم پاک شد.'),
          backgroundColor: AppColors.secondaryText,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'لطفاً نام کاربری و رمز عبور را وارد فرمایید.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.login(username, password);
      final user = UserModel.fromJson(res['user']);
      if (!mounted) return;

      // Browser-style credential saving prompt
      if (_savedUsername != username || _savedPassword != password) {
        final shouldSave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.password_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 10),
                  Text('ذخیره اطلاعات ورود', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'آیا مایلید نام کاربری و رمز عبور حساب «$username» در این سیستم ذخیره شود تا در ورود‌های بعدی پیشنهاد داده شود؟',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('خیر', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('بله، ذخیره شود', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );

        if (shouldSave == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_login_username', username);
          await prefs.setString('saved_login_password', password);
        }
      }

      if (res['is_offline_mode'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ورود در حالت پیکربندی آفلاین مدیر کل انجام شد.'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(currentUser: user)),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = msg;
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
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: Stack(
          children: [
            // Ambient soft background glow circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pastelGreen.withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withOpacity(0.08),
                ),
              ),
            ),

            // Center login card
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 450,
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withOpacity(0.07),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Official Institute Logo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 6),

                      const Text(
                        'سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ورود کاربران سازمانی و مدیریت مدارس',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      // Error message if any
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.holidayRedText, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.holidayRedText,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Username field
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نام کاربری',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'نام کاربری سازمانی خود را وارد کنید',
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: TextStyle(fontSize: 11, color: AppColors.secondaryText.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.secondaryText),
                          filled: true,
                          fillColor: AppColors.veryLightGreen,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                      // Password field
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'رمز عبور',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'رمز عبور خود را وارد کنید',
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: TextStyle(fontSize: 11, color: AppColors.secondaryText.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.secondaryText),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: AppColors.secondaryText,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.veryLightGreen,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 14),

                      // Browser-style autofill suggestion if saved credentials exist
                      if (_savedUsername != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.pastelGreen.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key_rounded, size: 18, color: AppColors.darkGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'پیشنهاد ورود: $_savedUsername',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: _applySavedCredentials,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('جای‌گذاری', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.secondaryText),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'فراموشی این حساب',
                                onPressed: _forgetSavedCredentials,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // Login button matching reference
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: AppColors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'ورود به سامانه',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
