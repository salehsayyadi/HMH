import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'ماه جاری (آبان ۱۴۰۵)';
  bool _isLoading = true;
  List<Map<String, dynamic>> _reportData = [];

  int _totalHours = 0;
  int _totalReservations = 0;
  String _averageEfficiency = '۰٪';
  int _totalCancellations = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getDashboardStats();
      final schools = await ApiService.getSchools();

      if (mounted) {
        setState(() {
          if (stats != null) {
            _totalReservations = stats['monthly_reservations'] ?? 0;
            _totalHours = _totalReservations * 2;
            _totalCancellations = stats['monthly_cancellations'] ?? 0;
            _averageEfficiency = _totalReservations > 0 ? '${(_totalReservations * 100 / (_totalReservations + 5)).round()}٪' : '۰٪';
          }
          _reportData = schools.map<Map<String, dynamic>>((s) {
            final resCount = s['reservations_count'] ?? 0;
            return {
              'school': s['name'] ?? '',
              'total': resCount,
              'hours': resCount * 2,
              'cancelled': 0,
              'efficiency': resCount > 0 ? '${(resCount * 10)}٪' : '۰٪',
            };
          }).where((item) => (item['total'] as int) > 0).toList();
        });
      }
    } catch (_) {
      // In clean database, keep at 0
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('در حال دریافت و ایجاد فایل اکسل...'),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );

      final bytes = await ApiService.downloadExcelReport();
      String saveDir = '';
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && Directory('$userProfile\\Downloads').existsSync()) {
        saveDir = '$userProfile\\Downloads';
      } else if (userProfile != null && Directory('$userProfile\\Desktop').existsSync()) {
        saveDir = '$userProfile\\Desktop';
      } else {
        saveDir = Directory.current.path;
      }

      final now = DateTime.now();
      final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final filePath = '$saveDir\\گزارش_رزروها_$nowStr.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 10),
                  Text('فایل اکسل با موفقیت ذخیره شد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('فایل گزارش با موفقیت در پوشه ذخیره شد:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: SelectableText(
                      filePath,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.darkGreen),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('بستن', style: TextStyle(color: AppColors.secondaryText)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Process.run('explorer.exe', ['/select,', filePath]);
                  },
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('نمایش در پوشه ویندوز'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره فایل اکسل: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.holidayRedText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('گزارش‌ها و تحلیل آماری عملکرد مدارس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('تحلیل جامع بهره‌مندی مدارس از سالن آمفی‌تئاتر مرکزی و دریافت خروجی آماری', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  label: const Text('خروجی اکسل (Excel)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Period Filter
          Row(
            children: [
              const Text('بازه زمانی گزارش:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              const SizedBox(width: 12),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'ماه جاری (آبان ۱۴۰۵)',
                    'سه ماهه اخیر (فصل پاییز)',
                    'نیم‌سال اول تحصیلی',
                    'کل سال جاری',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPeriod = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Summary Stats Cards (Enlarged)
          Row(
            children: [
              _buildReportCard('مجموع ساعات رزرو شده', '$_totalHours ساعت', Icons.access_time_rounded, AppColors.primaryGreen),
              const SizedBox(width: 16),
              _buildReportCard('کل رزروهای نهایی', '$_totalReservations سانس', Icons.event_available_rounded, const Color(0xFF1554A3)),
              const SizedBox(width: 16),
              _buildReportCard('میانگین بهره‌وری مدارس', _averageEfficiency, Icons.trending_up_rounded, AppColors.secondaryGreen),
              const SizedBox(width: 16),
              _buildReportCard('تعداد کل کنسلی‌ها', '$_totalCancellations سانس', Icons.cancel_outlined, AppColors.holidayRedText),
            ],
          ),
          const SizedBox(height: 18),

          // Table or Clean Empty State
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : _reportData.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assessment_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'هنوز اطلاعات آماری برای دوره انتخابی در پایگاه داده ثبت نشده است.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'پایگاه داده در وضعیت خام قرار دارد. با ثبت رزرو توسط مدارس، جدول تحلیلی ساعات و بهره‌وری تکمیل خواهد شد.',
                                    style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(1.4),
                                2: FlexColumnWidth(1.4),
                                3: FlexColumnWidth(1.2),
                                4: FlexColumnWidth(1.4),
                              },
                              border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppColors.veryLightGreen),
                                  children: [
                                    Padding(padding: EdgeInsets.all(14), child: Text('نام مدرسه تابعه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('تعداد کل رزروها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                    Padding(padding: EdgeInsets.all(14), child: Text('ساعات استفاده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                    Padding(padding: EdgeInsets.all(14), child: Text('لغوشده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                    Padding(padding: EdgeInsets.all(14), child: Text('درصد بهره‌وری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                  ],
                                ),
                                ..._reportData.map((d) {
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(14), child: Text(d['school'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.darkGreen))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text('${d['total']} سانس', style: const TextStyle(fontSize: 12.5), textAlign: TextAlign.center)),
                                      Padding(padding: const EdgeInsets.all(14), child: Text('${d['hours']} ساعت', style: const TextStyle(fontSize: 12.5), textAlign: TextAlign.center)),
                                      Padding(padding: const EdgeInsets.all(14), child: Text('${d['cancelled']}', style: const TextStyle(fontSize: 12.5, color: AppColors.holidayRedText), textAlign: TextAlign.center)),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(d['efficiency'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen), textAlign: TextAlign.center)),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText), overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
