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
  final _formKey     = GlobalKey<FormState>();
  final _ministryCtrl = TextEditingController();
  final _nearestCtrl  = TextEditingController();
  final _orgCodeCtrl  = TextEditingController();

  List<String> _institutions = const [];
  bool _institutionsFailed = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.flow.draft;
    _ministryCtrl.text = draft.ministry;
    _nearestCtrl.text  = draft.nearestStation;
    _orgCodeCtrl.text  = draft.orgAuthCode;
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
    _ministryCtrl.dispose();
    _nearestCtrl.dispose();
    _orgCodeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    widget.flow.draft
      ..ministry       = _ministryCtrl.text
      ..nearestStation = _nearestCtrl.text
      ..orgAuthCode    = _orgCodeCtrl.text;
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
              RegField(controller: _ministryCtrl, label: AppStrings.ministryLabel, hint: AppStrings.ministryHint, icon: Icons.account_balance_wallet_outlined, validator: ValidationUtils.validateOptionalText),
              const SizedBox(height: 12),
              RegField(controller: _nearestCtrl, label: AppStrings.nearestStationLabel, hint: AppStrings.nearestStationHint, icon: Icons.train_outlined, validator: ValidationUtils.validateOptionalText),
              const SizedBox(height: 12),
              RegField(controller: _orgCodeCtrl, label: AppStrings.orgCodeLabel, hint: AppStrings.orgCodeHint, icon: Icons.key_outlined, validator: ValidationUtils.validateOrgAuthCode),
            ]),
          ),
          const SizedBox(height: 20),
          RegPrimaryButton(label: AppStrings.next, onPressed: _next),
        ]),
      ),
    );
  }
}
