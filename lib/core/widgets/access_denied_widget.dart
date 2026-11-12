import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';

class AccessDeniedWidget extends StatelessWidget {
  final String title;
  final String message;
  final AppUserRole? currentRole;
  final VoidCallback? onBack;

  const AccessDeniedWidget({
    super.key,
    this.title = 'Quyền truy cập bị từ chối',
    required this.message,
    this.currentRole,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.red.shade100,
                    child: Icon(
                      Icons.gpp_bad_rounded,
                      size: 40,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (currentRole != null) ...[
                    const SizedBox(height: 16),
                    Chip(
                      avatar: Icon(
                        currentRole!.icon,
                        size: 16,
                        color: currentRole!.primaryColor,
                      ),
                      label: Text(
                        'Vai trò hiện tại: ${currentRole!.title}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: currentRole!.primaryColor,
                        ),
                      ),
                      backgroundColor: currentRole!.backgroundColor,
                      side: BorderSide(color: currentRole!.borderColor),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onBack ??
                        () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Quay lại trang chính'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
