import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedSchool = 'همه مدارس';

  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'fullName': 'مدیر ارشد سامانه',
      'username': '123IMHModirkol@1090',
      'school': 'مدیریت مرکزی موسسه',
      'position': 'مدیر ارشد سیستم',
      'phone': '09131110000',
      'role': 'super_admin',
      'isActive': true,
    },
    {
      'id': 2,
      'fullName': 'محمدمحسن کارستان',
      'username': 'm.karestan',
      'school': 'دبیرستان پسرانه دوره دوم امام حسین (ع)',
      'position': 'معاون اجرایی',
      'phone': '09132510001',
      'role': 'user',
      'isActive': true,
    },
    {
      'id': 3,
      'fullName': 'فاطمه کریمی',
      'username': 'f.karimi',
      'school': 'دبستان دخترانه امام حسین (ع)',
      'position': 'مدیر مدرسه',
      'phone': '09132510002',
      'role': 'user',
      'isActive': true,
    },
    {
      'id': 4,
      'fullName': 'علی رضایی',
      'username': 'a.rezaei',
      'school': 'دبستان پسرانه امام حسین (ع)',
      'position': 'معاون اجرایی',
      'phone': '09132510003',
      'role': 'user',
      'isActive': true,
    },
    {
      'id': 5,
      'fullName': 'مریم حسینی',
      'username': 'm.hosseini',
      'school': 'دبیرستان دخترانه دوره اول امام حسین (ع)',
      'position': 'معاون پرورشی',
      'phone': '09132510004',
      'role': 'user',
      'isActive': true,
    },
    {
      'id': 6,
      'fullName': 'حسین احمدی',
      'username': 'h.ahmadi',
      'school': 'دبیرستان پسرانه دوره اول امام حسین (ع)',
      'position': 'معاون اجرایی',
      'phone': '09132510005',
      'role': 'user',
      'isActive': true,
    },
    {
      'id': 7,
      'fullName': 'زهرا اکبری',
      'username': 'z.akbari',
      'school': 'دبیرستان دخترانه دوره دوم امام حسین (ع)',
      'position': 'مدیر مدرسه',
      'phone': '09132510006',
      'role': 'user',
      'isActive': true,
    },
  ];

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedSchool = 'دبیرستان پسرانه دوره دوم امام حسین (ع)';
    String selectedPos = 'معاون اجرایی';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryGreen, size: 22),
              SizedBox(width: 8),
              Text('تعریف کاربر سازمانی جدید', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
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
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: familyCtrl,
                          decoration: InputDecoration(
                            labelText: 'نام خانوادگی',
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    decoration: InputDecoration(
                      labelText: 'نام کاربری (انگلیسی)',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور اولیه',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'شماره همراه',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (userCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _users.add({
                      'id': _users.length + 1,
                      'fullName': '${nameCtrl.text.trim()} ${familyCtrl.text.trim()}',
                      'username': userCtrl.text.trim(),
                      'school': selectedSchool,
                      'position': selectedPos,
                      'phone': phoneCtrl.text.trim(),
                      'role': 'user',
                      'isActive': true,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('کاربر جدید با موفقیت افزوده شد.'), backgroundColor: AppColors.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ثبت و ایجاد کاربر'),
            ),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('بازنشانی رمز عبور: ${user['fullName']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passCtrl,
            decoration: InputDecoration(
              labelText: 'کلمه عبور جدید',
              labelStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('رمز عبور کاربر «${user['fullName']}» با موفقیت تغییر کرد.'), backgroundColor: AppColors.primaryGreen),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('ذخیره رمز جدید'),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت کاربران و دسترسی‌ها', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('تعریف کاربران مدارس، ویرایش مشخصات، تنظیم دسترسی و بازنشانی رمز عبور', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('افزودن کاربر جدید', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'جستجوی کاربر بر اساس نام، نام کاربری یا شماره همراه...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedSchool,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.mainText, fontFamily: 'Vazirmatn'),
                  items: [
                    'همه مدارس',
                    'دبستان دخترانه',
                    'دبستان پسرانه',
                    'دبیرستان دخترانه دوره اول',
                    'دبیرستان پسرانه دوره اول',
                    'دبیرستان دخترانه دوره دوم',
                    'دبیرستان پسرانه دوره دوم',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSchool = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Users Table
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
                          Padding(padding: EdgeInsets.all(12), child: Text('نام و نام خانوادگی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('نام کاربری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('مدرسه انتسابی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('سمت سازمانی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('شماره تماس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('وضعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(12), child: Text('عملیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), textAlign: TextAlign.center)),
                        ],
                      ),
                      ...filtered.map((user) {
                        final isActive = user['isActive'] as bool;
                        final isSuperAdmin = user['role'] == 'super_admin';
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSuperAdmin ? AppColors.primaryGreen : AppColors.secondaryGreen,
                                    child: Text(
                                      (user['fullName'] as String)[0],
                                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user['fullName'] as String,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Text(user['username'] as String, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(user['school'] as String, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(user['position'] as String, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(12), child: Text(user['phone'] as String, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.pastelGreen : AppColors.holidayRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isActive ? 'فعال' : 'غیرفعال',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.darkGreen : AppColors.holidayRedText),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'بازنشانی رمز عبور',
                                    icon: const Icon(Icons.key_rounded, size: 17, color: AppColors.primaryGreen),
                                    onPressed: () => _showResetPasswordDialog(user),
                                  ),
                                  IconButton(
                                    tooltip: isActive ? 'غیرفعال‌سازی کاربر' : 'فعال‌سازی کاربر',
                                    icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, size: 24, color: isActive ? AppColors.primaryGreen : AppColors.secondaryText),
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
