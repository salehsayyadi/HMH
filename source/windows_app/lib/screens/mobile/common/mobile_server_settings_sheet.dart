import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import 'mobile_footer.dart';

class MobileServerSettingsSheet extends StatefulWidget {
  const MobileServerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MobileServerSettingsSheet(),
    );
  }

  @override
  State<MobileServerSettingsSheet> createState() => _MobileServerSettingsSheetState();
}

class _MobileServerSettingsSheetState extends State<MobileServerSettingsSheet> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _apiPathCtrl = TextEditingController();
  final _fullUrlCtrl = TextEditingController();

  String _protocol = 'HTTPS';
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await ApiService.getServerConfig();
    setState(() {
      _hostCtrl.text = cfg['host'] ?? ApiService.defaultHost;
      _portCtrl.text = cfg['port'] ?? ApiService.defaultPort;
      _protocol = (cfg['protocol'] ?? ApiService.defaultProtocol).toUpperCase();
      _apiPathCtrl.text = cfg['apiPath'] ?? ApiService.defaultApiPath;
      _updateFullUrl();
    });
  }

  void _updateFullUrl() {
    final host = _hostCtrl.text.trim();
    final proto = _protocol.toLowerCase();
    final port = _portCtrl.text.trim();
    final path = _apiPathCtrl.text.trim();

    String url = '$proto://$host';
    if ((proto == 'http' && port != '80') || (proto == 'https' && port != '443')) {
      if (port.isNotEmpty) url += ':$port';
    }
    if (path.isNotEmpty) {
      url += path.startsWith('/') ? path : '/$path';
    }
    _fullUrlCtrl.text = url;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    _updateFullUrl();
    final tempUrl = _fullUrlCtrl.text.trim();

    try {
      final res = await ApiService.testConnectionUrl(tempUrl);
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = (res['apiConnected'] == true);
        _testResult = _testSuccess
            ? 'اتصال پایدار برقرار شد (${res['latencyMs'] ?? 50}ms)'
            : (res['message'] ?? 'عدم برقراری ارتباط با سرور مرکزی');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'خطا در برقراری ارتباط با سرور';
      });
    }
  }

  Future<void> _saveAndApply() async {
    _updateFullUrl();
    await ApiService.saveServerConfig(
      host: _hostCtrl.text.trim(),
      protocol: _protocol.toLowerCase(),
      port: _portCtrl.text.trim(),
      apiPath: _apiPathCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تنظیمات سرور ذخیره و فعال گردید.'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  void _resetToDefault() {
    setState(() {
      _hostCtrl.text = ApiService.defaultHost;
      _portCtrl.text = ApiService.defaultPort;
      _protocol = ApiService.defaultProtocol.toUpperCase();
      _apiPathCtrl.text = ApiService.defaultApiPath;
      _updateFullUrl();
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: bottomInset + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'تنظیمات اتصال به سرور',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Server Domain / IP
              _buildLabel('دامنه یا آی‌پی سرور'),
              const SizedBox(height: 6),
              TextField(
                controller: _hostCtrl,
                textDirection: TextDirection.ltr,
                onChanged: (_) => _updateFullUrl(),
                decoration: _inputDecoration(hint: 'مثال: kirkir.salehvip-clud.ir'),
              ),
              const SizedBox(height: 14),

              // Port & Protocol Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('پورت'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _portCtrl,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateFullUrl(),
                          decoration: _inputDecoration(hint: '443'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('پروتکل'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _protocol,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'HTTPS', child: Text('HTTPS')),
                            DropdownMenuItem(value: 'HTTP', child: Text('HTTP')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _protocol = val;
                                _portCtrl.text = (val == 'HTTPS') ? '443' : '80';
                                _updateFullUrl();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Full API URL (Readonly Preview)
              _buildLabel('آدرس کامل وب‌سرویس'),
              const SizedBox(height: 6),
              TextField(
                controller: _fullUrlCtrl,
                textDirection: TextDirection.ltr,
                readOnly: true,
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                decoration: _inputDecoration(fillColor: AppColors.veryLightGreen),
              ),

              // Test Result Banner
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _testSuccess ? AppColors.pastelGreen : AppColors.holidayRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _testSuccess ? AppColors.secondaryGreen : AppColors.holidayRedText,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 18,
                        color: _testSuccess ? AppColors.darkGreen : AppColors.holidayRedText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _testSuccess ? AppColors.darkGreen : AppColors.holidayRedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Test Connection Button
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 18),
                label: const Text('آزمایش اتصال سرور', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // Save & Apply Button
              ElevatedButton(
                onPressed: _saveAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'ذخیره و اعمال تنظیمات',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // Restore Default Button
              OutlinedButton(
                onPressed: _resetToDefault,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryText,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('پیش‌فرض', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText)),
              ),

              const MobileFooter(compact: false),
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

  InputDecoration _inputDecoration({String? hint, Color? fillColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: fillColor ?? Colors.white,
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
