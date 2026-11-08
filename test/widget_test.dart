// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flow/main.dart';

void main() {
  testWidgets('App loads test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
