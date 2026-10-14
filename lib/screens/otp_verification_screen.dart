import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/screens/register_success_screen.dart';
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

/// Final step. All the data is already collected and saved on the device, so
/// this page does three things in order:
///   1. texts a 6-digit code to the mobile number from the details page,
///   2. checks the code (the server answers with proof of verification), and
///   3. submits everything in a single register call.
///
/// If step 3 fails after the code was accepted, the page offers a retry
/// instead of asking for a new code.
class OTPVerificationScreen extends StatefulWidget {
  final RegistrationFlow flow;
  const OTPVerificationScreen({super.key, required this.flow});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  static const _length = 6;

  /// Matches the server's resend cooldown.
  static const _resendSeconds = 60;

  final _ctrls = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 0;

  bool _sending = false;
  bool _verifying = false;
  bool _submitting = false;
  String? _error;

  /// Only set when the server is in demo mode and returns the code itself.
  String? _devCode;

  RegistrationFlow get _flow => widget.flow;
  String get _phone => _flow.draft.phone.trim();
  String get _code => _ctrls.map((c) => c.text).join();

  /// The number was already verified earlier (for example the user came back to
  /// this page after a failed submit), so no new code is needed.
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
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _nodes) {
      f.dispose();
    }
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
    for (final c in _ctrls) {
      c.clear();
    }
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

  void _onChanged(int i, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Pasted code: spread it across the boxes.
      for (var k = 0; k < digits.length && i + k < _length; k++) {
        _ctrls[i + k].text = digits[k];
      }
      final last = (i + digits.length).clamp(0, _length - 1);
      _nodes[last].requestFocus();
    } else if (digits.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (digits.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() => _error = null);
  }

  Future<void> _verify() async {
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
    await _submit();
  }

  /// The one call that sends everything collected so far.
  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    RegistrationResult? result;
    try {
      result = await _flow.repo.register(_flow.draft.toData());
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    if (result != null && result.success) {
      final reference = result.referenceNumber;
      final status = result.verificationStatus;
      await _flow.finish();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => RegistrationSuccessScreen(
                referenceNumber: reference, verificationStatus: status)),
        (route) => route.isFirst,
      );
      return;
    }

    final message = result?.errorMessage ?? AppStrings.submitFailed;
    setState(() {
      _submitting = false;
      _error = message;
    });
    if (result != null && result.requiresVerification) {
      // The server no longer accepts our proof (expired): start over with a
      // fresh code, keeping the explanation visible.
      _flow.draft.clearPhoneVerification();
      await _sendCode();
      if (mounted && _error == null) setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verified;
    return RegistrationScaffold(
      title: verified ? AppStrings.phoneVerifiedTitle : AppStrings.otpTitle,
      subtitle: '${AppStrings.otpSentTo} ${maskPhone(_phone)}',
      child: Column(children: [
        RegCard(child: verified ? _verifiedBody() : _codeBody()),
        const SizedBox(height: 20),
        if (verified)
          RegPrimaryButton(
            label: _error == null
                ? AppStrings.submitRegistration
                : AppStrings.retryRegistration,
            loading: _submitting,
            onPressed: _submit,
          )
        else ...[
          RegPrimaryButton(
            label: AppStrings.otpVerify,
            loading: _verifying || _submitting,
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
        if (!_submitting)
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
      if (_error != null) ...[
        const SizedBox(height: 14),
        Text(_error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
      ],
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
      Row(children: [
        for (var i = 0; i < _length; i++) ...[
          Expanded(child: _box(i)),
          if (i < _length - 1) const SizedBox(width: 8),
        ],
      ]),
      if (_error != null) ...[
        const SizedBox(height: 14),
        Text(_error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
      ],
    ]);
  }

  Widget _box(int i) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        enabled: !_verifying && !_submitting,
        autofocus: i == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_length),
        ],
        style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: RegColors.deepViolet),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: RegColors.bg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _error != null ? Colors.redAccent : RegColors.border,
                  width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: RegColors.deepViolet, width: 1.8)),
        ),
        onChanged: (v) => _onChanged(i, v),
      ),
    );
  }
}
