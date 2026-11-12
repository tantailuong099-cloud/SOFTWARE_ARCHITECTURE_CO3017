import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/config/api_endpoint.dart';
import '../../../../core/config/api_endpoint_settings.dart';
import '../../domain/station_configuration.dart';
import '../../domain/station_configuration_source.dart';
import '../providers/gate_station_provider.dart';
import '../providers/station_settings_controller.dart';
import '../widgets/station_administration_panel.dart';

class StationSettingsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const StationSettingsScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<StationSettingsScreen> createState() =>
      _StationSettingsScreenState();
}

class _StationSettingsScreenState extends ConsumerState<StationSettingsScreen> {
  late final TextEditingController _url;
  String? _urlError;
  bool _applying = false;
  bool _warnHttp = false;

  @override
  void initState() {
    super.initState();
    final endpoint = ref.read(apiEndpointSettingsProvider);
    _url = TextEditingController(text: endpoint.value);
    _warnHttp = endpoint.usesInsecureRemoteHttp;
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    var warn = false;
    try {
      warn = ApiEndpoint.parse(value).usesInsecureRemoteHttp;
    } on FormatException {
      // Bỏ qua lỗi cú pháp khi người dùng đang nhập
    }
    setState(() {
      _urlError = null;
      _warnHttp = warn;
    });
  }

