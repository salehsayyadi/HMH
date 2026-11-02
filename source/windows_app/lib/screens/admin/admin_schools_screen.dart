import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  final List<Map<String, dynamic>> _schools = [
    {
      'id': 1,
      'name': 'دبستان دخترانه امام حسین (ع)',
      'code': 'SCH-101',
      'address': 'یزد، خیابان آیت‌الله کاشانی، کوچه مریم',
      'representative': 'خانم فاطمه کریمی (مدیر)',
      'phone': '035-38241001',
      'usersCount': 1,
      'reservationsCount': 11,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'دبستان پسرانه امام حسین (ع)',
      'code': 'SCH-102',
      'address': 'یزد، بلوار شهید پاکنژاد، جنب مجتمع آموزشی',
      'representative': 'آقای علی رضایی (معاون اجرایی)',
      'phone': '035-37252002',
      'usersCount': 1,
      'reservationsCount': 14,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'دبیرستان دخترانه دوره اول امام حسین (ع)',
      'code': 'SCH-201',
      'address': 'یزد، صفائیه، بلوار دانشگاه، خیابان ملاصدرا',
      'representative': 'خانم مریم حسینی (معاون پرورشی)',
      'phone': '035-38263003',
      'usersCount': 1,
      'reservationsCount': 12,
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'دبیرستان پسرانه دوره اول امام حسین (ع)',
      'code': 'SCH-202',
      'address': 'یزد، بلوار جمهوری اسلامی، کوچه شرق',
      'representative': 'آقای حسین احمدی (معاون اجرایی)',
      'phone': '035-35244004',
      'usersCount': 1,
      'reservationsCount': 7,
      'isActive': true,
    },
    {
      'id': 5,
      'name': 'دبیرستان دخترانه دوره دوم امام حسین (ع)',
      'code': 'SCH-301',
      'address': 'یزد، خیابان قیام، کوچه گلستان',
      'representative': 'خانم زهرا اکبری (مدیر)',
      'phone': '035-36225005',
      'usersCount': 1,
      'reservationsCount': 8,
      'isActive': true,
    },
    {
      'id': 6,
      'name': 'دبیرستان پسرانه دوره دوم امام حسین (ع)',
      'code': 'SCH-302',
      'address': 'یزد، بلوار ۱۷ شهریور، مجتمع فرهنگی آموزشی',
      'representative': 'آقای محمدمحسن کارستان (معاون اجرایی)',
      'phone': '035-37266006',
      'usersCount': 1,
      'reservationsCount': 15,
      'isActive': true,
    },
  ];

  void _showAddSchoolDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final repCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_business_rounded, color: AppColors.primaryGreen, size: 22),
              SizedBox(width: 8),
              Text('افزودن مدرسه یا شعبه جدید', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'نام رسمی مدرسه',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: 'کد شناسه (مانند SCH-401)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'شماره تماس',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: repCtrl,
                    decoration: InputDecoration(
                      labelText: 'نام مدیر یا نماینده تام‌الاختیار',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'آدرس پستی',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _schools.add({
                      'id': _schools.length + 1,
                      'name': nameCtrl.text.trim(),
                      'code': codeCtrl.text.trim().isEmpty ? 'SCH-${_schools.length + 101}' : codeCtrl.text.trim(),
                      'address': addrCtrl.text.trim(),
                      'representative': repCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'usersCount': 0,
                      'reservationsCount': 0,
                      'isActive': true,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('مدرسه جدید با موفقیت اضافه شد.'), backgroundColor: AppColors.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('ثبت مدرسه'),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت مدارس و شعب تابعه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    Text('مشاهده و ویرایش مشخصات مدارس ۶ گانه موسسه امام حسین (ع) یزد، سهمیه و وضعیت فعالیت', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddSchoolDialog,
                  icon: const Icon(Icons.add_business, size: 16),
                  label: const Text('افزودن مدرسه جدید', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // Schools Cards Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
              ),
              itemCount: _schools.length,
              itemBuilder: (context, i) {
                final sc = _schools[i];
                final isActive = sc['isActive'] as bool;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.veryLightGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sc['name'] as String,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sc['code'] as String,
                                  style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: AppColors.secondaryText),
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
                              const Icon(Icons.person_pin_outlined, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sc['representative'] as String,
                                  style: const TextStyle(fontSize: 11, color: AppColors.mainText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 6),
                              Text(sc['phone'] as String, style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: AppColors.secondaryText)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sc['address'] as String,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.cardBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people_outline, size: 14, color: AppColors.secondaryGreen),
                                const SizedBox(width: 4),
                                Text('${sc['usersCount']} کاربر', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryGreen)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.event_available_outlined, size: 14, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text('${sc['reservationsCount']} رزرو ثبت‌شده', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
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
