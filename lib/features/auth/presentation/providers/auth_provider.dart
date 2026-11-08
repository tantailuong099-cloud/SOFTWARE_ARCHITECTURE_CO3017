import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
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
  late AuthRepository _authRepository;
  bool _hasCheckedSavedSession = false;
  int _generation = 0;
  Future<void> _operations = Future<void>.value();

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);
    _authRepository = repository;
    final generation = ++_generation;
    _hasCheckedSavedSession = false;
    ref.listen(apiEndpointSettingsProvider, (previous, next) {
      if (previous == null || previous == next) return;
      _generation++;
      _hasCheckedSavedSession = true;
      state = AuthState();
      // Clear old credentials after any in-flight auth write and before the next login.
      unawaited(_enqueue(() => _clearStoredSession(repository)));
    });
    unawaited(
      Future<void>.microtask(() async {
        if (_isCurrent(generation)) await checkSavedSession();
      }),
    );
    return AuthState(isLoading: true);
  }

  Future<void> checkSavedSession() {
    if (_hasCheckedSavedSession) return Future<void>.value();
    _hasCheckedSavedSession = true;
    final generation = _generation;
    final repository = _authRepository;
    return _enqueue(() async {
      if (!_isCurrent(generation)) return;
      try {
        final data = await repository.getStoredUserData();
        if (!_isCurrent(generation)) return;
        final token = data['accessToken'];
        state = token == null
            ? AuthState()
            : AuthState(
                isAuthenticated: true,
                accessToken: token,
                role: data['role'],
                email: data['email'],
                name: data['name'],
                employeeCode: data['employeeCode'],
              );
      } catch (_) {
        if (_isCurrent(generation)) state = AuthState();
      }
    });
  }

  Future<bool> login(String email, String password) {
    final generation = ++_generation;
    final repository = _authRepository;
    _hasCheckedSavedSession = true;
    state = AuthState(isLoading: true);
    return _enqueue(() async {
      if (!_isCurrent(generation)) return false;
      try {
        await repository.clearStoredSession();
        if (!_isCurrent(generation)) return false;
        final result = await repository.login(email, password);
        if (!_isCurrent(generation)) return false;
        final user = Map<String, dynamic>.from(result['user'] as Map);
        state = AuthState(
          isAuthenticated: true,
          accessToken: result['accessToken'],
          role: result['role'],
          email: user['email'],
          name: user['fullName'],
          employeeCode: user['employeeCode'],
        );
        return true;
      } catch (error) {
        if (!_isCurrent(generation)) return false;
        await _clearStoredSession(repository);
        if (_isCurrent(generation)) {
          state = AuthState(
            errorMessage: error.toString().replaceAll('Exception: ', ''),
          );
        }
        return false;
      }
    });
  }

  Future<void> logout() {
    final generation = ++_generation;
    final repository = _authRepository;
    _hasCheckedSavedSession = true;
    state = state.copyWith(isLoading: true);
    return _enqueue(() async {
      if (!_isCurrent(generation)) return;
      try {
        await repository.logout();
      } finally {
        if (_isCurrent(generation)) state = AuthState();
      }
    });
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final operation = _operations.then((_) => action());
    _operations = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<void> _clearStoredSession(AuthRepository repository) async {
    try {
      await repository.clearStoredSession();
    } catch (_) {
      debugPrint('Could not clear the stored authentication session.');
    }
  }
}
