// lib/services/auth_repository.dart

/// Outcome of a passenger login.
class LoginResult {
  final bool success;

  /// Bearer token for the passenger endpoints (valid for 7 days).
  final String? token;

  /// `pending_institution_approval`, `pending_verification`, `verified`, ...
  final String? verificationStatus;
  final String? errorMessage;

  const LoginResult.success(this.token, {this.verificationStatus})
      : success = true,
        errorMessage = null;

  const LoginResult.failure(this.errorMessage)
      : success = false,
        token = null,
        verificationStatus = null;

  /// Signed in, but station staff (or the institution) have not approved the
  /// account yet, so applying for a season ticket is not possible.
  bool get awaitingVerification =>
      success && verificationStatus != null && verificationStatus != 'verified';
}

/// Passenger sign-in. Swap [MockAuthRepository] for [ApiAuthRepository]
/// without touching the screen; see auth_repository_factory.dart.
abstract class AuthRepository {
  Future<LoginResult> login(String phone, String password);
}
