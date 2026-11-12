import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
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
        data: {'email': email.trim().toLowerCase(), 'password': password.trim()},
        options: Options(followRedirects: false),
      );

      if (response.data is! Map) {
        throw const FormatException('Phản hồi đăng nhập không hợp lệ');
      }

      final issuer = response.requestOptions.baseUrl;
      if (issuer != _dio.options.baseUrl) {
        throw const FormatException(
          'The backend address changed. Sign in again.',
        );
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

      await _secureStorage.write(
        key: _keyAccessToken,
        value: jsonEncode({'token': accessToken, 'endpoint': issuer}),
      );
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
      final serverMsg = e.response?.data?['message'];
      final message = serverMsg is List
          ? serverMsg.join(', ')
          : serverMsg ?? e.message ?? 'Đăng nhập thất bại';
      debugPrint('[Auth API Failed] URL: ${e.requestOptions.uri} | Status: ${e.response?.statusCode} | Lý do từ Server: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('[Auth API Failed] Invalid login response: $e');
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  Future<Map<String, String?>> getStoredUserData() async {
    final session = await _readAccessSession();
    if (session == null || session.endpoint != _dio.options.baseUrl) {
      return const {};
    }
    final role = await _secureStorage.read(key: _keyUserRole);
    final email = await _secureStorage.read(key: _keyUserEmail);
    final name = await _secureStorage.read(key: _keyUserName);
    final employeeCode = await _secureStorage.read(key: _keyEmployeeCode);

    if (session.endpoint != _dio.options.baseUrl) return const {};
    return {
      'accessToken': session.token,
      'role': role,
      'email': email,
      'name': name,
      'employeeCode': employeeCode,
    };
  }

  Future<({String token, String endpoint})?> _readAccessSession() async {
    final stored = await _secureStorage.read(key: _keyAccessToken);
    if (stored == null || stored.isEmpty) return null;
    if (!stored.startsWith('{')) {
      return (token: stored, endpoint: ApiConfig.defaultBaseUrl);
    }
    try {
      final value = jsonDecode(stored);
      if (value case {
        'token': final String token,
        'endpoint': final String endpoint,
      } when token.isNotEmpty && endpoint.isNotEmpty) {
        return (token: token, endpoint: endpoint);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final session = await _readAccessSession();
      if (session != null && _dio.options.baseUrl == session.endpoint) {
        await _dio.post(
          '/auth/logout',
          options: Options(
            headers: {'Authorization': 'Bearer ${session.token}'},
            followRedirects: false,
          ),
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
