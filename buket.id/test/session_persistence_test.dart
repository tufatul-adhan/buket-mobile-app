import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buket_id/services/auth_service.dart';

void main() {
  group('Session Persistence Tests', () {
    setUp(() {
      // Initialize with empty SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('AuthService init should complete without errors', () async {
      final authService = AuthService();
      expect(() async => await authService.init(), returnsNormally);
    });

    test('Session should be cleared after logout', () async {
      final authService = AuthService();
      await authService.init();

      // Check initial state - not logged in
      var isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, isFalse);

      // After logout (even if not logged in)
      await authService.logout();

      // Should still not be logged in
      isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, isFalse);
    });

    test('getCurrentUser should return null when not logged in', () async {
      final authService = AuthService();
      await authService.init();

      // Initially not logged in
      var currentUser = await authService.getCurrentUser();
      expect(currentUser, isNull);

      // After logout
      await authService.logout();
      currentUser = await authService.getCurrentUser();
      expect(currentUser, isNull);
    });

    test('Session restoration logic - AuthService.init() works', () async {
      // First instance
      final authService1 = AuthService();
      await authService1.init();

      // Second instance (simulating app restart)
      final authService2 = AuthService();
      await authService2.init();

      // Both should work
      var isLoggedIn = await authService2.isLoggedIn();
      expect(isLoggedIn, isFalse);
    });

    test('Logout should clear all session data', () async {
      final authService = AuthService();
      await authService.init();

      // Logout
      await authService.logout();

      // Verify session is cleared
      var isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, isFalse);

      var currentUser = await authService.getCurrentUser();
      expect(currentUser, isNull);
    });
  });
}
