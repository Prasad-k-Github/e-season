// lib/utils/validation_utils.dart

import 'package:e_season/utils/app_strings.dart';

class ValidationUtils {
  // Letters (any script, including Sinhala/Tamil vowel signs) and spaces only.
  static final _nameRegex  = RegExp(r'^[\p{L}\p{M}‍ ]+$', unicode: true);
  static final _oldNicRegex = RegExp(r'^\d{9}[VvXx]$');
  static final _newNicRegex = RegExp(r'^\d{12}$');
  static final _phoneRegex = RegExp(r'^(07\d{8}|\+947\d{8})$');

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (!_nameRegex.hasMatch(name)) {
      return AppStrings.nameInvalid;
    }
    if (name.length < 3) {
      return AppStrings.nameTooShort;
    }
    return null;
  }

  /// The server accepts 3 to 500 characters.
  static String? validateAddress(String? value) {
    final address = value?.trim() ?? '';
    if (address.isEmpty) {
      return AppStrings.addressRequired;
    }
    if (address.length < 3) {
      return AppStrings.addressTooShort;
    }
    if (address.length > 500) {
      return AppStrings.addressTooLong;
    }
    return null;
  }

  /// Old format: 9 digits + V/X (any case). New format: 12 digits.
  static String? validateNIC(String? value) {
    final nic = value?.trim() ?? '';
    if (nic.isEmpty) {
      return AppStrings.nicRequired;
    }
    if (!_oldNicRegex.hasMatch(nic) && !_newNicRegex.hasMatch(nic)) {
      return AppStrings.nicInvalid;
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Email is optional: empty is fine, anything typed must look like an address.
  static String? validateOptionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) && email.length <= 255
        ? null
        : AppStrings.emailInvalid;
  }

  /// +947XXXXXXXX for 07XXXXXXXX, 7XXXXXXXX, 947XXXXXXXX and +947XXXXXXXX (the
  /// same rule the server uses); null when it is not a Sri Lankan mobile.
  static String? normalizePhone(String? value) {
    final t = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    for (final pattern in [r'^\+94(7\d{8})$', r'^94(7\d{8})$', r'^0(7\d{8})$']) {
      final m = RegExp(pattern).firstMatch(t);
      if (m != null) return '+94${m.group(1)}';
    }
    return null;
  }

  /// Sri Lankan mobile: 07XXXXXXXX or +947XXXXXXXX.
  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return AppStrings.phoneRequired;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return AppStrings.phoneInvalid;
    }
    return null;
  }

  /// Date of birth is optional, but cannot be in the future.
  static String? validateDateOfBirth(DateTime? value, {DateTime? today}) {
    if (value == null) return null;
    final now = today ?? DateTime.now();
    if (value.isAfter(DateTime(now.year, now.month, now.day))) {
      return AppStrings.dateOfBirthFuture;
    }
    return null;
  }

  static String? validateTravelClass(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.classRequired;
    }
    return null;
  }

  static String? validateStation(String? value) {
    final station = value?.trim() ?? '';
    if (station.isEmpty) {
      return AppStrings.stationRequired;
    }
    return validateOptionalText(station);
  }

  static String? validateEndStation(String? start, String? end) {
    final error = validateStation(end);
    if (error != null) return error;
    if (start != null &&
        start.trim().toLowerCase() == end!.trim().toLowerCase()) {
      return AppStrings.stationsSame;
    }
    return null;
  }

  static String? validateSeasonType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.seasonTypeRequired;
    }
    return null;
  }

  /// Optional free text, limited to the backend's 100-character columns.
  static String? validateOptionalText(String? value) {
    if (value != null && value.trim().length > 100) {
      return AppStrings.tooLong;
    }
    return null;
  }

  static String? validateInstitution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.institutionRequired;
    }
    return null;
  }

  static String? validateOrgAuthCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.orgCodeRequired;
    }
    return null;
  }

  /// A 6-digit one-time code.
  static String? validateOtp(String? value) {
    final code = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return AppStrings.otpRequired;
    }
    return null;
  }

  /// [path] is the picked image's file path, or null if none was picked.
  static String? validateImage(String? path) {
    if (path == null || path.isEmpty) {
      return AppStrings.imageRequired;
    }
    return null;
  }

  /// Login only checks that something was typed: the server decides whether the
  /// password is right, and older accounts may predate the stricter rules.
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.loginPasswordRequired;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    // Length limits match the backend (12–128 characters).
    if (value.length < 12) {
      return AppStrings.passwordTooShort;
    }
    if (value.length > 128) {
      return AppStrings.passwordTooLong;
    }
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$');
    if (!passwordRegex.hasMatch(value)) {
      return AppStrings.passwordWeak;
    }
    return null;
  }

  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (password != confirmPassword) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }
}
