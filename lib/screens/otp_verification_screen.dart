import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// 0771234567 -> 07******67
String maskPhone(String phone) {
  final t = phone.replaceAll(RegExp(r'\s'), '');
  if (t.length <= 4) return t;
  return '${t.substring(0, 2)}${'*' * (t.length - 4)}${t.substring(t.length - 2)}';
}

/// Second step, right after the details page. Texts a 6-digit code to the
/// mobile number from the details page and checks it; the server answers with
/// proof of verification, which the last page sends with the registration.
///
/// Normally it moves on to the photo page. With [popWhenVerified] (used when
/// the server stopped accepting the earlier proof) it pops with `true` instead.
class OTPVerificationScreen extends StatefulWidget {
  final RegistrationFlow flow;
  final bool popWhenVerified;
  const OTPVerificationScreen(
      {super.key, required this.flow, this.popWhenVerified = false});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  static const _length = 6;

  /// Matches the server's resend cooldown.
  static const _resendSeconds = 60;

  final _codeCtrl = TextEditingController();

  Timer? _timer;
  int _secondsLeft = 0;

  bool _sending = false;
  bool _verifying = false;
  String? _error;

  /// Only set when the server is in demo mode and returns the code itself.
  String? _devCode;

  RegistrationFlow get _flow => widget.flow;
  String get _phone =>
      ValidationUtils.normalizePhone(_flow.draft.phone) ?? _flow.draft.phone.trim();
  String get _code => _codeCtrl.text;

  /// The number was already verified earlier (for example the user came back to
  /// this page from a later one), so no new code is needed.
  bool get _verified => _flow.draft.isPhoneVerified;

  @override
  void initState() {
    super.initState();
    if (!_verified) {
      _flow.draft.clearPhoneVerification(); // proof for a different number
      _sending = true;
      unawaited(_sendCode(initial: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  void _clearBoxes() {
    _codeCtrl.clear();
  }

  Future<void> _sendCode({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _sending = true;
        _error = null;
      });
    }
    String? failure;
    String? devCode;
    try {
      final result = await _flow.repo.sendPhoneCode(_phone);
      devCode = result.devCode;
      if (!result.success) failure = result.errorMessage ?? AppStrings.otpSendFailed;
    } catch (_) {
      failure = AppStrings.otpSendFailed;
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = failure;
      _devCode = devCode ?? _devCode;
      if (failure != null) _secondsLeft = 0; // let them retry straight away
    });
    if (failure == null) {
      _clearBoxes();
      _startCooldown();
      if (!initial) showRegToast(context, AppStrings.otpResent);
    }
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    // Verify as soon as the whole code is in (typed, pasted or auto-filled).
    if (value.length == _length && !_verifying && !_sending) _verify();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final invalid = ValidationUtils.validateOtp(_code);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    OtpResult? result;
    try {
      result = await _flow.repo.verifyPhoneCode(_phone, _code);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    final token = result?.token;
    if (result == null || !result.success || token == null) {
      setState(() {
        _verifying = false;
        _error = result == null
            ? AppStrings.submitFailed
            : (result.errorMessage ?? AppStrings.otpIncorrect);
      });
      return;
    }
    _flow.draft
      ..registrationToken = token
      ..verifiedPhone = ValidationUtils.normalizePhone(_phone);
    setState(() => _verifying = false);
    _next();
  }

  void _next() {
    if (widget.popWhenVerified) {
      Navigator.pop(context, true);
    } else {
      _flow.pushNext(context, RegStep.verify);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verified;
    return RegistrationScaffold(
      title: verified ? AppStrings.phoneVerifiedTitle : AppStrings.otpTitle,
      step: widget.popWhenVerified ? null : _flow.numberOf(RegStep.verify),
      totalSteps: widget.popWhenVerified ? null : _flow.total,
      subtitle: '${AppStrings.otpSentTo} ${maskPhone(_flow.draft.phone.trim())}',
      child: Column(children: [
        RegCard(child: verified ? _verifiedBody() : _codeBody()),
        const SizedBox(height: 20),
        if (verified)
          RegPrimaryButton(label: AppStrings.continueLabel, onPressed: _next)
        else ...[
          RegPrimaryButton(
            label: AppStrings.otpVerify,
            loading: _verifying,
            onPressed: _sending ? null : _verify,
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(AppStrings.otpDidNotGet,
                style: GoogleFonts.inter(fontSize: 12, color: RegColors.muted)),
            TextButton(
              onPressed: _secondsLeft <= 0 && !_verifying && !_sending
                  ? () => _sendCode()
                  : null,
              child: Text(
                _secondsLeft > 0
                    ? AppStrings.otpResendIn.replaceAll('{s}', '$_secondsLeft')
                    : AppStrings.otpResend,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ],
        TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Text(AppStrings.changePhone,
                style: GoogleFonts.inter(fontSize: 12, color: RegColors.muted)),
          ),
      ]),
    );
  }

  Widget _verifiedBody() {
    return Column(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: RegColors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: RegColors.green, size: 36),
      ),
      const SizedBox(height: 14),
      Text(AppStrings.phoneVerifiedMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: RegColors.muted)),
    ]);
  }

  Widget _codeBody() {
    return Column(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: RegColors.gold.withValues(alpha: 0.15),
            shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined,
            color: RegColors.gold, size: 32),
      ),
      const SizedBox(height: 14),
      Text(_sending ? AppStrings.otpSending : AppStrings.otpInstruction,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: RegColors.muted)),
      if (_devCode != null) ...[
        const SizedBox(height: 10),
        Text(AppStrings.otpDemoCode.replaceAll('{code}', _devCode!),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: RegColors.gold)),
      ],
      const SizedBox(height: 20),
      _codeField(),
      if (_error != null) ...[
        const SizedBox(height: 14),
        Text(_error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
      ],
    ]);
  }

  Widget _codeField() {
    return TextField(
      controller: _codeCtrl,
      enabled: !_verifying,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_length),
      ],
      style: GoogleFonts.inter(
          fontSize: 26,
          letterSpacing: 12,
          fontWeight: FontWeight.w700,
          color: RegColors.deepViolet),
      decoration: InputDecoration(
        counterText: '',
        hintText: '------',
        filled: true,
        fillColor: RegColors.bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: _error != null ? Colors.redAccent : RegColors.border,
                width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RegColors.deepViolet, width: 1.8)),
      ),
      onChanged: _onChanged,
      onSubmitted: (_) => _verify(),
    );
  }
}
