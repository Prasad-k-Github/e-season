import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/password_screen.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/services/firebase_service.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/services/registration_repository_factory.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Registration step 1: passenger type and common details. Later steps are
/// separate pages, see [RegistrationFlow].
class RegisterScreen extends StatefulWidget {
  final PassengerType initialType;

  /// Defaults to the repository chosen in `.env` (real API or offline mock).
  final RegistrationRepository? repository;

  const RegisterScreen({
    super.key,
    this.initialType = PassengerType.general,
    this.repository,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _nicCtrl         = TextEditingController();
  final _issueDateCtrl   = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _firebaseService = FirebaseService();

  late final RegistrationFlow _flow = RegistrationFlow(
    draft: RegistrationDraft(type: widget.initialType),
    repo: widget.repository ?? createRegistrationRepository(),
  );

  RegistrationDraft get _draft => _flow.draft;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text    = _draft.fullName;
    _addressCtrl.text = _draft.address;
    _nicCtrl.text     = _draft.nic;
    _emailCtrl.text   = _draft.email;
    _phoneCtrl.text   = _draft.phone;
    final date = _draft.nicIssueDate;
    if (date != null) _issueDateCtrl.text = _formatDate(date);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _nicCtrl.dispose();
    _issueDateCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickIssueDate(FormFieldState<String> field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.nicIssueDate ?? DateTime(now.year - 5),
      firstDate: DateTime(1960),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    _issueDateCtrl.text = _formatDate(picked);
    field.didChange(_issueDateCtrl.text);
    setState(() => _draft.nicIssueDate = picked);
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    _draft
      ..fullName = _nameCtrl.text
      ..address  = _addressCtrl.text
      ..nic      = _nicCtrl.text
      ..email    = _emailCtrl.text
      ..phone    = _phoneCtrl.text;
    _flow.pushNext(context, RegStep.details);
  }

  void _googleRegister() async {
    // TODO: bypass – remove to re-enable Google registration
    Navigator.pushReplacementNamed(context, '/dashboard');
    return;
    // ignore: dead_code
    try {
      User? user = await _firebaseService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PasswordScreen(userData: {
            'fullName': user.displayName ?? '',
            'address':  '',
            'nic':      '',
            'email':    user.email ?? '',
            'phone':    user.phoneNumber ?? '',
          }),
        ));
      }
    } catch (e) { showRegToast(context, 'Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.stepDetails,
      step: _flow.numberOf(RegStep.details),
      totalSteps: _flow.total,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(children: [
          // Passenger type
          RegCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const RegSectionTitle(AppStrings.passengerType),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _TypeOption(
                  label: AppStrings.typeGovernment,
                  icon: Icons.badge_outlined,
                  selected: _draft.isGovernment,
                  onTap: () => setState(
                      () => _draft.setType(PassengerType.government)),
                )),
                const SizedBox(width: 10),
                Expanded(child: _TypeOption(
                  label: AppStrings.typeGeneral,
                  icon: Icons.person_outline_rounded,
                  selected: !_draft.isGovernment,
                  onTap: () => setState(
                      () => _draft.setType(PassengerType.general)),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Common details
          RegCard(
            child: Column(children: [
              RegField(controller: _nameCtrl, label: AppStrings.fullNameLabel, hint: AppStrings.fullNameHint, icon: Icons.person_outline_rounded, type: TextInputType.name, validator: ValidationUtils.validateName),
              const SizedBox(height: 12),
              RegField(controller: _addressCtrl, label: AppStrings.addressLabel, hint: AppStrings.addressHint, icon: Icons.home_outlined, type: TextInputType.streetAddress, validator: ValidationUtils.validateAddress),
              const SizedBox(height: 12),
              RegField(controller: _nicCtrl, label: AppStrings.nicLabel, hint: AppStrings.nicHint, icon: Icons.credit_card_outlined, validator: ValidationUtils.validateNIC),
              const SizedBox(height: 12),
              FormField<String>(
                validator: (_) =>
                    ValidationUtils.validateNicIssueDate(_draft.nicIssueDate),
                builder: (field) => TextField(
                  controller: _issueDateCtrl,
                  readOnly: true,
                  onTap: () => _pickIssueDate(field),
                  decoration: regFieldDec(AppStrings.nicIssueDateLabel,
                          AppStrings.nicIssueDateHint, Icons.event_outlined)
                      .copyWith(errorText: field.errorText),
                  style: GoogleFonts.inter(
                      fontSize: 14, color: RegColors.deepViolet),
                ),
              ),
              const SizedBox(height: 12),
              RegField(controller: _emailCtrl, label: AppStrings.emailLabel, hint: AppStrings.emailHint, icon: Icons.email_outlined, type: TextInputType.emailAddress, validator: ValidationUtils.validateEmail),
              const SizedBox(height: 12),
              RegField(controller: _phoneCtrl, label: AppStrings.mobileLabel, hint: AppStrings.mobileHint, icon: Icons.phone_outlined, type: TextInputType.phone, validator: ValidationUtils.validatePhone),
            ]),
          ),
          const SizedBox(height: 20),

          RegPrimaryButton(label: AppStrings.next, onPressed: _next),
          const SizedBox(height: 20),

          Row(children: [
            const Expanded(child: Divider(color: RegColors.border, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(AppStrings.or,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: RegColors.muted)),
            ),
            const Expanded(child: Divider(color: RegColors.border, thickness: 1)),
          ]),
          const SizedBox(height: 20),

          // Google sign up
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: _googleRegister,
              icon: Image.asset('assets/images/google_logo.png', height: 20),
              label: Text(AppStrings.signUpWithGoogle,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RegColors.deepViolet)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RegColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Passenger type option ───────────────────────────────────────────
class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({required this.label, required this.icon,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? RegColors.deepViolet : RegColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? RegColors.deepViolet : RegColors.border,
                width: 1.5),
          ),
          child: Column(children: [
            Icon(icon, size: 22,
                color: selected ? RegColors.gold : RegColors.muted),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : RegColors.deepViolet)),
          ]),
        ),
      );
}
