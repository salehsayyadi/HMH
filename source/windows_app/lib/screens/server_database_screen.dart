import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';

class ServerDatabaseScreen extends StatefulWidget {
  const ServerDatabaseScreen({super.key});

  @override
  State<ServerDatabaseScreen> createState() => _ServerDatabaseScreenState();
}

class _ServerDatabaseScreenState extends State<ServerDatabaseScreen> {
  // Right side fields
  final _mainDomainController = TextEditingController(text: 'salehvip-clud.ir');
  final _subDomainController = TextEditingController(text: 'reserve.salehvip-clud.ir');
  final _osController = TextEditingController(text: 'Ubuntu 24.04 LTS');
  final _backendTechController = TextEditingController(text: 'FastAPI / Python');
  final _dbHostController = TextEditingController(text: 'mysql');
  final _dbNameController = TextEditingController(text: 'amphitheater_db');
  final _httpsPortController = TextEditingController(text: '443');
  final _jwtSecretController = TextEditingController(text: '••••••••••••••••••••••••••••••');

  // Left side fields
  final _apiUrlController = TextEditingController(text: 'https://reserve.salehvip-clud.ir/api/v1');
  final _wsUrlController = TextEditingController(text: 'wss://reserve.salehvip-clud.ir/ws');
  final _webServerController = TextEditingController(text: 'Nginx');
  final _dbTypeController = TextEditingController(text: 'MySQL 9.7 LTS');
  final _dbPortController = TextEditingController(text: '3306');
  final _dbUserController = TextEditingController(text: 'amphitheater_app');
  final _sslCertController = TextEditingController(text: "Let's Encrypt");

  bool _isTesting = false;
  bool _apiConnected = false;
  bool _dbConnected = false;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final cfg = await ApiService.getServerConfig();
    final host = cfg['host'] ?? 'reserve.salehvip-clud.ir';
    final proto = cfg['protocol'] ?? 'https';
    final port = cfg['port'] ?? '443';
    final path = cfg['apiPath'] ?? '/api/v1';

    setState(() {
      _subDomainController.text = host;
      _apiUrlController.text = '$proto://$host$path';
      _wsUrlController.text = '${proto == "https" ? "wss" : "ws"}://$host/ws';
      _httpsPortController.text = port;
    });

    _testConnection(silent: true);
  }

  Future<void> _testConnection({bool silent = false}) async {
    setState(() {
      _isTesting = true;
      if (!silent) _testMessage = null;
    });

    final res = await ApiService.testServerConnection(_apiUrlController.text.trim());

    if (mounted) {
      setState(() {
        _isTesting = false;
        _apiConnected = res['success'] == true;
        _dbConnected = res['success'] == true; // If API is healthy, DB connection is online
        if (!silent) {
          if (res['success'] == true) {
            _testMessage = 'اتصال با موفقیت برقرار گردید (تاخیر: ${res['latencyMs']}ms — نسخه: ${res['version']})';
          } else {
            _testMessage = 'خطا در اتصال: ${res['error']}';
          }
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final domain = _subDomainController.text.trim();
    final isHttps = _apiUrlController.text.startsWith('https');

    await ApiService.saveServerConfig(
      host: domain,
      protocol: isHttps ? 'https' : 'http',
      port: _httpsPortController.text.trim(),
      apiPath: '/api/v1',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات سرور و پایگاه‌داده با موفقیت ذخیره و اعمال شد.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _testConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching design reference
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.storage_rounded, color: AppColors.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنظیمات اتصال به سرور',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'پیکربندی ارتباط با سرور، پایگاه‌داده و تنظیمات استقرار (Ubuntu Linux)',
                          style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),

                  // Connection status pills matching reference design
                  _buildStatusPill('اتصال دیتابیس', _dbConnected),
                  const SizedBox(width: 8),
                  _buildStatusPill('اتصال API', _apiConnected),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 24),

              // Test message banner if any
              if (_testMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _apiConnected ? AppColors.veryLightGreen : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _apiConnected ? AppColors.pastelGreen : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _apiConnected ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: _apiConnected ? AppColors.primaryGreen : AppColors.holidayRedText,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _apiConnected ? AppColors.darkGreen : AppColors.holidayRedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2-Column Grid matching reference design
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column (Server and Hosting parameters)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField('دامنه اصلی', _mainDomainController, Icons.public),
                        const SizedBox(height: 14),
                        _buildInputField('زیردامنه سامانه', _subDomainController, Icons.domain),
                        const SizedBox(height: 14),
                        _buildInputField('سیستم‌عامل سرور', _osController, Icons.computer),
                        const SizedBox(height: 14),
                        _buildInputField('فناوری بک‌اند', _backendTechController, Icons.code),
                        const SizedBox(height: 14),
                        _buildInputField('میزبان دیتابیس', _dbHostController, Icons.dns),
                        const SizedBox(height: 14),
                        _buildInputField('نام دیتابیس', _dbNameController, Icons.dataset),
                        const SizedBox(height: 14),
                        _buildInputField('پورت HTTPS', _httpsPortController, Icons.numbers),
                        const SizedBox(height: 14),
                        _buildInputField('کلید JWT / Secret', _jwtSecretController, Icons.key, obscure: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),

                  // Left Column (API and Connection parameters)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField('آدرس API', _apiUrlController, Icons.api),
                        const SizedBox(height: 14),
                        _buildInputField('آدرس WebSocket', _wsUrlController, Icons.sync_alt),
                        const SizedBox(height: 14),
                        _buildInputField('وب سرور', _webServerController, Icons.cloud),
                        const SizedBox(height: 14),
                        _buildInputField('دیتابیس', _dbTypeController, Icons.storage),
                        const SizedBox(height: 14),
                        _buildInputField('پورت دیتابیس', _dbPortController, Icons.numbers),
                        const SizedBox(height: 14),
                        _buildInputField('نام کاربری دیتابیس', _dbUserController, Icons.badge),
                        const SizedBox(height: 14),
                        _buildInputField('گواهی SSL', _sslCertController, Icons.security),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 20),

              // Action Buttons matching reference design
              Row(
                children: [
                  // Test Connection button
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : () => _testConnection(),
                    icon: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check_rounded, size: 18),
                    label: Text(_isTesting ? 'در حال آزمایش...' : 'آزمایش اتصال'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const Spacer(),

                  // Save Settings button (Green #006B52)
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('ذخیره تنظیمات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String title, bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.veryLightGreen : AppColors.error,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? AppColors.pastelGreen : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.primaryGreen : AppColors.holidayRedText,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$title: ${isConnected ? "متصل" : "قطع"}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isConnected ? AppColors.darkGreen : AppColors.holidayRedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.mainText),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.secondaryText),
            filled: true,
            fillColor: AppColors.veryLightGreen,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
