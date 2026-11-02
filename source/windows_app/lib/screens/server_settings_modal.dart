import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/services/api_service.dart';

class ServerSettingsModal extends StatefulWidget {
  const ServerSettingsModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ServerSettingsModal(),
    );
  }

  @override
  State<ServerSettingsModal> createState() => _ServerSettingsModalState();
}

class _ServerSettingsModalState extends State<ServerSettingsModal> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _apiPathController = TextEditingController();
  String _protocol = 'https';

  bool _isTesting = false;
  Map<String, dynamic>? _testResult;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final cfg = await ApiService.getServerConfig();
    setState(() {
      _hostController.text = cfg['host'] ?? ApiService.defaultHost;
      _protocol = cfg['protocol'] ?? ApiService.defaultProtocol;
      _portController.text = cfg['port'] ?? ApiService.defaultPort;
      _apiPathController.text = cfg['apiPath'] ?? ApiService.defaultApiPath;
    });
  }

  String _computeFullUrl() {
    final cleanHost = _hostController.text.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/.*$'), '');
    final cleanPort = _portController.text.trim();
    var cleanPath = _apiPathController.text.trim();
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    if ((_protocol == 'https' && (cleanPort.isEmpty || cleanPort == '443')) ||
        (_protocol == 'http' && (cleanPort.isEmpty || cleanPort == '80'))) {
      return '$_protocol://$cleanHost$cleanPath';
    } else {
      return '$_protocol://$cleanHost:$cleanPort$cleanPath';
    }
  }

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final targetUrl = _computeFullUrl();
    final res = await ApiService.testServerConnection(targetUrl);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = res;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
    });

    await ApiService.saveServerConfig(
      host: _hostController.text,
      protocol: _protocol,
      port: _portController.text,
      apiPath: _apiPathController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات اتصال با موفقیت ذخیره و اعمال گردید.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _resetToDefault() {
    setState(() {
      _hostController.text = ApiService.defaultHost;
      _protocol = ApiService.defaultProtocol;
      _portController.text = ApiService.defaultPort;
      _apiPathController.text = ApiService.defaultApiPath;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _computeFullUrl();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.veryLightGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.dns_rounded, color: AppColors.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تنظیمات اتصال به سرور مرکزی',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'پیکربندی آدرس اینترنتی یا محلی جهت ارتباط نرم‌افزار ویندوز با پایگاه‌داده',
                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 20),

                // Host Field
                const Text(
                  'دامنه یا آدرس IP سرور',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mainText),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _hostController,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'مثال: reserve.salehvip-clud.ir یا 192.168.1.100',
                    prefixIcon: const Icon(Icons.language_rounded, size: 20, color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.veryLightGreen,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Protocol and Port Row
                Row(
                  children: [
                    // Protocol selector
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'پروتکل امنیتی',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mainText),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.veryLightGreen,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _protocol,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'https', child: Text('HTTPS (اینترنت / امن)')),
                                  DropdownMenuItem(value: 'http', child: Text('HTTP (محلی / شبکه داخلی)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _protocol = val;
                                      if (val == 'https' && _portController.text == '80') {
                                        _portController.text = '443';
                                      } else if (val == 'http' && _portController.text == '443') {
                                        _portController.text = '80';
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Port field
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'شماره پورت',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mainText),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _portController,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: '443 یا 80 یا 8000',
                              prefixIcon: const Icon(Icons.numbers_rounded, size: 20, color: AppColors.secondaryText),
                              filled: true,
                              fillColor: AppColors.veryLightGreen,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Preview Full Base URL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'پیش‌نمایش آدرس نهایی وب‌سرویس:',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        previewUrl,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Connection test result display
                if (_testResult != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testResult!['success'] == true ? AppColors.veryLightGreen : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _testResult!['success'] == true ? AppColors.pastelGreen : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testResult!['success'] == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: _testResult!['success'] == true ? AppColors.primaryGreen : AppColors.holidayRedText,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _testResult!['success'] == true ? 'اتصال با موفقیت برقرار شد' : 'خطای ارتباط با سرور',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _testResult!['success'] == true ? AppColors.darkGreen : AppColors.holidayRedText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _testResult!['success'] == true
                                    ? 'زمان تاخیر پاسخگویی (Latency): ${_testResult!['latencyMs']} میلی‌ثانیه — نسخه سامانه: ${_testResult!['version']}'
                                    : '${_testResult!['error']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _testResult!['success'] == true ? AppColors.mainText : AppColors.holidayRedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    // Test connection button
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _runConnectionTest,
                      icon: _isTesting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check_rounded, size: 18),
                      label: Text(_isTesting ? 'در حال آزمایش...' : 'آزمایش اتصال'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Reset to default
                    TextButton.icon(
                      onPressed: _resetToDefault,
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('پیش‌فرض'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondaryText,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                    const Spacer(),

                    // Cancel
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText)),
                    ),
                    const SizedBox(width: 8),

                    // Save and apply
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره و اعمال'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
