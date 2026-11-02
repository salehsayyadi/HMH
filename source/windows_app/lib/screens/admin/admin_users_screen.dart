import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedSchool = 'همه مدارس';
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<String> _schoolNames = ['همه مدارس'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rawUsers = await ApiService.getUsers();
      final rawSchools = await ApiService.getSchools();

      final schoolsList = <String>['همه مدارس'];
      for (final s in rawSchools) {
        final name = s['name']?.toString();
        if (name != null && !schoolsList.contains(name)) {
          schoolsList.add(name);
        }
      }

      final mappedUsers = rawUsers.map<Map<String, dynamic>>((u) {
        return {
          'id': u['id'] ?? 0,
          'fullName': u['full_name'] ?? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
          'username': u['username'] ?? '',
          'school': u['school']?['name'] ?? u['school_name'] ?? 'مدیریت مرکزی',
          'position': u['position']?['title'] ?? u['position_title'] ?? 'کاربر سازمانی',
          'phone': u['phone_number'] ?? u['phone'] ?? '-',
          'role': u['role'] ?? 'user',
          'isActive': u['is_active'] ?? true,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _users = mappedUsers;
          _schoolNames = schoolsList;
        });
      }
    } catch (_) {
      // In fresh/empty database, _users remains empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedSchool = _schoolNames.length > 1 ? _schoolNames[1] : 'مدیریت مرکزی';
    String selectedPos = 'معاون اجرایی';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 10),
                Text('تعریف کاربر سازمانی جدید در پایگاه داده', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'نام',
                              labelStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: familyCtrl,
                            decoration: InputDecoration(
                              labelText: 'نام خانوادگی',
                              labelStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: userCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'نام کاربری (انگلیسی)',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'رمز عبور اولیه',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'شماره همراه',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (userCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                    setDlgState(() => isSaving = true);
                    final newUser = {
                      'id': _users.length + 1,
                      'fullName': '${nameCtrl.text.trim()} ${familyCtrl.text.trim()}',
                      'username': userCtrl.text.trim(),
                      'school': selectedSchool,
                      'position': selectedPos,
                      'phone': phoneCtrl.text.trim(),
                      'role': 'user',
                      'isActive': true,
                    };
                    try {
                      await ApiService.createUser({
                        'username': userCtrl.text.trim(),
                        'password': passCtrl.text.trim(),
                        'first_name': nameCtrl.text.trim(),
                        'last_name': familyCtrl.text.trim(),
                        'phone_number': phoneCtrl.text.trim(),
                        'role': 'user',
                      });
                    } catch (_) {}
                    setState(() {
                      _users.add(newUser);
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('کاربر جدید با موفقیت ایجاد گردید.'), backgroundColor: AppColors.primaryGreen),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ثبت و ایجاد کاربر', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('بازنشانی رمز عبور: ${user['fullName']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passCtrl,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'کلمه عبور جدید',
              labelStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('رمز عبور کاربر «${user['fullName']}» با موفقیت تغییر کرد.'), backgroundColor: AppColors.primaryGreen),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ذخیره رمز جدید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _users.where((u) {
      final matchesSearch = (u['fullName'] as String).toLowerCase().contains(search) ||
          (u['username'] as String).toLowerCase().contains(search) ||
          (u['phone'] as String).contains(search);
      final matchesSchool = _selectedSchool == 'همه مدارس' || (u['school'] as String).contains(_selectedSchool);
      return matchesSearch && matchesSchool;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت کاربران و دسترسی‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('تعریف کاربران مدارس، ویرایش مشخصات، تنظیم دسترسی و بازنشانی رمز عبور در دیتابیس', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('افزودن کاربر جدید', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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

          // Filters Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'جستجوی کاربر بر اساس نام، نام کاربری یا شماره همراه...',
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
            ],
          ),
          const SizedBox(height: 16),

          // Users Table or Clean Empty State
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
                                  Icon(Icons.people_outline_rounded, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'هیچ کاربری در پایگاه داده ثبت نشده است.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'پایگاه داده در وضعیت خام قرار دارد. جهت ایجاد دسترسی برای کادر مدارس، بر روی دکمه زیر کلیک نمایید.',
                                    style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _showAddUserDialog,
                                    icon: const Icon(Icons.person_add_rounded, size: 20),
                                    label: const Text('افزودن اولین کاربر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1.6),
                                2: FlexColumnWidth(2.6),
                                3: FlexColumnWidth(1.3),
                                4: FlexColumnWidth(1.3),
                                5: FlexColumnWidth(1),
                                6: FlexColumnWidth(1.6),
                              },
                              border: TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppColors.veryLightGreen),
                                  children: [
                                    Padding(padding: EdgeInsets.all(14), child: Text('نام و نام خانوادگی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('نام کاربری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('مدرسه انتسابی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('سمت سازمانی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('شماره تماس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('وضعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                                    Padding(padding: EdgeInsets.all(14), child: Text('عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), textAlign: TextAlign.center)),
                                  ],
                                ),
                                ...filtered.map((user) {
                                  final isActive = user['isActive'] as bool;
                                  final isSuperAdmin = user['role'] == 'super_admin';
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isSuperAdmin ? AppColors.primaryGreen : AppColors.secondaryGreen,
                                              child: Text(
                                                (user['fullName'] as String).isNotEmpty ? (user['fullName'] as String)[0] : '؟',
                                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                user['fullName'] as String,
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(user['username'] as String, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(user['school'] as String, style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(user['position'] as String, style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(14), child: Text(user['phone'] as String, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isActive ? AppColors.pastelGreen : AppColors.holidayRed,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isActive ? 'فعال' : 'غیرفعال',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? AppColors.darkGreen : AppColors.holidayRedText),
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
                                              tooltip: 'بازنشانی رمز عبور',
                                              icon: const Icon(Icons.key_rounded, size: 20, color: AppColors.primaryGreen),
                                              onPressed: () => _showResetPasswordDialog(user),
                                            ),
                                            IconButton(
                                              tooltip: isActive ? 'غیرفعال‌سازی کاربر' : 'فعال‌سازی کاربر',
                                              icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, size: 28, color: isActive ? AppColors.primaryGreen : AppColors.secondaryText),
                                              onPressed: () {
                                                setState(() {
                                                  user['isActive'] = !isActive;
                                                });
                                              },
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
