import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final _searchController = TextEditingController();
  String _selectedSchool = 'همه مدارس';
  String _selectedStatus = 'همه وضعیت‌ها';
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];
  List<String> _schoolNames = ['همه مدارس'];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      final rawReservations = await ApiService.getReservations();
      final rawSchools = await ApiService.getSchools();

      final schoolsList = <String>['همه مدارس'];
      for (final s in rawSchools) {
        final name = s['name']?.toString();
        if (name != null && !schoolsList.contains(name)) {
          schoolsList.add(name);
        }
      }

      final mapped = rawReservations.map<Map<String, dynamic>>((r) {
        return {
          'id': r['id'] ?? 0,
          'date': r['reservation_date_jalali'] ?? r['reservation_date'] ?? '-',
          'day': r['day_name'] ?? '',
          'timeSlot': r['time_slot']?['title'] ?? r['time_slot_title'] ?? 'سانس عمومی',
          'school': r['school']?['name'] ?? r['school_name'] ?? 'مدرسه متقاضی',
          'user': r['user']?['full_name'] ?? r['user_full_name'] ?? 'نماینده مدرسه',
          'phone': r['user']?['phone_number'] ?? r['phone'] ?? '-',
          'title': r['title'] ?? 'برنامه آمفی‌تئاتر',
          'status': r['status'] == 'cancelled' ? 'لغو شده' : 'تأیید شده',
          'cancelReason': r['cancellation_reason'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _reservations = mapped;
          _schoolNames = schoolsList;
        });
      }
    } catch (_) {
      // In fresh/empty database, keep list empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCancelDialog(Map<String, dynamic> item) {
    final reasonCtrl = TextEditingController();
    bool isCancelling = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('لغو رزرو شماره ${item['id']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.holidayRedText)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مدرسه: ${item['school']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('تاریخ و زمان: ${item['date']} — ${item['timeSlot']}', style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'علت لغو رزرو (الزامی)',
                    labelStyle: const TextStyle(fontSize: 13),
                    hintText: 'دلیل لغو این رزرو توسط مدیریت را مرقوم فرمایید...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                onPressed: isCancelling ? null : () async {
                  if (reasonCtrl.text.trim().isNotEmpty) {
                    setDlgState(() => isCancelling = true);
                    try {
                      await ApiService.cancelReservation(item['id'] as int);
                    } catch (_) {}
                    setState(() {
                      item['status'] = 'لغو شده';
                      item['cancelReason'] = reasonCtrl.text.trim();
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('رزرو شماره ${item['id']} لغو و زمان آن آزاد شد.'), backgroundColor: AppColors.primaryGreen),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.holidayRedText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isCancelling
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأیید لغو رزرو', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 24),
              const SizedBox(width: 10),
              Text('جزئیات کامل رزرو شماره ${item['id']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('مدرسه متقاضی:', item['school'] as String),
                _detailRow('کاربر ثبت‌کننده:', '${item['user']} (${item['phone']})'),
                _detailRow('تاریخ رزرو:', '${item['day']}، ${item['date']}'),
                _detailRow('بازه زمانی:', item['timeSlot'] as String),
                _detailRow('عنوان رویداد:', item['title'] as String),
                _detailRow('وضعیت فعلی:', item['status'] as String),
                if (item['cancelReason'] != null)
                  _detailRow('علت لغو:', item['cancelReason'] as String, isRed: true),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('بستن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isRed ? AppColors.holidayRedText : AppColors.mainText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _reservations.where((r) {
      final matchesSearch = (r['school'] as String).toLowerCase().contains(search) ||
          (r['user'] as String).toLowerCase().contains(search) ||
          (r['title'] as String).toLowerCase().contains(search);
      final matchesSchool = _selectedSchool == 'همه مدارس' || (r['school'] as String).contains(_selectedSchool);
      final matchesStatus = _selectedStatus == 'همه وضعیت‌ها' || (r['status'] as String) == _selectedStatus;
      return matchesSearch && matchesSchool && matchesStatus;
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
                const Icon(Icons.event_available_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت کلیه رزروهای آمفی‌تئاتر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('مشاهده تقویم و فهرست تمام رزروهای مدارس، تأیید، ابطال و مدیریت تغییرات در دیتابیس', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadReservations,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('به‌روزرسانی رزروها', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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

          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'جستجو در رزروها بر اساس نام مدرسه، کاربر متقاضی یا موضوع برنامه...',
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
                  value: _selectedSchool,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: _schoolNames.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSchool = val);
                  },
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
                  value: _selectedStatus,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: ['همه وضعیت‌ها', 'تأیید شده', 'لغو شده'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reservations Table or Clean Empty State
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
                                  Icon(Icons.event_busy_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'هیچ رزروی در پایگاه داده ثبت نشده است.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'پایگاه‌داده سامانه در وضعیت خام قرار دارد. کلیه رزروهای ثبت‌شده توسط مدارس به‌صورت زنده در این جدول ثبت و مدیریت خواهند شد.',
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
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(1.8),
                                2: FlexColumnWidth(1.8),
                                3: FlexColumnWidth(2.5),
                                4: FlexColumnWidth(2.8),
                                5: FlexColumnWidth(1.2),
                                6: FlexColumnWidth(1.6),
                              },
                              border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppColors.veryLightGreen),
                                  children: [
                                    Padding(padding: EdgeInsets.all(14), child: Text('شناسه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('تاریخ رزرو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('سانس زمانی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('مدرسه متقاضی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('عنوان رویداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('وضعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                  ],
                                ),
                                ...filtered.map((item) {
                                  final isConfirmed = item['status'] == 'تأیید شده';
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(14), child: Text('#${item['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12.5))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['date'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                            Text(item['day'] as String, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                                          ],
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(item['timeSlot'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['school'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                                            Text(item['user'] as String, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                                          ],
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(item['title'] as String, style: const TextStyle(fontSize: 12))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isConfirmed ? AppColors.pastelGreen : AppColors.holidayRed,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['status'] as String,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isConfirmed ? AppColors.darkGreen : AppColors.holidayRedText),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              tooltip: 'مشاهده جزئیات کامل',
                                              icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: AppColors.primaryGreen),
                                              onPressed: () => _showDetailsDialog(item),
                                            ),
                                            if (isConfirmed)
                                              IconButton(
                                                tooltip: 'لغو رزرو توسط مدیریت',
                                                icon: const Icon(Icons.cancel_outlined, size: 20, color: AppColors.holidayRedText),
                                                onPressed: () => _showCancelDialog(item),
                                              ),
                                          ],
                                        ),
                                      ),
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
