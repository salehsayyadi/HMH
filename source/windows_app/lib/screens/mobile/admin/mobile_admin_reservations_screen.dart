import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';

class MobileAdminReservationsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminReservationsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminReservationsScreen> createState() => _MobileAdminReservationsScreenState();
}

class _MobileAdminReservationsScreenState extends State<MobileAdminReservationsScreen> {
  final primaryTeal = const Color(0xFF00594C);
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _reservations = [];
  List<dynamic> _schools = [];
  String _searchQuery = '';
  int? _selectedSchoolId;
  String _selectedStatus = 'all';

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
        ApiService.getReservations(),
        ApiService.getSchools(),
      ]);
      if (mounted) {
        setState(() {
          _reservations = results[0];
          _schools = results[1];
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

  List<dynamic> get _filteredReservations {
    return _reservations.where((r) {
      final title = (r['title'] ?? r['description'] ?? '').toString().toLowerCase();
      final schoolName = (r['school_name'] ?? (r['school'] is Map ? r['school']['name'] : '') ?? '').toString().toLowerCase();
      final userName = (r['user_name'] ?? (r['user'] is Map ? '${r['user']['first_name']} ${r['user']['last_name']}' : '') ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          schoolName.contains(query) ||
          userName.contains(query);

      final schoolId = r['school_id'] ?? (r['school'] is Map ? r['school']['id'] : null);
      final matchesSchool = _selectedSchoolId == null || schoolId == _selectedSchoolId;

      final status = (r['status'] ?? 'approved').toString().toLowerCase();
      final isCancelled = status == 'cancelled' || status == 'canceled';
      final matchesStatus = _selectedStatus == 'all' ||
          (_selectedStatus == 'approved' && !isCancelled) ||
          (_selectedStatus == 'cancelled' && isCancelled);

      return matchesQuery && matchesSchool && matchesStatus;
    }).toList();
  }

  void _showReservationDetailsSheet(Map<String, dynamic> reservation) {
    final id = reservation['id'];
    final schoolName = reservation['school_name'] ??
        (reservation['school'] is Map ? reservation['school']['name'] : 'مدرسه نامشخص');
    final userName = reservation['user_name'] ??
        (reservation['user'] is Map ? '${reservation['user']['first_name']} ${reservation['user']['last_name']}' : 'کاربر نامشخص');
    final userPhone = reservation['user_phone'] ??
        (reservation['user'] is Map ? reservation['user']['phone_number'] : '') ?? '';
    final jalaliDate = reservation['jalali_date'] ?? reservation['reservation_date'] ?? '';
    final timeSlot = reservation['time_slot_title'] ??
        (reservation['time_slot'] is Map ? reservation['time_slot']['title'] : '۰۸:۰۰ - ۱۰:۰۰');
    final title = reservation['title'] ?? reservation['description'] ?? 'رزرو سالن';
    final status = (reservation['status'] ?? 'approved').toString().toLowerCase();
    final isCancelled = status == 'cancelled' || status == 'canceled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      'جزئیات کامل رزرو',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                    ),
                    const SizedBox(height: 4),
                    Text('رزرو شماره $id', style: const TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EBE8)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('مدرسه متقاضی', schoolName),
                    const Divider(height: 16, color: Color(0xFFF0F4F2)),
                    _buildDetailRow(
                      'کاربر ثبت‌کننده',
                      userPhone.isNotEmpty ? '$userName · $userPhone' : userName,
                    ),
                    const Divider(height: 16, color: Color(0xFFF0F4F2)),
                    _buildDetailRow('تاریخ رزرو', jalaliDate),
                    const Divider(height: 16, color: Color(0xFFF0F4F2)),
                    _buildDetailRow('بازه زمانی', timeSlot),
                    const Divider(height: 16, color: Color(0xFFF0F4F2)),
                    _buildDetailRow('عنوان رویداد', title),
                    const Divider(height: 16, color: Color(0xFFF0F4F2)),
                    _buildDetailRow(
                      'وضعیت فعلی',
                      isCancelled ? 'لغو شده' : 'تأیید شده',
                      valueColor: isCancelled ? Colors.red[700] : const Color(0xFF00796B),
                    ),
                    const SizedBox(height: 20),
                    if (!isCancelled) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCancelReasonDialog(reservation);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            foregroundColor: const Color(0xFFC62828),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('لغو رزرو توسط مدیریت', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F4F2),
                          foregroundColor: const Color(0xFF5A726D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('بستن'),
                      ),
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

  void _showCancelReasonDialog(Map<String, dynamic> reservation) {
    final reasonCtrl = TextEditingController();
    final id = reservation['id'];
    final schoolName = reservation['school_name'] ??
        (reservation['school'] is Map ? reservation['school']['name'] : '');
    final jalaliDate = reservation['jalali_date'] ?? '';
    final timeSlot = reservation['time_slot_title'] ?? '';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text('مدیریت کل سامانه', style: TextStyle(fontSize: 12, color: Color(0xFF5A726D))),
                      const SizedBox(height: 4),
                      Text(
                        'لغو رزرو شماره $id',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2EBE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('مدرسه', schoolName),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      _buildDetailRow('تاریخ و زمان', '$jalaliDate · $timeSlot'),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      const Text('علت لغو رزرو (الزامی)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonCtrl,
                        decoration: InputDecoration(
                          hintText: 'دلیل لغو این رزرو توسط مدیریت',
                          filled: true,
                          fillColor: const Color(0xFFF7FAF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final reason = reasonCtrl.text.trim();
                                  if (reason.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('لطفاً علت لغو رزرو را وارد کنید.')),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    await ApiService.cancelReservation(id, reason: reason);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _loadData();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('رزرو با موفقیت توسط مدیریت لغو گردید.'),
                                          backgroundColor: Color(0xFF00796B),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSubmitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red[700],
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            foregroundColor: const Color(0xFFC62828),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Color(0xFFC62828), strokeWidth: 2),
                                )
                              : const Text('تأیید لغو رزرو', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF0F4F2),
                            foregroundColor: const Color(0xFF5A726D),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('انصراف'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1B2E2B),
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF7A928D))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                        'مدیریت رزروها',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('کلیه رزروهای آمفی‌تئاتر', style: TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Search Input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('جستجو در رزروها', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                      decoration: InputDecoration(
                                        hintText: 'نام مدرسه، کاربر یا موضوع',
                                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8BA09B)),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // 2 Filter Dropdowns
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFD6E3DE)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int?>(
                                            isExpanded: true,
                                            value: _selectedSchoolId,
                                            hint: const Text('همه مدارس', style: TextStyle(fontSize: 13)),
                                            items: [
                                              const DropdownMenuItem<int?>(value: null, child: Text('همه مدارس')),
                                              ..._schools.map((s) => DropdownMenuItem<int?>(
                                                    value: s['id'],
                                                    child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 13)),
                                                  )),
                                            ],
                                            onChanged: (val) => setState(() => _selectedSchoolId = val),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFD6E3DE)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: _selectedStatus,
                                            items: const [
                                              DropdownMenuItem(value: 'all', child: Text('همه وضعیت‌ها', style: TextStyle(fontSize: 13))),
                                              DropdownMenuItem(value: 'approved', child: Text('تأیید شده', style: TextStyle(fontSize: 13))),
                                              DropdownMenuItem(value: 'cancelled', child: Text('لغو شده', style: TextStyle(fontSize: 13))),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedStatus = val);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Reservations List Container (admin-11)
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
                                  child: _filteredReservations.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: Text('هیچ رزروی یافت نشد.', style: TextStyle(color: Color(0xFF7A928D))),
                                          ),
                                        )
                                      : Column(
                                          children: List.generate(_filteredReservations.length, (index) {
                                            final r = _filteredReservations[index];
                                            final isLast = index == _filteredReservations.length - 1;
                                            final title = r['title'] ?? r['description'] ?? 'رزرو سالن';
                                            final schoolName = r['school_name'] ??
                                                (r['school'] is Map ? r['school']['name'] : 'مدرسه نامشخص');
                                            final jalaliDate = r['jalali_date'] ?? '';
                                            final status = (r['status'] ?? 'approved').toString().toLowerCase();
                                            final isCancelled = status == 'cancelled' || status == 'canceled';

                                            return Column(
                                              children: [
                                                ListTile(
                                                  onTap: () => _showReservationDetailsSheet(r),
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0F7F5),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.calendar_today_outlined,
                                                      color: primaryTeal,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1B2E2B),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '$jalaliDate · $schoolName',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A928D)),
                                                  ),
                                                  trailing: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isCancelled
                                                          ? const Color(0xFFFFEBEE)
                                                          : const Color(0xFFE8F5F1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      isCancelled ? 'لغو شده' : 'تأیید شده',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCancelled
                                                            ? const Color(0xFFC62828)
                                                            : const Color(0xFF00796B),
                                                      ),
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                ),
                                                if (!isLast)
                                                  const Divider(
                                                    height: 1,
                                                    indent: 16,
                                                    endIndent: 16,
                                                    color: Color(0xFFEBF2F0),
                                                  ),
                                              ],
                                            );
                                          }),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                // Refresh Button
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _loadData,
                                    icon: const Icon(Icons.refresh_rounded, size: 20),
                                    label: const Text(
                                      'به‌روزرسانی رزروها',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryTeal,
                                      side: const BorderSide(color: Color(0xFF00594C)),
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
}
