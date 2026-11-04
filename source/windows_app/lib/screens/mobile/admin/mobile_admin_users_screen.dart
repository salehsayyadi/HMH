import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../common/mobile_top_bar.dart';
import '../common/mobile_footer.dart';
import '../common/mobile_confirm_dialog.dart';

class MobileAdminUsersScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MobileAdminUsersScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MobileAdminUsersScreen> createState() => _MobileAdminUsersScreenState();
}

class _MobileAdminUsersScreenState extends State<MobileAdminUsersScreen> {
  final primaryTeal = const Color(0xFF00594C);
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _users = [];
  List<dynamic> _schools = [];
  String _searchQuery = '';
  int? _selectedSchoolId;

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
        ApiService.getUsers(),
        ApiService.getSchools(),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0];
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

  List<dynamic> get _filteredUsers {
    return _users.where((u) {
      final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      final phone = (u['phone_number'] ?? '').toString();
      final query = _searchQuery.toLowerCase().trim();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          username.contains(query) ||
          phone.contains(query);

      final matchesSchool = _selectedSchoolId == null || u['school_id'] == _selectedSchoolId;

      return matchesQuery && matchesSchool;
    }).toList();
  }

  String _getSchoolName(dynamic schoolId) {
    if (schoolId == null) return 'مدیریت کل / بدون مدرسه';
    final s = _schools.firstWhere((item) => item['id'] == schoolId, orElse: () => null);
    return s != null ? s['name'] ?? '' : 'مدرسه نامشخص';
  }

  void _showAddUserSheet() {
    final nameCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int? selectedSchool = _schools.isNotEmpty ? _schools.first['id'] : null;
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                        const Text(
                          'مدیریت کل سامانه',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5A726D)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ثبت کاربر سازمانی جدید',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('نام', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'علی',
                                      filled: true,
                                      fillColor: const Color(0xFFF7FAF9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('نام خانوادگی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: familyCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'رضایی',
                                      filled: true,
                                      fillColor: const Color(0xFFF7FAF9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('نام کاربری (انگلیسی)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: usernameCtrl,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'ali.rezaei',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('رمز عبور اولیه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: true,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('شماره همراه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: '۰۹۱۳ ۰۰۰ ۰۰۰۰',
                            filled: true,
                            fillColor: const Color(0xFFF7FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('مدرسه انتسابی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD6E3DE)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedSchool,
                              items: _schools.map<DropdownMenuItem<int>>((s) {
                                return DropdownMenuItem<int>(
                                  value: s['id'],
                                  child: Text(s['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setSheetState(() => selectedSchool = val);
                              },
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
                                    if (nameCtrl.text.trim().isEmpty ||
                                        familyCtrl.text.trim().isEmpty ||
                                        usernameCtrl.text.trim().isEmpty ||
                                        passwordCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('لطفاً فیلدهای الزامی را تکمیل کنید.')),
                                      );
                                      return;
                                    }

                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      await ApiService.createUser({
                                        'first_name': nameCtrl.text.trim(),
                                        'last_name': familyCtrl.text.trim(),
                                        'username': usernameCtrl.text.trim(),
                                        'password': passwordCtrl.text.trim(),
                                        'phone_number': phoneCtrl.text.trim(),
                                        'school_id': selectedSchool,
                                        'role': 'user',
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _loadData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('کاربر جدید با موفقیت ایجاد شد.'),
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
                                : const Text(
                                    '+ ثبت و ایجاد کاربر',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
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

  void _showUserOperationsSheet(Map<String, dynamic> user) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final username = user['username'] ?? '';
    final schoolName = _getSchoolName(user['school_id']);
    final phone = user['phone_number'] ?? 'ثبت نشده';
    final isActive = user['is_active'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Directionality(
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
                      const Text(
                        'مدیریت کل سامانه',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5A726D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عملیات کاربر',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fullName · $schoolName',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF5A726D)),
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
                    children: [
                      _buildDetailRow('نام و نام خانوادگی', fullName),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      _buildDetailRow('نام کاربری', username),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      _buildDetailRow('مدرسه انتسابی', schoolName),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      _buildDetailRow('شماره تماس', phone),
                      const Divider(height: 16, color: Color(0xFFF0F4F2)),
                      _buildDetailRow('وضعیت', isActive ? 'فعال' : 'غیرفعال',
                          valueColor: isActive ? const Color(0xFF00796B) : Colors.red[700]),
                      const SizedBox(height: 20),
                      // Reset Password button (admin-07)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showResetPasswordDialog(user);
                        },
                        icon: const Icon(Icons.vpn_key_outlined, size: 18),
                        label: const Text('بازنشانی رمز عبور'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTeal,
                          side: BorderSide(color: primaryTeal.withOpacity(0.5)),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Toggle active button
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await ApiService.updateUser(user['id'], {'is_active': !isActive});
                            _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isActive
                                      ? 'کاربر با موفقیت غیرفعال شد.'
                                      : 'کاربر با موفقیت فعال شد.'),
                                  backgroundColor: const Color(0xFF00796B),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F4F2),
                          foregroundColor: const Color(0xFF1B2E2B),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isActive ? 'غیرفعال‌سازی کاربر' : 'فعال‌سازی کاربر'),
                      ),
                      const SizedBox(height: 10),
                      // Delete user button (admin-24)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteUser(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEBEE),
                          foregroundColor: const Color(0xFFC62828),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('حذف کاربر', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final passwordCtrl = TextEditingController();
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
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
                      const Text(
                        'مدیریت کل سامانه',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5A726D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بازنشانی رمز عبور',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(fullName, style: const TextStyle(fontSize: 13, color: Color(0xFF5A726D))),
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
                      const Text('کلمه عبور جدید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          filled: true,
                          fillColor: const Color(0xFFF7FAF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFD6E3DE)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (passwordCtrl.text.trim().isEmpty) return;
                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    await ApiService.updateUser(user['id'], {
                                      'password': passwordCtrl.text.trim(),
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('رمز عبور کاربر با موفقیت تغییر یافت.'),
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
                              : const Text('ذخیره رمز جدید', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _confirmDeleteUser(Map<String, dynamic> user) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    showDialog(
      context: context,
      builder: (ctx) => MobileConfirmDialog(
        title: 'حذف حساب کاربر',
        message: 'آیا از حذف کاربر «$fullName» اطمینان دارید؟ این عملیات قابل بازگشت نیست.',
        confirmLabel: 'حذف قطعی',
        cancelLabel: 'انصراف',
        isDanger: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await ApiService.deleteUser(user['id']);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('کاربر با موفقیت حذف گردید.'),
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
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7A928D)),
        ),
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
                                ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('تلاش مجدد'),
                                ),
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
                                      const Text(
                                        'مدیریت کل سامانه',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF5A726D)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'مدیریت کاربران و دسترسی‌ها',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'تعریف کاربران مدارس',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF5A726D)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Search Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'جستجوی کاربر',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B2E2B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                      decoration: InputDecoration(
                                        hintText: 'نام، نام کاربری یا شماره همراه',
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
                                // School Filter Dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFD6E3DE)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      isExpanded: true,
                                      value: _selectedSchoolId,
                                      hint: const Text('همه مدارس'),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('همه مدارس'),
                                        ),
                                        ..._schools.map((s) => DropdownMenuItem<int?>(
                                              value: s['id'],
                                              child: Text(s['name'] ?? ''),
                                            )),
                                      ],
                                      onChanged: (val) => setState(() => _selectedSchoolId = val),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Users Card Container (admin-04)
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
                                  child: _filteredUsers.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: Text(
                                              'کاربری یافت نشد.',
                                              style: TextStyle(color: Color(0xFF7A928D)),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: List.generate(_filteredUsers.length, (index) {
                                            final user = _filteredUsers[index];
                                            final isLast = index == _filteredUsers.length - 1;
                                            final fullName =
                                                '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                                            final schoolName = _getSchoolName(user['school_id']);
                                            final username = user['username'] ?? '';
                                            final isActive = user['is_active'] == true;

                                            return Column(
                                              children: [
                                                ListTile(
                                                  onTap: () => _showUserOperationsSheet(user),
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0F7F5),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.person_outline_rounded,
                                                      color: primaryTeal,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    fullName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1B2E2B),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '$username · $schoolName',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF7A928D),
                                                    ),
                                                  ),
                                                  trailing: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? const Color(0xFFE8F5F1)
                                                          : const Color(0xFFECEFF1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      isActive ? 'فعال' : 'غیرفعال',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isActive
                                                          ? const Color(0xFF00796B)
                                                          : const Color(0xFF546E7A),
                                                      ),
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                // Add User Button
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _showAddUserSheet,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTeal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ ثبت کاربر جدید',
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
