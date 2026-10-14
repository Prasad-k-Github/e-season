// lib/models/registration_data.dart

enum PassengerType { general, government }

/// Everything collected by the registration pages, sent in one request.
///
/// Images are referenced by local file path. [toString] is redacted so NIC
/// numbers, passwords and image paths never end up in logs.
class RegistrationData {
  final PassengerType passengerType;
  final String fullName;
  final String address;
  final String nic;

  /// Used to verify the number with a code; the server takes the phone number
  /// from that verification, not from the registration request.
  final String phone;

  /// Optional, and not verified by the server.
  final String? email;
  final DateTime? dateOfBirth;

  /// `en`, `si` or `ta`.
  final String preferredLanguage;
  final String password;
  final String profilePhotoPath;
  final String nicFrontPath;
  final String nicBackPath;

  /// Government employees only; null for general passengers.
  final String? institution;
  final String? orgAuthCode;
  final String? employeeNo;
  final String? designation;

  /// General (private-sector) passengers only.
  final String? employerName;

  /// Proof from the server that [phone] was verified; the register request is
  /// refused without it.
  final String? registrationToken;

  const RegistrationData({
    required this.passengerType,
    required this.fullName,
    required this.address,
    required this.nic,
    required this.phone,
    required this.password,
    required this.profilePhotoPath,
    required this.nicFrontPath,
    required this.nicBackPath,
    this.email,
    this.dateOfBirth,
    this.preferredLanguage = 'en',
    this.institution,
    this.orgAuthCode,
    this.employeeNo,
    this.designation,
    this.employerName,
    this.registrationToken,
  });

  @override
  String toString() =>
      'RegistrationData(type: ${passengerType.name}, <personal data redacted>)';
}

class RegistrationResult {
  final bool success;

  /// Shown to the user, e.g. `ES-1A2B3C4D`.
  final String? referenceNumber;

  /// `pending_verification` or `pending_institution_approval`.
  final String? verificationStatus;
  final String? errorMessage;

  /// The server no longer accepts the phone verification (for example it
  /// expired), so the user must verify the number again.
  final bool requiresVerification;

  const RegistrationResult.success(this.referenceNumber, {this.verificationStatus})
      : success = true,
        errorMessage = null,
        requiresVerification = false;

  const RegistrationResult.failure(this.errorMessage,
      {this.requiresVerification = false})
      : success = false,
        referenceNumber = null,
        verificationStatus = null;
}

/// Outcome of sending or checking a verification code.
class OtpResult {
  final bool success;
  final String? errorMessage;

  /// Set when a code was verified: proof of the verified phone number.
  final String? token;

  /// Only present when the server runs in demo mode (no SMS gateway): the code
  /// itself, so the app can be tried without sending a real text message.
  final String? devCode;

  const OtpResult.success({this.token, this.devCode})
      : success = true,
        errorMessage = null;

  const OtpResult.failure(this.errorMessage)
      : success = false,
        token = null,
        devCode = null;
}
