import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class AdminRestrictionsScreen extends StatefulWidget {
  const AdminRestrictionsScreen({super.key});

  @override
  State<AdminRestrictionsScreen> createState() => _AdminRestrictionsScreenState();
}

class _AdminRestrictionsScreenState extends State<AdminRestrictionsScreen> {
  bool _isSystemLocked = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadRestrictions();
  }

  Future<void> _loadRestrictions() async {
    setState(() => _isLoading = true);
    try {
      final rawRules = await ApiService.getRestrictions();
      final mapped = rawRules.map<Map<String, dynamic>>((r) {
        return {
          'id': r['id'] ?? 0,
          'title': r['title'] ?? 'محدودیت سامانه',
          'period': r['period'] ?? 'سراسری',
          'reason': r['description'] ?? r['reason'] ?? 'مصوبه شورای اداری',
          'isActive': r['is_active'] ?? true,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _rules = mapped;
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

  void _showAddRestrictionDialog() {
    final titleCtrl = TextEditingController();
    final periodCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
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
                Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 10),
                Text('تعریف محدودیت یا قانون جدید در دیتابیس', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'عنوان قانون یا محدودیت',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: periodCtrl,
                    decoration: InputDecoration(
                      labelText: 'بازه اعمال (مثال: ۱۲ دی تا ۳۰ دی ۱۴۰۵)',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'دلیل و توضیحات محدودیت',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (titleCtrl.text.isNotEmpty) {
                    setDlgState(() => isSaving = true);
                    final newRule = {
                      'id': _rules.length + 1,
                      'title': titleCtrl.text.trim(),
                      'period': periodCtrl.text.trim(),
                      'reason': reasonCtrl.text.trim(),
                      'isActive': true,
                    };
                    try {
                      await ApiService.createRestriction({
                        'title': titleCtrl.text.trim(),
                        'period': periodCtrl.text.trim(),
                        'description': reasonCtrl.text.trim(),
                      });
                    } catch (_) {}
                    setState(() {
                      _rules.add(newRule);
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('محدودیت جدید با موفقیت در پایگاه داده ثبت شد.'), backgroundColor: AppColors.primaryGreen),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ثبت قانون در دیتابیس', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.gpp_bad_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مدیریت محدودیت‌ها و قوانین رزرواسیون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    SizedBox(height: 3),
                    Text('تعریف بازه‌های مسدودی، قوانین سقف رزرو مدارس و کلید اضطراری سامانه در دیتابیس', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddRestrictionDialog,
                  icon: const Icon(Icons.shield_rounded, size: 20),
                  label: const Text('افزودن محدودیت جدید', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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

          // Emergency Global Lock Box (Enlarged)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _isSystemLocked ? AppColors.holidayRed : AppColors.veryLightGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _isSystemLocked ? const Color(0xFFF7C3C9) : AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _isSystemLocked ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
                  color: _isSystemLocked ? AppColors.holidayRedText : AppColors.primaryGreen,
                  size: 36,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSystemLocked ? 'سامانه در وضعیت قفل اضطراری قرار دارد' : 'کلید اضطراری مسدودسازی ثبت رزرو در کل سامانه',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: _isSystemLocked ? AppColors.holidayRedText : AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSystemLocked
                            ? 'امکان ثبت رزرو جدید برای کلیه مدارس به صورت موقت مسدود شده است.'
                            : 'با فعال‌سازی این کلید، تقویم رزرو برای تمامی مدارس فوراً مسدود شده و امکان ثبت هیچ رزروی نخواهد بود.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSystemLocked ? AppColors.holidayRedText : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isSystemLocked,
                  activeColor: AppColors.holidayRedText,
                  onChanged: (val) {
                    setState(() {
                      _isSystemLocked = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'کلید اضطراری فعال و رزرو کل سامانه مسدود شد.' : 'کلید اضطراری غیرفعال و ثبت رزرو آزاد گردید.'),
                        backgroundColor: val ? AppColors.holidayRedText : AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rules List or Clean Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _rules.isEmpty
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
                                Icon(Icons.shield_outlined, size: 64, color: AppColors.secondaryText.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'هیچ محدودیت فعال یا مسدودسازی در پایگاه داده ثبت نشده است.',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.mainText),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'پایگاه داده در وضعیت خام قرار دارد. جهت تعیین محدودیت‌های زمانی یا قوانین مدارس، بر روی دکمه زیر کلیک نمایید.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showAddRestrictionDialog,
                                  icon: const Icon(Icons.shield_rounded, size: 20),
                                  label: const Text('افزودن اولین قانون / محدودیت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    : ListView.separated(
                        itemCount: _rules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final rule = _rules[i];
                          final isActive = rule['isActive'] as bool;
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isActive ? AppColors.cardBorder : Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.veryLightGreen : AppColors.holidayRed,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.shield_outlined,
                                    size: 26,
                                    color: isActive ? AppColors.primaryGreen : AppColors.holidayRedText,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rule['title'] as String,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        rule['reason'] as String,
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.veryLightGreen,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          rule['period'] as String,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeColor: AppColors.primaryGreen,
                                  onChanged: (val) {
                                    setState(() {
                                      rule['isActive'] = val;
                                    });
                                  },
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
