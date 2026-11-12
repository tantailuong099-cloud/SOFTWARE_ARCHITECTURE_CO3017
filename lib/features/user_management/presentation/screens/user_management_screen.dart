import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_user_model.dart';
import '../providers/user_management_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.indigo;
      case 'SECURITY_GUARD':
        return Colors.deepOrange;
      case 'SUPERVISOR':
        return Colors.purple;
      case 'HR_STAFF':
        return Colors.teal;
      case 'EMPLOYEE':
      default:
        return Colors.blueGrey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên (ADMIN)';
      case 'SECURITY_GUARD':
        return 'Bảo vệ (SECURITY)';
      case 'SUPERVISOR':
        return 'Giám sát (SUPERVISOR)';
      case 'HR_STAFF':
        return 'Nhân sự (HR)';
      case 'EMPLOYEE':
      default:
        return 'Nhân viên (EMPLOYEE)';
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddUserDialog(),
    );
  }

  void _showEditUserDialog(BuildContext context, AppUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUserDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);
    final filteredUsers = state.filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Top App Bar / Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: Colors.indigo,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quản Lý Tài Khoản Người Dùng',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quản lý danh sách nhân sự, phân quyền vai trò và cấp phép truy cập cổng trạm TMC',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: state.isLoading ? null : () => notifier.loadUsers(),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Tải lại danh sách',
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Thêm người dùng'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Tổng số tài khoản',
                        count: state.totalCount,
                        color: Colors.indigo,
                        icon: Icons.people_alt_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Đang hoạt động',
                        count: state.activeCount,
                        color: Colors.teal,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Đang tạm ngưng',
                        count: state.suspendedCount,
                        color: Colors.redAccent,
                        icon: Icons.block_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Search and Filters
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          onChanged: notifier.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên, mã NV, email...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Role filter dropdown
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: state.roleFilter,
                              isExpanded: true,
                              icon: const Icon(Icons.filter_list_rounded, size: 18),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              onChanged: (val) {
                                if (val != null) notifier.setRoleFilter(val);
                              },
                              items: const [
                                DropdownMenuItem(value: 'ALL', child: Text('Tất cả vai trò')),
                                DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                                DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên (EMPLOYEE)')),
                                DropdownMenuItem(value: 'SECURITY_GUARD', child: Text('Bảo vệ (SECURITY)')),
                                DropdownMenuItem(value: 'SUPERVISOR', child: Text('Giám sát (SUPERVISOR)')),
                                DropdownMenuItem(value: 'HR_STAFF', child: Text('Nhân sự (HR)')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status filter dropdown
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: state.statusFilter,
                              isExpanded: true,
                              icon: const Icon(Icons.toggle_on_outlined, size: 18),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              onChanged: (val) {
                                if (val != null) notifier.setStatusFilter(val);
                              },
                              items: const [
                                DropdownMenuItem(value: 'ALL', child: Text('Mọi trạng thái')),
                                DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                                DropdownMenuItem(value: 'SUSPENDED', child: Text('Tạm ngưng')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Error Message Banner if any
          if (state.errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // User List Content
          if (state.isLoading && state.users.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredUsers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy người dùng phù hợp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(context, user);
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUserModel user) {
    final roleColor = _getRoleColor(user.role);
    final isActive = user.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.12),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'SUSPENDED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        user.employeeCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.email_outlined, size: 14, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.email,
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.factoryId != null) ...[
                        const SizedBox(width: 14),
                        Icon(Icons.factory_outlined, size: 14, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          user.factoryId == 'BINH_DUONG' ? 'Bình Dương' : (user.factoryId == 'LONG_AN' ? 'Long An' : user.factoryId!),
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Actions
            IconButton.outlined(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Chỉnh sửa tài khoản',
              onPressed: () => _showEditUserDialog(context, user),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isActive ? 'Tạm ngưng tài khoản?' : 'Kích hoạt tài khoản?'),
                    content: Text(
                      isActive
                          ? 'Người dùng ${user.fullName} (${user.employeeCode}) sẽ bị khóa thẻ và không thể quét qua cổng.'
                          : 'Kích hoạt lại tài khoản ${user.fullName} để cho phép quét thẻ qua cổng trạm.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isActive ? Colors.red : Colors.green,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(isActive ? 'Khóa tài khoản' : 'Kích hoạt'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final ok = await ref.read(userManagementProvider.notifier).toggleUserStatus(user.id);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật trạng thái của ${user.fullName}'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                size: 16,
                color: isActive ? Colors.red.shade700 : Colors.green.shade700,
              ),
              label: Text(
                isActive ? 'Khóa' : 'Kích hoạt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isActive ? Colors.red.shade50 : Colors.green.shade50,
                side: BorderSide(color: isActive ? Colors.red.shade200 : Colors.green.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog: Thêm tài khoản người dùng
class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _employeeCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'password123');

  String _selectedRole = 'EMPLOYEE';
  String _selectedFactory = 'BINH_DUONG';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(userManagementProvider.notifier).createUser(
        employeeCode: _employeeCodeController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        factoryId: _selectedRole == 'ADMIN' ? null : _selectedFactory,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm tài khoản người dùng thành công!'),
              backgroundColor: Colors.teal,
            ),
          );
        } else {
          final err = ref.read(userManagementProvider).errorMessage ?? 'Lỗi không xác định';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.indigo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thêm Tài Khoản Mới',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Mã nhân viên
                  TextFormField(
                    controller: _employeeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã nhân viên (Employee Code) *',
                      hintText: 'Ví dụ: EMP-BD-010',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập mã NV' : null,
                  ),
                  const SizedBox(height: 14),

                  // Họ và tên
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      hintText: 'Ví dụ: Nguyễn Văn Hoàng',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập họ tên' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'hoang.nguyen@tmc.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu khởi tạo *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: 14),

                  // Vai trò
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò (Role) *',
                      prefixIcon: Icon(Icons.security_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên (EMPLOYEE)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                      DropdownMenuItem(value: 'SECURITY_GUARD', child: Text('Bảo vệ trạm cổng (SECURITY_GUARD)')),
                      DropdownMenuItem(value: 'SUPERVISOR', child: Text('Giám sát phân xưởng (SUPERVISOR)')),
                      DropdownMenuItem(value: 'HR_STAFF', child: Text('Nhân sự (HR_STAFF)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phân xưởng
                  if (_selectedRole != 'ADMIN')
                    DropdownButtonFormField<String>(
                      value: _selectedFactory,
                      decoration: const InputDecoration(
                        labelText: 'Phân xưởng làm việc *',
                        prefixIcon: Icon(Icons.factory_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BINH_DUONG', child: Text('Nhà máy Bình Dương (BINH_DUONG)')),
                        DropdownMenuItem(value: 'LONG_AN', child: Text('Nhà máy Long An (LONG_AN)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFactory = val);
                      },
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                        ),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Tạo tài khoản'),
                      ),
                    ],
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

// Dialog: Chỉnh sửa tài khoản
class _EditUserDialog extends ConsumerStatefulWidget {
  final AppUserModel user;
  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  String? _selectedFactory;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedFactory = widget.user.factoryId;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(userManagementProvider.notifier).updateUser(
        widget.user.id,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        factoryId: _selectedFactory,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công!'),
              backgroundColor: Colors.teal,
            ),
          );
        } else {
          final err = ref.read(userManagementProvider).errorMessage ?? 'Lỗi không xác định';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chỉnh Sửa Tài Khoản',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Mã NV: ${widget.user.employeeCode} (${widget.user.role})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Họ và tên
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập họ tên' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Đổi mật khẩu mới (không bắt buộc)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Đổi mật khẩu mới (để trống nếu giữ nguyên)',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phân xưởng
                  if (widget.user.role != 'ADMIN')
                    DropdownButtonFormField<String>(
                      value: _selectedFactory ?? 'BINH_DUONG',
                      decoration: const InputDecoration(
                        labelText: 'Phân xưởng làm việc',
                        prefixIcon: Icon(Icons.factory_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BINH_DUONG', child: Text('Nhà máy Bình Dương (BINH_DUONG)')),
                        DropdownMenuItem(value: 'LONG_AN', child: Text('Nhà máy Long An (LONG_AN)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFactory = val);
                      },
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Lưu thay đổi'),
                      ),
                    ],
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
