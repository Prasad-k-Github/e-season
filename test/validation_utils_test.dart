import 'package:flutter_test/flutter_test.dart';

import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/validation_utils.dart';

void main() {
  group('validateName', () {
    test('accepts letters and spaces, 3+ characters', () {
      expect(ValidationUtils.validateName('Kasun Perera'), isNull);
      expect(ValidationUtils.validateName('Ann'), isNull);
      expect(ValidationUtils.validateName('  Ann  '), isNull);
    });
    test('rejects empty', () {
      expect(ValidationUtils.validateName(null), AppStrings.nameRequired);
      expect(ValidationUtils.validateName('   '), AppStrings.nameRequired);
    });
    test('rejects fewer than 3 characters', () {
      expect(ValidationUtils.validateName('Al'), AppStrings.nameTooShort);
    });
    test('rejects digits and symbols', () {
      expect(ValidationUtils.validateName('Kasun1'), AppStrings.nameInvalid);
      expect(ValidationUtils.validateName('K. Perera'), AppStrings.nameInvalid);
    });
    test('accepts Sinhala and Tamil names, as the server does', () {
      expect(ValidationUtils.validateName('නිමල් පෙරේරා'), isNull);
      expect(ValidationUtils.validateName('கமலா சில்வா'), isNull);
    });
  });

  group('validateAddress', () {
    test('needs 3 to 500 characters', () {
      expect(ValidationUtils.validateAddress(''), AppStrings.addressRequired);
      expect(ValidationUtils.validateAddress('  '), AppStrings.addressRequired);
      expect(ValidationUtils.validateAddress('ab'), AppStrings.addressTooShort);
      expect(ValidationUtils.validateAddress('12 Galle Road, Colombo'), isNull);
      expect(ValidationUtils.validateAddress('x' * 501), AppStrings.addressTooLong);
    });
  });

  group('normalizePhone', () {
    test('turns every accepted form into +947XXXXXXXX', () {
      for (final input in ['0771234567', '94771234567', '+94771234567', '077 123-4567']) {
        expect(ValidationUtils.normalizePhone(input), '+94771234567', reason: input);
      }
    });
    test('returns null for anything that is not a Sri Lankan mobile', () {
      for (final input in [null, '', '0112345678', '+94112345678', '12345']) {
        expect(ValidationUtils.normalizePhone(input), isNull, reason: '$input');
      }
    });
  });

  group('validateNIC', () {
    test('accepts old format with V/X in any case', () {
      for (final nic in ['972430039V', '972430039v', '972430039X', '972430039x']) {
        expect(ValidationUtils.validateNIC(nic), isNull, reason: nic);
      }
    });
    test('accepts new 12-digit format', () {
      expect(ValidationUtils.validateNIC('199724300390'), isNull);
    });
    test('rejects empty', () {
      expect(ValidationUtils.validateNIC(''), AppStrings.nicRequired);
      expect(ValidationUtils.validateNIC(null), AppStrings.nicRequired);
    });
    test('rejects malformed numbers', () {
      for (final nic in [
        '97243003V',     // 8 digits + V
        '9724300391V',   // 10 digits + V
        '972430039A',    // wrong letter
        '972430039',     // missing letter
        '19972430039',   // 11 digits
        '1997243003901', // 13 digits
        '19972430039V',  // 12 digits + letter
      ]) {
        expect(ValidationUtils.validateNIC(nic), AppStrings.nicInvalid, reason: nic);
      }
    });
  });

  group('validatePhone', () {
    test('accepts 07XXXXXXXX and +947XXXXXXXX', () {
      expect(ValidationUtils.validatePhone('0771234567'), isNull);
      expect(ValidationUtils.validatePhone('+94771234567'), isNull);
    });
    test('rejects empty', () {
      expect(ValidationUtils.validatePhone(''), AppStrings.phoneRequired);
    });
    test('rejects non Sri Lankan mobile formats', () {
      for (final phone in [
        '0112345678',    // landline
        '077123456',     // too short
        '07712345678',   // too long
        '94771234567',   // missing +
        '+9477123456',   // too short
        '+94112345678',  // landline
        '077 123 4567',  // spaces
      ]) {
        expect(ValidationUtils.validatePhone(phone), AppStrings.phoneInvalid, reason: phone);
      }
    });
  });

  group('government fields', () {
    test('institution is required', () {
      expect(ValidationUtils.validateInstitution(null), AppStrings.institutionRequired);
      expect(ValidationUtils.validateInstitution('Sri Lanka Railways'), isNull);
    });
    test('organisation code is required', () {
      expect(ValidationUtils.validateOrgAuthCode(' '), AppStrings.orgCodeRequired);
      expect(ValidationUtils.validateOrgAuthCode('ABC123'), isNull);
    });
  });

  group('validateOtp', () {
    test('accepts exactly 6 digits', () {
      expect(ValidationUtils.validateOtp('123456'), isNull);
      expect(ValidationUtils.validateOtp(' 123456 '), isNull);
    });
    test('rejects anything else', () {
      for (final code in [null, '', '12345', '1234567', '12345a', '12 456']) {
        expect(ValidationUtils.validateOtp(code), AppStrings.otpRequired,
            reason: '$code');
      }
    });
  });

  group('validateImage', () {
    test('requires a picked file', () {
      expect(ValidationUtils.validateImage(null), AppStrings.imageRequired);
      expect(ValidationUtils.validateImage(''), AppStrings.imageRequired);
      expect(ValidationUtils.validateImage('/tmp/photo.jpg'), isNull);
    });
  });

  group('other validators', () {
    test('email', () {
      expect(ValidationUtils.validateEmail('kasun@gmail.com'), isNull);
      expect(ValidationUtils.validateEmail('kasun'), AppStrings.emailInvalid);
    });
    test('optional email may be empty but must be valid when typed', () {
      expect(ValidationUtils.validateOptionalEmail(null), isNull);
      expect(ValidationUtils.validateOptionalEmail('  '), isNull);
      expect(ValidationUtils.validateOptionalEmail('nimal@example.com'), isNull);
      expect(ValidationUtils.validateOptionalEmail('nimal@'), AppStrings.emailInvalid);
      expect(ValidationUtils.validateOptionalEmail('a b@c.com'), AppStrings.emailInvalid);
    });
    test('password and confirm', () {
      expect(ValidationUtils.validatePassword('ChangeMe-12345'), isNull);
      expect(ValidationUtils.validatePassword('Abcdef1!'), AppStrings.passwordTooShort);
      expect(ValidationUtils.validatePassword('Aa1-${'x' * 126}'), AppStrings.passwordTooLong);
      expect(ValidationUtils.validatePassword('changeme12345'), AppStrings.passwordWeak);
      expect(ValidationUtils.validateConfirmPassword('a', 'b'), AppStrings.passwordsDoNotMatch);
    });
  });

  group('season application fields', () {
    test('date of birth is optional and not in the future', () {
      final today = DateTime(2026, 10, 14);
      expect(ValidationUtils.validateDateOfBirth(null), isNull);
      expect(ValidationUtils.validateDateOfBirth(DateTime(1990, 5, 10), today: today), isNull);
      expect(ValidationUtils.validateDateOfBirth(today, today: today), isNull);
      expect(ValidationUtils.validateDateOfBirth(DateTime(2026, 10, 15), today: today),
          AppStrings.dateOfBirthFuture);
    });
    test('class and season type are required', () {
      expect(ValidationUtils.validateTravelClass(null), AppStrings.classRequired);
      expect(ValidationUtils.validateTravelClass('Second'), isNull);
      expect(ValidationUtils.validateSeasonType(null), AppStrings.seasonTypeRequired);
      expect(ValidationUtils.validateSeasonType('Monthly'), isNull);
    });
    test('stations are required, max 100 chars, and must differ', () {
      expect(ValidationUtils.validateStation(' '), AppStrings.stationRequired);
      expect(ValidationUtils.validateStation('Colombo Fort'), isNull);
      expect(ValidationUtils.validateStation('x' * 101), AppStrings.tooLong);
      expect(ValidationUtils.validateEndStation('Colombo Fort', 'Kandy'), isNull);
      expect(ValidationUtils.validateEndStation('Colombo Fort', 'colombo fort '),
          AppStrings.stationsSame);
      expect(ValidationUtils.validateEndStation('Colombo Fort', ''), AppStrings.stationRequired);
    });
    test('optional text allows empty but caps length', () {
      expect(ValidationUtils.validateOptionalText(''), isNull);
      expect(ValidationUtils.validateOptionalText(null), isNull);
      expect(ValidationUtils.validateOptionalText('x' * 101), AppStrings.tooLong);
    });
  });
}
