import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/api_registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

const _base = 'http://test.local';

late Directory _dir;
late String _jpg, _png;

RegistrationData _private({String? photo}) => RegistrationData(
      passengerType:     PassengerType.general,
      fullName:          'Nimal Perera',
      address:           '12 Galle Road, Colombo',
      nic:               '199012345678',
      phone:             '0771234567',
      email:             'nimal@example.com',
      dateOfBirth:       DateTime(1990, 5, 10),
      preferredLanguage: 'en',
      password:          'Passw0rd#123',
      employerName:      'ABC Pvt Ltd',
      profilePhotoPath:  photo ?? _jpg,
      nicFrontPath:      _jpg,
      nicBackPath:       _png,
      registrationToken: 'reg-token',
    );

RegistrationData _government() => RegistrationData(
      passengerType:     PassengerType.government,
      fullName:          'Kamala Silva',
      address:           '45 Temple Road, Kandy',
      nic:               '199112345678',
      phone:             '0712345678',
      preferredLanguage: 'en',
      password:          'Passw0rd#123',
      institution:       'Ministry of Education',
      orgAuthCode:       'DEMO-EDU-2026',
      employeeNo:        'EMP-1001',
      designation:       'Teacher',
      profilePhotoPath:  _jpg,
      nicFrontPath:      _jpg,
      nicBackPath:       _png,
      registrationToken: 'reg-token',
    );

http.StreamedResponse _streamed(int status, Object body) => http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: {'content-type': 'application/json'},
    );

http.Response _json(int status, Object body) => http.Response(
      jsonEncode(body), status,
      headers: {'content-type': 'application/json'},
    );

/// Records every request (multipart ones keep their fields and files).
class _Recorder {
  final requests = <http.BaseRequest>[];
  http.MultipartRequest get multipart => requests.single as http.MultipartRequest;
}

ApiRegistrationRepository _repo(_Recorder rec, int status, Object body) =>
    ApiRegistrationRepository(
      baseUrl: _base,
      client: MockClient.streaming((request, _) async {
        rec.requests.add(request);
        return _streamed(status, body);
      }),
    );

