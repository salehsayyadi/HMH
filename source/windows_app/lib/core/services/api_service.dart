import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String defaultHost = 'reserve.salehvip-clud.ir';
  static const String defaultProtocol = 'https';
  static const String defaultPort = '443';
  static const String defaultApiPath = '/api/v1';

  static String baseUrl = 'https://reserve.salehvip-clud.ir/api/v1';
  static bool isOfflineEmergencyMode = false;

  /// بارگذاری تنظیمات سرور از حافظه پایدار دستگاه هنگام راه‌اندازی برنامه
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_base_url');
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      baseUrl = savedUrl.trim();
    } else {
      baseUrl = 'https://$defaultHost$defaultApiPath';
    }
  }

  /// دریافت اجزای تفکیک‌شده تنظیمات سرور
  static Future<Map<String, String>> getServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('server_host') ?? defaultHost;
    final protocol = prefs.getString('server_protocol') ?? defaultProtocol;
    final port = prefs.getString('server_port') ?? defaultPort;
    final apiPath = prefs.getString('server_api_path') ?? defaultApiPath;
    final fullUrl = prefs.getString('server_base_url') ?? '$protocol://$host$apiPath';

    return {
      'host': host,
      'protocol': protocol,
      'port': port,
      'apiPath': apiPath,
      'fullUrl': fullUrl,
    };
  }

  /// ذخیره پیکربندی جدید آدرس سرور
  static Future<void> saveServerConfig({
    required String host,
    required String protocol,
    required String port,
    required String apiPath,
  }) async {
    final cleanHost = host.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/.*$'), '');
    final cleanPort = port.trim();
    final cleanProtocol = protocol.trim().toLowerCase();
    var cleanPath = apiPath.trim();
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    String newBaseUrl;
    if ((cleanProtocol == 'https' && (cleanPort.isEmpty || cleanPort == '443')) ||
        (cleanProtocol == 'http' && (cleanPort.isEmpty || cleanPort == '80'))) {
      newBaseUrl = '$cleanProtocol://$cleanHost$cleanPath';
    } else {
      newBaseUrl = '$cleanProtocol://$cleanHost:$cleanPort$cleanPath';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_host', cleanHost);
    await prefs.setString('server_protocol', cleanProtocol);
    await prefs.setString('server_port', cleanPort);
    await prefs.setString('server_api_path', cleanPath);
    await prefs.setString('server_base_url', newBaseUrl);

    baseUrl = newBaseUrl;
  }

  /// آزمایش بلادرنگ اتصال به سرور و محاسبه تاخیر (Latency)
  static Future<Map<String, dynamic>> testServerConnection([String? customBaseUrl]) async {
    final target = (customBaseUrl ?? baseUrl).replaceAll(RegExp(r'/+$'), '');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(Uri.parse('$target/system/health'))
          .timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'version': data['version'] ?? '1.0.0',
          'message': 'اتصال به سرور مرکزی با موفقیت برقرار شد.',
        };
      } else {
        return {
          'success': false,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'error': 'پاسخ نامعتبر از سرور (کد وضعیت: ${response.statusCode})',
        };
      }
    } on SocketException catch (_) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'error': 'عدم برقراری ارتباط با سرور. پورت یا آدرس مشخص‌شده پاسخگو نیست.',
      };
    } on TimeoutException catch (_) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'error': 'مهلت اتصال به پایان رسید (Timeout). لطفا سرعت شبکه و فایروال سرور را بررسی فرمایید.',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'error': 'خطای شبکه: ${e.toString()}',
      };
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    isOfflineEmergencyMode = false;
  }

  /// احراز هویت با قابلیت ویژه ورود آفلاین مدیر کل جهت پیکربندی سرور
  static Future<Map<String, dynamic>> login(String username, String password) async {
    isOfflineEmergencyMode = false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      // Handle server-side 5xx errors (like 502 Bad Gateway, 503, 504)
      if (response.statusCode >= 500) {
        return _handleOfflineLoginFallback(username, password);
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        // If server returned non-JSON (HTML 502/504 page)
        return _handleOfflineLoginFallback(username, password);
      }

      if (response.statusCode == 200) {
        await saveTokens(data['access_token'], data['refresh_token']);
        return data;
      } else {
        throw Exception(data['detail'] ?? 'نام کاربری یا رمز عبور اشتباه است.');
      }
    } on SocketException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } on HandshakeException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } on TlsException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } on http.ClientException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } on TimeoutException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } on FormatException catch (_) {
      return _handleOfflineLoginFallback(username, password);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('Socket') || msg.contains('refused') || msg.contains('Connection') || 
          msg.contains('errno') || msg.contains('Handshake') || msg.contains('SSL') || 
          msg.contains('Format') || msg.contains('Unexpected') || msg.contains('502') || msg.contains('503')) {
        return _handleOfflineLoginFallback(username, password);
      }
      rethrow;
    }
  }

  /// مدیریت دسترسی آفلاین برای مدیر کل و کاربر تست در صورت عدم دسترسی به سرور
  static Future<Map<String, dynamic>> _handleOfflineLoginFallback(String username, String password) async {
    final cleanUser = username.trim().toLowerCase();
    // اگر کاربر وارد شده مدیر ارشد بوت‌استرپ سامانه باشد، اجازه ورود آفلاین جهت تنظیم سرور داده می‌شود
    if (username.trim() == '123IMHModirkol@1090' && password == '123IMHModirkol@1090') {
      isOfflineEmergencyMode = true;
      await saveTokens('offline_admin_token', 'offline_admin_refresh');

      return {
        'access_token': 'offline_admin_token',
        'refresh_token': 'offline_admin_refresh',
        'is_offline_mode': true,
        'user': {
          'id': 1,
          'username': '123IMHModirkol@1090',
          'first_name': 'مدیر',
          'last_name': 'ارشد',
          'full_name': 'مدیر ارشد سامانه (حالت پیکربندی آفلاین)',
          'role': 'super_admin',
          'phone_number': '09130000000',
          'is_active': true,
          'must_change_password': false,
          'school': {
            'id': 1,
            'name': 'مدیریت مرکزی موسسه امام حسین (ع)',
            'code': 'CENTRAL',
          },
          'position': {
            'id': 1,
            'title': 'مدیر ارشد سیستم',
          },
        },
      };
    }

    // دسترسی کاربر عادی آزمایشی (test / test) برای آزمایش رزرو و امکانات
    if (cleanUser == 'test' && password == 'test') {
      isOfflineEmergencyMode = true;
      await saveTokens('offline_test_token', 'offline_test_refresh');

      return {
        'access_token': 'offline_test_token',
        'refresh_token': 'offline_test_refresh',
        'is_offline_mode': true,
        'user': {
          'id': 99,
          'username': 'test',
          'first_name': 'کاربر',
          'last_name': 'تست',
          'full_name': 'کاربر تست',
          'role': 'user',
          'phone_number': '09131234567',
          'is_active': true,
          'must_change_password': false,
          'school': {
            'id': 2,
            'name': 'مدرسه پسرانه دوره دوم',
            'code': 'SCH-B2',
          },
          'position': {
            'id': 1,
            'title': 'معاون اجرایی',
          },
        },
      };
    }

    throw Exception(
      'ارتباط با وب‌سرویس سرور برقرار نشد (پاسخ نامعتبر یا خطای سرور دریافت گردید).\n'
      'لطفاً از اتصال اینترنت یا فعال بودن وب‌سرویس در بخش «تنظیمات سرور» اطمینان حاصل فرمایید.\n'
      'همچنین می‌توانید با کاربر آزمایشی (نام کاربری: test / رمز عبور: test) وارد شوید.',
    );
  }

  static Future<Map<String, dynamic>> getMe() async {
    if (isOfflineEmergencyMode) {
      final token = await getToken();
      if (token == 'offline_test_token') {
        return {
          'id': 99,
          'username': 'test',
          'first_name': 'کاربر',
          'last_name': 'تست',
          'full_name': 'کاربر تست',
          'role': 'user',
          'phone_number': '09131234567',
          'is_active': true,
          'must_change_password': false,
          'school': {
            'id': 2,
            'name': 'مدرسه پسرانه دوره دوم',
            'code': 'SCH-B2',
          },
          'position': {
            'id': 1,
            'title': 'معاون اجرایی',
          },
        };
      }
      return {
        'id': 1,
        'username': '123IMHModirkol@1090',
        'first_name': 'مدیر',
        'last_name': 'ارشد',
        'full_name': 'مدیر ارشد سامانه (حالت پیکربندی آفلاین)',
        'role': 'super_admin',
        'phone_number': '09130000000',
        'is_active': true,
        'must_change_password': false,
      };
    }

    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('نشست کاربری منقضی شده است');
    }
  }

  static Future<Map<String, dynamic>> getCalendarWeek({String? targetDate}) async {
    if (isOfflineEmergencyMode) {
      // در حالت آفلاین، خطای شبیه‌سازی شده صادر می‌شود تا تقویم با سانس‌های فعال آماده آزمایش بارگذاری شود
      throw Exception('پیکربندی حالت آفلاین - نمایش هفته آزمایشی');
    }

    final token = await getToken();
    var uri = Uri.parse('$baseUrl/calendar/week');
    if (targetDate != null) {
      uri = uri.replace(queryParameters: {'target_date': targetDate});
    }

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('خطا در دریافت تقویم هفتگی');
    }
  }

  static Future<Map<String, dynamic>> reserveSlot({
    required int timeSlotId,
    required String reservationDate,
    String? title,
    String? description,
  }) async {
    if (isOfflineEmergencyMode) {
      // شبیه‌سازی ثبت موفق رزرو در حالت تست آفلاین جهت امکان ارزیابی پنجره ثبت و جریان کاربری
      return {
        'id': 999,
        'reservation_date': reservationDate,
        'time_slot_id': timeSlotId,
        'school_id': 2,
        'school_name': 'مدرسه پسرانه دوره دوم',
        'user_id': 99,
        'user_full_name': 'کاربر تست',
        'position_title': 'معاون اجرایی',
        'phone_number': '09131234567',
        'description': description ?? 'رزرو آزمایشی سالن آمفی‌تئاتر',
        'status': 'confirmed',
        'can_cancel': true,
        'created_at': DateTime.now().toIso8601String(),
        'time_slot': {
          'id': timeSlotId,
          'slot_number': timeSlotId,
          'title': 'سانس $timeSlotId',
          'start_time': '08:00',
          'end_time': '10:00',
          'is_active': true,
        }
      };
    }

    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'time_slot_id': timeSlotId,
        'reservation_date': reservationDate,
        'title': title,
        'description': description,
      }),
    ).timeout(const Duration(seconds: 4));

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'خطا در ثبت رزرو');
    }
  }

  static Future<void> cancelReservation(int id) async {
    if (isOfflineEmergencyMode) {
      return;
    }

    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/reservations/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? 'خطا در لغو رزرو');
    }
  }

  static Future<List<dynamic>> getMyReservations() async {
    if (isOfflineEmergencyMode) {
      return [];
    }

    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('خطا در دریافت سوابق رزرو');
    }
  }

  static Future<List<dynamic>> getMyHistory() => getMyReservations();

  static Future<Map<String, dynamic>> createReservation({
    required String date,
    required int timeSlotId,
    String? title,
    String? description,
  }) =>
      reserveSlot(
        timeSlotId: timeSlotId,
        reservationDate: date,
        title: title,
        description: description,
      );

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (isOfflineEmergencyMode) {
      throw Exception('تغییر رمز در حالت آفلاین مقدور نیست.');
    }

    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'خطا در تغییر رمز عبور');
    }
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/system/health')).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('سرور پاسخگو نیست');
    }
  }

  // --- Real Dynamic Database API Endpoints for Windows Administration ---

  static Future<List<dynamic>> getUsers() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/users/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getSchools() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/schools/?include_inactive=true'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getReservations() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/reservations/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getTimeSlots() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/time-slots/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getHolidays() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/holidays/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getRestrictions() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/restrictions/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getDashboardStats() async {
    if (isOfflineEmergencyMode) return null;
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/reports/dashboard'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getAuditLogs() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/audit-logs/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return [];
  }

  // --- Real Database Mutation APIs for Windows Administration ---

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      throw Exception('در حالت آفلاین تغییر در پایگاه‌داده امکان‌پذیر نیست.');
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 201) return resData;
    throw Exception(resData['detail'] ?? 'خطا در ثبت کاربر در دیتابیس');
  }

  static Future<void> deleteUser(int id) async {
    if (isOfflineEmergencyMode) return;
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> createSchool(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      throw Exception('در حالت آفلاین تغییر در پایگاه‌داده امکان‌پذیر نیست.');
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/schools/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 201) return resData;
    throw Exception(resData['detail'] ?? 'خطا در ثبت مدرسه در دیتابیس');
  }

  static Future<void> deleteSchool(int id) async {
    if (isOfflineEmergencyMode) return;
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/schools/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      throw Exception('در حالت آفلاین تغییر در پایگاه‌داده امکان‌پذیر نیست.');
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/holidays/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 201) return resData;
    throw Exception(resData['detail'] ?? 'خطا در ثبت تعطیلی در دیتابیس');
  }

  static Future<void> deleteHoliday(int id) async {
    if (isOfflineEmergencyMode) return;
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/holidays/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> createRestriction(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      throw Exception('در حالت آفلاین تغییر در پایگاه‌داده امکان‌پذیر نیست.');
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/restrictions/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 201) return resData;
    throw Exception(resData['detail'] ?? 'خطا در ثبت محدودیت در دیتابیس');
  }

  static Future<void> deleteRestriction(int id) async {
    if (isOfflineEmergencyMode) return;
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/restrictions/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
