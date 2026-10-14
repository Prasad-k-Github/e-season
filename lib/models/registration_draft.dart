// lib/models/registration_draft.dart

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/utils/validation_utils.dart';

enum RegStep { details, photo, nicImages, employment, password }

/// Mutable state shared by the registration pages.
///
/// Each page reads its fields from here on open and writes them back when the
/// user continues, so going back never loses what was typed. Everything except
/// the password and the phone proof is saved to local storage after each step
/// (see [toJson]) so an interrupted registration can be resumed.
class RegistrationDraft {
  PassengerType type;

  // Common details
  String fullName = '';
  String address = '';
  String nic = '';
  DateTime? dateOfBirth;
  String email = '';
  String phone = '';
  String preferredLanguage = 'en';

  /// General (private-sector) passengers only.
  String employerName = '';

  // Images (local file paths)
  String? profilePhotoPath;
  String? nicFrontPath;
  String? nicBackPath;

  // Government employment
  String? institution;
  String orgAuthCode = '';
  String employeeNo = '';
  String designation = '';

  // Memory only: never written to local storage.
  String password = '';

  /// Proof from the server that [verifiedPhone] was confirmed with a code.
  /// Required to register; short-lived, so it is never saved either.
  String? registrationToken;
  String? verifiedPhone;

  RegistrationDraft({this.type = PassengerType.general});

  bool get isGovernment => type == PassengerType.government;

  /// True when [registrationToken] was issued for the current phone number.
  bool get isPhoneVerified =>
      registrationToken != null &&
      verifiedPhone != null &&
      verifiedPhone == ValidationUtils.normalizePhone(phone);

  void clearPhoneVerification() {
    registrationToken = null;
    verifiedPhone = null;
  }

  /// Each passenger type has its own extra fields; switching clears the other's.
  void setType(PassengerType value) {
    type = value;
    if (value == PassengerType.general) {
      clearGovernmentFields();
    } else {
      employerName = '';
    }
  }

  void clearGovernmentFields() {
    institution = null;
    orgAuthCode = '';
    employeeNo = '';
    designation = '';
  }

  /// Wipes the secrets once registration is finished or abandoned.
  void clearSecrets() {
    password = '';
    clearPhoneVerification();
  }

  Map<String, dynamic> toJson() => {
        'type':              type.name,
        'fullName':          fullName,
        'address':           address,
        'nic':               nic,
        'dateOfBirth':       dateOfBirth?.toIso8601String(),
        'email':             email,
        'phone':             phone,
        'preferredLanguage': preferredLanguage,
        'employerName':      employerName,
        'profilePhotoPath':  profilePhotoPath,
        'nicFrontPath':      nicFrontPath,
        'nicBackPath':       nicBackPath,
        'institution':       institution,
        'orgAuthCode':       orgAuthCode,
        'employeeNo':        employeeNo,
        'designation':       designation,
      };

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key] is String ? json[key] as String : '';
    String? optional(String key) =>
        json[key] is String && (json[key] as String).isNotEmpty
            ? json[key] as String
            : null;
    final language = text('preferredLanguage');

    return RegistrationDraft(
      type: PassengerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PassengerType.general,
      ),
    )
      ..fullName          = text('fullName')
      ..address           = text('address')
      ..nic               = text('nic')
      ..dateOfBirth       = DateTime.tryParse(text('dateOfBirth'))
      ..email             = text('email')
      ..phone             = text('phone')
      ..preferredLanguage = const ['en', 'si', 'ta'].contains(language) ? language : 'en'
      ..employerName      = text('employerName')
      ..profilePhotoPath  = optional('profilePhotoPath')
      ..nicFrontPath      = optional('nicFrontPath')
      ..nicBackPath       = optional('nicBackPath')
      ..institution       = optional('institution')
      ..orgAuthCode       = text('orgAuthCode')
      ..employeeNo        = text('employeeNo')
      ..designation       = text('designation');
  }

  /// Replaces this draft's contents with [other]'s (used when resuming).
  void copyFrom(RegistrationDraft other) {
    type = other.type;
    fullName = other.fullName;
    address = other.address;
    nic = other.nic;
    dateOfBirth = other.dateOfBirth;
    email = other.email;
    phone = other.phone;
    preferredLanguage = other.preferredLanguage;
    employerName = other.employerName;
    profilePhotoPath = other.profilePhotoPath;
    nicFrontPath = other.nicFrontPath;
    nicBackPath = other.nicBackPath;
    institution = other.institution;
    orgAuthCode = other.orgAuthCode;
    employeeNo = other.employeeNo;
    designation = other.designation;
  }

  /// Only call once every page has been validated.
  RegistrationData toData() {
    String? blankToNull(String v) => v.trim().isEmpty ? null : v.trim();
    return RegistrationData(
      passengerType:     type,
      fullName:          fullName.trim(),
      address:           address.trim(),
      nic:               nic.trim().toUpperCase(),
      phone:             phone.trim(),
      email:             blankToNull(email),
      dateOfBirth:       dateOfBirth,
      preferredLanguage: preferredLanguage,
      password:          password,
      profilePhotoPath:  profilePhotoPath!,
      nicFrontPath:      nicFrontPath!,
      nicBackPath:       nicBackPath!,
      institution:       isGovernment ? institution : null,
      orgAuthCode:       isGovernment ? orgAuthCode.trim() : null,
      employeeNo:        isGovernment ? blankToNull(employeeNo) : null,
      designation:       isGovernment ? blankToNull(designation) : null,
      employerName:      isGovernment ? null : blankToNull(employerName),
      registrationToken: registrationToken,
    );
  }

  @override
  String toString() => 'RegistrationDraft(<redacted>)';
}
