// lib/services/api_registration_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/registration_options.dart';

/// Talks to the Eseason Node.js backend.
///
///   Register:           POST /api/v1/auth/register/passenger
///                       (creates the account and emails a 6-digit code)
///   Verify email:       POST /api/v1/auth/verify-email         { email, code }
///   Resend code:        POST /api/v1/auth/resend-verification  { email }
///
/// Journey details (class, stations) are no longer sent at registration; they
/// belong to the season application. Government employment details are not
/// sent yet because POST /api/v1/government-passengers requires a login token
/// plus class and season type, which only exist at season application.
///
/// Nothing is logged: request bodies contain NIC numbers and passwords.
class ApiRegistrationRepository implements RegistrationRepository {
  /// Android emulator alias for the host machine's localhost.
  static const defaultBaseUrl = 'http://10.0.2.2:3000';
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  ApiRegistrationRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Reads `API_BASE_URL` from `.env`, falling back to [defaultBaseUrl].
  factory ApiRegistrationRepository.fromEnv() {
    String? url;
    try {
      url = dotenv.maybeGet('API_BASE_URL');
    } catch (_) {
      // dotenv not loaded (e.g. in tests)
    }
    return ApiRegistrationRepository(
        baseUrl: (url == null || url.isEmpty) ? defaultBaseUrl : url);
  }

  @override
  Future<List<String>> fetchInstitutions() async =>
      RegistrationOptions.institutions;

  @override
  Future<OtpResult> verifyEmail(String email, String code) =>
      _otpCall('/api/v1/auth/verify-email', {'email': email, 'code': code});

  @override
  Future<OtpResult> resendVerificationCode(String email) =>
      _otpCall('/api/v1/auth/resend-verification', {'email': email});

  Future<OtpResult> _otpCall(String path, Map<String, dynamic> body) async {
    try {
      await _post(path, body);
      return const OtpResult.success();
    } on _ApiException catch (e) {
      return OtpResult.failure(e.message);
    } on SocketException {
      return const OtpResult.failure(AppStrings.serverUnreachable);
    } on TimeoutException {
      return const OtpResult.failure(AppStrings.serverUnreachable);
    } on http.ClientException {
      return const OtpResult.failure(AppStrings.serverUnreachable);
    }
  }

  @override
  Future<RegistrationResult> register(RegistrationData data) async {
    try {
      final registered = await _post('/api/v1/auth/register/passenger', {
        'nameInitial':  data.fullName,
        'email':        data.email,
        'password':     data.password,
        'address':      data.address,
        'phoneNo':      data.phone,
        'nicNo':        data.nic,
        'nicIssueDate': _formatDate(data.nicIssueDate),
      });
      return RegistrationResult.success(registered['id'] as String?);
    } on _ApiException catch (e) {
      return RegistrationResult.failure(e.message);
    } on SocketException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    } on TimeoutException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    } on http.ClientException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    }
  }

  /// POSTs [body] as JSON and returns the response's `data` object.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {String? token}) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final Object? json = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json is Map<String, dynamic> ? json['data'] : null;
      return data is Map<String, dynamic> ? data : const {};
    }
    throw _ApiException(_errorMessage(response.statusCode, json));
  }

  static Object? _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  /// Turns `{ error: { code, message, details } }` into a readable message.
  static String _errorMessage(int status, Object? json) {
    final error = json is Map<String, dynamic> ? json['error'] : null;
    if (error is! Map<String, dynamic>) return AppStrings.submitFailed;

    switch (error['code']) {
      case 'DUPLICATE_PASSENGER':
        return AppStrings.duplicatePassenger;
      case 'RATE_LIMITED':
        return AppStrings.rateLimited;
      case 'INVALID_VERIFICATION_CODE':
        return AppStrings.otpIncorrect;
      case 'VALIDATION_ERROR':
        final details = error['details'];
        if (details is Map<String, dynamic> && details.isNotEmpty) {
          return '${AppStrings.serverRejectedFields} ${details.keys.join(', ')}';
        }
    }
    final message = error['message'];
    return message is String && message.isNotEmpty
        ? message
        : AppStrings.submitFailed;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _ApiException implements Exception {
  final String message;
  const _ApiException(this.message);
}
