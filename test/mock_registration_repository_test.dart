import 'package:flutter_test/flutter_test.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

void main() {
  final data = RegistrationData(
    passengerType:    PassengerType.government,
    fullName:         'Kasun Perera',
    address:          '25, Galle Rd, Matara',
    nic:              '972430039V',
    nicIssueDate:     DateTime(2015, 6, 1),
    email:            'kasun@gmail.com',
    phone:            '0771234567',
    password:         'ChangeMe-12345',
    profilePhotoPath: '/tmp/profile.jpg',
    nicFrontPath:     '/tmp/front.jpg',
    nicBackPath:      '/tmp/back.jpg',
    institution:      'Sri Lanka Railways',
    orgAuthCode:      'ABC123',
  );
  const repo = MockRegistrationRepository(delay: Duration.zero);

  test('register succeeds with a reference number', () async {
    final result = await repo.register(data);
    expect(result.success, isTrue);
    expect(result.referenceNumber, startsWith('P-'));
  });

  test('fetchInstitutions returns the mock list', () async {
    expect(await repo.fetchInstitutions(), isNotEmpty);
  });

  test('verifyEmail accepts the demo code only; resend succeeds', () async {
    expect(
        (await repo.verifyEmail(
                'kasun@gmail.com', MockRegistrationRepository.demoOtp))
            .success,
        isTrue);
    final wrong = await repo.verifyEmail('kasun@gmail.com', '000000');
    expect(wrong.success, isFalse);
    expect(wrong.errorMessage, AppStrings.otpIncorrect);
    expect((await repo.resendVerificationCode('kasun@gmail.com')).success, isTrue);
  });

  test('toString does not expose NIC, image paths or password', () {
    final text = data.toString();
    expect(text, isNot(contains('972430039V')));
    expect(text, isNot(contains('/tmp/')));
    expect(text, isNot(contains('ChangeMe-12345')));
  });
}
