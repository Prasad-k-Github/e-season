import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Last registration step: password and data-collection consent. Continuing
/// creates the account (the server emails a code) and opens email verification.
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
  bool _creating = false;

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

  bool get _alreadyCreated => widget.flow.draft.registeredId != null;

  /// Creates the account (the server emails the code as part of this), then
  /// opens email verification. If the account already exists from an earlier
  /// attempt, goes straight to verification instead of registering twice.
  Future<void> _continue() async {
    if (!_canContinue || !_formKey.currentState!.validate()) return;
    final flow = widget.flow;
    flow.draft.password = _passCtrl.text;

    if (_alreadyCreated) {
      flow.openVerification(context);
      return;
    }

    setState(() => _creating = true);
    try {
      final result = await flow.repo.register(flow.draft.toData());
      if (!mounted) return;
      if (result.success) {
        flow.draft.registeredId = result.referenceNumber ?? '';
        flow.openVerification(context);
      } else {
        showRegToast(context, result.errorMessage ?? AppStrings.submitFailed);
      }
    } catch (_) {
      if (mounted) showRegToast(context, AppStrings.submitFailed);
    } finally {
      if (mounted) setState(() => _creating = false);
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
      child: AbsorbPointer(
        absorbing: _creating,
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

          RegPrimaryButton(
            label: AppStrings.createAccountButton,
            loading: _creating,
            onPressed: _canContinue ? _continue : null,
          ),
          const SizedBox(height: 8),
          Text(
              !_canContinue
                  ? AppStrings.submitHint
                  : _alreadyCreated
                      ? AppStrings.alreadyCreatedHint
                      : AppStrings.passwordHintBox,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: RegColors.muted)),
        ]),
        ),
      ),
    );
  }
}
