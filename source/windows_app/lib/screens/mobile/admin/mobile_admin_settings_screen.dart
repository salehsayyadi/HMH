import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';

class MobileAdminSettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminSettingsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminSettingsScreen> createState() => _MobileAdminSettingsScreenState();
}

class _MobileAdminSettingsScreenState extends State<MobileAdminSettingsScreen> {
  final primaryTeal = const Color(0xFF00594C);

  final _domainCtrl = TextEditingController(text: 'kirkir.salehvip-clud.ir');
  final _portCtrl = TextEditingController(text: '443');
  final _apiBaseCtrl = TextEditingController(text: 'https://kirkir.salehvip-clud.ir/api/v1');
  final _wsCtrl = TextEditingController(text: 'wss://kirkir.salehvip-clud.ir/ws');

  final _dbHostCtrl = TextEditingController(text: 'mysql');
  final _dbPortCtrl = TextEditingController(text: '3306');
  final _dbNameCtrl = TextEditingController(text: 'amphitheater_db');
  final _dbUserCtrl = TextEditingController(text: 'amphitheater_app');

  bool _isServerConnected = true;
  bool _isDbConnected = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final res = await ApiService.testServerConnection();
      if (mounted) {
        setState(() {
          _isServerConnected = res['success'] == true;
          _isDbConnected = res['database'] != 'disconnected';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isServerConnected = false;
          _isDbConnected = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      final res = await ApiService.testServerConnection(_apiBaseCtrl.text.trim());
      if (mounted) {
        setState(() {
          _isServerConnected = res['success'] == true;
          _isDbConnected = res['database'] != 'disconnected';
          _isTesting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isServerConnected
                ? 'اتصال به وب‌سرویس و دیتابیس با موفقیت برقرار شد.'
                : 'برقراری ارتباط با وب‌سرویس با خطا مواجه شد.'),
            backgroundColor: _isServerConnected ? const Color(0xFF00796B) : Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isServerConnected = false;
          _isDbConnected = false;
          _isTesting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آزمایش اتصال: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ApiService.saveServerConfig(
        domain: _domainCtrl.text.trim(),
        apiBase: _apiBaseCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تنظیمات ارتباطی با موفقیت در سامانه ذخیره گردید.'),
            backgroundColor: Color(0xFF00796B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره تنظیمات: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              MobileTopBar(onLogout: widget.onLogout),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Text('مدیریت کل سامانه', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                            const SizedBox(height: 4),
                            Text(
                              'تنظیمات اتصال',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('سرور و وب‌سرویس API', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status Card (admin-20)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EBE8)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F7F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.cloud_outlined, color: primaryTeal, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('سرویس مرکزی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text('وضعیت اتصال وب‌سرویس', style: TextStyle(fontSize: 12, color: Color(0xFF7A928D))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isServerConnected ? const Color(0xFFE8F5F1) : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isServerConnected ? 'متصل' : 'قطع',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isServerConnected ? const Color(0xFF00796B) : const Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFFF0F4F2)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F7F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.storage_outlined, color: primaryTeal, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('پایگاه داده', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text('وضعیت اتصال دیتابیس', style: TextStyle(fontSize: 12, color: Color(0xFF7A928D))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isDbConnected ? const Color(0xFFE8F5F1) : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isDbConnected ? 'متصل' : 'قطع',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isDbConnected ? const Color(0xFF00796B) : const Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Server Specifications Card (admin-20)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EBE8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مشخصات ارتباط سرور و وب‌سرویس',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTeal),
                            ),
                            const SizedBox(height: 14),
                            const Text('دامنه یا آی‌پی سرور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _domainCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('پورت سرور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _portCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('آدرس کامل وب‌سرویس API', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _apiBaseCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('آدرس وب‌سوکت رویدادهای زنده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _wsCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Database Settings Card (admin-21)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EBE8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مشخصات پایگاه داده مرکزی (MySQL)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTeal),
                            ),
                            const SizedBox(height: 14),
                            const Text('میزبان دیتابیس در سرور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dbHostCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('پورت پایگاه داده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dbPortCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('نام پایگاه داده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dbNameCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('نام کاربری دیتابیس', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dbUserCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF7FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _isTesting ? null : _testConnection,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryTeal,
                                  side: const BorderSide(color: Color(0xFF00594C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isTesting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('آزمایش اتصال سرور و دیتابیس', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _saveSettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('ذخیره و اعمال تنظیمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const MobileFooter(),
                      const SizedBox(height: 16),
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
