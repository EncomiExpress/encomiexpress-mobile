import 'package:flutter_test/flutter_test.dart';

import 'package:encomiexpress/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const EncomiExpressApp());
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}