import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_confirm_dialog.dart';

class MobileAdminSchoolsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminSchoolsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminSchoolsScreen> createState() => _MobileAdminSchoolsScreenState();
}

class _MobileAdminSchoolsScreenState extends State<MobileAdminSchoolsScreen> {
  final primaryTeal = const Color(0xFF00594C);
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _schools = [];
  List<dynamic> _users = [];
  List<dynamic> _reservations = [];

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
        ApiService.getSchools(),
        ApiService.getUsers(),
        ApiService.getReservations(),
      ]);
      if (mounted) {
        setState(() {
          _schools = results[0];
          _users = results[1];
          _reservations = results[2];
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

  int _getUserCountForSchool(int schoolId) {
    return _users.where((u) => u['school_id'] == schoolId).length;
  }

  int _getReservationCountForSchool(int schoolId) {
    return _reservations.where((r) => r['school_id'] == schoolId).length;
  }

  void _showAddSchoolSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final managerCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Directionality(
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
            child: SingleChildScrollView(
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
                          'ثبت واحد آموزشی جدید',
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
                        const Text('نام مدرسه یا واحد آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'دبستان پسرانه امام حسین (ع)',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('شماره تماس', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: '۰۳۵-۳۰۰۰۰۰۰۰',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('نام مدیر مدرسه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: managerCtrl,
                          decoration: InputDecoration(
                            hintText: 'نام و نام خانوادگی مدیر',
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
                                    if (nameCtrl.text.trim().isEmpty) return;
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final code = 'SCH-${DateTime.now().millisecondsSinceEpoch % 10000}';
                                      await ApiService.createSchool({
                                        'name': nameCtrl.text.trim(),
                                        'code': code,
                                        'phone': phoneCtrl.text.trim(),
                                        'description': managerCtrl.text.trim(),
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _loadData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('واحد آموزشی با موفقیت ثبت شد.'),
                                            backgroundColor: Color(0xFF00796B),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSubmitting = false);
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
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('ثبت در سامانه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      ),
    );
  }

  void _showEditSchoolSheet(Map<String, dynamic> school) {
    final nameCtrl = TextEditingController(text: school['name'] ?? '');
    final phoneCtrl = TextEditingController(text: school['phone'] ?? '');
    final managerCtrl = TextEditingController(text: school['description'] ?? '');
    final addressCtrl = TextEditingController(text: school['address'] ?? 'یزد');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Directionality(
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
            child: SingleChildScrollView(
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
                          'ویرایش واحد آموزشی',
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
                        const Text('نام مدرسه یا واحد آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('شماره تماس', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('نام مدیر یا نماینده مدرسه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: managerCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('آدرس واحد آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(
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
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      await ApiService.updateSchool(school['id'], {
                                        'name': nameCtrl.text.trim(),
                                        'phone': phoneCtrl.text.trim(),
                                        'description': managerCtrl.text.trim(),
                                        'address': addressCtrl.text.trim(),
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _loadData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('اطلاعات مدرسه با موفقیت ویرایش شد.'),
                                            backgroundColor: Color(0xFF00796B),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSubmitting = false);
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
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('ذخیره تغییرات', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Delete school button (admin-25)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteSchool(school);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEE),
                              foregroundColor: const Color(0xFFC62828),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('حذف مدرسه', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  void _confirmDeleteSchool(Map<String, dynamic> school) {
    final schoolName = school['name'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => MobileConfirmDialog(
        title: 'حذف واحد آموزشی',
        message:
            'آیا از حذف واحد آموزشی «$schoolName» اطمینان دارید؟ تمامی رزروها و کاربران متصل به این واحد نیز تحت تأثیر قرار خواهند گرفت.',
        confirmLabel: 'حذف قطعی',
        cancelLabel: 'انصراف',
        isDanger: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await ApiService.deleteSchool(school['id']);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('واحد آموزشی با موفقیت حذف گردید.'),
                  backgroundColor: Color(0xFF00796B),
                ),
              );
            }
          } catch (e) {
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
      ),
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
                                        'مدیریت مدارس',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'مدارس و واحدهای آموزشی موسسه',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF5A726D)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                  child: _schools.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: Text('هیچ واحد آموزشی ثبت نشده است.',
                                                style: TextStyle(color: Color(0xFF7A928D))),
                                          ),
                                        )
                                      : Column(
                                          children: List.generate(_schools.length, (index) {
                                            final school = _schools[index];
                                            final isLast = index == _schools.length - 1;
                                            final userCount = _getUserCountForSchool(school['id']);
                                            final resCount = _getReservationCountForSchool(school['id']);

                                            return Column(
                                              children: [
                                                ListTile(
                                                  onTap: () => _showEditSchoolSheet(school),
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0F7F5),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.school_outlined,
                                                      color: primaryTeal,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    school['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1B2E2B),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    'مدیر مدرسه · $userCount کاربر · $resCount رزرو',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF7A928D),
                                                    ),
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.chevron_left_rounded,
                                                    color: Color(0xFF8BA09B),
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
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _showAddSchoolSheet,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTeal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ ثبت واحد آموزشی جدید',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
