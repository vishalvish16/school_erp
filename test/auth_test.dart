// =============================================================================
// FILE: test/auth_test.dart
// PURPOSE: Unit tests for LoginNotifier and Auth logic
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/features/auth/login_provider.dart';
import 'package:school_erp_admin/features/auth/login_repository.dart';

class MockLoginRepo extends Mock implements LoginRepository {}

void main() {
  late MockLoginRepo mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockLoginRepo();
    container = ProviderContainer(
      overrides: [loginRepositoryProvider.overrideWith((ref) => mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LoginNotifier Tests', () {
    test('initial state is correct', () {
      final state = container.read(loginProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
      expect(state.errorMessage, null);
    });

    test('updateEmail updates state and clears error', () {
      container.read(loginProvider.notifier).setError('Old Error');
      container.read(loginProvider.notifier).updateEmail('test@email.com');

      final state = container.read(loginProvider);
      expect(state.email, 'test@email.com');
      expect(state.errorMessage, null);
    });

    test('login success flow', () async {
      when(
        () => mockRepo.login(any(), any()),
      ).thenAnswer((_) async => 'mock_token');

      container.read(loginProvider.notifier).updateEmail('admin@test.com');
      container.read(loginProvider.notifier).updatePassword('password');

      final loginFuture = container.read(loginProvider.notifier).login();

      // Check loading state
      expect(container.read(loginProvider).isLoading, true);

      await loginFuture;

      final state = container.read(loginProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, true);
      expect(state.errorMessage, null);
    });

    test('login failure flow', () async {
      when(
        () => mockRepo.login(any(), any()),
      ).thenThrow(Exception('Invalid Credentials'));

      container.read(loginProvider.notifier).updateEmail('wrong@test.com');
      container.read(loginProvider.notifier).updatePassword('wrong');

      await container.read(loginProvider.notifier).login();

      final state = container.read(loginProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
      expect(state.errorMessage, 'Invalid Credentials');
    });
  });
}
