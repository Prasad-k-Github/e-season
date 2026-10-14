// lib/screens/registration_flow.dart
//
// Ties the registration pages together: which pages a passenger type sees, in
// what order, and the shared draft, local storage and repository they use.
//
// Data is collected page by page and saved locally after each one. Nothing is
// sent to the server until every page is done and the email is verified; then
// one register call sends it all.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/otp_verification_screen.dart';
import 'package:e_season/screens/register_government_screen.dart';
import 'package:e_season/screens/register_nic_screen.dart';
import 'package:e_season/screens/register_password_screen.dart';
import 'package:e_season/screens/register_photo_screen.dart';
import 'package:e_season/services/draft_store.dart';
import 'package:e_season/services/registration_repository.dart';

export 'package:e_season/models/registration_draft.dart' show RegStep;

class RegistrationFlow {
  final RegistrationDraft draft;
  final RegistrationRepository repo;
  final DraftStore store;

  RegistrationFlow({
    required this.draft,
    required this.repo,
    DraftStore? store,
  }) : store = store ?? MemoryDraftStore();

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

  /// Saves the draft after [completed] was finished. Never throws: a storage
  /// problem must not stop someone registering.
  Future<void> save(RegStep completed) async {
    try {
      draft.profilePhotoPath = await _keep(draft.profilePhotoPath);
      draft.nicFrontPath = await _keep(draft.nicFrontPath);
      draft.nicBackPath = await _keep(draft.nicBackPath);
      await store.save(draft, completed);
    } catch (_) {
      // Deliberately not logged: errors here can contain file paths.
    }
  }

  Future<String?> _keep(String? path) async =>
      path == null ? null : store.keepImage(path);

  /// Opens the page after [current] and saves the draft in the background. The
  /// password page is last; it calls [openVerification] instead.
  void pushNext(BuildContext context, RegStep current) {
    final index = steps.indexOf(current);
    assert(index + 1 < steps.length, 'The password page is the last step.');
    unawaited(save(current));
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => _pageFor(steps[index + 1])));
  }

  /// Opens email verification. The password is held in memory only, so it is
  /// never part of what [save] writes.
  void openVerification(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => OTPVerificationScreen(flow: this)));
  }

  /// Re-opens the pages after [lastCompleted] as a back stack, so Back walks
  /// through the earlier pages with their values already filled in.
  void resume(BuildContext context, RegStep lastCompleted) {
    final target = steps.indexOf(lastCompleted) + 1;
    if (target <= 0) return;
    final last = target < steps.length ? target : steps.length - 1;
    for (var i = 1; i <= last; i++) {
      final page = _pageFor(steps[i]);
      Navigator.push(
        context,
        i < last
            ? _InstantRoute(builder: (_) => page)
            : MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  /// Registration succeeded: remove the saved copy and every secret.
  Future<void> finish() async {
    draft.clearSecrets();
    try {
      await store.clear();
    } catch (_) {
      // The account exists; a leftover local draft is not worth failing over.
    }
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

/// A page route that appears at once, for the pages stacked below the one the
/// user actually lands on when resuming.
class _InstantRoute<T> extends MaterialPageRoute<T> {
  _InstantRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;
}
