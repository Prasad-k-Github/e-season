import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/otp_verification_screen.dart';
import 'package:e_season/screens/register_password_screen.dart';
import 'package:e_season/screens/register_photo_screen.dart';
import 'package:e_season/screens/register_screen.dart';
import 'package:e_season/screens/register_success_screen.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/services/draft_store.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

/// The mock, plus call counters and scripted failures.
class _FakeRepo extends MockRegistrationRepository {
  int sendCalls = 0;
  int verifyCalls = 0;
  int registerCalls = 0;
  OtpResult? sendResult;
  final registerResults = <RegistrationResult>[];
  RegistrationData? lastRegistered;

  _FakeRepo() : super(delay: Duration.zero);

  @override
  Future<OtpResult> sendPhoneCode(String phone) {
    sendCalls++;
    return sendResult != null ? Future.value(sendResult) : super.sendPhoneCode(phone);
  }

  @override
  Future<OtpResult> verifyPhoneCode(String phone, String code) {
    verifyCalls++;
    return super.verifyPhoneCode(phone, code);
  }

  @override
  Future<RegistrationResult> register(RegistrationData data) {
    registerCalls++;
    lastRegistered = data;
    if (registerResults.isNotEmpty) return Future.value(registerResults.removeAt(0));
    return super.register(data);
  }
}

RegistrationDraft _draft() => RegistrationDraft(type: PassengerType.general)
  ..fullName = 'Kasun Perera'
  ..address = '12 Main St'
  ..nic = '972430039V'
  ..dateOfBirth = DateTime(1990, 5, 10)
  ..email = 'kasun@gmail.com'
  ..phone = '0771234567'
  ..password = 'ChangeMe-12345'
  ..profilePhotoPath = '/tmp/p.jpg'
  ..nicFrontPath = '/tmp/f.jpg'
  ..nicBackPath = '/tmp/b.jpg';

RegistrationFlow _flow(_FakeRepo repo, {MemoryDraftStore? store, RegistrationDraft? draft}) =>
    RegistrationFlow(
      draft: draft ?? _draft(),
      repo: repo,
      store: store ?? MemoryDraftStore(),
    );

Future<void> _pump(WidgetTester tester, Widget home) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(MaterialApp(home: home));
  await _settle(tester);
}

/// Lets zero-delay fake futures finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await _settle(tester); // a full code is verified automatically
}

