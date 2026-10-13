import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/otp_verification_screen.dart';
import 'package:e_season/screens/register_password_screen.dart';
import 'package:e_season/screens/register_success_screen.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

/// Wraps the mock and counts calls so tests can check what the pages invoke.
class _CountingRepo extends MockRegistrationRepository {
  int registerCalls = 0;
  int resendCalls = 0;
  _CountingRepo() : super(delay: Duration.zero);

  @override
  Future<RegistrationResult> register(RegistrationData data) {
    registerCalls++;
    return super.register(data);
  }

  @override
  Future<OtpResult> resendVerificationCode(String email) {
    resendCalls++;
    return super.resendVerificationCode(email);
  }
}

RegistrationFlow _flow(RegistrationRepository repo) {
  final draft = RegistrationDraft(type: PassengerType.general)
    ..fullName = 'Kasun Perera'
    ..address = '12 Main St'
    ..nic = '972430039V'
    ..nicIssueDate = DateTime(2015, 6, 1)
    ..email = 'kasun@gmail.com'
    ..phone = '0771234567'
    ..profilePhotoPath = '/tmp/p.jpg'
    ..nicFrontPath = '/tmp/f.jpg'
    ..nicBackPath = '/tmp/b.jpg';
  return RegistrationFlow(draft: draft, repo: repo);
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pump();
}

/// Lets zero-delay mock futures finish.
Future<void> _settleCalls(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('maskEmail hides all but the first character', () {
    expect(maskEmail('kasun.perera@gmail.com'), 'k***@gmail.com');
    expect(maskEmail('not-an-email'), 'not-an-email');
  });

  group('OTPVerificationScreen', () {
    testWidgets('shows six boxes, the masked email and a resend countdown',
        (tester) async {
      await _pump(tester, OTPVerificationScreen(flow: _flow(_CountingRepo())));
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.textContaining('k***@gmail.com'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    testWidgets('a wrong code shows an error and stays on the page',
        (tester) async {
      await _pump(tester, OTPVerificationScreen(flow: _flow(_CountingRepo())));
      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.pump();
      await tester.tap(find.text(AppStrings.otpVerify));
      await _settleCalls(tester);

      expect(find.text(AppStrings.otpIncorrect), findsOneWidget);
      expect(find.byType(RegistrationSuccessScreen), findsNothing);
    });

    testWidgets('an incomplete code is rejected before calling the server',
        (tester) async {
      await _pump(tester, OTPVerificationScreen(flow: _flow(_CountingRepo())));
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.pump();
      await tester.tap(find.text(AppStrings.otpVerify));
      await tester.pump();

      expect(find.text(AppStrings.otpRequired), findsOneWidget);
    });

    testWidgets('the right code (pasted) verifies and shows the success page',
        (tester) async {
      final flow = _flow(_CountingRepo())
        ..draft.registeredId = 'P-123'
        ..draft.password = 'ChangeMe-12345';
      await _pump(tester, OTPVerificationScreen(flow: flow));
      await tester.enterText(
          find.byType(TextField).first, MockRegistrationRepository.demoOtp);
      await tester.pump();
      await tester.tap(find.text(AppStrings.otpVerify));
      await _settleCalls(tester);
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationSuccessScreen), findsOneWidget);
      expect(find.textContaining('P-123'), findsOneWidget);
      // The password is wiped once verification is done.
      expect(flow.draft.password, isEmpty);
      expect(flow.draft.registeredId, isNull);
    });

    testWidgets('resend is only enabled after the cooldown', (tester) async {
      final repo = _CountingRepo();
      await _pump(tester, OTPVerificationScreen(flow: _flow(repo)));

      await tester.tap(find.textContaining('Resend code in'));
      await tester.pump();
      expect(repo.resendCalls, 0);

      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text(AppStrings.otpResend));
      await _settleCalls(tester);
      expect(repo.resendCalls, 1);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });
  });

  group('RegisterPasswordScreen', () {
    Future<void> fillAndSubmit(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ChangeMe-12345');
      await tester.enterText(fields.at(1), 'ChangeMe-12345');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text(AppStrings.createAccountButton));
      await _settleCalls(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('button stays disabled until the consent box is ticked',
        (tester) async {
      await _pump(
          tester, RegisterPasswordScreen(flow: _flow(_CountingRepo())));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ChangeMe-12345');
      await tester.enterText(fields.at(1), 'ChangeMe-12345');
      await tester.pump();

      ElevatedButton button() =>
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button().onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('creating the account registers once and opens verification',
        (tester) async {
      final repo = _CountingRepo();
      final flow = _flow(repo);
      await _pump(tester, RegisterPasswordScreen(flow: flow));
      await fillAndSubmit(tester);

      expect(repo.registerCalls, 1);
      expect(flow.draft.registeredId, startsWith('P-'));
      expect(find.byType(OTPVerificationScreen), findsOneWidget);
    });

    testWidgets('coming back and continuing does not register twice',
        (tester) async {
      final repo = _CountingRepo();
      final flow = _flow(repo);
      await _pump(tester, RegisterPasswordScreen(flow: flow));
      await fillAndSubmit(tester);
      expect(repo.registerCalls, 1);

      // Back to the password page, then continue again.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(OTPVerificationScreen), findsNothing);

      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(repo.registerCalls, 1);
      expect(find.byType(OTPVerificationScreen), findsOneWidget);
    });
  });
}
