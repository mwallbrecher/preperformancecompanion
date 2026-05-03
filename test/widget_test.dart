import 'package:flutter_test/flutter_test.dart';
import 'package:preperformancecompanion/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PrePerformanceApp());
    expect(find.byType(PrePerformanceApp), findsOneWidget);
  });
}