void main() {
  setUpAll(() {
    _dir = Directory.systemTemp.createTempSync('es_api_test');
    _jpg = '${_dir.path}${Platform.pathSeparator}photo.jpg';
    _png = '${_dir.path}${Platform.pathSeparator}nic.png';
    File(_jpg).writeAsBytesSync([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
    File(_png).writeAsBytesSync([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  });

  tearDownAll(() {
    if (_dir.existsSync()) _dir.deleteSync(recursive: true);
  });

  group('register', () {
    test('a private passenger is sent exactly as the API expects', () async {
      final rec = _Recorder();
      final repo = _repo(rec, 201, {
        'userId': 'u1',
        'referenceNumber': 'ES-1A2B3C4D',
        'verificationStatus': 'pending_verification',
        'token': 'user-token',
      });

      final result = await repo.register(_private());

      expect(result.success, isTrue);
      expect(result.referenceNumber, 'ES-1A2B3C4D');
      expect(result.verificationStatus, 'pending_verification');

      final request = rec.multipart;
      expect(request.method, 'POST');
      expect(request.url.toString(), '$_base/api/register');
      expect(request.headers['Authorization'], 'Bearer reg-token');
      expect(request.fields, {
        'passengerType':     'private',
        'password':          'Passw0rd#123',
        'fullName':          'Nimal Perera',
        'nic':               '199012345678',
        'address':           '12 Galle Road, Colombo',
        'email':             'nimal@example.com',
        'dateOfBirth':       '1990-05-10',
        'preferredLanguage': 'en',
        'consent':           'true',
        'employerName':      'ABC Pvt Ltd',
      });
      expect(request.fields.containsKey('phone'), isFalse,
          reason: 'the server takes the number from the verified code');
    });

    test('the three images go as files with their real types', () async {
      final rec = _Recorder();
      await _repo(rec, 201, {'referenceNumber': 'ES-1'}).register(_private());

      final files = {for (final f in rec.multipart.files) f.field: f};
      expect(files.keys, unorderedEquals(['photo', 'nicFront', 'nicBack']));
      expect(files['photo']!.contentType.mimeType, 'image/jpeg');
      expect(files['nicFront']!.contentType.mimeType, 'image/jpeg');
      expect(files['nicBack']!.contentType.mimeType, 'image/png');
      expect(files['photo']!.length, 7);
    });

    test('a government employee sends institution details and no employer', () async {
      final rec = _Recorder();
      await _repo(rec, 201, {
        'referenceNumber': 'ES-9',
        'verificationStatus': 'pending_institution_approval',
      }).register(_government());

      expect(rec.multipart.fields, {
        'passengerType':     'government',
        'password':          'Passw0rd#123',
        'fullName':          'Kamala Silva',
        'nic':               '199112345678',
        'address':           '45 Temple Road, Kandy',
        'preferredLanguage': 'en',
        'consent':           'true',
        'institution':       'Ministry of Education',
        'orgAuthCode':       'DEMO-EDU-2026',
        'employeeNo':        'EMP-1001',
        'designation':       'Teacher',
      });
    });

    test('blank optional values are left out', () async {
      final rec = _Recorder();
      final data = RegistrationData(
        passengerType: PassengerType.general,
        fullName: 'Nimal Perera',
        address: '12 Galle Road',
        nic: '199012345678',
        phone: '0771234567',
        email: '  ',
        employerName: '',
        password: 'Passw0rd#123',
        profilePhotoPath: _jpg,
        nicFrontPath: _jpg,
        nicBackPath: _png,
        registrationToken: 'reg-token',
      );
      await _repo(rec, 201, {'referenceNumber': 'ES-1'}).register(data);

      final keys = rec.multipart.fields.keys;
      expect(keys, isNot(contains('email')));
      expect(keys, isNot(contains('employerName')));
      expect(keys, isNot(contains('dateOfBirth')));
    });

    test('an expired registration token (401) asks the user to verify again', () async {
      final result = await _repo(_Recorder(), 401, {
        'error': {'code': 'unauthorized', 'message': 'Invalid or expired token'}
      }).register(_private());

      expect(result.success, isFalse);
      expect(result.requiresVerification, isTrue);
      expect(result.errorMessage, AppStrings.verificationExpired);
    });

    test("the server's own message is shown, e.g. for a duplicate account", () async {
      final result = await _repo(_Recorder(), 409, {
        'error': {
          'code': 'already_registered',
          'message': 'An account with this phone, NIC or email already exists'
        }
      }).register(_private());

      expect(result.errorMessage,
          'An account with this phone, NIC or email already exists');
      expect(result.requiresVerification, isFalse);
    });

    test('validation errors list what is wrong', () async {
      final result = await _repo(_Recorder(), 400, {
        'error': {
          'code': 'validation_error',
          'message': 'Invalid request data',
          'details': [
            {'field': 'nic', 'message': 'Invalid NIC. Use 9 digits + V/X, or 12 digits'},
            {'field': 'address', 'message': 'Address is required'},
          ],
        }
      }).register(_private());

      expect(result.errorMessage,
          'Invalid NIC. Use 9 digits + V/X, or 12 digits\nAddress is required');
    });

    test('an unreadable image says so', () async {
      final result = await _repo(_Recorder(), 201, {}).register(
          _private(photo: '${_dir.path}${Platform.pathSeparator}missing.jpg'));
      expect(result.success, isFalse);
      expect(result.errorMessage, AppStrings.imageReadFailed);
    });

    test('network failure maps to server unreachable', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient.streaming((_, __) async => throw http.ClientException('refused')),
      );
      expect((await repo.register(_private())).errorMessage,
          AppStrings.serverUnreachable);
    });
  });

  group('phone verification', () {
    test('sendPhoneCode posts the number and passes on the demo code', () async {
      http.Request? seen;
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((req) async {
          seen = req;
          return _json(200, {'expiresInSeconds': 300, 'devCode': '482913'});
        }),
      );

      final result = await repo.sendPhoneCode('0771234567');

      expect(result.success, isTrue);
      expect(result.devCode, '482913');
      expect(seen!.url.toString(), '$_base/api/auth/otp/request');
      expect(jsonDecode(seen!.body), {'phone': '0771234567'});
    });

    test('there is no demo code in production', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(200, {'expiresInSeconds': 300})),
      );
      expect((await repo.sendPhoneCode('0771234567')).devCode, isNull);
    });

    test('asking again inside the cooldown is fine: the earlier code still works',
        () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(429, {
              'error': {
                'code': 'otp_cooldown',
                'message': 'Please wait a moment before requesting another code'
              }
            })),
      );
      expect((await repo.sendPhoneCode('0771234567')).success, isTrue);
    });

    test('a bad number is explained', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(400, {
              'error': {'code': 'bad_phone', 'message': 'Enter a valid Sri Lankan mobile number (07XXXXXXXX)'}
            })),
      );
      final result = await repo.sendPhoneCode('123');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Enter a valid Sri Lankan mobile number (07XXXXXXXX)');
    });

    test('verifyPhoneCode returns the registration token', () async {
      http.Request? seen;
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((req) async {
          seen = req;
          return _json(200, {'registered': false, 'registrationToken': 'reg-token'});
        }),
      );

      final result = await repo.verifyPhoneCode('0771234567', '123456');

      expect(result.success, isTrue);
      expect(result.token, 'reg-token');
      expect(seen!.url.toString(), '$_base/api/auth/otp/verify');
      expect(jsonDecode(seen!.body), {'phone': '0771234567', 'code': '123456'});
    });

    test('a number that already has an account cannot register again', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async =>
            _json(200, {'registered': true, 'token': 'user-token', 'verificationStatus': 'verified'})),
      );
      final result = await repo.verifyPhoneCode('0771234567', '123456');
      expect(result.success, isFalse);
      expect(result.token, isNull);
      expect(result.errorMessage, AppStrings.phoneAlreadyRegistered);
    });

    test('a wrong code shows the server message and gives no token', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(400, {
              'error': {'code': 'otp_incorrect', 'message': 'Incorrect code'}
            })),
      );
      final result = await repo.verifyPhoneCode('0771234567', '000000');
      expect(result.success, isFalse);
      expect(result.token, isNull);
      expect(result.errorMessage, 'Incorrect code');
    });

    test('network failure maps to server unreachable', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => throw http.ClientException('refused')),
      );
      expect((await repo.sendPhoneCode('0771234567')).errorMessage,
          AppStrings.serverUnreachable);
      expect((await repo.verifyPhoneCode('0771234567', '123456')).errorMessage,
          AppStrings.serverUnreachable);
    });
  });

  group('institutions', () {
    test('returns the names from GET /api/institutions', () async {
      http.Request? seen;
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((req) async {
          seen = req;
          return _json(200, [
            {'id': 'a', 'name': 'Ministry of Education'},
            {'id': 'b', 'name': 'Ministry of Health'},
          ]);
        }),
      );

      expect(await repo.fetchInstitutions(),
          ['Ministry of Education', 'Ministry of Health']);
      expect(seen!.url.toString(), '$_base/api/institutions');
    });

    test('a server error is thrown so the page can show it', () async {
      final repo = ApiRegistrationRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(500, {
              'error': {'code': 'server_error', 'message': 'Something went wrong'}
            })),
      );
      expect(repo.fetchInstitutions(), throwsA(anything));
    });
  });
}
