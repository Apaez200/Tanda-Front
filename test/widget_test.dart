import 'package:flutter_test/flutter_test.dart';
import 'package:tandachain/main.dart';

void main() {
  testWidgets('TandaChain app smoke test — renders splash', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const TandaChainApp());

    // Pump a few frames to let animations initialize
    await tester.pump(const Duration(milliseconds: 100));

    // The splash screen should show the brand name
    expect(find.textContaining('TandaChain'), findsWidgets);

    // Settle all pending timers and animations
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
