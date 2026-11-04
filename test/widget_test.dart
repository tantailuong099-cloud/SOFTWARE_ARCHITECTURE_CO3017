import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/app/app.dart';

void main() {
  testWidgets('TMC Gate App launches and renders kiosk screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TMCGateApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('TMC Gate Station Kiosk'), findsOneWidget);
  });
}
