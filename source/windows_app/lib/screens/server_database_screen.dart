import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';

class ServerDatabaseScreen extends StatefulWidget {
  const ServerDatabaseScreen({super.key});

  @override
  State<ServerDatabaseScreen> createState() => _ServerDatabaseScreenState();
}

class _ServerDatabaseScreenState extends State<ServerDatabaseScreen> {
  // Server connection fields
  final _subDomainController = TextEditingController(text: 'reserve.salehvip-clud.ir');
  final _httpsPortController = TextEditingController(text: '443');
  final _apiUrlController = TextEditingController(text: 'https://reserve.salehvip-clud.ir/api/v1');
  final _wsUrlController = TextEditingController(text: 'wss://reserve.salehvip-clud.ir/ws');

  // Database connection fields
  final _dbHostController = TextEditingController(text: 'mysql');
  final _dbPortController = TextEditingController(text: '3306');
  final _dbNameController = TextEditingController(text: 'amphitheater_db');
  final _dbUserController = TextEditingController(text: 'amphitheater_app');

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
      _httpsPortController.text = port;
      _apiUrlController.text = '$proto://$host$path';
      _wsUrlController.text = '${proto == "https" ? "wss" : "ws"}://$host/ws';
    });

    _testConnection(silent: true);
  }

  void _updateDerivedUrls() {
    final host = _subDomainController.text.trim();
    final port = _httpsPortController.text.trim();
    final isHttps = port == '443';
    final proto = isHttps ? 'https' : 'http';
    final wsProto = isHttps ? 'wss' : 'ws';
    final portStr = (port == '443' || port == '80' || port.isEmpty) ? '' : ':$port';

    setState(() {
      _apiUrlController.text = '$proto://$host$portStr/api/v1';
      _wsUrlController.text = '$wsProto://$host$portStr/ws';
    });
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
        _apiConnected = res['apiConnected'] == true || (res['success'] == true);
        _dbConnected = res['dbConnected'] == true;
        if (!silent) {
          if (res['success'] == true && _dbConnected) {
            _testMessage = 'اتصال به وب‌سرویس و پایگاه داده با موفقیت برقرار گردید (تاخیر: ${res['latencyMs']}ms — نسخه: ${res['version']})';
          } else if (_apiConnected && !_dbConnected) {
            _testMessage = res['message'] ?? 'وب‌سرویس متصل است اما پایگاه داده مرکزی در دسترس نیست.';
          } else {
            _testMessage = res['error'] ?? 'خطا در برقراری ارتباط با سرور مرکزی.';
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storage_rounded, color: AppColors.primaryGreen, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنظیمات اتصال به سرور و پایگاه داده',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'پیکربندی پارامترهای ضروری ارتباط با سرور مرکزی لینوکس و پایگاه داده MySQL',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),

                  // Connection status pills
                  _buildStatusPill('پایگاه داده', _dbConnected),
                  const SizedBox(width: 10),
                  _buildStatusPill('سرویس مرکزی', _apiConnected),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 22),

              // Test message banner if any
              if (_testMessage != null) ...[
                final isFullSuccess = _apiConnected && _dbConnected;
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isFullSuccess ? AppColors.veryLightGreen : (_apiConnected ? Colors.amber.shade50 : AppColors.error),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFullSuccess ? AppColors.pastelGreen : (_apiConnected ? Colors.amber.shade300 : Colors.red.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFullSuccess ? Icons.check_circle_rounded : (_apiConnected ? Icons.warning_amber_rounded : Icons.error_outline_rounded),
                        color: isFullSuccess ? AppColors.primaryGreen : (_apiConnected ? Colors.amber.shade900 : AppColors.holidayRedText),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isFullSuccess ? AppColors.darkGreen : (_apiConnected ? Colors.amber.shade900 : AppColors.holidayRedText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Clean 2-Column Grid of Essential Fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column (Server and API parameters)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.mainBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, size: 20, color: AppColors.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'مشخصات ارتباط سرور و وب‌سرویس (API)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildInputField('دامنه یا آی‌پی سرور (Domain / IP)', _subDomainController, Icons.domain, onChanged: (_) => _updateDerivedUrls()),
                          const SizedBox(height: 16),
                          _buildInputField('پورت سرور (Port)', _httpsPortController, Icons.numbers, onChanged: (_) => _updateDerivedUrls()),
                          const SizedBox(height: 16),
                          _buildInputField('آدرس کامل وب‌سرویس API', _apiUrlController, Icons.api),
                          const SizedBox(height: 16),
                          _buildInputField('آدرس وب‌سوکت رویدادهای زنده (WebSocket)', _wsUrlController, Icons.sync_alt),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),

                  // Left Column (Database parameters on Server)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.mainBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.storage_rounded, size: 20, color: AppColors.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'مشخصات پایگاه داده مرکزی (MySQL Server)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildInputField('میزبان دیتابیس در سرور (Host)', _dbHostController, Icons.dns),
                          const SizedBox(height: 16),
                          _buildInputField('پورت پایگاه داده (MySQL Port)', _dbPortController, Icons.numbers),
                          const SizedBox(height: 16),
                          _buildInputField('نام پایگاه داده (Database Name)', _dbNameController, Icons.dataset),
                          const SizedBox(height: 16),
                          _buildInputField('نام کاربری دیتابیس (Database User)', _dbUserController, Icons.badge),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  // Test Connection button
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : () => _testConnection(),
                    icon: _isTesting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check_rounded, size: 21),
                    label: Text(_isTesting ? 'در حال آزمایش اتصال...' : 'آزمایش اتصال سرور و دیتابیس', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const Spacer(),

                  // Save Settings button (Green #006B52)
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded, size: 21),
                    label: const Text('ذخیره و اعمال تنظیمات', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (ApiService.isOfflineEmergencyMode && _apiConnected && _dbConnected) ...[
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          ApiService.isOfflineEmergencyMode = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سامانه با موفقیت به حالت آنلاین متصل شد.'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_done_rounded, size: 21),
                      label: const Text('فعال‌سازی حالت آنلاین', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.primaryGreen : AppColors.holidayRedText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ${isConnected ? "متصل" : "قطع"}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isConnected ? AppColors.darkGreen : AppColors.holidayRedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.mainText),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.secondaryText),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
