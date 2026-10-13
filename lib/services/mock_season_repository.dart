// lib/services/mock_season_repository.dart

import 'package:e_season/models/season_application.dart';
import 'package:e_season/services/season_repository.dart';

/// Offline stand-in: always succeeds after [delay].
class MockSeasonRepository implements SeasonRepository {
  final Duration delay;

  const MockSeasonRepository({this.delay = const Duration(seconds: 1)});

  @override
  Future<SeasonApplicationResult> apply(SeasonApplication application) async {
    await Future.delayed(delay);
    final ref = DateTime.now().millisecondsSinceEpoch.toString();
    return SeasonApplicationResult.success('APP-${ref.substring(ref.length - 6)}');
  }
}
