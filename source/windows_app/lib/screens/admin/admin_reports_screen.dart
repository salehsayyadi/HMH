import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'سه ماهه اخیر (فصل پاییز)';

  final List<Map<String, dynamic>> _reportData = [
    {'school': 'دبیرستان پسرانه دوره دوم امام حسین (ع)', 'total': 15, 'hours': 30, 'cancelled': 0, 'efficiency': '۹۵٪'},
    {'school': 'دبستان پسرانه امام حسین (ع)', 'total': 14, 'hours': 28, 'cancelled': 0, 'efficiency': '۹۱٪'},
    {'school': 'دبیرستان دخترانه دوره اول امام حسین (ع)', 'total': 12, 'hours': 24, 'cancelled': 1, 'efficiency': '۸۴٪'},
    {'school': 'دبستان دخترانه امام حسین (ع)', 'total': 11, 'hours': 22, 'cancelled': 0, 'efficiency': '۸۰٪'},
    {'school': 'دبیرستان دخترانه دوره دوم امام حسین (ع)', 'total': 8, 'hours': 16, 'cancelled': 1, 'efficiency': '۶۵٪'},
    {'school': 'دبیرستان پسرانه دوره اول امام حسین (ع)', 'total': 7, 'hours': 14, 'cancelled': 1, 'efficiency': '۵۸٪'},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('گزارش‌ها و تحلیل آماری عملکرد مدارس', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('تحلیل جامع استفاده مدارس از سالن آمفی‌تئاتر مرکزی و خروجی گزارش اکسل', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('فایل گزارش اکسل (XLSX) با موفقیت در پوشه دانلودها ذخیره شد.'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('خروجی اکسل (Excel)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Period Filter
          Row(
            children: [
              const Text('بازه گزارش‌گیری:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'ماه جاری (آبان ۱۴۰۵)',
                    'سه ماهه اخیر (فصل پاییز)',
                    'نیم‌سال اول تحصیلی',
                    'کل سال تحصیلی ۱۴۰۳-۱۴۰۴',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPeriod = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Stats Cards
          Row(
            children: [
              _buildReportCard('مجموع ساعات رزرو شده', '۱۳۴ ساعت', Icons.access_time_rounded, AppColors.primaryGreen),
              const SizedBox(width: 14),
              _buildReportCard('کل رزروهای نهایی', '۶۷ سانس', Icons.event_available_rounded, const Color(0xFF1554A3)),
              const SizedBox(width: 14),
              _buildReportCard('میانگین بهره‌وری مدارس', '۷۹.۸٪', Icons.trending_up_rounded, AppColors.secondaryGreen),
              const SizedBox(width: 14),
              _buildReportCard('تعداد کل کنسلی‌ها', '۳ سانس', Icons.cancel_outlined, AppColors.holidayRedText),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
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
                          Padding(padding: EdgeInsets.all(12), child: Text('نام مدرسه تابعه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('تعداد کل رزروها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                          Padding(padding: EdgeInsets.all(12), child: Text('ساعات استفاده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                          Padding(padding: EdgeInsets.all(12), child: Text('لغوشده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                          Padding(padding: EdgeInsets.all(12), child: Text('درصد بهره‌وری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                        ],
                      ),
                      ..._reportData.map((d) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(12), child: Text(d['school'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.darkGreen))),
                            Padding(padding: const EdgeInsets.all(12), child: Text('${d['total']} سانس', style: const TextStyle(fontSize: 11.5), textAlign: TextAlign.center)),
                            Padding(padding: const EdgeInsets.all(12), child: Text('${d['hours']} ساعت', style: const TextStyle(fontSize: 11.5), textAlign: TextAlign.center)),
                            Padding(padding: const EdgeInsets.all(12), child: Text('${d['cancelled']}', style: const TextStyle(fontSize: 11.5, color: AppColors.holidayRedText), textAlign: TextAlign.center)),
                            Padding(padding: const EdgeInsets.all(12), child: Text(d['efficiency'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen), textAlign: TextAlign.center)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText), overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
