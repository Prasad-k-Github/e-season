import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/models/registration_data.dart';
import 'package:e_season/screens/register_success_screen.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Last page: password and data-collection consent. Submitting sends everything
/// collected so far in one register call, with the proof from the mobile
/// verification done earlier.
class RegisterPasswordScreen extends StatefulWidget {
  final RegistrationFlow flow;
  const RegisterPasswordScreen({super.key, required this.flow});

  @override
  State<RegisterPasswordScreen> createState() => _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState extends State<RegisterPasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false, _showConfirm = false;
  bool _consent = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passCtrl.text = _confirmCtrl.text = widget.flow.draft.password;
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _consent &&
      ValidationUtils.validatePassword(_passCtrl.text) == null &&
      ValidationUtils.validateConfirmPassword(
              _passCtrl.text, _confirmCtrl.text) ==
          null;

  Future<void> _submit() async {
    if (!_canContinue || !_formKey.currentState!.validate()) return;
    final flow = widget.flow;
    flow.draft.password = _passCtrl.text;
    setState(() {
      _submitting = true;
      _error = null;
    });
    RegistrationResult? result;
    try {
      result = await flow.repo.register(flow.draft.toData());
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    if (result != null && result.success) {
      final reference = result.referenceNumber;
      final status = result.verificationStatus;
      await flow.finish();
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

    setState(() {
      _submitting = false;
      _error = result?.errorMessage ?? AppStrings.submitFailed;
    });
    if (result != null && result.requiresVerification) {
      // The proof expired: verify the number again, then submit once more.
      flow.draft.clearPhoneVerification();
      final verified = await flow.reverify(context);
      if (mounted && verified == true) await _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return RegistrationScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.stepPassword,
      step: flow.numberOf(RegStep.password),
      totalSteps: flow.total,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: Column(children: [
          RegCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(AppStrings.passwordSubtitle,
                  style: TextStyle(fontSize: 13, color: RegColors.muted)),
              const SizedBox(height: 16),
              RegField(
                controller: _passCtrl,
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                icon: Icons.lock_outline_rounded,
                type: TextInputType.visiblePassword,
                validator: ValidationUtils.validatePassword,
                obscure: !_showPass,
                onToggleObscure: () => setState(() => _showPass = !_showPass),
              ),
              const SizedBox(height: 12),
              RegField(
                controller: _confirmCtrl,
                label: AppStrings.confirmPasswordLabel,
                hint: AppStrings.confirmPasswordHint,
                icon: Icons.lock_outline_rounded,
                type: TextInputType.visiblePassword,
                validator: (v) =>
                    ValidationUtils.validateConfirmPassword(_passCtrl.text, v),
                obscure: !_showConfirm,
                onToggleObscure: () =>
                    setState(() => _showConfirm = !_showConfirm),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Consent
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _consent = !_consent),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _consent,
                activeColor: RegColors.deepViolet,
                onChanged: (v) => setState(() => _consent = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(AppStrings.consentText,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: RegColors.muted)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
            const SizedBox(height: 12),
          ],
          RegPrimaryButton(
            label: _error == null
                ? AppStrings.submitRegistration
                : AppStrings.retryRegistration,
            loading: _submitting,
            onPressed: _canContinue && !_submitting ? _submit : null,
          ),
          const SizedBox(height: 8),
          Text(_canContinue ? AppStrings.passwordHintBox : AppStrings.submitHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: RegColors.muted)),
        ]),
      ),
    );
  }
}
