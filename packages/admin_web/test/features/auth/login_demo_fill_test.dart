import 'package:admin_web/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Demo menu fills Staff ID + password', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));

    // Fields start empty.
    var staffField =
        tester.widget<TextFormField>(find.byKey(const Key('staffField')));
    var passwordField =
        tester.widget<TextFormField>(find.byKey(const Key('passwordField')));
    expect(staffField.controller?.text, isEmpty);
    expect(passwordField.controller?.text, isEmpty);

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S98765 — Dr. Aminah').last);
    await tester.pumpAndSettle();

    staffField =
        tester.widget<TextFormField>(find.byKey(const Key('staffField')));
    passwordField =
        tester.widget<TextFormField>(find.byKey(const Key('passwordField')));

    expect(staffField.controller?.text, 'S98765');
    expect(passwordField.controller?.text, 'password123');
  });
}
