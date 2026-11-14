import 'package:flutter/material.dart';
import '../../data/models/access_scan_models.dart';
import '../providers/gate_station_provider.dart';

class TurnstileStatusCard extends StatelessWidget {
  final GateDisplayStatus status;
  final AccessScanResponse? response;
  final GateStation activeStation;

  const TurnstileStatusCard({
    super.key,
    required this.status,
    required this.response,
    required this.activeStation,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case GateDisplayStatus.idle:
        return _buildIdleCard(context);
      case GateDisplayStatus.processing:
        return _buildProcessingCard(context);
      case GateDisplayStatus.authorized:
        return _buildAuthorizedCard(context);
      case GateDisplayStatus.denied:
        return _buildDeniedCard(context);
      case GateDisplayStatus.controllerError:
        return _buildControllerErrorCard(context);
    }
  }

  Widget _buildIdleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 32, color: Colors.blueGrey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CỔNG ĐANG KHÓA (LOCKED)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng xuất trình mã QR hợp lệ trước ống kính trạm',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐANG XÁC THỰC MÃ QR...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kiểm tra tính hợp lệ & chính sách cổng phân xưởng...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizedCard(BuildContext context) {
    final latency = response?.processingLatencyMs ?? 0;
    final isDuplicate = response?.isCachedDuplicate ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'XÁC NHẬN MỞ CỔNG (UNLOCKED)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      'Cần xoay Turnstile đã mở • Chiều: ${activeStation.direction}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFA5D6A7)),
          _infoRow('Nhân viên:', response?.employeeName ?? 'N/A'),
          _infoRow('Mã nhân viên:', response?.employeeId ?? 'N/A'),
          _infoRow('Phân xưởng:', response?.factoryId ?? activeStation.factoryId),
          _infoRow('Trạng thái bộ điều khiển:', response?.controllerOutcome ?? 'CONFIRMED'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian xử lý: ${latency}ms',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDuplicate ? 'IDEMPOTENT RETRY' : 'SLA <= 2.0s ĐẠT CHUẨN ✅',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeniedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF5350), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFC62828),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỪ CHỐI TRUY CẬP (ACCESS DENIED)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                    Text(
                      'Cổng tiếp tục KHÓA • Ghi nhận sự kiện',
                      style: TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEF9A9A)),
          _infoRow('Lý do từ chối:', _formatReason(response?.reasonCode)),
          if (response?.employeeName != null)
            _infoRow('Nhân viên:', response!.employeeName!),
          if (response?.employeeId != null)
            _infoRow('Mã nhân viên:', response!.employeeId!),
          _infoRow('Trạm kiểm soát:', activeStation.stationId),
          _infoRow('Mã sự kiện:', response?.eventId ?? 'Không lưu (Ngoài phạm vi)'),
        ],
      ),
    );
  }

  Widget _buildControllerErrorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE65100),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LỖI THIẾT BỊ CỔNG (FAIL-SECURE)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      'Bộ điều khiển không phản hồi • Giữ cổng khóa (NFR-REL-01)',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBF360C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Kết quả controller:', response?.controllerOutcome ?? 'CONTROLLER_FAILED'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReason(String? code) {
    if (code == null) return 'N/A';
    switch (code) {
      case 'CREDENTIAL_EXPIRED':
        return 'Mã QR đã hết hạn hiệu lực (CREDENTIAL_EXPIRED)';
      case 'CREDENTIAL_SUSPENDED':
        return 'Mã QR đang bị tạm ngưng (CREDENTIAL_SUSPENDED)';
      case 'CREDENTIAL_REVOKED':
        return 'Mã QR đã bị thu hồi (CREDENTIAL_REVOKED)';
      case 'INACTIVE_EMPLOYEE':
        return 'Nhân viên đã nghỉ việc/không hoạt động (INACTIVE_EMPLOYEE)';
      case 'UNAUTHORIZED_FACTORY_GATE':
        return 'Nhân viên không thuộc phân xưởng này (UNAUTHORIZED_FACTORY)';
      case 'UNRECOGNIZED_CREDENTIAL':
        return 'Mã QR không thuộc hệ thống TMC (UNRECOGNIZED)';
      case 'STATION_DISABLED':
      case 'STATION_INACTIVE':
        return 'Trạm kiểm soát đang dừng hoạt động (STATION_INACTIVE)';
      default:
        return code;
    }
  }
}