  Future<void> _apply({bool restoreDefault = false}) async {
    if (_applying) return;
    final ApiEndpoint next;
    try {
      next = restoreDefault
          ? ref.read(defaultApiEndpointProvider)
          : ApiEndpoint.parse(_url.text);
    } on FormatException catch (error) {
      setState(() => _urlError = error.message);
      return;
    }
    setState(() {
      _applying = true;
      _urlError = null;
    });
    try {
      if (next != ref.read(apiEndpointSettingsProvider)) {
        final pending = ref
            .read(gateStationNotifierProvider)
            .offlineQueue
            .length;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Thay đổi máy chủ API?'),
              ],
            ),
            content: Text(
              'Các yêu cầu API kế tiếp sẽ được chuyển hướng tới địa chỉ mới. Vui lòng đăng nhập lại sau khi đổi máy chủ.'
              '${next.usesInsecureRemoteHttp ? '\n\nLưu ý: Kết nối HTTP bên ngoài môi trường phát triển cục bộ không có mã hóa dữ liệu truyền tải.' : ''}'
              '${pending > 0 ? '\n\nHiện có $pending lượt quét ngoại tuyến chưa đồng bộ trong hàng đợi.' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy bỏ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Đồng ý đổi địa chỉ'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }

      final settings = ref.read(apiEndpointSettingsProvider.notifier);
      if (restoreDefault) {
        await settings.restoreDefault();
      } else {
        await settings.save(next);
      }
      if (!mounted) return;
      _url.text = next.value;
      setState(() => _warnHttp = next.usesInsecureRemoteHttp);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restoreDefault
                ? 'Đã khôi phục địa chỉ API về mặc định (${next.value}).'
                : 'Đã lưu và áp dụng địa chỉ API mới thành công.',
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiEndpointUpdateFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _urlError = switch (failure) {
          ApiEndpointUpdateFailure.application =>
            'Không thể thiết lập địa chỉ API. Địa chỉ hiện tại vẫn đang được dùng.',
          ApiEndpointUpdateFailure.persistenceUncertain =>
            'Không thể kiểm tra địa chỉ đã lưu. Hãy thử áp dụng lại.',
          ApiEndpointUpdateFailure.persistence =>
            'Không thể lưu địa chỉ API vào bộ nhớ bảo mật thiết bị.',
          ApiEndpointUpdateFailure.busy =>
            'Hệ thống đang bận cập nhật địa chỉ API.',
        };
      });
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    if (authState.isAuthenticated && !userRole.canAccessSettings) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Cấu Hình Trạm & Kết Nối Backend')) : null,
        body: AccessDeniedWidget(
          title: 'Từ chối quyền truy cập Cấu hình',
          message:
              'Chức năng cấu hình thiết bị trạm và địa chỉ API chỉ dành riêng cho Quản trị viên (ADMIN).',
          currentRole: userRole,
        ),
      );
    }
    final local = ref.watch(
      gateStationNotifierProvider.select((state) => state.activeStation),
    );
    final endpoint = ref.watch(apiEndpointSettingsProvider);
    final remote = ref.watch(stationConfigurationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Cấu Hình Trạm & Kết Nối Backend'),
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.lightBlueAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cấu Hình Trạm & Kết Nối Backend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Thiết lập địa chỉ Endpoint API máy chủ, kiểm tra độ trễ mạng và cấu hình cổng phần cứng.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. Thông Tin Trạm Đang Hoạt Động (Active Gate Station)
                _buildCard(
                  title: 'Thông Tin Trạm Đang Hoạt Động',
                  subtitle: 'Trạm kiểm soát hiện hành được chọn trên thiết bị này',
                  icon: Icons.meeting_room_rounded,
                  iconColor: Colors.indigo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Gate Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: local.direction == 'ENTRY'
                                    ? Colors.blue.shade100
                                    : Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                local.direction == 'ENTRY'
                                    ? Icons.login_rounded
                                    : Icons.logout_rounded,
                                color: local.direction == 'ENTRY'
                                    ? Colors.blue.shade800
                                    : Colors.amber.shade900,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        local.stationId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: local.direction == 'ENTRY'
                                              ? Colors.blue.shade50
                                              : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: local.direction == 'ENTRY'
                                                ? Colors.blue.shade200
                                                : Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          local.direction == 'ENTRY' ? 'LỐI VÀO' : 'LỐI RA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: local.direction == 'ENTRY'
                                                ? Colors.blue.shade800
                                                : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    local.gateIdentifier,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: local.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: local.isActive ? Colors.green.shade300 : Colors.red.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: local.isActive ? Colors.green.shade600 : Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    local.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: local.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Grid specs
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          return isNarrow
                              ? Column(
                                  children: [
                                    _specRow('Khu vực Nhà máy', local.factoryId == 'BINH_DUONG' ? 'Bình Dương (BINH_DUONG)' : 'Long An (LONG_AN)', Icons.business_rounded),
                                    _specRow('Hardware Controller', StationConfiguration.visibleControllerEndpoint(local.controllerEndpoint)?.toString() ?? 'Chưa kết nối (Local Simulated)', Icons.hardware_rounded),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _specTile('Khu vực Nhà máy', local.factoryId == 'BINH_DUONG' ? 'Bình Dương (BINH_DUONG)' : 'Long An (LONG_AN)', Icons.business_rounded)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _specTile('Hardware Controller', StationConfiguration.visibleControllerEndpoint(local.controllerEndpoint)?.toString() ?? 'Chưa kết nối (Simulated)', Icons.hardware_rounded)),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Backend Sync Status Banner
                      remote.when(
                        skipLoadingOnRefresh: false,
                        loading: () => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Đang truy vấn trạng thái trạm từ máy chủ backend...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        error: (_, _) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 20, color: Colors.amber.shade800),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cấu hình từ xa chưa sẵn sàng hoặc máy chủ tạm thời không thể truy cập.',
                                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        data: (station) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 20, color: Colors.green.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Đã đồng bộ thành công với máy chủ (${station.stationId} • ${station.gateIdentifier})',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Cấu Hình Kết Nối Backend (API Base URL)
                _buildCard(
                  title: 'Địa Chỉ Máy Chủ Backend (API Base URL)',
                  subtitle: 'Đường dẫn dịch vụ API cho toàn bộ các chức năng xác thực và điểm danh',
                  icon: Icons.dns_rounded,
                  iconColor: Colors.blue.shade700,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active URL Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Text('Địa chỉ đang dùng: ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            Expanded(
                              child: Text(
                                endpoint.value,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Presets from .env
                      if (ApiConfig.availablePresets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 6),
                            Text(
                              'Cấu hình nhanh từ .env (Presets):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ApiConfig.availablePresets.map((preset) {
                            final isSelected = _url.text.trim() == preset.url.trim();
                            return Tooltip(
                              message: preset.url,
                              child: FilterChip(
                                selected: isSelected,
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blue.shade800,
                                avatar: Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.sensors_rounded,
                                  size: 16,
                                  color: isSelected ? Colors.blue.shade800 : Colors.blueGrey,
                                ),
                                label: Text(
                                  preset.name.isNotEmpty ? preset.name : preset.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                  ),
                                ),
                                onSelected: _applying
                                    ? null
                                    : (_) {
                                        setState(() {
                                          _url.text = preset.url;
                                          _onUrlChanged(preset.url);
                                        });
                                      },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Text input for URL
                      TextField(
                        controller: _url,
                        enabled: !_applying,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        onChanged: _onUrlChanged,
                        decoration: InputDecoration(
                          labelText: 'Đường dẫn API Base URL',
                          hintText: 'http://localhost:3000/api',
                          errorText: _urlError,
                          errorMaxLines: 3,
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: _url.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _url.clear();
                                    _onUrlChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),

                      if (endpoint.usesInsecureRemoteHttp || _warnHttp) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cảnh báo: Kết nối HTTP từ xa không có mã hóa TLS. Khuyến khích sử dụng HTTPS trên production.',
                                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Action Buttons
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            icon: _applying
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_rounded, size: 18),
                            onPressed: _applying ? null : () => _apply(),
                            label: const Text('Áp dụng địa chỉ'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            onPressed: _applying ? null : () => _apply(restoreDefault: true),
                            label: const Text('Khôi phục mặc định'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.wifi_find_rounded, size: 18),
                            onPressed: remote.isLoading || _applying
                                ? null
                                : () => ref.invalidate(stationConfigurationProvider),
                            label: const Text('Kiểm tra kết nối'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reachability result banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              remote.hasValue ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                              size: 18,
                              color: remote.hasValue ? Colors.green.shade700 : Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatConnectionMessage(remote),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: remote.hasValue ? Colors.green.shade900 : Colors.blueGrey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Điều Khiển Phần Cứng Cổng (Turnstile Controller)
                _buildCard(
                  title: 'Điều Khiển Phần Cứng Cổng (Turnstile Controller)',
                  subtitle: 'Cấu hình thông số thiết bị phần cứng cổng xoay và điểm danh ngoại tuyến',
                  icon: Icons.developer_board_rounded,
                  iconColor: Colors.deepPurple,
                  child: StationAdministrationPanel(
                    key: ValueKey(local.stationId),
                    station: local,
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Thông Tin Hệ Thống (System Info)
                _buildCard(
                  title: 'Thông Tin Hệ Thống (System Information)',
                  subtitle: 'Kiến trúc và các tiêu chuẩn vận hành sản xuất của ứng dụng',
                  icon: Icons.shield_rounded,
                  iconColor: Colors.teal,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      return Column(
                        children: [
                          if (isNarrow) ...[
                            _infoTile('Phiên bản phần mềm', 'TMC Gate Kiosk v1.0.0 (Production)', Icons.verified_rounded, Colors.green),
                            _infoTile('Kiến trúc giải pháp', 'Modular Monolith Backend & Flutter Client', Icons.architecture_rounded, Colors.blue),
                            _infoTile('Tiêu chuẩn độ trễ', 'SLA <= 2.0s / lượt xác thực thẻ', Icons.speed_rounded, Colors.orange),
                            _infoTile('Khả năng chịu lỗi', 'Hàng đợi ngoại tuyến Offline Resilient Queue', Icons.cloud_sync_rounded, Colors.purple),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: _infoTile('Phiên bản phần mềm', 'TMC Gate Kiosk v1.0.0', Icons.verified_rounded, Colors.green)),
                                const SizedBox(width: 12),
                                Expanded(child: _infoTile('Kiến trúc giải pháp', 'Modular Monolith Architecture', Icons.architecture_rounded, Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _infoTile('Tiêu chuẩn độ trễ', 'SLA <= 2.0s / lượt quẹt', Icons.speed_rounded, Colors.orange)),
                                const SizedBox(width: 12),
                                Expanded(child: _infoTile('Khả năng chịu lỗi', 'Offline Resilient Queue', Icons.cloud_sync_rounded, Colors.purple)),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _specTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _specTile(label, value, icon),
    );
  }

  Widget _infoTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatConnectionMessage(AsyncValue<StationConfiguration> remote) {
    return remote.when(
      skipLoadingOnRefresh: false,
      loading: () => 'Đang kiểm tra kết nối tới trạm trên máy chủ backend...',
      data: (station) => 'Máy chủ đã xác nhận trạm ${station.stationId} kết nối tốt.',
      error: (error, _) => switch (error) {
        StationConfigurationFailure.unauthorized =>
          'Máy chủ từ chối quyền truy cập cấu hình trạm (401/403).',
        StationConfigurationFailure.notFound =>
          'Không tìm thấy trạm này trên cơ sở dữ liệu của máy chủ.',
        StationConfigurationFailure.invalidResponse =>
          'Phản hồi từ máy chủ không đúng định dạng dữ liệu.',
        _ => 'Không thể kết nối tới máy chủ API. Vui lòng kiểm tra lại địa chỉ hoặc mạng.',
      },
    );
  }
}
