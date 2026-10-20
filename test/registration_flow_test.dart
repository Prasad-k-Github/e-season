import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/screens/registration_flow.dart';
import 'package:e_season/services/draft_store.dart';
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
        RegStep.verify,
        RegStep.photo,
        RegStep.nicImages,
        RegStep.password,
      ]);
      expect(flow.total, 5);
    });

    test('government employees get the employment page before the password', () {
      final flow = _flow(PassengerType.government);
      expect(flow.steps, [
        RegStep.details,
        RegStep.verify,
        RegStep.photo,
        RegStep.nicImages,
        RegStep.employment,
        RegStep.password,
      ]);
      expect(flow.numberOf(RegStep.password), 6);
    });

    test('step count follows the selected passenger type', () {
      final flow = _flow(PassengerType.general);
      expect(flow.total, 5);
      flow.draft.setType(PassengerType.government);
      expect(flow.total, 6);
    });
  });

  group('RegistrationDraft', () {
    test('switching to general clears government-only fields', () {
      final draft = RegistrationDraft(type: PassengerType.government)
        ..institution = 'Sri Lanka Railways'
        ..orgAuthCode = 'ABC123'
        ..employeeNo = 'EMP-1001'
        ..designation = 'Teacher';

      draft.setType(PassengerType.general);

      expect(draft.institution, isNull);
      expect(draft.orgAuthCode, isEmpty);
      expect(draft.employeeNo, isEmpty);
      expect(draft.designation, isEmpty);
    });

    test('switching to government clears the private-sector employer', () {
      final draft = RegistrationDraft(type: PassengerType.general)
        ..employerName = 'ABC Pvt Ltd';
      draft.setType(PassengerType.government);
      expect(draft.employerName, isEmpty);
    });

    test('toData trims, upper-cases the NIC and drops government fields for general', () {
      final draft = RegistrationDraft(type: PassengerType.general)
        ..fullName = '  Kasun Perera '
        ..address = '12 Main St'
        ..nic = '972430039v'
        ..email = ' kasun@gmail.com '
        ..phone = '0771234567'
        ..password = 'ChangeMe-12345'
        ..employerName = ' ABC Pvt Ltd '
        ..profilePhotoPath = '/tmp/p.jpg'
        ..nicFrontPath = '/tmp/f.jpg'
        ..nicBackPath = '/tmp/b.jpg'
        ..designation = 'ignored';

      final data = draft.toData();

      expect(data.fullName, 'Kasun Perera');
      expect(data.nic, '972430039V');
      expect(data.email, 'kasun@gmail.com');
      expect(data.employerName, 'ABC Pvt Ltd');
      expect(data.institution, isNull);
      expect(data.designation, isNull);
    });

    test('toData sends government fields only for government employees', () {
      final draft = RegistrationDraft(type: PassengerType.government)
        ..fullName = 'Kamala Silva'
        ..address = '45 Temple Road'
        ..nic = '199112345678'
        ..phone = '0712345678'
        ..password = 'Passw0rd#123'
        ..profilePhotoPath = '/tmp/p.jpg'
        ..nicFrontPath = '/tmp/f.jpg'
        ..nicBackPath = '/tmp/b.jpg'
        ..institution = 'Ministry of Education'
        ..orgAuthCode = ' DEMO-EDU-2026 '
        ..employeeNo = ''
        ..designation = 'Teacher';

      final data = draft.toData();

      expect(data.institution, 'Ministry of Education');
      expect(data.orgAuthCode, 'DEMO-EDU-2026');
      expect(data.employeeNo, isNull, reason: 'blank optional values become null');
      expect(data.designation, 'Teacher');
      expect(data.employerName, isNull);
      expect(data.email, isNull);
    });

    test('toString is redacted', () {
      final draft = RegistrationDraft()..nic = '972430039V'..password = 'secret';
      expect(draft.toString(), isNot(contains('972430039V')));
      expect(draft.toString(), isNot(contains('secret')));
    });
  });

  group('local storage', () {
    RegistrationDraft filled() => RegistrationDraft(type: PassengerType.government)
      ..fullName = 'Kasun Perera'
      ..address = '12 Main St'
      ..nic = '972430039V'
      ..dateOfBirth = DateTime(1990, 5, 10)
      ..email = 'kasun@gmail.com'
      ..phone = '0771234567'
      ..preferredLanguage = 'si'
      ..profilePhotoPath = '/tmp/p.jpg'
      ..nicFrontPath = '/tmp/f.jpg'
      ..nicBackPath = '/tmp/b.jpg'
      ..institution = 'Sri Lanka Railways'
      ..orgAuthCode = 'ABC123'
      ..employeeNo = 'EMP-1001'
      ..designation = 'Teacher';

    test('a draft survives a JSON round trip', () {
      final copy = RegistrationDraft.fromJson(
          jsonDecode(jsonEncode(filled().toJson())) as Map<String, dynamic>);

      expect(copy.type, PassengerType.government);
      expect(copy.fullName, 'Kasun Perera');
      expect(copy.nic, '972430039V');
      expect(copy.dateOfBirth, DateTime(1990, 5, 10));
      expect(copy.preferredLanguage, 'si');
      expect(copy.nicBackPath, '/tmp/b.jpg');
      expect(copy.institution, 'Sri Lanka Railways');
      expect(copy.orgAuthCode, 'ABC123');
      expect(copy.employeeNo, 'EMP-1001');
      expect(copy.designation, 'Teacher');
    });

    test('damaged or partial JSON falls back to safe defaults', () {
      final copy = RegistrationDraft.fromJson(
          {'type': 'alien', 'dateOfBirth': 5, 'preferredLanguage': 'xx'});
      expect(copy.type, PassengerType.general);
      expect(copy.fullName, isEmpty);
      expect(copy.dateOfBirth, isNull);
      expect(copy.preferredLanguage, 'en');
      expect(copy.profilePhotoPath, isNull);
    });

    test('the password and phone proof are never written to storage', () {
      final draft = filled()
        ..password = 'ChangeMe-12345'
        ..registrationToken = 'secret-proof'
        ..verifiedPhone = '+94771234567';
      final text = jsonEncode(draft.toJson());
      expect(text, isNot(contains('ChangeMe-12345')));
      expect(text, isNot(contains('secret-proof')));
    });

    test('the phone proof only counts for the number it was issued for', () {
      final draft = filled()
        ..registrationToken = 't'
        ..verifiedPhone = '+94771234567';
      expect(draft.isPhoneVerified, isTrue);
      draft.phone = '077 123 4567'; // same number, different formatting
      expect(draft.isPhoneVerified, isTrue);
      draft.phone = '+94771234567';
      expect(draft.isPhoneVerified, isTrue);
      draft.phone = '0712345678';
      expect(draft.isPhoneVerified, isFalse);
    });

    test('save stores the draft and the completed step, finish wipes it', () async {
      final store = MemoryDraftStore();
      final flow = RegistrationFlow(
        draft: filled()
          ..password = 'ChangeMe-12345'
          ..registrationToken = 't'
          ..verifiedPhone = '+94771234567',
        repo: const MockRegistrationRepository(delay: Duration.zero),
        store: store,
      );

      await flow.save(RegStep.nicImages);
      final saved = await store.load();
      expect(saved!.step, RegStep.nicImages);
      expect(saved.draft.fullName, 'Kasun Perera');

      await flow.finish();
      expect(await store.load(), isNull);
      expect(flow.draft.password, isEmpty);
      expect(flow.draft.registrationToken, isNull);
    });

    test('save moves picked images to the store and keeps their new paths', () async {
      final flow = RegistrationFlow(
        draft: filled(),
        repo: const MockRegistrationRepository(delay: Duration.zero),
        store: _KeepingStore(),
      );
      await flow.save(RegStep.photo);
      expect(flow.draft.profilePhotoPath, 'kept:/tmp/p.jpg');
      expect(flow.draft.nicFrontPath, 'kept:/tmp/f.jpg');
      expect(flow.draft.nicBackPath, 'kept:/tmp/b.jpg');
    });

    test('a failing store never throws out of save', () async {
      final flow = RegistrationFlow(
        draft: filled(),
        repo: const MockRegistrationRepository(delay: Duration.zero),
        store: _BrokenStore(),
      );
      await flow.save(RegStep.details); // completes without throwing
    });
  });
}

class _KeepingStore extends MemoryDraftStore {
  @override
  Future<String> keepImage(String sourcePath) async => 'kept:$sourcePath';
}

class _BrokenStore extends MemoryDraftStore {
  @override
  Future<void> save(RegistrationDraft draft, RegStep step) =>
      throw Exception('disk full');
}
