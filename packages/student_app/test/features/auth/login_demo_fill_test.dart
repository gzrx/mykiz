import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Demo menu fills matric + password', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));

    // Fields start empty.
    var matricField =
        tester.widget<TextFormField>(find.byKey(const Key('matricField')));
    var passwordField =
        tester.widget<TextFormField>(find.byKey(const Key('passwordField')));
    expect(matricField.controller?.text, isEmpty);
    expect(passwordField.controller?.text, isEmpty);

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A123456 — Ahmad').last);
    await tester.pumpAndSettle();

    matricField =
        tester.widget<TextFormField>(find.byKey(const Key('matricField')));
    passwordField =
        tester.widget<TextFormField>(find.byKey(const Key('passwordField')));

    expect(matricField.controller?.text, 'A123456');
    expect(passwordField.controller?.text, 'password123');
  });
}
