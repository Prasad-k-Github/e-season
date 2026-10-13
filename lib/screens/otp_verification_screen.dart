import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/screens/register_success_screen.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// kasun.perera@gmail.com -> k***@gmail.com
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email[0]}***${email.substring(at)}';
}

/// Final registration step: confirms the email address with the 6-digit code
/// the server emailed when the account was created.
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
  int _secondsLeft = _resendSeconds;

  bool _verifying = false;
  bool _resending = false;
  String? _error;

  String get _email => widget.flow.draft.email.trim();
  String get _code => _ctrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCooldown(); // the first code was emailed when the account was created
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

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    String? failure;
    try {
      final result = await widget.flow.repo.resendVerificationCode(_email);
      if (!result.success) failure = result.errorMessage ?? AppStrings.otpSendFailed;
    } catch (_) {
      failure = AppStrings.otpSendFailed;
    }
    if (!mounted) return;
    setState(() {
      _resending = false;
      _error = failure;
    });
    if (failure == null) {
      for (final c in _ctrls) {
        c.clear();
      }
      _nodes.first.requestFocus();
      _startCooldown();
      showRegToast(context, AppStrings.otpResent);
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
    try {
      final result = await widget.flow.repo.verifyEmail(_email, _code);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _verifying = false;
          _error = result.errorMessage ?? AppStrings.otpIncorrect;
        });
        return;
      }
      final draft = widget.flow.draft;
      final reference = draft.registeredId;
      draft.password = '';
      draft.registeredId = null;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => RegistrationSuccessScreen(referenceNumber: reference)),
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = AppStrings.submitFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: AppStrings.otpTitle,
      subtitle: '${AppStrings.otpSentTo} ${maskEmail(_email)}',
      child: Column(children: [
        RegCard(
          child: Column(children: [
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
            Text(AppStrings.otpAccountCreated,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: RegColors.muted)),
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
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        RegPrimaryButton(
          label: AppStrings.otpVerify,
          loading: _verifying,
          onPressed: _verify,
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppStrings.otpDidNotGet,
              style: GoogleFonts.inter(fontSize: 12, color: RegColors.muted)),
          TextButton(
            onPressed: _secondsLeft <= 0 && !_verifying && !_resending
                ? _resend
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
      ]),
    );
  }

  Widget _box(int i) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        enabled: !_verifying,
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
