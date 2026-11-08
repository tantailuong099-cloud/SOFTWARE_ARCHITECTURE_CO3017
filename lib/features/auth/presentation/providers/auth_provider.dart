import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:tmc_gate_app/features/auth/data/auth_repository.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? accessToken;
  final String? role;
  final String? email;
  final String? name;
  final String? employeeCode;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.accessToken,
    this.role,
    this.email,
    this.name,
    this.employeeCode,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? accessToken,
    String? role,
    String? email,
    String? name,
    String? employeeCode,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      role: role ?? this.role,
      email: email ?? this.email,
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  bool _hasCheckedSavedSession = false;
  bool _isLoggingIn = false;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    // Trigger initial check asynchronously
    Future.microtask(() => checkSavedSession());
    return AuthState(isLoading: true);
  }

  Future<void> checkSavedSession() async {
    if (_hasCheckedSavedSession) return;
    _hasCheckedSavedSession = true;
    state = state.copyWith(isLoading: true);
    try {
      final data = await _authRepository.getStoredUserData();
      if (_isLoggingIn || state.isAuthenticated) return;
      final token = data['accessToken'];
      if (token != null && token.isNotEmpty) {
        debugPrint('[Auth] Restored saved session for ${data['email']}');
        state = state.copyWith(
          isAuthenticated: true,
          accessToken: token,
          role: data['role'],
          email: data['email'],
          name: data['name'],
          employeeCode: data['employeeCode'],
          isLoading: false,
        );
      } else {
        debugPrint('[Auth] No saved session. Authentication required.');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      debugPrint('[Auth] Failed to restore session: $e');
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint('[Auth] Login requested for $email');
    _isLoggingIn = true;
    await _authRepository.clearStoredSession();
    state = AuthState(
      isLoading: true,
      isAuthenticated: false,
      accessToken: null,
      errorMessage: null,
    );
    try {
      final result = await _authRepository.login(email, password);
      final rawUser = result['user'];
      final user = rawUser is Map<String, dynamic>
          ? rawUser
          : Map<String, dynamic>.from(rawUser as Map);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: result['accessToken'],
        role: result['role'],
        email: user['email'],
        name: user['fullName'],
        employeeCode: user['employeeCode'],
      );
      debugPrint(
        '[Auth Success] User "${user['email']}" (${user['role']}) authenticated.',
      );
      return true;
    } catch (e) {
      debugPrint('[Auth Failed] Login failed for $email: $e');
      await _authRepository.clearStoredSession();
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        accessToken: null,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> logout() async {
    debugPrint('[Auth] Logout requested.');
    state = state.copyWith(isLoading: true);
    await _authRepository.logout();
    state = AuthState(); // reset to unauthenticated
  }
}
