import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final _searchController = TextEditingController();
  String _selectedAction = 'همه عملیات‌ها';
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final rawLogs = await ApiService.getAuditLogs();
      final mapped = rawLogs.map<Map<String, dynamic>>((l) {
        return {
          'id': l['id'] ?? 0,
          'user': l['user_full_name'] ?? l['username'] ?? 'مدیر ارشد',
          'school': l['school_name'] ?? 'مدیریت مرکزی',
          'action': l['action'] ?? 'عملیات سامانه',
          'ip': l['ip_address'] ?? '127.0.0.1',
          'time': l['created_at_jalali'] ?? l['created_at'] ?? 'اخیراً',
          'details': l['details'] ?? l['description'] ?? 'عملیات موفقیت‌آمیز',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _logs = mapped;
        });
      }
    } catch (_) {
      // In clean database, keep empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _logs.where((l) {
      final matchesSearch = (l['user'] as String).toLowerCase().contains(search) ||
          (l['details'] as String).toLowerCase().contains(search) ||
          (l['action'] as String).toLowerCase().contains(search);
      final matchesAction = _selectedAction == 'همه عملیات‌ها' || l['action'] == _selectedAction;
      return matchesSearch && matchesAction;
    }).toList();

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
                const Icon(Icons.history_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاریخچه فعالیت‌ها و لاگ امنیتی سیستم (Audit Trail)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('ردیابی تغییرات، رخدادهای ورود، ثبت و لغو رزروها با ثبت زمان و آدرس IP کاربر در پایگاه داده', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadLogs,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('به‌روزرسانی تاریخچه', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'جستجو در لاگ‌ها بر اساس نام کاربر، عنوان عملیات یا جزئیات رویداد...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                    prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedAction,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'همه عملیات‌ها',
                    'ورود به سامانه',
                    'ثبت رزرو جدید',
                    'لغو رزرو',
                    'تغییر تنظیمات سرور',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAction = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audit Table or Clean Empty State
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
                    : filtered.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'هیچ رخدادی در تاریخچه سامانه ثبت نشده است.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'پایگاه داده در وضعیت خام قرار دارد. کلیه ورودها، ایجاد کاربران، ثبت و لغو رزروها پس از انجام به‌صورت خودکار در این جدول ذخیره می‌شوند.',
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
                                0: FlexColumnWidth(1.8),
                                1: FlexColumnWidth(1.4),
                                2: FlexColumnWidth(1.8),
                                3: FlexColumnWidth(1.1),
                                4: FlexColumnWidth(1.8),
                                5: FlexColumnWidth(3),
                              },
                              border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppColors.veryLightGreen),
                                  children: [
                                    Padding(padding: EdgeInsets.all(14), child: Text('کاربر اقدام‌کننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('مدرسه انتسابی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('عنوان عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('آدرس IP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('زمان رخداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('شرح و جزئیات رویداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                  ],
                                ),
                                ...filtered.map((log) {
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(14), child: Text(log['user'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.darkGreen))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(log['school'] as String, style: const TextStyle(fontSize: 12))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.pastelGreen,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            log['action'] as String,
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(log['ip'] as String, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(log['time'] as String, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(log['details'] as String, style: const TextStyle(fontSize: 12))),
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
}
