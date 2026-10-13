// lib/utils/registration_options.dart
//
// Fixed choices offered on the registration form. The backend stores these
// as free text, so the values below are what gets sent.

class RegistrationOptions {
  RegistrationOptions._();

  static const travelClasses = ['First', 'Second', 'Third'];

  static const seasonTypes = ['Monthly', 'Quarterly', 'Annual'];

  /// Government work places (sent as `workPlace`).
  static const institutions = [
    'Ministry of Education',
    'Ministry of Finance',
    'Ministry of Health',
    'Ministry of Transport',
    'Sri Lanka Railways',
    'Sri Lanka Police',
    'Department of Census and Statistics',
    'Divisional Secretariat',
    'Provincial Council',
  ];
}
