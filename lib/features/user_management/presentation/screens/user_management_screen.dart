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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: Colors.indigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Quản Lý Người Dùng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: state.isLoading ? null : () => notifier.loadUsers(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Tải lại danh sách',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý nhân sự, phân quyền vai trò và trạng thái truy cập cổng TMC',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                  ),

                  const SizedBox(height: 14),

                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Tổng số',
                        count: state.totalCount,
                        color: Colors.indigo,
                        icon: Icons.people_alt_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'Hoạt động',
                        count: state.activeCount,
                        color: Colors.teal,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'Tạm ngưng',
                        count: state.suspendedCount,
                        color: Colors.redAccent,
                        icon: Icons.block_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search and Filters (2 rows for responsive layout)
                  Column(
                    children: [
                      TextField(
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Role filter dropdown
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: state.roleFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.filter_list_rounded, size: 16),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  onChanged: (val) {
                                    if (val != null) notifier.setRoleFilter(val);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả vai trò')),
                                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                                    DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên')),
                                    DropdownMenuItem(value: 'SECURITY_GUARD', child: Text('Bảo vệ')),
                                    DropdownMenuItem(value: 'SUPERVISOR', child: Text('Giám sát')),
                                    DropdownMenuItem(value: 'HR_STAFF', child: Text('Nhân sự')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status filter dropdown
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: state.statusFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.toggle_on_outlined, size: 16),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  onChanged: (val) {
                                    if (val != null) notifier.setStatusFilter(val);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'ALL', child: Text('Mọi trạng thái')),
                                    DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                                    DropdownMenuItem(value: 'SUSPENDED', child: Text('Đang tạm ngưng')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name & Code + Actions
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 12, color: Colors.blueGrey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            user.employeeCode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton.outlined(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Chỉnh sửa tài khoản',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditUserDialog(context, user),
                ),
                const SizedBox(width: 6),
                // Lock / Unlock button
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
                            child: Text(isActive ? 'Khóa' : 'Kích hoạt'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final ok = await ref.read(userManagementProvider.notifier).toggleUserStatus(user.id);
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã cập nhật trạng thái của '),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    size: 14,
                    color: isActive ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  label: Text(
                    isActive ? 'Khóa' : 'Kích hoạt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive ? Colors.red.shade50 : Colors.green.shade50,
                    side: BorderSide(color: isActive ? Colors.red.shade200 : Colors.green.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Middle: Role, Status, and Factory Badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    isActive ? 'HOẠT ĐỘNG' : 'TẠM NGƯNG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
                if (user.factoryId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.factory_outlined, size: 11, color: Colors.blueGrey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          user.factoryId == 'BINH_DUONG'
                              ? 'Bình Dương'
                              : (user.factoryId == 'LONG_AN' ? 'Long An' : user.factoryId!),
                          style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Bottom: Email
            Row(
              children: [
                Icon(Icons.email_outlined, size: 12, color: Colors.blueGrey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.email,
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
