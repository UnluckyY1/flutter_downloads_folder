import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:downloadsfolder_example/main.dart';

void main() {
  testWidgets('Example app renders its action buttons', (tester) async {
    await tester.pumpWidget(const MyExample());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Plugin example app'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Get Download Path'),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Pick a File'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Show Download Folder'),
        findsOneWidget);
  });
}
