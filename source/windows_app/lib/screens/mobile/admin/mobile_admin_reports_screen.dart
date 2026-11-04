import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';

class MobileAdminReportsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminReportsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminReportsScreen> createState() => _MobileAdminReportsScreenState();
}

class _MobileAdminReportsScreenState extends State<MobileAdminReportsScreen> {
  final primaryTeal = const Color(0xFF00594C);
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _schools = [];
  List<dynamic> _reservations = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getSchools(),
        ApiService.getReservations(),
      ]);
      if (mounted) {
        setState(() {
          _dashboardStats = results[0] as Map<String, dynamic>?;
          _schools = results[1] as List<dynamic>;
          _reservations = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ApiService.downloadExcelReport();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/IMH_Report_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() => _isExporting = false);
        _showExcelSavedDialog(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت فایل اکسل: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _showExcelSavedDialog(String filePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text('مدیریت کل سامانه', style: TextStyle(fontSize: 12, color: Color(0xFF5A726D))),
                    const SizedBox(height: 4),
                    Text(
                      'خروجی اکسل',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                    ),
                    const SizedBox(height: 4),
                    const Text('گزارش‌ها و تحلیل آماری', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EBE8)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'فایل اکسل با موفقیت ذخیره شد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'فایل گزارش آماده مشاهده است.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5A726D)),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        OpenFilex.open(filePath);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: const BorderSide(color: Color(0xFF00594C)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('نمایش در پوشه / باز کردن فایل', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F4F2),
                        foregroundColor: const Color(0xFF5A726D),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('بستن'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derived stats
    final totalApproved = _reservations.where((r) {
      final s = (r['status'] ?? 'approved').toString().toLowerCase();
      return s != 'cancelled' && s != 'canceled';
    }).length;

    final totalCancelled = _reservations.where((r) {
      final s = (r['status'] ?? 'approved').toString().toLowerCase();
      return s == 'cancelled' || s == 'canceled';
    }).length;

    final totalHours = totalApproved * 2;
    final totalAttempts = totalApproved + totalCancelled;
    final efficiency = totalAttempts > 0 ? ((totalApproved / totalAttempts) * 100).toInt() : 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              MobileTopBar(onLogout: widget.onLogout),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadData, child: const Text('تلاش مجدد')),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
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
                                        'گزارش‌ها و تحلیل آماری',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('عملکرد مدارس در سالن آمفی‌تئاتر', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Month Indicator Pill (admin-19)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFD6E3DE)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ماه جاری (سال تحصیلی)',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B2E2B)),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5A726D)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 4 Stat Cards in 2x2 Grid (admin-19)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        'مجموع ساعات رزرو شده',
                                        '$totalHours',
                                        'ساعت',
                                        primaryTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        'کل رزروهای نهایی',
                                        '$totalApproved',
                                        'سانس',
                                        primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        'میانگین بهره‌وری مدارس',
                                        '$efficiency٪',
                                        '',
                                        primaryTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        'تعداد کل کنسلی‌ها',
                                        '$totalCancelled',
                                        'سانس',
                                        const Color(0xFFC62828),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // School Stats Container (admin-19)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2EBE8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 8),
                                        child: Text(
                                          'آمار مدارس',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B2E2B)),
                                        ),
                                      ),
                                      if (_schools.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: Text('اطلاعاتی ثبت نشده است.', style: TextStyle(color: Color(0xFF7A928D))),
                                          ),
                                        )
                                      else
                                        ...List.generate(_schools.length, (index) {
                                          final school = _schools[index];
                                          final isLast = index == _schools.length - 1;
                                          final sId = school['id'];
                                          final schoolRes = _reservations.where((r) => r['school_id'] == sId).toList();
                                          final appRes = schoolRes.where((r) {
                                            final st = (r['status'] ?? 'approved').toString().toLowerCase();
                                            return st != 'cancelled' && st != 'canceled';
                                          }).length;
                                          final cancRes = schoolRes.length - appRes;
                                          final hrs = appRes * 2;
                                          final pct = totalApproved > 0 ? ((appRes / totalApproved) * 100).toInt() : 0;

                                          return Column(
                                            children: [
                                              ListTile(
                                                leading: Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0F7F5),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(Icons.school_outlined, color: primaryTeal, size: 20),
                                                ),
                                                title: Text(
                                                  school['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1B2E2B),
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '$appRes رزرو · $hrs ساعت · ${cancRes > 0 ? "$cancRes لغو شده" : "بدون لغو"}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF7A928D)),
                                                ),
                                                trailing: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE8F5F1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '$pct٪',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryTeal,
                                                    ),
                                                  ),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              ),
                                              if (!isLast)
                                                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEBF2F0)),
                                            ],
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Export Excel Button (admin-19)
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _isExporting ? null : _exportExcel,
                                    icon: _isExporting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.file_download_outlined, size: 20),
                                    label: const Text(
                                      'خروجی اکسل (Excel)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTeal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
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

  Widget _buildMetricCard(String title, String value, String unit, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF7A928D))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7A928D)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
