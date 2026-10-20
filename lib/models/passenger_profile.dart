// lib/models/passenger_profile.dart

/// The signed-in passenger, from `GET /api/me`.
class PassengerProfile {
  final String fullName;
  final String? phone;
  final String? email;
  final String? referenceNumber;

  /// `pending_verification`, `pending_institution_approval`, `rejected`,
  /// `verified`, ...
  final String verificationStatus;
  final String? rejectionReason;

  const PassengerProfile({
    required this.fullName,
    required this.verificationStatus,
    this.phone,
    this.email,
    this.referenceNumber,
    this.rejectionReason,
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
  String get initial =>
      fullName.trim().isEmpty ? 'U' : fullName.trim()[0].toUpperCase();

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return PassengerProfile(
      fullName: text('fullName') ?? text('name') ?? '',
      verificationStatus: text('verificationStatus') ?? text('status') ?? 'pending_verification',
      phone: text('phone'),
      email: text('email'),
      referenceNumber: text('referenceNumber'),
      rejectionReason: text('rejectionReason') ?? text('rejectReason'),
    );
  }
}
