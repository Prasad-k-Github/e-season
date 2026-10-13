// lib/models/season_application.dart

/// A season ticket application: which class, season type and route.
class SeasonApplication {
  final String travelClass;
  final String seasonType;
  final String startStation;
  final String endStation;

  const SeasonApplication({
    required this.travelClass,
    required this.seasonType,
    required this.startStation,
    required this.endStation,
  });
}

class SeasonApplicationResult {
  final bool success;
  final String? referenceNumber;
  final String? errorMessage;

  const SeasonApplicationResult.success(this.referenceNumber)
      : success = true,
        errorMessage = null;

  const SeasonApplicationResult.failure(this.errorMessage)
      : success = false,
        referenceNumber = null;
}
