import 'package:flutter/material.dart';

/// Các vai trò người dùng trong hệ thống TMC Attendance M2
/// Phù hợp với database schema:
/// - ADMIN: Quản trị viên hệ thống
/// - SECURITY_GUARD: Nhân viên bảo vệ trực trạm cổng
/// - SUPERVISOR: Cán bộ giám sát phân xưởng
/// - HR_STAFF: Nhân viên phòng nhân sự
/// - EMPLOYEE: Nhân viên / Công nhân
enum AppUserRole {
  admin,
  securityGuard,
  supervisor,
  hrStaff,
  employee;

  static AppUserRole fromString(String? role) {
    if (role == null || role.trim().isEmpty) {
      // Mặc định ADMIN nếu không truyền role (nhằm tương thích với fixture tests cũ)
      return AppUserRole.admin;
    }
    switch (role.toUpperCase().trim()) {
      case 'ADMIN':
        return AppUserRole.admin;
      case 'SECURITY_GUARD':
        return AppUserRole.securityGuard;
      case 'SUPERVISOR':
        return AppUserRole.supervisor;
      case 'HR_STAFF':
        return AppUserRole.hrStaff;
      case 'EMPLOYEE':
        return AppUserRole.employee;
      default:
        return AppUserRole.employee;
    }
  }

  String get code {
    switch (this) {
      case AppUserRole.admin:
        return 'ADMIN';
      case AppUserRole.securityGuard:
        return 'SECURITY_GUARD';
      case AppUserRole.supervisor:
        return 'SUPERVISOR';
      case AppUserRole.hrStaff:
        return 'HR_STAFF';
      case AppUserRole.employee:
        return 'EMPLOYEE';
    }
  }

  String get title {
    switch (this) {
      case AppUserRole.admin:
        return 'Quản trị viên (ADMIN)';
      case AppUserRole.securityGuard:
        return 'Bảo vệ trực cổng (SECURITY_GUARD)';
      case AppUserRole.supervisor:
        return 'Giám sát phân xưởng (SUPERVISOR)';
      case AppUserRole.hrStaff:
        return 'Nhân viên Nhân sự (HR_STAFF)';
      case AppUserRole.employee:
        return 'Nhân viên / Công nhân (EMPLOYEE)';
    }
  }

  String get description {
    switch (this) {
      case AppUserRole.admin:
        return 'Chào mừng Quản trị viên! Bạn có toàn quyền quản trị hệ thống: cấu hình kết nối trạm cổng, quản lý thiết bị, trực trạm quét Kiosk, theo dõi nhật ký toàn bộ nhân sự và quản lý thẻ mã QR.';
      case AppUserRole.securityGuard:
        return 'Chào mừng Nhân viên Bảo vệ! Bạn được phân công vận hành Trạm quét Kiosk tại cổng, theo dõi trạng thái đóng/mở barie, giám sát nhật ký quẹt thẻ thời gian thực và sử dụng thẻ QR cá nhân.';
      case AppUserRole.supervisor:
        return 'Chào mừng Giám sát viên! Bạn có quyền theo dõi nhật ký quét thẻ ra/vào của công nhân viên trong các phân xưởng để quản lý ca làm việc và sử dụng mã QR cá nhân để điểm danh.';
      case AppUserRole.hrStaff:
        return 'Chào mừng Nhân sự! Bạn có quyền tra cứu, kiểm tra nhật ký sự kiện quẹt thẻ vào/ra phục vụ việc đối soát công chuẩn xác và sử dụng mã QR cá nhân để điểm danh.';
      case AppUserRole.employee:
        return 'Chào mừng Nhân viên! Bạn có thể sử dụng mã QR cá nhân (mã tĩnh hoặc mã động 30s) trên thẻ nhân viên điện tử để quét qua trạm kiểm soát ra/vào công ty.';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppUserRole.admin:
        return Colors.indigo.shade800;
      case AppUserRole.securityGuard:
        return Colors.deepOrange.shade800;
      case AppUserRole.supervisor:
        return Colors.deepPurple.shade800;
      case AppUserRole.hrStaff:
        return Colors.teal.shade800;
      case AppUserRole.employee:
        return Colors.blueGrey.shade800;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AppUserRole.admin:
        return Colors.indigo.shade50;
      case AppUserRole.securityGuard:
        return Colors.deepOrange.shade50;
      case AppUserRole.supervisor:
        return Colors.deepPurple.shade50;
      case AppUserRole.hrStaff:
        return Colors.teal.shade50;
      case AppUserRole.employee:
        return Colors.blueGrey.shade50;
    }
  }

  Color get borderColor {
    switch (this) {
      case AppUserRole.admin:
        return Colors.indigo.shade200;
      case AppUserRole.securityGuard:
        return Colors.deepOrange.shade200;
      case AppUserRole.supervisor:
        return Colors.deepPurple.shade200;
      case AppUserRole.hrStaff:
        return Colors.teal.shade200;
      case AppUserRole.employee:
        return Colors.blueGrey.shade200;
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case AppUserRole.securityGuard:
        return Icons.local_police_rounded;
      case AppUserRole.supervisor:
        return Icons.supervisor_account_rounded;
      case AppUserRole.hrStaff:
        return Icons.assignment_ind_rounded;
      case AppUserRole.employee:
        return Icons.badge_rounded;
    }
  }

  // --- Quyền hạn truy cập UI ---

  /// Trạm quét Kiosk (GateStationKioskScreen): Chỉ ADMIN và SECURITY_GUARD
  bool get canAccessKiosk =>
      this == AppUserRole.admin || this == AppUserRole.securityGuard;

  /// Nhật ký sự kiện ra vào (RecentGateEventsScreen): ADMIN, SECURITY_GUARD, SUPERVISOR, HR_STAFF
  bool get canAccessRecentEvents => this != AppUserRole.employee;

  /// Thẻ nhân viên & mã QR cá nhân (EmployeeQRCardScreen): Toàn bộ tài khoản
  bool get canAccessQrCard => true;

  /// Cấu hình trạm và kết nối API (StationSettingsScreen): Chỉ duy nhất ADMIN
  bool get canAccessSettings => this == AppUserRole.admin;
}
