import 'package:atom/config/app_theme.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      extensions: const [AppColors.light],
    ),
    home: Scaffold(body: SafeArea(child: child)),
  );
}

void main() {
  testWidgets('nested header prioritizes the full title and back navigation', (
    tester,
  ) async {
    var wentBack = false;

    await tester.pumpWidget(
      _testApp(
        customHeader(
          label: 'Change Password',
          icon: Icons.security,
          showBackButton: true,
          onPressed: () => wentBack = true,
        ),
      ),
    );

    expect(find.text('Change Password'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.security), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(wentBack, isTrue);
  });

  testWidgets('root header keeps its contextual icon and subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const customHeader(
          label: 'Support Tickets',
          subtitle: 'Raise and track maintenance tickets',
          icon: Icons.confirmation_number_outlined,
        ),
      ),
    );

    expect(find.text('Support Tickets'), findsOneWidget);
    expect(find.text('Raise and track maintenance tickets'), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}
