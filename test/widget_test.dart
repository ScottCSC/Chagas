import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chagas_app/theme/app_theme.dart';

void main() {
  testWidgets('MaterialApp con AppTheme construye sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: Text('smoke')),
        ),
      ),
    );

    expect(find.text('smoke'), findsOneWidget);
  });
}
