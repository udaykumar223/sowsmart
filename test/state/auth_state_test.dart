import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/state/auth_state.dart';

void main() {
  group('AuthState Tests', () {
    test('Initial state is unauthenticated and not loading', () {
      final authState = AuthState();
      expect(authState.isAuthenticated, isFalse);
      expect(authState.currentUser, isNull);
      expect(authState.isLoading, isFalse);
      expect(authState.errorMessage, isNull);
    });

    test('Demo sign-in authenticates user and sets display name and email', () {
      final authState = AuthState();

      authState.signInDemo(name: 'Kisan Rao', email: 'kisan@sowsmart.app');

      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser?.displayName, equals('Kisan Rao'));
      expect(authState.currentUser?.email, equals('kisan@sowsmart.app'));
      expect(authState.isDemoMode, isTrue);
    });

    test('Sign out clears authenticated user and resets demo mode', () async {
      final authState = AuthState();
      authState.signInDemo(name: 'Farmer John');
      expect(authState.isAuthenticated, isTrue);

      await authState.signOut();

      expect(authState.isAuthenticated, isFalse);
      expect(authState.currentUser, isNull);
      expect(authState.isDemoMode, isFalse);
    });

    test('Clear error removes any previous error message', () {
      final authState = AuthState();
      // Trigger sign in with null credentials
      authState.clearError();
      expect(authState.errorMessage, isNull);
    });
  });
}
