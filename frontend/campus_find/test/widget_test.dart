import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_find/core/theme.dart';
import 'package:campus_find/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip renders its status label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: StatusChip(status: 'pending'),
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
  });

  test('AppTheme builds a Material 3 theme', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
  });
}
