// lib/services/ticket_api.dart
//
// Client for the season-ticket endpoints of the e_season backend:
//   GET  /api/stations                       -> [{ id, name, line }]
//   POST /api/fares/quote                    -> { fareLkr, durationMonths }
//   POST /api/applications                   -> application
//   GET  /api/applications                   -> [application]
//   POST /api/applications/:id/cancel        -> { status }
//   POST /api/applications/:id/pay           -> { paid, ticket? , message? }  (sandbox, no card data)
//   GET  /api/tickets                        -> [ticket with qrToken]
//
// Needs the passenger's Bearer token. Nothing is logged.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:e_season/services/api_support.dart';
import 'package:e_season/services/session_store.dart';
import 'package:e_season/utils/app_strings.dart';

class TicketApiException implements Exception {
  final String message;
  final String? code;
  final bool unauthorized;
  const TicketApiException(this.message, {this.code, this.unauthorized = false});
  @override
  String toString() => message;
}

class Station {
  final String id;
  final String name;
  const Station(this.id, this.name);
}

class FareQuote {
  final int fareLkr;
  const FareQuote(this.fareLkr);
}

class SeasonApplicationInfo {
  final String id;
  final String fromStation;
  final String toStation;
  final String ticketClass;
  final String period;
  final String startDate;
  final String endDate;
  final int fareLkr;
  final String status;
  final String? rejectionReason;

  const SeasonApplicationInfo({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.ticketClass,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.fareLkr,
    required this.status,
    this.rejectionReason,
  });

  factory SeasonApplicationInfo.fromJson(Map<String, dynamic> j) =>
      SeasonApplicationInfo(
        id: '${j['id']}',
        fromStation: '${j['fromStation'] ?? ''}',
        toStation: '${j['toStation'] ?? ''}',
        ticketClass: '${j['ticketClass'] ?? ''}',
        period: '${j['period'] ?? ''}',
        startDate: '${j['startDate'] ?? ''}',
        endDate: '${j['endDate'] ?? ''}',
        fareLkr: (j['fareLkr'] as num?)?.toInt() ?? 0,
        status: '${j['status'] ?? ''}',
        rejectionReason: j['rejectionReason'] as String?,
      );

  bool get awaitingPayment => status == 'approved_awaiting_payment';
  bool get awaitingOfficer => status == 'pending_institution_approval';
  bool get cancellable =>
      status == 'draft' || awaitingOfficer || awaitingPayment;

  String get statusLabel {
    switch (status) {
      case 'pending_institution_approval':
        return 'Waiting for your institution';
      case 'approved_awaiting_payment':
        return 'Approved, payment due';
      case 'paid':
        return 'Paid';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class SeasonTicket {
  final String id;
  final String fromStation;
  final String toStation;
  final String ticketClass;
  final String validFrom;
  final String validTo;
  final String status; // active | expired | revoked ...
  final String qrToken;

  const SeasonTicket({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.ticketClass,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.qrToken,
  });

  factory SeasonTicket.fromJson(Map<String, dynamic> j) => SeasonTicket(
        id: '${j['id']}',
        fromStation: '${j['fromStation'] ?? ''}',
        toStation: '${j['toStation'] ?? ''}',
        ticketClass: '${j['ticketClass'] ?? ''}',
        validFrom: '${j['validFrom'] ?? ''}',
        validTo: '${j['validTo'] ?? ''}',
        status: '${j['status'] ?? ''}',
        qrToken: '${j['qrToken'] ?? ''}',
      );

  bool get isActive => status == 'active';
}

class PayOutcome {
  final bool paid;
  final String? message;
  const PayOutcome(this.paid, this.message);
}

class TicketApi {
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final SessionStore _session;
  final http.Client _client;

  TicketApi({required this.baseUrl, SessionStore? session, http.Client? client})
      : _session = session ?? SecureSessionStore(),
        _client = client ?? http.Client();

  factory TicketApi.fromEnv({SessionStore? session}) =>
      TicketApi(baseUrl: apiBaseUrlFromEnv(), session: session);

  Future<Object?> _call(String method, String path, {Object? body}) async {
    final token = await _session.readToken();
    if (token == null) {
      throw const TicketApiException('Please sign in again.',
          unauthorized: true);
    }
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final uri = Uri.parse('$baseUrl/api$path');
    try {
      final http.Response r;
      if (method == 'POST') {
        r = await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(_timeout);
      } else {
        r = await _client.get(uri, headers: headers).timeout(_timeout);
      }
      final json = decodeJson(r.body);
      // 402 is the sandbox "payment declined" answer, which the caller handles.
      if (r.statusCode >= 200 && r.statusCode < 300 || r.statusCode == 402) {
        return json;
      }
      final err = readApiError(json);
      throw TicketApiException(err.message,
          code: err.code, unauthorized: r.statusCode == 401);
    } on SocketException {
      throw TicketApiException('${AppStrings.serverUnreachable} ($baseUrl)');
    } on TimeoutException {
      throw TicketApiException('${AppStrings.serverUnreachable} ($baseUrl)');
    } on http.ClientException {
      throw TicketApiException('${AppStrings.serverUnreachable} ($baseUrl)');
    }
  }

  List<Map<String, dynamic>> _list(Object? json) => json is List
      ? [for (final e in json) if (e is Map<String, dynamic>) e]
      : const [];

  Future<List<Station>> stations() async {
    final json = await _call('GET', '/stations');
    return [
      for (final s in _list(json)) Station('${s['id']}', '${s['name']}'),
    ];
  }

  Future<FareQuote> quote({
    required String fromId,
    required String toId,
    required String ticketClass,
    required String period,
  }) async {
    final json = await _call('POST', '/fares/quote', body: {
      'fromStationId': fromId,
      'toStationId': toId,
      'ticketClass': ticketClass,
      'period': period,
    });
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return FareQuote((map['fareLkr'] as num?)?.toInt() ?? 0);
  }

  Future<SeasonApplicationInfo> apply({
    required String fromId,
    required String toId,
    required String ticketClass,
    required String period,
    required String startDate,
  }) async {
    final json = await _call('POST', '/applications', body: {
      'fromStationId': fromId,
      'toStationId': toId,
      'ticketClass': ticketClass,
      'period': period,
      'startDate': startDate,
    });
    if (json is! Map<String, dynamic>) {
      throw const TicketApiException(AppStrings.applyFailed);
    }
    return SeasonApplicationInfo.fromJson(json);
  }

  Future<List<SeasonApplicationInfo>> applications() async {
    final json = await _call('GET', '/applications');
    return [for (final a in _list(json)) SeasonApplicationInfo.fromJson(a)];
  }

  Future<void> cancel(String applicationId) async {
    await _call('POST', '/applications/$applicationId/cancel');
  }

  /// Sandbox payment. Pass `simulateFailure: true` to demo a declined payment
  /// (the server ignores it in production).
  Future<PayOutcome> pay(String applicationId,
      {bool simulateFailure = false}) async {
    final json = await _call('POST', '/applications/$applicationId/pay',
        body: simulateFailure ? {'simulate': 'fail'} : <String, dynamic>{});
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return PayOutcome(map['paid'] == true, map['message'] as String?);
  }

  Future<List<SeasonTicket>> tickets() async {
    final json = await _call('GET', '/tickets');
    return [for (final t in _list(json)) SeasonTicket.fromJson(t)];
  }
}
