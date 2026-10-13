import 'package:flutter/material.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Registration step 2: profile photo.
class RegisterPhotoScreen extends StatefulWidget {
  final RegistrationFlow flow;
  const RegisterPhotoScreen({super.key, required this.flow});

  @override
  State<RegisterPhotoScreen> createState() => _RegisterPhotoScreenState();
}

class _RegisterPhotoScreenState extends State<RegisterPhotoScreen> {
  String? _error;

  Future<void> _pick() async {
    final path = await pickImageWithSheet(context);
    if (path == null || !mounted) return;
    setState(() {
      widget.flow.draft.profilePhotoPath = path;
      _error = null;
    });
  }

  void _next() {
    final error =
        ValidationUtils.validateImage(widget.flow.draft.profilePhotoPath);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.flow.pushNext(context, RegStep.photo);
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return RegistrationScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.stepPhoto,
      step: flow.numberOf(RegStep.photo),
      totalSteps: flow.total,
      child: Column(children: [
        RegCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(AppStrings.photoSubtitle,
                style: TextStyle(fontSize: 13, color: RegColors.muted)),
            const SizedBox(height: 16),
            ImagePickTile(
              label: AppStrings.profilePhoto,
              icon: Icons.face_outlined,
              path: flow.draft.profilePhotoPath,
              errorText: _error,
              aspectRatio: 1,
              onTap: _pick,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        RegPrimaryButton(label: AppStrings.next, onPressed: _next),
      ]),
    );
  }
}
