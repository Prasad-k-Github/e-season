// lib/services/profile_repository.dart

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:e_season/models/passenger_profile.dart';
import 'package:e_season/services/api_support.dart';
import 'package:e_season/utils/app_strings.dart';

class ProfileResult {
  final PassengerProfile? profile;
  final String? errorMessage;

  /// The token is no longer valid (401): the passenger must log in again.
  final bool sessionExpired;

  const ProfileResult.success(PassengerProfile this.profile)
      : errorMessage = null,
        sessionExpired = false;

  const ProfileResult.failure(this.errorMessage, {this.sessionExpired = false})
      : profile = null;
}

/// `GET /api/me` with the passenger's bearer token.
abstract class ProfileRepository {
  Future<ProfileResult> fetch(String token);
}

class ApiProfileRepository implements ProfileRepository {
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  ApiProfileRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  factory ApiProfileRepository.fromEnv() =>
      ApiProfileRepository(baseUrl: apiBaseUrlFromEnv());

  @override
  Future<ProfileResult> fetch(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/me'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      final json = decodeJson(response.body);
      if (response.statusCode == 200 && json is Map<String, dynamic>) {
        return ProfileResult.success(PassengerProfile.fromJson(json));
      }
      if (response.statusCode == 401) {
        return const ProfileResult.failure(AppStrings.sessionExpired,
            sessionExpired: true);
      }
      return ProfileResult.failure(readApiError(json).message);
    } on SocketException {
      return const ProfileResult.failure(AppStrings.serverUnreachable);
    } on TimeoutException {
      return const ProfileResult.failure(AppStrings.serverUnreachable);
    } on http.ClientException {
      return const ProfileResult.failure(AppStrings.serverUnreachable);
    }
  }
}

/// Offline stand-in (`USE_MOCK_API=true`).
class MockProfileRepository implements ProfileRepository {
  final String status;
  const MockProfileRepository({this.status = 'verified'});

  @override
  Future<ProfileResult> fetch(String token) async => ProfileResult.success(
      PassengerProfile(
          fullName: 'Kasun Perera',
          phone: '+94771234567',
          referenceNumber: 'ES-123456',
          verificationStatus: status));
}

ProfileRepository createProfileRepository() =>
    useMockApi() ? const MockProfileRepository() : ApiProfileRepository.fromEnv();
