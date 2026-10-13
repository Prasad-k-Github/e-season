import 'package:flutter_test/flutter_test.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/services/mock_registration_repository.dart';

RegistrationFlow _flow(PassengerType type) => RegistrationFlow(
      draft: RegistrationDraft(type: type),
      repo: const MockRegistrationRepository(delay: Duration.zero),
    );

void main() {
  group('RegistrationFlow', () {
    test('general passengers skip the government employment page', () {
      final flow = _flow(PassengerType.general);
      expect(flow.steps, [
        RegStep.details,
        RegStep.photo,
        RegStep.nicImages,
        RegStep.password,
      ]);
      expect(flow.total, 4);
    });

    test('government employees get the employment page before the password', () {
      final flow = _flow(PassengerType.government);
      expect(flow.steps, [
        RegStep.details,
        RegStep.photo,
        RegStep.nicImages,
        RegStep.employment,
        RegStep.password,
      ]);
      expect(flow.numberOf(RegStep.password), 5);
    });

    test('step count follows the selected passenger type', () {
      final flow = _flow(PassengerType.general);
      expect(flow.total, 4);
      flow.draft.setType(PassengerType.government);
      expect(flow.total, 5);
    });
  });

  group('RegistrationDraft', () {
    test('switching to general clears government-only fields', () {
      final draft = RegistrationDraft(type: PassengerType.government)
        ..institution = 'Sri Lanka Railways'
        ..ministry = 'Transport'
        ..nearestStation = 'Colombo Fort'
        ..orgAuthCode = 'ABC123';

      draft.setType(PassengerType.general);

      expect(draft.institution, isNull);
      expect(draft.ministry, isEmpty);
      expect(draft.nearestStation, isEmpty);
      expect(draft.orgAuthCode, isEmpty);
    });

    test('toData trims, upper-cases the NIC and drops government fields for general', () {
      final draft = RegistrationDraft(type: PassengerType.general)
        ..fullName = '  Kasun Perera '
        ..address = '12 Main St'
        ..nic = '972430039v'
        ..nicIssueDate = DateTime(2015, 6, 1)
        ..email = ' kasun@gmail.com '
        ..phone = '0771234567'
        ..password = 'ChangeMe-12345'
        ..profilePhotoPath = '/tmp/p.jpg'
        ..nicFrontPath = '/tmp/f.jpg'
        ..nicBackPath = '/tmp/b.jpg'
        ..ministry = 'ignored';

      final data = draft.toData();

      expect(data.fullName, 'Kasun Perera');
      expect(data.nic, '972430039V');
      expect(data.email, 'kasun@gmail.com');
      expect(data.institution, isNull);
      expect(data.ministry, isNull);
    });

    test('toString is redacted', () {
      final draft = RegistrationDraft()..nic = '972430039V'..password = 'secret';
      expect(draft.toString(), isNot(contains('972430039V')));
      expect(draft.toString(), isNot(contains('secret')));
    });
  });
}
