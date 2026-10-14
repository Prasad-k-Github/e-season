// lib/services/registration_repository_factory.dart

import 'package:e_season/services/api_registration_repository.dart';
import 'package:e_season/services/api_support.dart';
import 'package:e_season/services/mock_registration_repository.dart';
import 'package:e_season/services/registration_repository.dart';

/// Picks the repository from `.env`: `USE_MOCK_API=true` gives the offline
/// mock (code `123456`), anything else talks to the real backend.
RegistrationRepository createRegistrationRepository() => useMockApi()
    ? const MockRegistrationRepository()
    : ApiRegistrationRepository.fromEnv();
