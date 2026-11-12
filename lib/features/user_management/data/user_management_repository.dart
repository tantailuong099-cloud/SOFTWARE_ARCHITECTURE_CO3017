import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'models/app_user_model.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserManagementRepository(dio);
});

class UserManagementRepository {
  final Dio _dio;

  UserManagementRepository(this._dio);

  Future<List<AppUserModel>> fetchUsers({
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _dio.get('/users', queryParameters: queryParams);
      final data = response.data;

      if (data is Map && data['items'] is List) {
        final items = data['items'] as List;
        return items
            .map((item) => AppUserModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tải danh sách người dùng';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<AppUserModel> createUser({
    required String employeeCode,
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? factoryId,
    String status = 'ACTIVE',
  }) async {
    try {
      final payload = <String, dynamic>{
        'employeeCode': employeeCode.trim(),
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'status': status,
        if (factoryId != null && factoryId.isNotEmpty) 'factoryId': factoryId,
      };

      final response = await _dio.post('/users', data: payload);
      final data = Map<String, dynamic>.from(response.data as Map);
      return AppUserModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tạo tài khoản';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<AppUserModel> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? password,
    String? factoryId,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (fullName != null && fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
        if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
        if (factoryId != null) 'factoryId': factoryId.isEmpty ? null : factoryId,
      };

      final response = await _dio.patch('/users/$id', data: payload);
      final data = Map<String, dynamic>.from(response.data as Map);
      return AppUserModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật người dùng';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<AppUserModel> updateUserStatus(String id, String status) async {
    try {
      final response = await _dio.patch(
        '/users/$id/status',
        data: {'status': status.toUpperCase()},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return AppUserModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể đổi trạng thái';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }
}
