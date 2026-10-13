import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/api_registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

RegistrationData _data(PassengerType type) => RegistrationData(
      passengerType:    type,
      fullName:         'Kasun Perera',
      address:          '12 Main St, Colombo',
      nic:              '972430039V',
      nicIssueDate:     DateTime(2015, 6, 1),
      email:            'kasun@gmail.com',
      phone:            '0771234567',
      password:         'ChangeMe-12345',
      profilePhotoPath: '/tmp/profile.jpg',
      nicFrontPath:     '/tmp/front.jpg',
      nicBackPath:      '/tmp/back.jpg',
      institution:      'Ministry of Finance',
      ministry:         'Finance',
      nearestStation:   'Colombo Fort',
      orgAuthCode:      'ABC123',
    );

http.Response _json(int status, Object body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  const base = 'http://test.local';

  test('register sends the passenger fields and no journey details', () async {
    final requests = <http.Request>[];
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((req) async {
        requests.add(req);
        return _json(201, {'data': {'id': 'P-123', 'status': 'Pending'}});
      }),
    );

    final result = await repo.register(_data(PassengerType.general));

    expect(result.success, isTrue);
    expect(result.referenceNumber, 'P-123');
    expect(requests, hasLength(1));
    expect(requests.single.url.toString(), '$base/api/v1/auth/register/passenger');
    expect(jsonDecode(requests.single.body), {
      'nameInitial':  'Kasun Perera',
      'email':        'kasun@gmail.com',
      'password':     'ChangeMe-12345',
      'address':      '12 Main St, Colombo',
      'phoneNo':      '0771234567',
      'nicNo':        '972430039V',
      'nicIssueDate': '2015-06-01',
    });
  });

  test('government employee: still a single register call for now', () async {
    final requests = <http.Request>[];
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((req) async {
        requests.add(req);
        return _json(201, {'data': {'id': 'P-123'}});
      }),
    );

    final result = await repo.register(_data(PassengerType.government));

    expect(result.success, isTrue);
    expect(requests.map((r) => r.url.path),
        ['/api/v1/auth/register/passenger']);
  });

  test('verifyEmail posts email and code to /verify-email', () async {
    http.Request? seen;
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((req) async {
        seen = req;
        return _json(200, {'data': {'verified': true}});
      }),
    );

    final result = await repo.verifyEmail('kasun@gmail.com', '123456');

    expect(result.success, isTrue);
    expect(seen!.url.toString(), '$base/api/v1/auth/verify-email');
    expect(jsonDecode(seen!.body), {'email': 'kasun@gmail.com', 'code': '123456'});
  });

  test('a wrong code (INVALID_VERIFICATION_CODE) maps to a friendly message', () async {
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((_) async => _json(400, {
            'error': {
              'code': 'INVALID_VERIFICATION_CODE',
              'message': 'Invalid or expired verification code'
            }
          })),
    );
    final result = await repo.verifyEmail('kasun@gmail.com', '000000');
    expect(result.success, isFalse);
    expect(result.errorMessage, AppStrings.otpIncorrect);
  });

  test('resendVerificationCode posts the email to /resend-verification', () async {
    http.Request? seen;
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((req) async {
        seen = req;
        return _json(200, {'data': {'message': 'If the email is awaiting verification, a new code has been sent'}});
      }),
    );

    final result = await repo.resendVerificationCode('kasun@gmail.com');

    expect(result.success, isTrue);
    expect(seen!.url.toString(), '$base/api/v1/auth/resend-verification');
    expect(jsonDecode(seen!.body), {'email': 'kasun@gmail.com'});
  });

  test('DUPLICATE_PASSENGER maps to a friendly message', () async {
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((_) async => _json(409, {
            'error': {'code': 'DUPLICATE_PASSENGER', 'message': 'A passenger with this NIC or email already exists'}
          })),
    );
    final result = await repo.register(_data(PassengerType.general));
    expect(result.success, isFalse);
    expect(result.errorMessage, AppStrings.duplicatePassenger);
  });

  test('validation errors list the rejected fields', () async {
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((_) async => _json(400, {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Request validation failed',
              'details': {'password': ['too short']},
            }
          })),
    );
    final result = await repo.register(_data(PassengerType.general));
    expect(result.errorMessage, '${AppStrings.serverRejectedFields} password');
  });

  test('network failure maps to server unreachable', () async {
    final repo = ApiRegistrationRepository(
      baseUrl: base,
      client: MockClient((_) async => throw http.ClientException('refused')),
    );
    expect((await repo.register(_data(PassengerType.general))).errorMessage,
        AppStrings.serverUnreachable);
    expect((await repo.resendVerificationCode('kasun@gmail.com')).errorMessage,
        AppStrings.serverUnreachable);
  });
}
