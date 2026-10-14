import 'package:flutter/material.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Registration step 4 (government employees only): employment details.
class RegisterGovernmentScreen extends StatefulWidget {
  final RegistrationFlow flow;
  const RegisterGovernmentScreen({super.key, required this.flow});

  @override
  State<RegisterGovernmentScreen> createState() =>
      _RegisterGovernmentScreenState();
}

class _RegisterGovernmentScreenState extends State<RegisterGovernmentScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _orgCodeCtrl   = TextEditingController();
  final _employeeNoCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();

  List<String> _institutions = const [];
  bool _institutionsFailed = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.flow.draft;
    _orgCodeCtrl.text     = draft.orgAuthCode;
    _employeeNoCtrl.text  = draft.employeeNo;
    _designationCtrl.text = draft.designation;
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    try {
      final list = await widget.flow.repo.fetchInstitutions();
      if (mounted) setState(() => _institutions = list);
    } catch (_) {
      if (mounted) setState(() => _institutionsFailed = true);
    }
  }

  @override
  void dispose() {
    _orgCodeCtrl.dispose();
    _employeeNoCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    widget.flow.draft
      ..orgAuthCode = _orgCodeCtrl.text
      ..employeeNo  = _employeeNoCtrl.text
      ..designation = _designationCtrl.text;
    widget.flow.pushNext(context, RegStep.employment);
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return RegistrationScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.stepEmployment,
      step: flow.numberOf(RegStep.employment),
      totalSteps: flow.total,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(children: [
          RegCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(AppStrings.employmentSubtitle,
                  style: TextStyle(fontSize: 13, color: RegColors.muted)),
              const SizedBox(height: 16),
              RegDropdown(
                label: AppStrings.institutionLabel,
                hint: AppStrings.institutionHint,
                icon: Icons.account_balance_outlined,
                value: flow.draft.institution,
                items: _institutions,
                forcedError:
                    _institutionsFailed ? AppStrings.institutionsLoadFailed : null,
                onChanged: (v) => flow.draft.institution = v,
                validator: ValidationUtils.validateInstitution,
              ),
              const SizedBox(height: 12),
              RegField(controller: _orgCodeCtrl, label: AppStrings.orgCodeLabel, hint: AppStrings.orgCodeHint, icon: Icons.key_outlined, validator: ValidationUtils.validateOrgAuthCode),
              const SizedBox(height: 12),
              RegField(controller: _employeeNoCtrl, label: AppStrings.employeeNoLabel, hint: AppStrings.employeeNoHint, icon: Icons.numbers_rounded, validator: ValidationUtils.validateOptionalText),
              const SizedBox(height: 12),
              RegField(controller: _designationCtrl, label: AppStrings.designationLabel, hint: AppStrings.designationHint, icon: Icons.work_outline_rounded, validator: ValidationUtils.validateOptionalText),
            ]),
          ),
          const SizedBox(height: 20),
          RegPrimaryButton(label: AppStrings.next, onPressed: _next),
        ]),
      ),
    );
  }
}
