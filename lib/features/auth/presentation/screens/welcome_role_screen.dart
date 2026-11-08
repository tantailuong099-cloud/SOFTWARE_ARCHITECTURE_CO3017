import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';

class WelcomeRoleScreen extends ConsumerWidget {
  const WelcomeRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = (authState.role ?? 'EMPLOYEE').toUpperCase();
    final name = authState.name ?? authState.email ?? 'Người dùng';
    final employeeCode = authState.employeeCode ?? 'N/A';
    final token = authState.accessToken ?? '';

    // Render text based on role as requested
    bool isAdmin = role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận Đăng nhập Thành công'),
        backgroundColor: isAdmin ? Colors.indigo[800] : Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Role Icon / Badge
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: isAdmin
                            ? Colors.indigo.shade100
                            : Colors.teal.shade100,
                        child: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.badge_rounded,
                          size: 40,
                          color: isAdmin
                              ? Colors.indigo[800]
                              : Colors.teal[700],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Welcome Title
                      Text(
                        'Đăng nhập thành công!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAdmin
                              ? Colors.indigo[800]
                              : Colors.teal[700],
                        ),
                      ),
                      Text(
                        'Mã NV: $employeeCode | Email: ${authState.email}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 36),

                      // ROLE-SPECIFIC RENDER TEXT AS REQUESTED
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? Colors.indigo.shade50
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAdmin
                                ? Colors.indigo.shade200
                                : Colors.teal.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isAdmin
                                      ? Icons.verified_user
                                      : Icons.check_circle_outline,
                                  color: isAdmin
                                      ? Colors.indigo[700]
                                      : Colors.teal[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAdmin
                                      ? 'Quyền Hạn: Quản trị viên (ADMIN)'
                                      : 'Quyền Hạn: Nhân viên (EMPLOYEE)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isAdmin
                                        ? Colors.indigo[900]
                                        : Colors.teal[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAdmin
                                  ? 'Chào mừng Quản trị viên! Bạn có toàn quyền quản lý hệ thống trạm kiểm soát, giám sát nhật ký ra vào toàn công ty và cấu hình các thiết bị bảo vệ.'
                                  : 'Chào mừng Nhân viên! Bạn có thể xem mã QR cá nhân của mình để điểm danh qua trạm kiểm soát ra vào công ty.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isAdmin
                                    ? Colors.indigo[900]
                                    : Colors.teal[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Token display section
                      ExpansionTile(
                        leading: const Icon(Icons.vpn_key_rounded, size: 20),
                        title: const Text(
                          'Xem JWT Access Token & Trạng thái',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                token.isEmpty ? 'Không có token' : token,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).logout();
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Đăng xuất tài khoản',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
