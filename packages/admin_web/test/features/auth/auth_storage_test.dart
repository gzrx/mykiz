import 'package:admin_web/features/auth/data/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips token and user', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AuthStorage();
    final user = User(
      id: 'u1',
      identifier: 'S98765',
      name: 'Dr. Aminah',
      role: 'admin',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await storage.save('tok-123', user);
    final restored = await storage.read();

    expect(restored, isNotNull);
    expect(restored!.token, 'tok-123');
    expect(restored.user.identifier, 'S98765');

    await storage.clear();
    expect(await storage.read(), isNull);
  });
}
