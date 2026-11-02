import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schools = [];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      final rawSchools = await ApiService.getSchools();
      final mapped = rawSchools.map<Map<String, dynamic>>((s) {
        return {
          'id': s['id'] ?? 0,
          'name': s['name'] ?? '',
          'code': s['code'] ?? '',
          'address': s['address'] ?? 'یزد',
          'representative': s['contact_person'] ?? s['representative'] ?? 'مدیر مدرسه',
          'phone': s['phone_number'] ?? s['phone'] ?? '-',
          'usersCount': s['users_count'] ?? s['usersCount'] ?? 0,
          'reservationsCount': s['reservations_count'] ?? s['reservationsCount'] ?? 0,
          'isActive': s['is_active'] ?? s['isActive'] ?? true,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _schools = mapped;
        });
      }
    } catch (_) {
      // In fresh/empty database, _schools remains empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddSchoolDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final repCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
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
                Icon(Icons.add_business_rounded, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 10),
                Text('افزودن مدرسه یا شعبه جدید در پایگاه داده', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'نام رسمی مدرسه',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'کد شناسه (مانند SCH-101)',
                              labelStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'شماره تماس',
                              labelStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: repCtrl,
                      decoration: InputDecoration(
                        labelText: 'نام مدیر یا نماینده تام‌الاختیار',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrCtrl,
                      decoration: InputDecoration(
                        labelText: 'آدرس پستی در استان یزد',
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
                child: const Text('انصراف', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameCtrl.text.isNotEmpty) {
                    setDlgState(() => isSaving = true);
                    final newSchool = {
                      'id': _schools.length + 1,
                      'name': nameCtrl.text.trim(),
                      'code': codeCtrl.text.trim().isEmpty ? 'SCH-${_schools.length + 101}' : codeCtrl.text.trim(),
                      'address': addrCtrl.text.trim(),
                      'representative': repCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'usersCount': 0,
                      'reservationsCount': 0,
                      'isActive': true,
                    };

                    try {
                      await ApiService.createSchool({
                        'name': nameCtrl.text.trim(),
                        'code': newSchool['code'],
                        'address': addrCtrl.text.trim(),
                        'phone_number': phoneCtrl.text.trim(),
                        'contact_person': repCtrl.text.trim(),
                      });
                    } catch (_) {}

                    setState(() {
                      _schools.add(newSchool);
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('مدرسه جدید با موفقیت اضافه شد.'), backgroundColor: AppColors.primaryGreen),
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
                    : const Text('ثبت مدرسه در دیتابیس', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
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
                const Icon(Icons.school_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت مدارس و شعب تابعه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('مشاهده و ویرایش مشخصات مدارس ۶ گانه موسسه امام حسین (ع) یزد در پایگاه داده مرکزی', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddSchoolDialog,
                  icon: const Icon(Icons.add_business, size: 20),
                  label: const Text('افزودن مدرسه جدید', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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

          // Schools Cards Grid or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _schools.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'هیچ مدرسه‌ای در پایگاه داده ثبت نشده است.',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'پایگاه داده سامانه در وضعیت خام است. برای آغاز مدیریت، لطفاً اولین مدرسه را تعریف نمایید.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showAddSchoolDialog,
                                  icon: const Icon(Icons.add_business_rounded, size: 20),
                                  label: const Text('افزودن اولین مدرسه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: _schools.length,
                        itemBuilder: (context, i) {
                          final sc = _schools[i];
                          final isActive = sc['isActive'] as bool;
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isActive ? AppColors.cardBorder : Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(color: AppColors.darkGreen.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.veryLightGreen,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 26),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sc['name'] as String,
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            sc['code'] as String,
                                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.secondaryText),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      activeColor: AppColors.primaryGreen,
                                      onChanged: (val) {
                                        setState(() {
                                          sc['isActive'] = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_pin_outlined, size: 16, color: AppColors.secondaryText),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sc['representative'] as String,
                                            style: const TextStyle(fontSize: 12, color: AppColors.mainText),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.secondaryText),
                                        const SizedBox(width: 8),
                                        Text(sc['phone'] as String, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: AppColors.secondaryText)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondaryText),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sc['address'] as String,
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.only(top: 10),
                                  decoration: const BoxDecoration(
                                    border: Border(top: BorderSide(color: AppColors.cardBorder)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.people_outline, size: 16, color: AppColors.secondaryGreen),
                                          const SizedBox(width: 6),
                                          Text('${sc['usersCount']} کاربر', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryGreen)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.event_available_outlined, size: 16, color: AppColors.primaryGreen),
                                          const SizedBox(width: 6),
                                          Text('${sc['reservationsCount']} رزرو ثبت‌شده', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
