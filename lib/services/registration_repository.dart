// lib/services/registration_repository.dart

import 'package:e_season/models/registration_data.dart';

/// Contract the registration pages depend on.
///
/// Swap [MockRegistrationRepository] for [ApiRegistrationRepository] without
/// touching any screen; see registration_repository_factory.dart.
///
/// Order of calls: the pages collect everything locally, then
/// [sendPhoneCode] -> [verifyPhoneCode] -> [register] (once, with the proof).
abstract class RegistrationRepository {
  /// Names of the institutions a government employee can pick from.
  Future<List<String>> fetchInstitutions();

  /// Texts a 6-digit code to [phone]. Also used to resend.
  Future<OtpResult> sendPhoneCode(String phone);

  /// Checks the [code]. On success [OtpResult.token] is the proof the register
  /// call must carry.
  Future<OtpResult> verifyPhoneCode(String phone, String code);

  /// Creates the account in one call with everything collected, including the
  /// three images. The server refuses it unless
  /// [RegistrationData.registrationToken] is valid.
  Future<RegistrationResult> register(RegistrationData data);
}
