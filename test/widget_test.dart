// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:stroke_sense/main.dart';
import 'package:stroke_sense/core/theme_provider.dart';

void main() {
  testWidgets('StrokeSense app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const StrokeSenseApp(),
      ),
    );

    // Verify that the app title is present
    expect(find.text('StrokeSense'), findsOneWidget);
    
    // Verify that at least one exercise module is displayed
    expect(find.text('Pagar'), findsOneWidget);
  });
}
