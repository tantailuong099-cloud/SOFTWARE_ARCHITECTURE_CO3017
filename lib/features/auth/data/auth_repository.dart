import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._dio);

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyEmployeeCode = 'employee_code';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.data is! Map) {
        throw const FormatException('Phản hồi đăng nhập không hợp lệ');
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      final rawUser = data['user'];
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          rawUser is! Map) {
        throw const FormatException(
          'Phản hồi đăng nhập thiếu thông tin xác thực',
        );
      }

      final user = Map<String, dynamic>.from(rawUser);
      final role = user['role'] as String? ?? 'EMPLOYEE';
      final emailVal = user['email'] as String? ?? email;
      final nameVal = user['fullName'] as String? ?? '';
      final empCode = user['employeeCode'] as String? ?? '';

      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      await _secureStorage.write(key: _keyUserRole, value: role);
      await _secureStorage.write(key: _keyUserEmail, value: emailVal);
      await _secureStorage.write(key: _keyUserName, value: nameVal);
      await _secureStorage.write(key: _keyEmployeeCode, value: empCode);

      debugPrint('[Auth Success] Credentials accepted by API for $emailVal.');
      return {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': user,
        'role': role,
      };
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Đăng nhập thất bại';
      debugPrint('[Auth API Failed] Login request failed: $message');
      throw Exception(message is List ? message.join(', ') : message);
    } catch (e) {
      debugPrint('[Auth API Failed] Invalid login response: $e');
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  Future<Map<String, String?>> getStoredUserData() async {
    final accessToken = await _secureStorage.read(key: _keyAccessToken);
    final role = await _secureStorage.read(key: _keyUserRole);
    final email = await _secureStorage.read(key: _keyUserEmail);
    final name = await _secureStorage.read(key: _keyUserName);
    final employeeCode = await _secureStorage.read(key: _keyEmployeeCode);

    return {
      'accessToken': accessToken,
      'role': role,
      'email': email,
      'name': name,
      'employeeCode': employeeCode,
    };
  }

  Future<void> logout() async {
    try {
      final token = await _secureStorage.read(key: _keyAccessToken);
      if (token != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _secureStorage.deleteAll();
    }
  }

  Future<void> clearStoredSession() async {
    await _secureStorage.deleteAll();
  }
}
