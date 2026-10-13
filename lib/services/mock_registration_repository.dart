// lib/services/mock_registration_repository.dart

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/registration_options.dart';

/// Offline stand-in for the backend. Always succeeds after [delay], and
/// accepts [demoOtp] as the email code.
class MockRegistrationRepository implements RegistrationRepository {
  static const demoOtp = '123456';

  final Duration delay;

  const MockRegistrationRepository({this.delay = const Duration(seconds: 1)});

  @override
  Future<List<String>> fetchInstitutions() async =>
      RegistrationOptions.institutions;

  @override
  Future<RegistrationResult> register(RegistrationData data) async {
    await Future.delayed(delay);
    final ref = DateTime.now().millisecondsSinceEpoch.toString();
    return RegistrationResult.success('P-${ref.substring(ref.length - 6)}');
  }

  @override
  Future<OtpResult> verifyEmail(String email, String code) async {
    await Future.delayed(delay);
    return code == demoOtp
        ? const OtpResult.success()
        : const OtpResult.failure(AppStrings.otpIncorrect);
  }

  @override
  Future<OtpResult> resendVerificationCode(String email) async {
    await Future.delayed(delay);
    return const OtpResult.success();
  }
}
