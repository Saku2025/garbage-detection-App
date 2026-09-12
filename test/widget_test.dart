import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const GarbageDetectionApp());

    await tester.pumpAndSettle();

    expect(find.byType(GarbageDetectionApp), findsOneWidget);
  });
}
