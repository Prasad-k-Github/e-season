import 'package:flutter_test/flutter_test.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

RegistrationData _data(PassengerType type, {String? token}) => RegistrationData(
      passengerType:     type,
      fullName:          'Kasun Perera',
      address:           '25, Galle Rd, Matara',
      nic:               '972430039V',
      phone:             '0771234567',
      email:             'kasun@gmail.com',
      password:          'ChangeMe-12345',
      profilePhotoPath:  '/tmp/profile.jpg',
      nicFrontPath:      '/tmp/front.jpg',
      nicBackPath:       '/tmp/back.jpg',
      institution:       'Sri Lanka Railways',
      orgAuthCode:       'ABC123',
      registrationToken: token,
    );

void main() {
  const repo = MockRegistrationRepository(delay: Duration.zero);

  test('register succeeds with a reference number once verified', () async {
    final result = await repo.register(
        _data(PassengerType.general, token: MockRegistrationRepository.demoToken));
    expect(result.success, isTrue);
    expect(result.referenceNumber, startsWith('ES-'));
    expect(result.verificationStatus, 'pending_verification');
  });

  test('government employees wait for their institution first', () async {
    final result = await repo.register(
        _data(PassengerType.government, token: MockRegistrationRepository.demoToken));
    expect(result.verificationStatus, 'pending_institution_approval');
  });

  test('fetchInstitutions returns the mock list', () async {
    expect(await repo.fetchInstitutions(), isNotEmpty);
  });

  test('sending a code gives the demo code', () async {
    final result = await repo.sendPhoneCode('0771234567');
    expect(result.success, isTrue);
    expect(result.devCode, MockRegistrationRepository.demoOtp);
  });

  test('verifyPhoneCode accepts the demo code only and hands out the proof', () async {
    final ok = await repo.verifyPhoneCode(
        '0771234567', MockRegistrationRepository.demoOtp);
    expect(ok.success, isTrue);
    expect(ok.token, MockRegistrationRepository.demoToken);

    final wrong = await repo.verifyPhoneCode('0771234567', '000000');
    expect(wrong.success, isFalse);
    expect(wrong.token, isNull);
    expect(wrong.errorMessage, AppStrings.otpIncorrect);
  });

  test('register refuses a missing proof, like the real server', () async {
    final result = await repo.register(_data(PassengerType.general));
    expect(result.success, isFalse);
    expect(result.requiresVerification, isTrue);
  });

  test('toString does not expose NIC, image paths or password', () {
    final text = _data(PassengerType.general).toString();
    expect(text, isNot(contains('972430039V')));
    expect(text, isNot(contains('/tmp/')));
    expect(text, isNot(contains('ChangeMe-12345')));
  });
}
