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

  // Stored active session credentials for seamless online reconnection
  static String? activeUsername;
  static String? activePassword;

  // Local caching for smooth offline administration without crash
  static final List<Map<String, dynamic>> _localOfflineUsers = [];
  static final List<Map<String, dynamic>> _localOfflineSchools = [];

  /// بارگذاری تنظیمات سرور از حافظه پایدار دستگاه هنگام راه‌اندازی برنامه
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_base_url');
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      baseUrl = savedUrl.trim().replaceAll(RegExp(r'/+$'), '');
    } else {
      baseUrl = 'https://$defaultHost$defaultApiPath';
    }
  }

  /// ایمن‌سازی تجزیه پاسخ‌های سرور جهت جلوگیری از FormatException: Unexpected end of input
  static dynamic _decodeResponse(http.Response res) {
    if (res.bodyBytes.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return <String, dynamic>{};
      }
      if (res.statusCode >= 300 && res.statusCode < 400) {
        throw Exception('مسیر وب‌سرویس نیاز به انتقال دارد (کد وضعیت ${res.statusCode}).');
      }
      throw Exception('پاسخی از سرور دریافت نشد (کد وضعیت: ${res.statusCode})');
    }

    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded;
    } catch (_) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw Exception('قالب پاسخ سرور نامعتبر است (کد وضعیت: ${res.statusCode})');
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
    cleanPath = cleanPath.replaceAll(RegExp(r'/+$'), '');

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
          .timeout(const Duration(seconds: 20));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        final hasDbField = data is Map && data.containsKey('database');
        final dbConnected = hasDbField ? (data['database'] == 'connected') : true;
        final isOverallSuccess = !hasDbField || dbConnected;
        return {
          'success': isOverallSuccess,
          'apiConnected': true,
          'dbConnected': dbConnected,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'version': (data is Map && data['version'] != null) ? data['version'] : '1.0.0',
          'message': isOverallSuccess
              ? 'اتصال به وب‌سرویس و پایگاه داده مرکزی با موفقیت برقرار شد.'
              : 'وب‌سرویس فعال است اما پایگاه داده مرکزی متصل نیست (${data is Map ? data['database_error'] : 'خطا در دیتابیس'}).',
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
    activeUsername = null;
    activePassword = null;
    isOfflineEmergencyMode = false;
  }

  /// احراز هویت با قابلیت اتصال آنلاین پایدار و سوییچ به حالت آفلاین در صورت عدم سلامت دیتابیس
  static Future<Map<String, dynamic>> login(String username, String password) async {
    isOfflineEmergencyMode = false;
    activeUsername = username.trim();
    activePassword = password;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 25));

      // Handle server-side 5xx errors (like 500, 502 Bad Gateway, 503, 504)
      if (response.statusCode >= 500) {
        return _handleOfflineLoginFallback(username, password);
      }

      dynamic data;
      try {
        data = _decodeResponse(response);
      } catch (_) {
        return _handleOfflineLoginFallback(username, password);
      }

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        isOfflineEmergencyMode = false;
        await saveTokens(data['access_token'], data['refresh_token']);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 422) {
        // Real server returned explicit auth rejection: show exact message, do NOT fallback to offline!
        final msg = (data is Map && data['detail'] != null) ? data['detail'].toString() : 'نام کاربری یا رمز عبور اشتباه است.';
        throw Exception(msg);
      } else {
        return _handleOfflineLoginFallback(username, password);
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
          msg.contains('Format') || msg.contains('Unexpected') || msg.contains('502') || msg.contains('503') || msg.contains('500')) {
        return _handleOfflineLoginFallback(username, password);
      }
      rethrow;
    }
  }

  /// مدیریت دسترسی آفلاین برای مدیر کل و کاربر آزمایشی در صورت قطعی سرور یا دیتابیس
  static Future<Map<String, dynamic>> _handleOfflineLoginFallback(String username, String password) async {
    final cleanUser = username.trim().toLowerCase();

    // پشتیبانی کامل از نام کاربری مدیر ارشد با یا بدون پسوند @1090
    final isSuperAdminUser = (cleanUser == '123imhmodirkol@1090' || cleanUser == '123imhmodirkol');
    final isSuperAdminPass = (password == '123IMHModirkol@1090' || password == '123IMHModirkol');

    if (isSuperAdminUser && isSuperAdminPass) {
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

    // دسترسی کاربر عادی آزمایشی (test / test)
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
      'ارتباط با وب‌سرویس یا پایگاه‌داده سرور برقرار نشد (پاسخ نامعتبر یا خطای سرور دریافت گردید).\n'
      'لطفاً از اتصال اینترنت یا فعال بودن وب‌سرویس و دیتابیس در بخش «تنظیمات سرور» اطمینان حاصل فرمایید.',
    );
  }

  /// اتصال مجدد آنلاین و تبادل سشن آفلاین با توکن معتبر و دائمی سرور
  static Future<Map<String, dynamic>> reconnectOnline() async {
    final health = await testServerConnection();
    if (health['success'] != true || health['dbConnected'] != true) {
      return {
        'success': false,
        'error': health['message'] ?? health['error'] ?? 'سرور یا پایگاه داده هنوز در دسترس نیست.',
      };
    }

    // در صورتی که مشخصات نشست فعال در حافظه باشد، احراز هویت بلادرنگ با سرور انجام می‌شود
    if (activeUsername != null && activePassword != null) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': activeUsername, 'password': activePassword}),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = _decodeResponse(res);
          if (data is Map<String, dynamic> && data.containsKey('access_token')) {
            await saveTokens(data['access_token'], data['refresh_token']);
            isOfflineEmergencyMode = false;
            return {
              'success': true,
              'message': 'اتصال آنلاین با موفقیت برقرار و توکن امنیتی سرور فعال شد.',
              'user': data['user'],
            };
          }
        } else {
          final data = _decodeResponse(res);
          final msg = (data is Map && data['detail'] != null) ? data['detail'].toString() : 'عدم تایید مشخصات ورود';
          return {
            'success': false,
            'error': 'احراز هویت سرور ناموفق بود: $msg',
          };
        }
      } catch (e) {
        return {
          'success': false,
          'error': 'خطا در ارتباط با وب‌سرویس سرور: $e',
        };
      }
    }

    // بررسی توکن قبلی در صورت عدم وجود پسورد در حافظه
    final token = await getToken();
    if (token != null && !token.startsWith('offline_')) {
      try {
        final meRes = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15));
        if (meRes.statusCode == 200) {
          isOfflineEmergencyMode = false;
          final meData = _decodeResponse(meRes);
          return {
            'success': true,
            'message': 'اتصال آنلاین با موفقیت برقرار شد.',
            'user': meData,
          };
        }
      } catch (_) {}
    }

    return {
      'success': false,
      'error': 'جهت اتصال کامل آنلاین به سرور، لطفاً یک‌بار از حساب خارج شده و مجدداً وارد شوید.',
    };
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
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw Exception('نشست کاربری منقضی شده است');
    }
  }

  static Future<Map<String, dynamic>> getCalendarWeek({String? targetDate}) async {
    if (isOfflineEmergencyMode) {
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
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return _decodeResponse(response);
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
      Uri.parse('$baseUrl/reservations'),
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
    ).timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    } else {
      throw Exception(data['detail'] ?? 'خطا در ثبت رزرو');
    }
  }

  static Future<void> cancelReservation(int id) async {
    if (isOfflineEmergencyMode) return;

    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/reservations/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = _decodeResponse(response);
      throw Exception(data['detail'] ?? 'خطا در لغو رزرو');
    }
  }

  static Future<List<dynamic>> getMyReservations() async {
    if (isOfflineEmergencyMode) return [];

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reservations/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
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

    final data = _decodeResponse(response);
    if (response.statusCode == 200) {
      return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    } else {
      throw Exception(data['detail'] ?? 'خطا در تغییر رمز عبور');
    }
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/system/health')).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    } else {
      throw Exception('سرور پاسخگو نیست');
    }
  }

  // --- Real Dynamic Database API Endpoints for Windows Administration ---

  static Future<List<dynamic>> getUsers() async {
    if (isOfflineEmergencyMode) {
      return [
        {
          'id': 1,
          'username': '123IMHModirkol@1090',
          'first_name': 'مدیر',
          'last_name': 'ارشد',
          'full_name': 'مدیر ارشد سامانه',
          'role': 'super_admin',
          'phone_number': '09130000000',
          'is_active': true,
          'school': {'id': 1, 'name': 'مدیریت مرکزی موسسه امام حسین (ع)', 'code': 'CENTRAL'},
          'position': {'id': 1, 'title': 'مدیر ارشد سیستم'}
        },
        ..._localOfflineUsers,
      ];
    }
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getSchools() async {
    if (isOfflineEmergencyMode) {
      return [
        {
          'id': 1,
          'name': 'مدیریت مرکزی موسسه حضرت امام حسین (ع)',
          'code': 'CENTRAL',
          'address': 'یزد، بلوار شهید صدوقی',
          'phone': '03530000000',
          'is_active': true,
        },
        {
          'id': 2,
          'name': 'دبیرستان پسرانه دوره اول',
          'code': 'SCH-B1',
          'address': 'یزد، صفائیه',
          'phone': '03538200001',
          'is_active': true,
        },
        {
          'id': 3,
          'name': 'دبیرستان دخترانه دوره اول',
          'code': 'SCH-G1',
          'address': 'یزد، صفائیه',
          'phone': '03538200002',
          'is_active': true,
        },
        ..._localOfflineSchools,
      ];
    }
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/schools?include_inactive=true'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getReservations() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/reservations'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getTimeSlots() async {
    if (isOfflineEmergencyMode) {
      return [
        {'id': 1, 'slot_number': 1, 'title': 'سانس اول (صبح)', 'start_time': '08:00', 'end_time': '10:00', 'is_active': true},
        {'id': 2, 'slot_number': 2, 'title': 'سانس دوم (پیش از ظهر)', 'start_time': '10:30', 'end_time': '12:30', 'is_active': true},
        {'id': 3, 'slot_number': 3, 'title': 'سانس سوم (بعد از ظهر)', 'start_time': '14:00', 'end_time': '16:00', 'is_active': true},
        {'id': 4, 'slot_number': 4, 'title': 'سانس چهارم (عصر)', 'start_time': '16:30', 'end_time': '18:30', 'is_active': true},
      ];
    }
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/time-slots'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getHolidays() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/holidays'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getRestrictions() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/restrictions'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
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
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getAuditLogs() async {
    if (isOfflineEmergencyMode) return [];
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/audit-logs'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  // --- Real Database Mutation APIs for Windows Administration ---

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      // ثبت محلی کاربر در حالت آفلاین
      final newId = 100 + _localOfflineUsers.length + 1;
      final localUser = {
        'id': newId,
        'username': data['username'] ?? '',
        'first_name': data['first_name'] ?? '',
        'last_name': data['last_name'] ?? '',
        'full_name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
        'phone_number': data['phone_number'] ?? '',
        'role': data['role'] ?? 'user',
        'school_id': data['school_id'],
        'position_id': data['position_id'] ?? 1,
        'is_active': true,
        'must_change_password': false,
        'school': {
          'id': data['school_id'] ?? 1,
          'name': 'مدرسه انتخاب‌شده',
          'code': 'SCH',
        },
        'position': {
          'id': data['position_id'] ?? 1,
          'title': 'کاربر سازمانی',
        },
      };
      _localOfflineUsers.add(localUser);
      return localUser;
    }

    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = _decodeResponse(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (resData is Map<String, dynamic>) ? resData : <String, dynamic>{};
    }
    throw Exception(resData['detail'] ?? 'خطا در ثبت کاربر در دیتابیس (کد وضعیت: ${res.statusCode})');
  }

  static Future<void> deleteUser(int id) async {
    if (isOfflineEmergencyMode) {
      _localOfflineUsers.removeWhere((u) => u['id'] == id);
      return;
    }
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> createSchool(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      final newId = 10 + _localOfflineSchools.length + 1;
      final localSchool = {
        'id': newId,
        'name': data['name'] ?? '',
        'code': data['code'] ?? 'SCH-$newId',
        'address': data['address'] ?? '',
        'phone': data['phone'] ?? '',
        'is_active': true,
      };
      _localOfflineSchools.add(localSchool);
      return localSchool;
    }

    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/schools'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = _decodeResponse(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (resData is Map<String, dynamic>) ? resData : <String, dynamic>{};
    }
    throw Exception(resData['detail'] ?? 'خطا در ثبت مدرسه در دیتابیس (کد وضعیت: ${res.statusCode})');
  }

  static Future<void> deleteSchool(int id) async {
    if (isOfflineEmergencyMode) {
      _localOfflineSchools.removeWhere((s) => s['id'] == id);
      return;
    }
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/schools/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> updateSchool(int id, Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      final idx = _localOfflineSchools.indexWhere((s) => s['id'] == id);
      if (idx != -1) {
        _localOfflineSchools[idx].addAll(data);
      }
      return;
    }
    final token = await getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/schools/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      final resData = _decodeResponse(res);
      throw Exception(resData['detail'] ?? 'خطا در ویرایش مدرسه');
    }
  }

  static Future<Map<String, dynamic>> createTimeSlot(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      return {
        'id': DateTime.now().millisecondsSinceEpoch % 1000,
        ...data,
      };
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/time-slots'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = _decodeResponse(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (resData is Map<String, dynamic>) ? resData : <String, dynamic>{};
    }
    throw Exception(resData['detail'] ?? 'خطا در ثبت سانس زمانی');
  }

  static Future<void> deleteTimeSlot(int id) async {
    if (isOfflineEmergencyMode) return;
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/time-slots/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<List<int>> downloadExcelReport() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/reports/reservations/excel'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    throw Exception('خطا در دریافت خروجی اکسل از سرور');
  }

  static Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data) async {
    if (isOfflineEmergencyMode) {
      return {
        'id': DateTime.now().millisecondsSinceEpoch % 1000,
        ...data,
      };
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/holidays'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = _decodeResponse(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (resData is Map<String, dynamic>) ? resData : <String, dynamic>{};
    }
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
      return {
        'id': DateTime.now().millisecondsSinceEpoch % 1000,
        ...data,
      };
    }
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/restrictions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resData = _decodeResponse(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (resData is Map<String, dynamic>) ? resData : <String, dynamic>{};
    }
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
