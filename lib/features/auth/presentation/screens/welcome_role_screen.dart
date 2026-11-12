import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import '../providers/auth_provider.dart';

class WelcomeRoleScreen extends ConsumerWidget {
  const WelcomeRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    final name = authState.name ?? authState.email ?? 'Người dùng';
    final employeeCode = authState.employeeCode ?? 'N/A';
    final token = authState.accessToken ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận Đăng nhập Thành công'),
        backgroundColor: userRole.primaryColor,
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
              constraints: const BoxConstraints(maxWidth: 640),
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
                        backgroundColor: userRole.backgroundColor,
                        child: Icon(
                          userRole.icon,
                          size: 40,
                          color: userRole.primaryColor,
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
                              color: userRole.primaryColor,
                            ),
                      ),
                      Text(
                        'Mã NV: $employeeCode | Email: ${authState.email}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 36),

                      // ROLE-SPECIFIC INFO CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: userRole.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: userRole.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(userRole.icon, color: userRole.primaryColor),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Quyền Hạn: ${userRole.title}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: userRole.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userRole.description,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // UI ACCESS CONTROL MATRIX CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_person_outlined,
                                  size: 20,
                                  color: Colors.blueGrey.shade800,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Phân quyền truy cập giao diện (UI Access Control)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPermissionItem(
                              context,
                              title: 'Trạm quét Kiosk (Gate Station)',
                              isAllowed: userRole.canAccessKiosk,
                              note: userRole.canAccessKiosk
                                  ? 'Được phép vận hành trạm quét và điều khiển cổng barie.'
                                  : 'Bị chặn (Chỉ dành cho ADMIN & SECURITY_GUARD).',
                            ),
                            const Divider(height: 16),
                            _buildPermissionItem(
                              context,
                              title: 'Nhật ký sự kiện ra vào (Gate Events)',
                              isAllowed: userRole.canAccessRecentEvents,
                              note: userRole.canAccessRecentEvents
                                  ? 'Được phép theo dõi luồng sự kiện quẹt thẻ vào/ra.'
                                  : 'Bị chặn (Không dành cho vai trò EMPLOYEE).',
                            ),
                            const Divider(height: 16),
                            _buildPermissionItem(
                              context,
                              title: 'Mã QR Thẻ nhân viên (Employee QR Card)',
                              isAllowed: userRole.canAccessQrCard,
                              note:
                                  'Được phép hiển thị mã QR tĩnh và mã QR động 30s qua cổng.',
                            ),
                            const Divider(height: 16),
                            _buildPermissionItem(
                              context,
                              title: 'Cấu hình trạm & kết nối API (Station Settings)',
                              isAllowed: userRole.canAccessSettings,
                              note: userRole.canAccessSettings
                                  ? 'Được phép cấu hình endpoint API và thiết bị trạm.'
                                  : 'Bị chặn (Chỉ dành riêng cho ADMIN).',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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

                      // Site Selection Buttons
                      if (userRole == AppUserRole.admin) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/admin'),
                            icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                            label: const Text('Truy Cập Site Quản Trị (Admin Portal)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.go('/user'),
                            icon: const Icon(Icons.badge_rounded, size: 18),
                            label: const Text('Xem Giao Diện Thẻ Nhân Viên (User Portal)'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/user'),
                            icon: const Icon(Icons.badge_rounded, size: 18),
                            label: const Text('Vào Giao Diện Nhân Viên (User Portal)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

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

  Widget _buildPermissionItem(
    BuildContext context, {
    required String title,
    required bool isAllowed,
    required String note,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isAllowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isAllowed ? Colors.green.shade600 : Colors.red.shade600,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isAllowed
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isAllowed
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      isAllowed ? 'Cho phép' : 'Bị chặn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAllowed
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
