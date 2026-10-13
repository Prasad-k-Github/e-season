import 'package:flutter/material.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Registration step 3: NIC front and back images.
class RegisterNicScreen extends StatefulWidget {
  final RegistrationFlow flow;
  const RegisterNicScreen({super.key, required this.flow});

  @override
  State<RegisterNicScreen> createState() => _RegisterNicScreenState();
}

class _RegisterNicScreenState extends State<RegisterNicScreen> {
  String? _frontError, _backError;

  Future<void> _pickFront() async {
    final path = await pickImageWithSheet(context);
    if (path == null || !mounted) return;
    setState(() {
      widget.flow.draft.nicFrontPath = path;
      _frontError = null;
    });
  }

  Future<void> _pickBack() async {
    final path = await pickImageWithSheet(context);
    if (path == null || !mounted) return;
    setState(() {
      widget.flow.draft.nicBackPath = path;
      _backError = null;
    });
  }

  void _next() {
    final draft = widget.flow.draft;
    final front = ValidationUtils.validateImage(draft.nicFrontPath);
    final back = ValidationUtils.validateImage(draft.nicBackPath);
    if (front != null || back != null) {
      setState(() {
        _frontError = front;
        _backError = back;
      });
      return;
    }
    widget.flow.pushNext(context, RegStep.nicImages);
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return RegistrationScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.stepNic,
      step: flow.numberOf(RegStep.nicImages),
      totalSteps: flow.total,
      child: Column(children: [
        RegCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(AppStrings.nicSubtitle,
                style: TextStyle(fontSize: 13, color: RegColors.muted)),
            const SizedBox(height: 16),
            ImagePickTile(
              label: AppStrings.nicFront,
              icon: Icons.credit_card_outlined,
              path: flow.draft.nicFrontPath,
              errorText: _frontError,
              onTap: _pickFront,
            ),
            const SizedBox(height: 18),
            ImagePickTile(
              label: AppStrings.nicBack,
              icon: Icons.flip_outlined,
              path: flow.draft.nicBackPath,
              errorText: _backError,
              onTap: _pickBack,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        RegPrimaryButton(label: AppStrings.next, onPressed: _next),
      ]),
    );
  }
}
