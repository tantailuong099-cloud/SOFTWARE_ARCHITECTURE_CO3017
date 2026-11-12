import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/app_user_model.dart';
import '../../data/user_management_repository.dart';

class UserManagementState {
  final List<AppUserModel> users;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String searchQuery;
  final String roleFilter;
  final String statusFilter;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.searchQuery = '',
    this.roleFilter = 'ALL',
    this.statusFilter = 'ALL',
  });

  List<AppUserModel> get filteredUsers {
    return users.where((user) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchCode = user.employeeCode.toLowerCase().contains(query);
        final matchName = user.fullName.toLowerCase().contains(query);
        final matchEmail = user.email.toLowerCase().contains(query);
        if (!matchCode && !matchName && !matchEmail) return false;
      }

      if (roleFilter != 'ALL' && user.role.toUpperCase() != roleFilter) {
        return false;
      }

      if (statusFilter != 'ALL' && user.status.toUpperCase() != statusFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  int get totalCount => users.length;
  int get activeCount => users.where((u) => u.isActive).length;
  int get suspendedCount => users.where((u) => !u.isActive).length;

  UserManagementState copyWith({
    List<AppUserModel>? users,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return UserManagementNotifier(repository);
});

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserManagementRepository _repository;

  UserManagementNotifier(this._repository) : super(const UserManagementState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.fetchUsers();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(String role) {
    state = state.copyWith(roleFilter: role);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<bool> createUser({
    required String employeeCode,
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? factoryId,
    String status = 'ACTIVE',
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final created = await _repository.createUser(
        employeeCode: employeeCode,
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        factoryId: factoryId,
        status: status,
      );
      state = state.copyWith(
        users: [created, ...state.users],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? password,
    String? factoryId,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final updated = await _repository.updateUser(
        id,
        fullName: fullName,
        email: email,
        password: password,
        factoryId: factoryId,
      );
      final updatedList = state.users.map((u) => u.id == id ? updated : u).toList();
      state = state.copyWith(users: updatedList, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleUserStatus(String id) async {
    final user = state.users.where((u) => u.id == id).firstOrNull;
    if (user == null) return false;

    final nextStatus = user.isActive ? 'SUSPENDED' : 'ACTIVE';
    try {
      final updated = await _repository.updateUserStatus(id, nextStatus);
      final updatedList = state.users.map((u) => u.id == id ? updated : u).toList();
      state = state.copyWith(users: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
