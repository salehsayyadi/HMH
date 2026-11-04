import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MobileSavedAccountsSheet extends StatelessWidget {
  final List<Map<String, String>> accounts;
  final ValueChanged<Map<String, String>> onSelect;
  final ValueChanged<String> onDelete;

  const MobileSavedAccountsSheet({
    super.key,
    required this.accounts,
    required this.onSelect,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, String>> accounts,
    required ValueChanged<Map<String, String>> onSelect,
    required ValueChanged<String> onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MobileSavedAccountsSheet(
        accounts: accounts,
        onSelect: onSelect,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'حساب‌های ذخیره‌شده',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'هیچ حساب کاربری ذخیره‌شده‌ای موجود نیست.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...accounts.map((acc) {
                final username = acc['username'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Remove button (X)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.secondaryText),
                        onPressed: () => onDelete(username),
                        tooltip: 'حذف از لیست',
                      ),

                      // Select Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onSelect(acc);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('انتخاب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

                      const Spacer(),

                      // Account Name & Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'حساب ذخیره‌شده',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),

                      // User Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
