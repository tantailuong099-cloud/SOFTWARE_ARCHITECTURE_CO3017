import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gate_station_repository.dart';
import '../../domain/recent_gate_event.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final employeeAttendanceEventsProvider =
    FutureProvider.autoDispose<List<RecentGateEvent>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final employeeCode = authState.employeeCode ?? '';
  if (employeeCode.isEmpty) return const [];

  final repository = ref.watch(gateStationRepositoryProvider);
  return repository.fetchEmployeeEvents(employeeCode);
});
