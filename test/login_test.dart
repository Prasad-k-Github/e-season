import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_season/screens/login_screen.dart';
import 'package:e_season/services/api_auth_repository.dart';
import 'package:e_season/services/auth_repository.dart';
import 'package:e_season/services/mock_auth_repository.dart';
import 'package:e_season/services/session_store.dart';
import 'package:e_season/utils/app_strings.dart';

const _base = 'http://test.local';

http.Response _json(int status, Object body) => http.Response(
      jsonEncode(body), status,
      headers: {'content-type': 'application/json'},
    );

/// Counts calls and replays a scripted result.
class _FakeAuth implements AuthRepository {
  int calls = 0;
  String? lastPhone, lastPassword;
  LoginResult result = const LoginResult.success('user-token',
      verificationStatus: 'verified');

  @override
  Future<LoginResult> login(String phone, String password) async {
    calls++;
    lastPhone = phone;
    lastPassword = password;
    return result;
  }
}

void main() {
  group('ApiAuthRepository', () {
    test('posts the phone and password and returns the token', () async {
      http.Request? seen;
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((req) async {
          seen = req;
          return _json(200, {'token': 'jwt-token', 'verificationStatus': 'verified'});
        }),
      );

      final result = await repo.login('0771234567', 'Passw0rd#123');

      expect(result.success, isTrue);
      expect(result.token, 'jwt-token');
      expect(result.verificationStatus, 'verified');
      expect(result.awaitingVerification, isFalse);
      expect(seen!.url.toString(), '$_base/api/auth/login');
      expect(seen!.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(seen!.body),
          {'phone': '0771234567', 'password': 'Passw0rd#123'});
    });

    test('an account that is not approved yet is flagged', () async {
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(200,
            {'token': 't', 'verificationStatus': 'pending_verification'})),
      );
      final result = await repo.login('0771234567', 'x');
      expect(result.success, isTrue);
      expect(result.awaitingVerification, isTrue);
    });

    test('wrong credentials show the same server message, with no token', () async {
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(401, {
              'error': {
                'code': 'unauthorized',
                'message': 'Incorrect phone number or password'
              }
            })),
      );
      final result = await repo.login('0771234567', 'wrong');
      expect(result.success, isFalse);
      expect(result.token, isNull);
      expect(result.errorMessage, 'Incorrect phone number or password');
    });

    test('rate limiting is explained', () async {
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(429, {
              'error': {
                'code': 'rate_limited',
                'message': 'Too many requests. Try again later.'
              }
            })),
      );
      expect((await repo.login('0771234567', 'x')).errorMessage,
          'Too many requests. Try again later.');
    });

    test('a success without a token is treated as a failure', () async {
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((_) async => _json(200, {'verificationStatus': 'verified'})),
      );
      final result = await repo.login('0771234567', 'x');
      expect(result.success, isFalse);
      expect(result.errorMessage, AppStrings.loginFailed);
    });

    test('network failure maps to server unreachable', () async {
      final repo = ApiAuthRepository(
        baseUrl: _base,
        client: MockClient((_) async => throw http.ClientException('refused')),
      );
      expect((await repo.login('0771234567', 'x')).errorMessage,
          AppStrings.serverUnreachable);
    });
  });

  group('MockAuthRepository', () {
    const repo = MockAuthRepository(delay: Duration.zero);

    test('signs in with the demo password only', () async {
      final ok = await repo.login('0771234567', MockAuthRepository.demoPassword);
      expect(ok.success, isTrue);
      expect(ok.token, MockAuthRepository.demoToken);

      final bad = await repo.login('0771234567', 'nope');
      expect(bad.success, isFalse);
      expect(bad.errorMessage, AppStrings.loginIncorrect);
    });
  });

  group('LoginScreen', () {
    late _FakeAuth auth;
    late MemorySessionStore session;

    setUp(() {
      auth = _FakeAuth();
      session = MemorySessionStore();
    });

    Future<void> open(WidgetTester tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(auth: auth, session: session),
        routes: {'/dashboard': (_) => const Scaffold(body: Text('DASHBOARD'))},
      ));
      await tester.pump();
    }

    Future<void> submit(WidgetTester tester,
        {String phone = '0771234567', String password = 'Passw0rd#123'}) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), phone);
      await tester.enterText(fields.at(1), password);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('signing in stores the token and opens the dashboard',
        (tester) async {
      await open(tester);
      await submit(tester);
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(auth.lastPhone, '0771234567');
      expect(auth.lastPassword, 'Passw0rd#123');
      expect(await session.readToken(), 'user-token');
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    testWidgets('wrong credentials show the message and stay on the page',
        (tester) async {
      auth.result = const LoginResult.failure('Incorrect phone number or password');
      await open(tester);
      await submit(tester, password: 'wrong');

      expect(find.text('Incorrect phone number or password'), findsOneWidget);
      expect(await session.readToken(), isNull);
      expect(find.text('DASHBOARD'), findsNothing);

      // The button works again so they can retry.
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
    });

    testWidgets('an invalid number or empty password is caught before the server',
        (tester) async {
      await open(tester);
      await submit(tester, phone: '0112345678', password: '');

      expect(find.text(AppStrings.phoneInvalid), findsOneWidget);
      expect(find.text(AppStrings.loginPasswordRequired), findsOneWidget);
      expect(auth.calls, 0);
    });

    testWidgets('an 8-character password is accepted, as the server allows',
        (tester) async {
      await open(tester);
      await submit(tester, password: 'abcd1234');
      await tester.pumpAndSettle();

      expect(auth.calls, 1, reason: 'login must not apply the stricter sign-up rules');
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    testWidgets('an unapproved account still signs in, with a notice',
        (tester) async {
      auth.result = const LoginResult.success('user-token',
          verificationStatus: 'pending_verification');
      await open(tester);
      await submit(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.loginAwaitingVerification), findsOneWidget);
      expect(await session.readToken(), 'user-token');
      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });
}