void main() {
  test('maskPhone keeps only the first and last two characters', () {
    expect(maskPhone('0771234567'), '07******67');
    expect(maskPhone('077 123 4567'), '07******67');
    expect(maskPhone('1234'), '1234');
  });

  group('OTPVerificationScreen', () {
    testWidgets('texts a code when opened, then waits for it', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));

      expect(repo.sendCalls, 1);
      expect(repo.registerCalls, 0, reason: 'nothing is registered before the code');
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('07******67'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    testWidgets('shows the demo code when the server is in demo mode', (tester) async {
      await _pump(tester, OTPVerificationScreen(flow: _flow(_FakeRepo())));
      expect(
          find.text(AppStrings.otpDemoCode
              .replaceAll('{code}', MockRegistrationRepository.demoOtp)),
          findsOneWidget);
    });

    testWidgets('shows no demo code when the server sends none', (tester) async {
      final repo = _FakeRepo()..sendResult = const OtpResult.success();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));
      expect(find.textContaining('Demo mode'), findsNothing);
    });

    testWidgets('a wrong code shows an error and registers nothing', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));
      await _enterCode(tester, '000000');

      expect(find.text(AppStrings.otpIncorrect), findsOneWidget);
      expect(repo.registerCalls, 0);
      expect(find.byType(RegistrationSuccessScreen), findsNothing);
    });

    testWidgets('an incomplete code is rejected before calling the server',
        (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.pump();
      await tester.tap(find.text(AppStrings.otpVerify));
      await tester.pump();

      expect(find.text(AppStrings.otpRequired), findsOneWidget);
      expect(repo.verifyCalls, 0);
    });

    testWidgets('the right code verifies and moves on to the photo page',
        (tester) async {
      final repo = _FakeRepo();
      final flow = _flow(repo);
      await _pump(tester, OTPVerificationScreen(flow: flow));
      await _enterCode(tester, MockRegistrationRepository.demoOtp);
      await tester.pumpAndSettle();

      expect(repo.verifyCalls, 1);
      expect(repo.registerCalls, 0, reason: 'nothing is registered yet');
      expect(flow.draft.isPhoneVerified, isTrue);
      expect(flow.draft.registrationToken, MockRegistrationRepository.demoToken);
      expect(find.byType(RegisterPhotoScreen), findsOneWidget);
    });

    testWidgets('popWhenVerified returns true instead of opening the photo page',
        (tester) async {
      final repo = _FakeRepo();
      final flow = _flow(repo);
      bool? result;
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await flow.reverify(context),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await _settle(tester);
      await _enterCode(tester, MockRegistrationRepository.demoOtp);
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(RegisterPhotoScreen), findsNothing);
    });

    testWidgets('a number that cannot be texted shows the reason', (tester) async {
      final repo = _FakeRepo()
        ..sendResult = const OtpResult.failure(AppStrings.phoneAlreadyRegistered);
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));

      expect(find.text(AppStrings.phoneAlreadyRegistered), findsOneWidget);
      // They can retry or change the number straight away.
      expect(find.text(AppStrings.otpResend), findsOneWidget);
      expect(find.text(AppStrings.changePhone), findsOneWidget);
    });

    testWidgets('coming back with an already verified number skips the code',
        (tester) async {
      final repo = _FakeRepo();
      final draft = _draft()
        ..registrationToken = MockRegistrationRepository.demoToken
        ..verifiedPhone = '+94771234567';
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo, draft: draft)));

      expect(repo.sendCalls, 0);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text(AppStrings.continueLabel));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterPhotoScreen), findsOneWidget);
      expect(repo.registerCalls, 0);
    });

    testWidgets('resend is only enabled after the cooldown', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));
      expect(repo.sendCalls, 1);

      await tester.tap(find.textContaining('Resend code in'));
      await tester.pump();
      expect(repo.sendCalls, 1);

      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text(AppStrings.otpResend));
      await _settle(tester);
      expect(repo.sendCalls, 2);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });
  });

  group('RegisterPasswordScreen', () {
    Future<void> fill(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ChangeMe-12345');
      await tester.enterText(fields.at(1), 'ChangeMe-12345');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
    }

    RegistrationDraft verified() => _draft()
      ..registrationToken = MockRegistrationRepository.demoToken
      ..verifiedPhone = '+94771234567';

    testWidgets('submitting registers everything once and clears the secrets',
        (tester) async {
      final repo = _FakeRepo();
      final store = MemoryDraftStore();
      final flow = _flow(repo, store: store, draft: verified());
      await flow.save(RegStep.nicImages);
      expect(store.hasDraft, isTrue);

      await _pump(tester, RegisterPasswordScreen(flow: flow));
      await fill(tester);
      await tester.tap(find.text(AppStrings.submitRegistration));
      await _settle(tester);
      await tester.pumpAndSettle();

      expect(repo.registerCalls, 1);
      expect(repo.sendCalls, 0, reason: 'no new code');
      expect(repo.lastRegistered!.fullName, 'Kasun Perera');
      expect(repo.lastRegistered!.registrationToken,
          MockRegistrationRepository.demoToken);
      expect(find.byType(RegistrationSuccessScreen), findsOneWidget);
      expect(store.hasDraft, isFalse);
      expect(flow.draft.password, isEmpty);
      expect(flow.draft.registrationToken, isNull);
    });

    testWidgets('if submitting fails, retry does not ask for a code again',
        (tester) async {
      final repo = _FakeRepo()
        ..registerResults.add(
            const RegistrationResult.failure(AppStrings.serverUnreachable));
      final flow = _flow(repo, draft: verified());
      await _pump(tester, RegisterPasswordScreen(flow: flow));
      await fill(tester);
      await tester.tap(find.text(AppStrings.submitRegistration));
      await _settle(tester);

      expect(find.text(AppStrings.serverUnreachable), findsOneWidget);
      expect(find.text(AppStrings.retryRegistration), findsOneWidget);

      await tester.tap(find.text(AppStrings.retryRegistration));
      await _settle(tester);
      await tester.pumpAndSettle();

      expect(repo.sendCalls, 0);
      expect(repo.verifyCalls, 0);
      expect(repo.registerCalls, 2);
      expect(find.byType(RegistrationSuccessScreen), findsOneWidget);
    });

    testWidgets('an expired proof sends the user to verify the number again',
        (tester) async {
      final repo = _FakeRepo()
        ..registerResults.add(const RegistrationResult.failure(
            AppStrings.verificationExpired,
            requiresVerification: true));
      final flow = _flow(repo, draft: verified());
      await _pump(tester, RegisterPasswordScreen(flow: flow));
      await fill(tester);
      await tester.tap(find.text(AppStrings.submitRegistration));
      await _settle(tester);

      expect(find.byType(OTPVerificationScreen), findsOneWidget);
      expect(repo.sendCalls, 1, reason: 'a new code was sent');
      expect(flow.draft.registrationToken, isNull);

      await tester.pumpAndSettle(); // let the page transition finish
      await _enterCode(tester, MockRegistrationRepository.demoOtp);
      await tester.pumpAndSettle();

      expect(repo.verifyCalls, 1);
      expect(find.byType(OTPVerificationScreen), findsNothing);
      expect(repo.registerCalls, 2, reason: 'submitted again after verifying');
      expect(find.byType(RegistrationSuccessScreen), findsOneWidget);
    });

    testWidgets('stays disabled until the consent box is ticked', (tester) async {
      await _pump(tester, RegisterPasswordScreen(flow: _flow(_FakeRepo())));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ChangeMe-12345');
      await tester.enterText(fields.at(1), 'ChangeMe-12345');
      await tester.pump();

      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);
    });
  });

  group('resuming a saved registration', () {
    Future<MemoryDraftStore> savedStore(RegStep step) async {
      final store = MemoryDraftStore();
      await store.save(_draft(), step);
      return store;
    }

    testWidgets('Continue refills the details and opens the next page',
        (tester) async {
      final store = await savedStore(RegStep.details);
      await _pump(
          tester,
          RegisterScreen(
              repository: _FakeRepo(), store: store));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.resumeTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.resumeContinue));
      await tester.pumpAndSettle();

      // Details were completed, so we land on mobile verification.
      expect(find.byType(OTPVerificationScreen), findsOneWidget);
    });

    testWidgets('Start over deletes the saved copy', (tester) async {
      final store = await savedStore(RegStep.photo);
      await _pump(
          tester,
          RegisterScreen(
              repository: _FakeRepo(), store: store));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(AppStrings.resumeStartOver));
      await tester.pumpAndSettle();

      expect(store.hasDraft, isFalse);
      expect(find.byType(RegisterPhotoScreen), findsNothing);
    });

    testWidgets('nothing is offered when nothing was saved', (tester) async {
      await _pump(
          tester,
          RegisterScreen(
              repository: _FakeRepo(), store: MemoryDraftStore()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.resumeTitle), findsNothing);
    });
  });
}
