import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:e_season/screens/apply_ticket_screen.dart';
import 'package:e_season/services/ticket_api.dart';

const _navy = Color(0xFF0A2558);
const _gold = Color(0xFFE8A020);
const _muted = Color(0xFF8A94A6);
const _green = Color(0xFF1DA462);
const _red = Color(0xFFD64545);

/// "My Pass" tab: the active season ticket as a QR code (works offline once
/// loaded, the station app checks it against the public key), plus the
/// passenger's applications and past tickets.
class MyPassTab extends StatefulWidget {
  final TicketApi? api;
  final VoidCallback? onUnauthorized;
  const MyPassTab({super.key, this.api, this.onUnauthorized});

  @override
  State<MyPassTab> createState() => _MyPassTabState();
}

class _MyPassTabState extends State<MyPassTab> {
  late final TicketApi _api = widget.api ?? TicketApi.fromEnv();

  bool _loading = true;
  String? _error;
  List<SeasonTicket> _tickets = const [];
  List<SeasonApplicationInfo> _apps = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tickets = await _api.tickets();
      final apps = await _api.applications();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _apps = apps;
        _loading = false;
      });
    } on TicketApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) widget.onUnauthorized?.call();
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pay(SeasonApplicationInfo a) async {
    setState(() => _busyId = a.id);
    try {
      final r = await _api.pay(a.id);
      if (!mounted) return;
      _snack(r.paid ? 'Payment successful. Your ticket is ready.' : (r.message ?? 'Payment declined.'));
      await _load();
    } on TicketApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancel(SeasonApplicationInfo a) async {
    setState(() => _busyId = a.id);
    try {
      await _api.cancel(a.id);
      if (!mounted) return;
      await _load();
    } on TicketApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openApply() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ApplyTicketScreen(api: _api)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: _red, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    SeasonTicket? active;
    for (final t in _tickets) {
      if (t.isActive) {
        active = t;
        break;
      }
    }
    final past = _tickets.where((t) => t != active).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active != null) _ticketCard(active) else _noTicket(),
          const SizedBox(height: 16),
          if (_apps.isNotEmpty) ...[
            _heading('Applications'),
            for (final a in _apps) _appTile(a),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: 8),
            _heading('Past tickets'),
            for (final t in past) _pastTile(t),
          ],
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
      );

  Widget _noTicket() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.confirmation_num_outlined, size: 44, color: _muted),
          const SizedBox(height: 8),
          Text('No active season ticket',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _navy)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _openApply,
            style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: _navy),
            child: const Text('Apply for a season ticket'),
          ),
        ]),
      );

  Widget _ticketCard(SeasonTicket t) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold, width: 2)),
        child: Column(children: [
          Text('SEASON TICKET',
              style: GoogleFonts.inter(
                  fontSize: 12, letterSpacing: 1.5, color: _muted)),
          const SizedBox(height: 6),
          Text('${t.fromStation} → ${t.toStation}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
          Text('${t.ticketClass[0].toUpperCase()}${t.ticketClass.substring(1)} class',
              style: GoogleFonts.inter(color: _muted)),
          const SizedBox(height: 14),
          QrImageView(
            data: t.qrToken,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
            size: 260,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Text('Valid ${t.validFrom} to ${t.validTo}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Show this code to the inspector. Works without internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: _muted)),
        ]),
      );

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':
        return _green;
      case 'rejected':
      case 'cancelled':
        return _red;
      case 'approved_awaiting_payment':
        return _gold;
      default:
        return _muted;
    }
  }

  Widget _appTile(SeasonApplicationInfo a) {
    final busy = _busyId == a.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('${a.fromStation} → ${a.toStation}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
          Text('LKR ${a.fareLkr}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _navy)),
        ]),
        const SizedBox(height: 2),
        Text('${a.period} · ${a.startDate} to ${a.endDate}',
            style: GoogleFonts.inter(fontSize: 12, color: _muted)),
        const SizedBox(height: 6),
        Text(a.statusLabel,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: _statusColor(a.status))),
        if (a.status == 'rejected' && a.rejectionReason != null)
          Text('Reason: ${a.rejectionReason}',
              style: GoogleFonts.inter(fontSize: 12, color: _red)),
        if (a.awaitingPayment || a.cancellable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              if (a.awaitingPayment)
                ElevatedButton(
                  onPressed: busy ? null : () => _pay(a),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _green, foregroundColor: Colors.white),
                  child: Text(busy ? 'Please wait…' : 'Pay now'),
                ),
              if (a.cancellable)
                TextButton(
                    onPressed: busy ? null : () => _cancel(a),
                    child: const Text('Cancel')),
            ]),
          ),
      ]),
    );
  }

  Widget _pastTile(SeasonTicket t) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history_rounded, color: _muted),
        title: Text('${t.fromStation} → ${t.toStation}'),
        subtitle: Text('${t.validFrom} to ${t.validTo} · ${t.status}'),
      );
}
