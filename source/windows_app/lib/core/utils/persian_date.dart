import 'package:shamsi_date/shamsi_date.dart';

class PersianDateUtils {
  static const List<String> persianWeekdays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  static const List<String> persianMonths = [
    '',
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static String toPersianDigits(dynamic input) {
    if (input == null) return '';
    String str = input.toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], persian[i]);
    }
    return str;
  }

  static String formatJalali(DateTime date, {bool withMonthName = true}) {
    final jalali = Jalali.fromDateTime(date);
    if (withMonthName) {
      final monthName = persianMonths[jalali.month];
      return '${toPersianDigits(jalali.day)} $monthName ${toPersianDigits(jalali.year)}';
    }
    final m = jalali.month.toString().padLeft(2, '0');
    final d = jalali.day.toString().padLeft(2, '0');
    return '${toPersianDigits(jalali.year)}/${toPersianDigits(m)}/${toPersianDigits(d)}';
  }

  static String getWeekdayName(DateTime date) {
    // DateTime weekday: Monday=1 ... Sunday=7
    // Persian: Saturday=0 ... Friday=6
    // Saturday is weekday 6 in Dart
    final pyWd = date.weekday % 7; // Sunday=0, Monday=1, ..., Saturday=6
    final persianIdx = (date.weekday + 1) % 7;
    return persianWeekdays[persianIdx];
  }
}
