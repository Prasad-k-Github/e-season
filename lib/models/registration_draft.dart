// lib/models/registration_draft.dart

import 'package:e_season/models/registration_data.dart';

/// Mutable state shared by the registration pages.
///
/// Each page reads its fields from here on open and writes them back when the
/// user continues, so going back never loses what was typed.
class RegistrationDraft {
  PassengerType type;

  // Common details
  String fullName = '';
  String address = '';
  String nic = '';
  DateTime? nicIssueDate;
  String email = '';
  String phone = '';

  // Images (local file paths)
  String? profilePhotoPath;
  String? nicFrontPath;
  String? nicBackPath;

  // Government employment
  String? institution;
  String ministry = '';
  String nearestStation = '';
  String orgAuthCode = '';

  // Password (kept in memory only until verification finishes)
  String password = '';

  /// Set once the account exists on the server but its email is not verified
  /// yet, so going back and pressing "Create account" again never registers
  /// twice.
  String? registeredId;

  RegistrationDraft({this.type = PassengerType.general});

  bool get isGovernment => type == PassengerType.government;

  /// Switching to general clears the government-only fields.
  void setType(PassengerType value) {
    type = value;
    if (value == PassengerType.general) clearGovernmentFields();
  }

  void clearGovernmentFields() {
    institution = null;
    ministry = '';
    nearestStation = '';
    orgAuthCode = '';
  }

  /// Only call once every page has been validated.
  RegistrationData toData() => RegistrationData(
        passengerType:    type,
        fullName:         fullName.trim(),
        address:          address.trim(),
        nic:              nic.trim().toUpperCase(),
        nicIssueDate:     nicIssueDate!,
        email:            email.trim(),
        phone:            phone.trim(),
        password:         password,
        profilePhotoPath: profilePhotoPath!,
        nicFrontPath:     nicFrontPath!,
        nicBackPath:      nicBackPath!,
        institution:      isGovernment ? institution : null,
        ministry:         isGovernment ? ministry.trim() : null,
        nearestStation:   isGovernment ? nearestStation.trim() : null,
        orgAuthCode:      isGovernment ? orgAuthCode.trim() : null,
      );

  @override
  String toString() => 'RegistrationDraft(<redacted>)';
}
