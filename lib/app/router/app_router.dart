import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/admin_portal_screen.dart';
import '../../features/home/presentation/screens/user_portal_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.uri.path == '/login';

      // 1. Khi đang khởi động / kiểm tra phiên lưu trữ:
      // Tuyệt đối không cho vào /admin hay /user khi chưa có xác thực
      if (authState.isLoading) {
        return isLoggedIn ? null : (isLoggingIn ? null : '/login');
      }

      // 2. Chưa xác thực đăng nhập: Chuyển toàn bộ về /login
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 3. Đã đăng nhập thành công: Nếu đang ở /login hoặc / -> Chuyển vào trang chính theo Role
      if (isLoggingIn || state.uri.path == '/') {
        final role = AppUserRole.fromString(authState.role);
        return role == AppUserRole.admin ? '/admin' : '/user';
      }

      // 4. Bảo vệ route /admin: Chỉ ADMIN mới được truy cập
      if (state.uri.path.startsWith('/admin')) {
        final role = AppUserRole.fromString(authState.role);
        if (role != AppUserRole.admin) {
          return '/user';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        redirect: (context, state) {
          if (!authState.isAuthenticated) return '/login';
          final role = AppUserRole.fromString(authState.role);
          return role == AppUserRole.admin ? '/admin' : '/user';
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminPortalScreen(),
      ),
      GoRoute(
        path: '/user',
        name: 'user',
        builder: (context, state) => const UserPortalScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        redirect: (context, state) {
          if (!authState.isAuthenticated) return '/login';
          final role = AppUserRole.fromString(authState.role);
          return role == AppUserRole.admin ? '/admin' : '/user';
        },
      ),
    ],
  );
});

// Helper stream notifier for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
}
