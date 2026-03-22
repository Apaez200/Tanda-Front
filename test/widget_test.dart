import 'package:flutter_test/flutter_test.dart';
import 'package:tandachain/main.dart';

void main() {
  testWidgets('Rendix app smoke test — renders splash', (WidgetTester tester) async {
    await tester.pumpWidget(const RendixApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Rendix'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
