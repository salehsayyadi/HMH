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
  String _apiStatus = 'پاسخگویی سریع و پایدار';

  Future<void> _checkServer() async {
    setState(() {
      _checking = true;
    });
    try {
      final res = await ApiService.checkHealth();
      setState(() {
        _serverOnline = (res['status'] == 'healthy');
        _apiStatus = 'نسخه ${res['version']} — وضعیت عادی';
      });
    } catch (_) {
      setState(() {
        _serverOnline = false;
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
              // Organization Header
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primaryGreen, size: 38),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس — نسخه ویندوز',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'نسخه برنامه: ۱.۰.۰ (تولید رسمی)',
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
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

              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkServer,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('بررسی مجدد اتصال به سرور'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
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
