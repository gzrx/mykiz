import 'package:admin_web/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell shows nav labels expanded, toggles to collapsed',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AppShell(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        child: const Text('BODY'),
      ),
    ));
    // Expanded: labels visible.
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );

    // Toggle collapse.
    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pumpAndSettle();
    // NavigationRail keeps the label widget mounted (Visibility.maintain)
    // for semantics even when collapsed, so assert on the rail's
    // `extended` flag rather than label text presence.
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
  });
}
