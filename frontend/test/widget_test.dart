// test/widget_test.dart - REEMPLAZAR TODO CON:
//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('¡Frontend Funcionando!'), findsOneWidget);
  });
}
