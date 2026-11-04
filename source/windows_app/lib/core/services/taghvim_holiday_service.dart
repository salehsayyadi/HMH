import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side Dynamic Taghvim.com Holiday Extraction & Local Storage Service
/// Automatically extracts and caches official holidays month by month directly
/// into the local PC database without cluttering the central server memory.
class TaghvimHolidayService {
  static const String _prefKeyPrefix = 'imh_taghvim_holidays_cache_v2';
  static final Map<String, String> _memoryCache = {};
  static bool _isInitialized = false;

  /// Default instant seeds matching official taghvim.com database
  static const Map<int, Map<int, String>> _defaultOfficialHolidays = {
    1: {
      1: 'جشن نوروز / سال نو',
      2: 'عید نوروز',
      3: 'عید نوروز',
      4: 'عید نوروز',
      12: 'روز جمهوری اسلامی ایران',
      13: 'روز طبیعت (سیزده به در)',
      14: 'شهادت امام جعفر صادق (ع)',
    },
    2: {
      27: 'عید سعید قربان',
    },
    3: {
      4: 'عید سعید غدیر خم',
      14: 'رحلت حضرت امام خمینی (ره)',
      15: 'قیام ۱۵ خرداد',
      25: 'تاسوعای حسینی',
      26: 'عاشورای حسینی',
    },
    5: {
      13: 'اربعین حسینی',
      21: 'رحلت رسول اکرم (ص) و شهادت امام حسن مجتبی (ع)',
      22: 'شهادت امام رضا (ع)',
      30: 'شهادت امام حسن عسکری (ع)',
    },
    6: {
      8: 'میلاد رسول اکرم (ص) و امام جعفر صادق (ع)',
    },
    8: {
      22: 'شهادت حضرت فاطمه زهرا (س)',
    },
    10: {
      2: 'ولادت امام علی (ع) و روز پدر',
      16: 'مبعث رسول اکرم (ص)',
    },
    11: {
      4: 'ولادت حضرت قائم (عج) و جشن نیمه شعبان',
      22: 'پیروزی انقلاب اسلامی ایران',
    },
    12: {
      9: 'شهادت حضرت علی (ع)',
      19: 'عید سعید فطر',
      20: 'تعطیلی عید سعید فطر',
      29: 'روز ملی شدن صنعت نفت ایران',
    },
  };

  /// Initialize and load cached holidays from local PC disk
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefKeyPrefix));
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw != null) {
          final Map<String, dynamic> decoded = json.decode(raw);
          decoded.forEach((dateKey, title) {
            _memoryCache[dateKey] = title.toString();
          });
        }
      }
      _isInitialized = true;
    } catch (_) {
      // In case of disk error, fallback to memory
      _isInitialized = true;
    }
  }

  /// Get holiday title for a specific Jalali date
  static String? getHolidayTitle(int year, int month, int day) {
    final key = '$year-$month-$day';
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    // Fallback to built-in taghvim official dates
    return _defaultOfficialHolidays[month]?[day];
  }

  /// Check if a Jalali date is an official holiday
  static bool isHoliday(int year, int month, int day) {
    return getHolidayTitle(year, month, day) != null;
  }

  /// Asynchronously fetch and sync current month events from taghvim.com directly
  /// and persist them to local SQLite/SharedPreferences cache on the client PC.
  static Future<void> syncMonthFromTaghvim(int year, int month) async {
    try {
      final url = Uri.parse('https://taghvim.com/get_events/?action=get_events&month=$month');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://taghvim.com/',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final monthCache = <String, String>{};

        for (final item in data) {
          if (item is Map && item['is_holiday'] == true) {
            final day = item['day'] as int? ?? 0;
            final title = (item['name'] as String? ?? 'تعطیل رسمی').trim();
            final key = '$year-$month-$day';
            _memoryCache[key] = title;
            monthCache[key] = title;
          }
        }

        // Save month to persistent local disk storage
        if (monthCache.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('${_prefKeyPrefix}_${year}_$month', json.encode(monthCache));
        }
      }
    } catch (_) {
      // Silent error: Taghvim site may be unreachable, offline seed provides continuous reliability
    }
  }
}
