import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gate_event_types.dart';
import '../../domain/recent_gate_event.dart';
import '../../domain/recent_gate_events_source.dart';
import '../providers/gate_station_provider.dart';
import '../providers/recent_gate_events_controller.dart';

class RecentGateEventsScreen extends ConsumerWidget {
  const RecentGateEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(
      gateStationNotifierProvider.select((state) => state.activeStation),
    );
    final events = ref.watch(recentGateEventsProvider);

    void refresh() => ref.invalidate(recentGateEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Gate Events (UC-04)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (station.stationId.isNotEmpty)
              Text(
                'Station: ${station.stationId} · ${station.gateIdentifier}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh events',
            onPressed: events.isLoading || station.stationId.isEmpty
                ? null
                : refresh,
          ),
        ],
      ),
      body: events.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading recent events',
          ),
        ),
        data: (items) {
          if (items == null) {
            return const Center(
              child: Text('Select a station to view its recent events.'),
            );
          }
          if (items.isEmpty) {
            return const Center(
              child: Text('No recent events recorded for this station.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildEventCard(items[index]),
          );
        },
        error: (error, _) {
          final message = switch (error) {
            RecentEventsFailure.unauthorized =>
              'Access to this station’s events was denied. Check your sign-in and station permissions.',
            RecentEventsFailure.invalidResponse =>
              'The server returned invalid event data. Try again.',
            _ =>
              'Could not load recent events. Check your connection and try again.',
          };
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  TextButton(onPressed: refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(RecentGateEvent event) {
    final isApproved = event.accessDecision == AccessDecision.approved;
    final controllerLabel = switch (event.controllerOutcome) {
      ControllerOutcome.controllerConfirmed => 'Confirmed',
      ControllerOutcome.controllerFailed => 'Failed',
      ControllerOutcome.controllerUnknown => 'Unknown',
      ControllerOutcome.controllerPending => 'Pending',
      ControllerOutcome.notApplicable => 'Not applicable',
    };
    final directionLabel = switch (event.direction) {
      GateDirection.entry => 'Entry',
      GateDirection.exit => 'Exit',
      null => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isApproved
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Icon(
                isApproved ? Icons.check_circle : Icons.cancel,
                color: isApproved ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.employeeName ?? 'Employee unavailable',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (event.employeeId != null)
                    Text('Employee ID: ${event.employeeId}'),
                  Text(
                    'Access decision: ${isApproved ? 'APPROVED' : 'DENIED'}',
                  ),
                  Text('Controller outcome: $controllerLabel'),
                  if (!isApproved && event.denialReason != null)
                    Text('Denial reason: ${event.denialReason}'),
                  Text('Station: ${event.stationId}'),
                  if (event.factoryId != null)
                    Text('Factory: ${event.factoryId}'),
                  if (directionLabel != null)
                    Text('Direction: $directionLabel'),
                  Text('Recorded: ${event.serverTimestamp.toIso8601String()}'),
                  Text('Event ID: ${event.eventId}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
