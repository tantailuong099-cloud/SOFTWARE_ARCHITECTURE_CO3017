import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gate_station_repository.dart' show dynamicQRSourceProvider;
import '../../domain/dynamic_qr_source.dart';

final dynamicQRClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

final dynamicQRControllerProvider =
    NotifierProvider.autoDispose<DynamicQRController, DynamicQRState>(
      DynamicQRController.new,
    );

sealed class DynamicQRState {
  const DynamicQRState();
}

final class DynamicQRInitial extends DynamicQRState {
  const DynamicQRInitial();
}

final class DynamicQRLoading extends DynamicQRState {
  const DynamicQRLoading();
}

final class DynamicQRReady extends DynamicQRState {
  final DynamicQR credential;
  final int remainingSeconds;

  const DynamicQRReady(this.credential, this.remainingSeconds);
}

final class DynamicQRExpired extends DynamicQRState {
  const DynamicQRExpired();
}

final class DynamicQRError extends DynamicQRState {
  final DynamicQRFailure failure;

  const DynamicQRError(this.failure);
}

class DynamicQRController extends Notifier<DynamicQRState> {
  static const refreshInterval = Duration(seconds: 30);

  String? _employeeId;
  int _requestGeneration = 0;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  DynamicQRState build() {
    _employeeId = null;
    ref.onDispose(_invalidate);
    return const DynamicQRInitial();
  }

  /// Null ends dynamic mode. Re-selecting the active employee is a no-op unless in error state.
  void selectEmployee(String? employeeId) {
    if (employeeId == _employeeId && state is! DynamicQRError) return;
    _employeeId = employeeId;
    if (employeeId == null) {
      _invalidate();
      state = const DynamicQRInitial();
      return;
    }
    unawaited(_load(employeeId));
  }

  Future<void> retry() async {
    final employeeId = _employeeId;
    if (employeeId == null || state is DynamicQRLoading) return;
    await _load(employeeId);
  }

  /// Rechecks time when an action runs, including before the next countdown tick.
  String? get validPayload {
    final current = state;
    if (current is DynamicQRReady &&
        current.credential.expiresAt.isAfter(_now())) {
      return current.credential.qrPayload;
    }
    return null;
  }

  DateTime _now() => ref.read(dynamicQRClockProvider)();

  void _invalidate() {
    _requestGeneration++;
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _load(String employeeId) async {
    _invalidate();
    final generation = _requestGeneration;
    state = const DynamicQRLoading();

    try {
      final credential = await ref
          .read(dynamicQRSourceProvider)
          .fetchDynamicQR(employeeId);
      if (generation != _requestGeneration) return;

      if (credential.expiresAt.isAfter(_now())) {
        _refreshTimer = Timer(refreshInterval, retry);
      }
      _updateCountdown(credential);
    } on DynamicQRFailure catch (failure) {
      if (generation != _requestGeneration) return;
      state = DynamicQRError(failure);
    }
  }

  void _updateCountdown(DynamicQR credential) {
    final remaining = credential.expiresAt.difference(_now());
    if (remaining <= Duration.zero) {
      state = const DynamicQRExpired();
      return;
    }

    // Schedule the next displayed second, including the expiry instant.
    final wholeSeconds =
        (remaining.inMicroseconds - 1) ~/ Duration.microsecondsPerSecond;
    _countdownTimer = Timer(
      remaining - Duration(seconds: wholeSeconds),
      () => _updateCountdown(credential),
    );
    state = DynamicQRReady(credential, wholeSeconds + 1);
  }
}
