import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = 'http://localhost:8000/api/v1';

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
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      await saveTokens(data['access_token'], data['refresh_token']);
      return data;
    } else {
      throw Exception(data['detail'] ?? 'خطا در ورود به سامانه');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('نشست کاربری منقضی شده است');
    }
  }

  static Future<Map<String, dynamic>> getCalendarWeek({String? targetDate}) async {
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
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'خطا در بارگذاری تقویم');
    }
  }

  static Future<Map<String, dynamic>> createReservation({
    required String date,
    required int timeSlotId,
    String? description,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reservation_date': date,
        'time_slot_id': timeSlotId,
        'description': description,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'این زمان هم‌اکنون توسط کاربر دیگری رزرو شده است.');
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(int id, {String? reason}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'خطا در لغو رزرو');
    }
  }

  static Future<List<dynamic>> getMyHistory() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/my-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('خطا در دریافت سوابق رزرو');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
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
    final response = await http.get(Uri.parse('$baseUrl/system/health'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('سرور پاسخگو نیست');
    }
  }
}
