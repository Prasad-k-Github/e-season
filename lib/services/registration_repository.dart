// lib/services/registration_repository.dart

import 'package:e_season/models/registration_data.dart';

/// Contract the registration pages depend on.
///
/// Swap [MockRegistrationRepository] for [ApiRegistrationRepository] without
/// touching any screen; see registration_repository_factory.dart.
abstract class RegistrationRepository {
  /// Institutions a government employee can pick from.
  Future<List<String>> fetchInstitutions();

  /// Creates the account. The server emails a 6-digit verification code to
  /// [RegistrationData.email] as part of this call.
  Future<RegistrationResult> register(RegistrationData data);

  /// Confirms the emailed [code] for [email].
  Future<OtpResult> verifyEmail(String email, String code);

  /// Emails a fresh code. The server answers the same way whether or not the
  /// address is awaiting verification, and enforces its own cooldown.
  Future<OtpResult> resendVerificationCode(String email);
}
