// lib/services/season_repository.dart

import 'package:e_season/models/season_application.dart';

/// Contract the "Apply for Season" screen depends on.
abstract class SeasonRepository {
  Future<SeasonApplicationResult> apply(SeasonApplication application);
}
