// lib/services/api_support.dart
//
// Small helpers shared by the clients that talk to the e_season backend.

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:e_season/utils/app_strings.dart';

/// Android emulator alias for the host machine's localhost.
const defaultApiBaseUrl = 'http://10.0.2.2:3000';

/// `API_BASE_URL` from `.env`, falling back to [defaultApiBaseUrl].
String apiBaseUrlFromEnv() {
  String? url;
  try {
    url = dotenv.maybeGet('API_BASE_URL');
  } catch (_) {
    // dotenv not loaded (e.g. in tests)
  }
  return (url == null || url.isEmpty) ? defaultApiBaseUrl : url;
}

/// True when `.env` says `USE_MOCK_API=true` (work offline with fake data).
bool useMockApi() {
  String? flag;
  try {
    flag = dotenv.maybeGet('USE_MOCK_API');
  } catch (_) {
    // dotenv not loaded (e.g. in tests)
  }
  return flag?.trim().toLowerCase() == 'true';
}

Object? decodeJson(String body) {
  try {
    return body.isEmpty ? null : jsonDecode(body);
  } on FormatException {
    return null;
  }
}

/// Reads `{ error: { code, message, details? } }`. The server's messages are
/// written for users, so they are shown as they are. Validation errors list
/// each problem (`details` is a list of `{ field, message }`).
({String? code, String message}) readApiError(Object? json) {
  final error = json is Map<String, dynamic> ? json['error'] : null;
  if (error is! Map<String, dynamic>) {
    return (code: null, message: AppStrings.submitFailed);
  }
  final code = error['code'] is String ? error['code'] as String : null;
  final message =
      error['message'] is String && (error['message'] as String).isNotEmpty
          ? error['message'] as String
          : AppStrings.submitFailed;

  final details = error['details'];
  if (code == 'validation_error' && details is List && details.isNotEmpty) {
    final problems = [
      for (final d in details.take(3))
        if (d is Map<String, dynamic> && d['message'] is String)
          d['message'] as String,
    ];
    if (problems.isNotEmpty) return (code: code, message: problems.join('\n'));
  }
  return (code: code, message: message);
}
