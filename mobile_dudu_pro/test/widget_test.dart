import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_dudu_pro/theme/theme_controller.dart';

void main() {
  testWidgets('ThemeController + MaterialApp', (WidgetTester tester) async {
    final tc = ThemeController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: tc,
        child: Consumer<ThemeController>(
          builder: (context, t, _) {
            return MaterialApp(
              themeMode: t.mode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: const Scaffold(body: Text('ok')),
            );
          },
        ),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
