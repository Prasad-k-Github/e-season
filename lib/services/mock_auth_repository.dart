// lib/services/mock_auth_repository.dart

import 'package:e_season/services/auth_repository.dart';
import 'package:e_season/utils/app_strings.dart';

/// Offline stand-in: any phone number signs in with [demoPassword].
class MockAuthRepository implements AuthRepository {
  static const demoPassword = 'Passw0rd#123';
  static const demoToken = 'mock-user-token';

  final Duration delay;

  const MockAuthRepository({this.delay = const Duration(seconds: 1)});

  @override
  Future<LoginResult> login(String phone, String password) async {
    await Future.delayed(delay);
    if (password != demoPassword) {
      return const LoginResult.failure(AppStrings.loginIncorrect);
    }
    return const LoginResult.success(demoToken, verificationStatus: 'verified');
  }
}
