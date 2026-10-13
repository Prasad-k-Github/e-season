// lib/screens/registration_flow.dart
//
// Ties the registration pages together: which pages a passenger type sees, in
// what order, and the shared draft + repository they all use.

import 'package:flutter/material.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/otp_verification_screen.dart';
import 'package:e_season/screens/register_government_screen.dart';
import 'package:e_season/screens/register_nic_screen.dart';
import 'package:e_season/screens/register_password_screen.dart';
import 'package:e_season/screens/register_photo_screen.dart';
import 'package:e_season/services/registration_repository.dart';

enum RegStep { details, photo, nicImages, employment, password }

class RegistrationFlow {
  final RegistrationDraft draft;
  final RegistrationRepository repo;

  RegistrationFlow({required this.draft, required this.repo});

  /// Pages for the currently selected passenger type, in order. Government
  /// employment is only shown to government employees.
  List<RegStep> get steps => [
        RegStep.details,
        RegStep.photo,
        RegStep.nicImages,
        if (draft.type == PassengerType.government) RegStep.employment,
        RegStep.password,
      ];

  int get total => steps.length;

  /// 1-based position of [step] in [steps].
  int numberOf(RegStep step) => steps.indexOf(step) + 1;

  /// Opens the page after [current]. The password page is last: it creates
  /// the account itself and then calls [openVerification].
  void pushNext(BuildContext context, RegStep current) {
    final index = steps.indexOf(current);
    assert(index + 1 < steps.length, 'The password page is the last step.');
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => _pageFor(steps[index + 1])));
  }

  /// Opens the email verification page once the account has been created.
  void openVerification(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => OTPVerificationScreen(flow: this)));
  }

  Widget _pageFor(RegStep step) {
    switch (step) {
      case RegStep.photo:
        return RegisterPhotoScreen(flow: this);
      case RegStep.nicImages:
        return RegisterNicScreen(flow: this);
      case RegStep.employment:
        return RegisterGovernmentScreen(flow: this);
      case RegStep.password:
        return RegisterPasswordScreen(flow: this);
      case RegStep.details:
        throw StateError('The details page is the entry point.');
    }
  }
}
