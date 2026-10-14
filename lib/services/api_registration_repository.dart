// lib/services/api_registration_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import 'package:e_season/models/registration_data.dart';
import 'package:e_season/services/api_support.dart';
import 'package:e_season/services/registration_repository.dart';
import 'package:e_season/utils/app_strings.dart';

/// Talks to the e_season Node.js backend. All paths are under `/api`.
///
///   Institutions:  GET  /api/institutions                      -> [{id, name}]
///   Send code:     POST /api/auth/otp/request  { phone }       -> { devCode? }
///   Verify code:   POST /api/auth/otp/verify   { phone, code } -> { registrationToken }
///   Register:      POST /api/register  (multipart, Bearer registrationToken)
///                  fields + files photo, nicFront, nicBack     -> { referenceNumber, ... }
///
/// The server takes the phone number from the verified code, so the register
/// request does not send one.
///
/// Nothing is logged: requests contain NIC numbers, passwords and ID images.
class ApiRegistrationRepository implements RegistrationRepository {
  static const _timeout = Duration(seconds: 15);

  /// Uploading three photos over a slow mobile connection takes a while.
  static const _uploadTimeout = Duration(seconds: 90);

  final String baseUrl;
  final http.Client _client;

  ApiRegistrationRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Reads `API_BASE_URL` from `.env`, falling back to the emulator address.
  factory ApiRegistrationRepository.fromEnv() =>
      ApiRegistrationRepository(baseUrl: apiBaseUrlFromEnv());

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  // ── Institutions ──────────────────────────────────────────────────

  @override
  Future<List<String>> fetchInstitutions() async {
    final response = await _client
        .get(_uri('/institutions'), headers: {'Accept': 'application/json'})
        .timeout(_timeout);
    final json = decodeJson(response.body);
    if (response.statusCode != 200 || json is! List) {
      throw _ApiException(readApiError(json).message);
    }
    return [
      for (final item in json)
        if (item is Map<String, dynamic> && item['name'] is String)
          item['name'] as String,
    ];
  }

  // ── Phone verification ────────────────────────────────────────────

  @override
  Future<OtpResult> sendPhoneCode(String phone) async {
    try {
      final json = await _postJson('/auth/otp/request', {'phone': phone});
      final devCode = json['devCode'];
      return OtpResult.success(devCode: devCode is String ? devCode : null);
    } on _ApiException catch (e) {
      // A code was sent a moment ago and is still valid; waiting is enough.
      if (e.code == 'otp_cooldown') return const OtpResult.success();
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
  Future<OtpResult> verifyPhoneCode(String phone, String code) async {
    try {
      final json =
          await _postJson('/auth/otp/verify', {'phone': phone, 'code': code});
      final token = json['registrationToken'];
      if (json['registered'] == true || token is! String) {
        // The number already has an account, so there is nothing to register.
        return const OtpResult.failure(AppStrings.phoneAlreadyRegistered);
      }
      return OtpResult.success(token: token);
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

  // ── Registration ──────────────────────────────────────────────────

  @override
  Future<RegistrationResult> register(RegistrationData data) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/register'))
        ..headers['Authorization'] = 'Bearer ${data.registrationToken ?? ''}'
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(_fields(data));
      request.files
        ..add(await _image('photo', data.profilePhotoPath))
        ..add(await _image('nicFront', data.nicFrontPath))
        ..add(await _image('nicBack', data.nicBackPath));

      final streamed = await _client.send(request).timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      final json = decodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
        final reference = map['referenceNumber'];
        final status = map['verificationStatus'];
        return RegistrationResult.success(
          reference is String ? reference : null,
          verificationStatus: status is String ? status : null,
        );
      }
      final error = readApiError(json);
      // 401 means the registration token expired (they last 30 minutes).
      final expired = response.statusCode == 401;
      return RegistrationResult.failure(
        expired ? AppStrings.verificationExpired : error.message,
        requiresVerification: expired,
      );
    } on FileSystemException {
      return const RegistrationResult.failure(AppStrings.imageReadFailed);
    } on SocketException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    } on TimeoutException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    } on http.ClientException {
      return const RegistrationResult.failure(AppStrings.serverUnreachable);
    }
  }

  /// Text fields of the register request. Empty optional values are left out.
  static Map<String, String> _fields(RegistrationData data) {
    final government = data.passengerType == PassengerType.government;
    final fields = <String, String>{
      'passengerType':     government ? 'government' : 'private',
      'password':          data.password,
      'fullName':          data.fullName,
      'nic':               data.nic,
      'address':           data.address,
      'preferredLanguage': data.preferredLanguage,
      'consent':           'true',
    };
    void optional(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) fields[key] = value.trim();
    }

    optional('email', data.email);
    if (data.dateOfBirth != null) fields['dateOfBirth'] = _formatDate(data.dateOfBirth!);
    if (government) {
      optional('institution', data.institution);
      optional('orgAuthCode', data.orgAuthCode);
      optional('employeeNo', data.employeeNo);
      optional('designation', data.designation);
    } else {
      optional('employerName', data.employerName);
    }
    return fields;
  }

  /// The server only takes JPEG or PNG and checks the declared type.
  static Future<http.MultipartFile> _image(String field, String path) {
    final isPng = path.toLowerCase().endsWith('.png');
    return http.MultipartFile.fromPath(
      field,
      path,
      contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────

  /// POSTs [body] as JSON and returns the response object.
  Future<Map<String, dynamic>> _postJson(
      String path, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final json = decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json is Map<String, dynamic> ? json : const {};
    }
    final error = readApiError(json);
    throw _ApiException(error.message, code: error.code);
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _ApiException implements Exception {
  final String message;
  final String? code;
  const _ApiException(this.message, {this.code});
}
