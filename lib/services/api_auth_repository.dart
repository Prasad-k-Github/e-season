// lib/services/api_auth_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:e_season/services/api_support.dart';
import 'package:e_season/services/auth_repository.dart';
import 'package:e_season/utils/app_strings.dart';

/// `POST /api/auth/login  { phone, password }  ->  { token, verificationStatus }`
///
/// A wrong phone number or password gives the same 401 message either way, so
/// the screen can show it as it is. Nothing is logged: the request carries the
/// password.
class ApiAuthRepository implements AuthRepository {
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  ApiAuthRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  factory ApiAuthRepository.fromEnv() =>
      ApiAuthRepository(baseUrl: apiBaseUrlFromEnv());

  @override
  Future<LoginResult> login(String phone, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(_timeout);

      final json = decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
        final token = map['token'];
        if (token is! String || token.isEmpty) {
          return const LoginResult.failure(AppStrings.loginFailed);
        }
        final status = map['verificationStatus'];
        return LoginResult.success(token,
            verificationStatus: status is String ? status : null);
      }
      return LoginResult.failure(readApiError(json).message);
    } on SocketException {
      return const LoginResult.failure(AppStrings.serverUnreachable);
    } on TimeoutException {
      return const LoginResult.failure(AppStrings.serverUnreachable);
    } on http.ClientException {
      return const LoginResult.failure(AppStrings.serverUnreachable);
    }
  }
}
