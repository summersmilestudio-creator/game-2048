import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_2048/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const Game2048App());
    expect(find.text('2048'), findsWidgets);
  });
}
