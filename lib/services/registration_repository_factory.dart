// lib/services/registration_repository_factory.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:e_season/services/api_registration_repository.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/services/registration_repository.dart';

/// Picks the repository from `.env`: `USE_MOCK_API=true` gives the offline
/// mock (email code `123456`), anything else talks to the real backend.
RegistrationRepository createRegistrationRepository() {
  String? flag;
  try {
    flag = dotenv.maybeGet('USE_MOCK_API');
  } catch (_) {
    // dotenv not loaded (e.g. in tests)
  }
  return flag?.trim().toLowerCase() == 'true'
      ? const MockRegistrationRepository()
      : ApiRegistrationRepository.fromEnv();
}
