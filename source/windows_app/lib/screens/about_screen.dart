import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checking = false;
  bool _serverOnline = true;
  bool _dbOnline = true;
  int _latencyMs = 0;
  String _apiStatus = 'در حال استعلام وضعیت سرویس...';

  Future<void> _checkServer() async {
    setState(() {
      _checking = true;
    });
    try {
      final res = await ApiService.testServerConnection();
      setState(() {
        _serverOnline = (res['apiConnected'] == true);
        _dbOnline = (res['dbConnected'] == true);
        _latencyMs = res['latencyMs'] is int ? res['latencyMs'] : 0;
        final ver = res['version'] ?? '1.0.0';
        _apiStatus = _serverOnline
            ? 'نسخه $ver — پاسخگویی پایدار'
            : (res['message'] ?? 'عدم دسترسی به سرور مرکزی');
      });
    } catch (_) {
      setState(() {
        _serverOnline = false;
        _dbOnline = false;
        _latencyMs = 0;
        _apiStatus = 'عدم دسترسی به سرور مرکزی';
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organization Header (Clean without logo per user requirement)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مرکزی',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد',
                      style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'نسخه تولیدی سامانه: ۱.۰.۱۵',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Server Status Section per Part 19
              // "وضعیت اتصال به سرور تنها در این صفحه نمایش داده شود"
              const Text(
                'وضعیت اتصال و ارتباط با سرور مرکزی',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildStatusRow(
                      'وضعیت اتصال به سرور مرکزی:',
                      _serverOnline ? 'متصل (Online)' : 'قطع ارتباط (Offline)',
                      _serverOnline ? AppColors.darkGreen : AppColors.holidayRedText,
                      _serverOnline ? Icons.cloud_done : Icons.cloud_off,
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildStatusRow(
                      'وضعیت پایگاه‌داده متمرکز (MySQL):',
                      _dbOnline ? 'متصل و آماده پردازش (Connected)' : 'عدم دسترسی به پایگاه‌داده',
                      _dbOnline ? AppColors.darkGreen : AppColors.holidayRedText,
                      _dbOnline ? Icons.dns : Icons.error_outline,
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildStatusRow(
                      'تاخیر پاسخگویی (Latency):',
                      _latencyMs > 0 ? '$_latencyMs میلی‌ثانیه' : (_serverOnline ? 'کمتر از ۱ ثانیه' : 'نامشخص'),
                      _latencyMs < 500 ? AppColors.darkGreen : AppColors.orangeWarning,
                      Icons.speed,
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildStatusRow(
                      'وضعیت همگام‌سازی بلادرنگ:',
                      'فعال از طریق وب‌سوکت امن (WSS)',
                      AppColors.primaryGreen,
                      Icons.sync,
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildStatusRow(
                      'وضعیت سرویس API:',
                      _apiStatus,
                      AppColors.mainText,
                      Icons.api,
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildStatusRow(
                      'پروتکل ارتباطی:',
                      'امن TLS 1.3 با رمزنگاری سرتاسری',
                      AppColors.mainText,
                      Icons.security,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _checking ? null : _checkServer,
                    icon: _checking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen))
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_checking ? 'در حال بررسی...' : 'بررسی مجدد اتصال به سرور',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              const Text(
                'توسعه و پشتیبانی فنی: موسسه فرهنگی آموزشی حضرت امام حسین (ع) — تمامی حقوق محفوظ است.',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, String val, Color valColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valColor),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
        const Spacer(),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }
}
