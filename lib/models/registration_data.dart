// lib/models/registration_data.dart

enum PassengerType { general, government }

/// Everything collected by the registration pages.
///
/// Images are referenced by local file path. [toString] is redacted so NIC
/// numbers, passwords and image paths never end up in logs.
class RegistrationData {
  final PassengerType passengerType;
  final String fullName;
  final String address;
  final String nic;
  final DateTime nicIssueDate;
  final String email;
  final String phone;
  final String password;
  final String profilePhotoPath;
  final String nicFrontPath;
  final String nicBackPath;

  /// Government employees only; null for general passengers.
  final String? institution;
  final String? ministry;
  final String? nearestStation;
  final String? orgAuthCode;

  const RegistrationData({
    required this.passengerType,
    required this.fullName,
    required this.address,
    required this.nic,
    required this.nicIssueDate,
    required this.email,
    required this.phone,
    required this.password,
    required this.profilePhotoPath,
    required this.nicFrontPath,
    required this.nicBackPath,
    this.institution,
    this.ministry,
    this.nearestStation,
    this.orgAuthCode,
  });

  @override
  String toString() =>
      'RegistrationData(type: ${passengerType.name}, <personal data redacted>)';
}

class RegistrationResult {
  final bool success;
  final String? referenceNumber;
  final String? errorMessage;

  const RegistrationResult.success(this.referenceNumber)
      : success = true,
        errorMessage = null;

  const RegistrationResult.failure(this.errorMessage)
      : success = false,
        referenceNumber = null;
}

/// Outcome of sending or verifying an email OTP.
class OtpResult {
  final bool success;
  final String? errorMessage;

  const OtpResult.success()
      : success = true,
        errorMessage = null;

  const OtpResult.failure(this.errorMessage) : success = false;
}
