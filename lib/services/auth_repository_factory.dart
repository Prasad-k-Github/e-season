// lib/services/auth_repository_factory.dart

import 'package:e_season/services/api_auth_repository.dart';
import 'package:e_season/services/api_support.dart';
import 'package:e_season/services/auth_repository.dart';
import 'package:e_season/services/mock_auth_repository.dart';

/// Real backend, or the offline mock when `.env` has `USE_MOCK_API=true`.
AuthRepository createAuthRepository() =>
    useMockApi() ? const MockAuthRepository() : ApiAuthRepository.fromEnv();
