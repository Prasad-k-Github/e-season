// lib/services/mock_registration_repository.dart

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/registration_options.dart';

/// Offline stand-in for the backend. Always succeeds after [delay], accepts
/// [demoOtp] as the code, and refuses to register without the proof the code
/// check hands out, like the real server.
class MockRegistrationRepository implements RegistrationRepository {
  static const demoOtp = '123456';
  static const demoToken = 'mock-registration-token';

  final Duration delay;

  const MockRegistrationRepository({this.delay = const Duration(seconds: 1)});

  @override
  Future<List<String>> fetchInstitutions() async =>
      RegistrationOptions.institutions;

  @override
  Future<OtpResult> sendPhoneCode(String phone) async {
    await Future.delayed(delay);
    return const OtpResult.success(devCode: demoOtp);
  }

  @override
  Future<OtpResult> verifyPhoneCode(String phone, String code) async {
    await Future.delayed(delay);
    return code == demoOtp
        ? const OtpResult.success(token: demoToken)
        : const OtpResult.failure(AppStrings.otpIncorrect);
  }

  @override
  Future<RegistrationResult> register(RegistrationData data) async {
    await Future.delayed(delay);
    if (data.registrationToken != demoToken) {
      return const RegistrationResult.failure(AppStrings.verificationExpired,
          requiresVerification: true);
    }
    final ref = DateTime.now().millisecondsSinceEpoch.toString();
    return RegistrationResult.success(
      'ES-${ref.substring(ref.length - 6)}',
      verificationStatus: data.passengerType == PassengerType.government
          ? 'pending_institution_approval'
          : 'pending_verification',
    );
  }
}
