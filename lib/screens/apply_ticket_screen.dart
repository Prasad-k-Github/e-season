import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/services/ticket_api.dart';
import 'package:e_season/widgets/registration_widgets.dart';

// Same palette and widgets as the registration screens.
const _navy = RegColors.deepViolet;
const _muted = RegColors.muted;
const _green = RegColors.green;
const _red = Color(0xFFD64545);

const _classes = {'first': 'First class', 'second': 'Second class', 'third': 'Third class'};
const _periods = {'weekly': 'Weekly', 'monthly': 'Monthly', 'quarterly': 'Quarterly (3 months)'};

/// Apply for a season ticket with the real backend: route, class, period and
/// start date, then a fare quote, the application and the (sandbox) payment.
/// Government employees go through their institution first, so payment only
/// appears once the officer has approved.
class ApplyTicketScreen extends StatefulWidget {
  final TicketApi? api;
  const ApplyTicketScreen({super.key, this.api});

  @override
  State<ApplyTicketScreen> createState() => _ApplyTicketScreenState();
}

class _ApplyTicketScreenState extends State<ApplyTicketScreen> {
  late final TicketApi _api = widget.api ?? TicketApi.fromEnv();

  List<Station> _stations = const [];
  bool _loading = true;
  String? _loadError;

  String? _fromId, _toId, _class, _period;
  DateTime? _start;
  FareQuote? _quote;
  bool _busy = false;

  SeasonApplicationInfo? _created;
  String? _message; // result of the last action
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final s = await _api.stations();
      if (!mounted) return;
      setState(() {
        _stations = s;
        _loading = false;
      });
    } on TicketApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _formComplete =>
      _fromId != null &&
      _toId != null &&
      _fromId != _toId &&
      _class != null &&
      _period != null &&
      _start != null;

  void _invalidateQuote() {
    _quote = null;
    _message = null;
  }

  void _show(String text, {bool error = false}) {
    _message = text;
    _messageIsError = error;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked;
      _invalidateQuote();
    });
  }

  Future<void> _getQuote() async {
    setState(() => _busy = true);
    try {
      final q = await _api.quote(
          fromId: _fromId!, toId: _toId!, ticketClass: _class!, period: _period!);
      if (!mounted) return;
      setState(() {
        _quote = q;
        _message = null;
      });
    } on TicketApiException catch (e) {
      if (!mounted) return;
      setState(() => _show(e.message, error: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final app = await _api.apply(
          fromId: _fromId!,
          toId: _toId!,
          ticketClass: _class!,
          period: _period!,
          startDate: _iso(_start!));
      if (!mounted) return;
      setState(() {
        _created = app;
        _message = null;
      });
    } on TicketApiException catch (e) {
      if (!mounted) return;
      setState(() => _show(e.message, error: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay({bool fail = false}) async {
    final app = _created;
    if (app == null) return;
    setState(() => _busy = true);
    try {
      final r = await _api.pay(app.id, simulateFailure: fail);
      if (!mounted) return;
      if (r.paid) {
        Navigator.pop(context, true); // the caller refreshes "My Pass"
      } else {
        setState(() => _show(r.message ?? 'Payment declined. Try again.', error: true));
      }
    } on TicketApiException catch (e) {
      if (!mounted) return;
      setState(() => _show(e.message, error: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Apply for Season',
      subtitle: 'Choose your route, class and season type',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: _navy)))
          : _loadError != null
              ? _errorView()
              : (_created == null ? _form() : _afterApply(_created!)),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: _red, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            RegPrimaryButton(label: 'Retry', showArrow: false, onPressed: _loadStations),
          ]),
        ),
      );

  Widget _card(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RegCard(child: child),
      );

  Widget _banner() {
    if (_message == null) return const SizedBox.shrink();
    final color = _messageIsError ? _red : _green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(_message!, style: TextStyle(color: color)),
    );
  }

  Widget _dropdown(String label, IconData icon, String? value,
      Map<String, String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value, // ignore: deprecated_member_use
      isExpanded: true,
      decoration: regFieldDec(label, '', icon),
      style: GoogleFonts.inter(fontSize: 14, color: RegColors.deepViolet),
      borderRadius: BorderRadius.circular(12),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: _busy ? null : onChanged,
    );
  }

  Widget _form() {
    final stationItems = {for (final s in _stations) s.id: s.name};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _card(Column(children: [
        _dropdown('From station', Icons.trip_origin_rounded, _fromId, stationItems,
            (v) => setState(() {
                  _fromId = v;
                  _invalidateQuote();
                })),
        const SizedBox(height: 12),
        _dropdown('To station', Icons.place_outlined, _toId, stationItems,
            (v) => setState(() {
                  _toId = v;
                  _invalidateQuote();
                })),
        const SizedBox(height: 12),
        _dropdown('Class', Icons.airline_seat_recline_normal_outlined, _class, _classes,
            (v) => setState(() {
                  _class = v;
                  _invalidateQuote();
                })),
        const SizedBox(height: 12),
        _dropdown('Season type', Icons.date_range_outlined, _period, _periods,
            (v) => setState(() {
                  _period = v;
                  _invalidateQuote();
                })),
        const SizedBox(height: 12),
        InkWell(
          onTap: _busy ? null : _pickDate,
          child: InputDecorator(
            decoration: regFieldDec('Start date', '', Icons.calendar_today_outlined),
            child: Text(_start == null ? 'Choose a date' : _iso(_start!),
                style: GoogleFonts.inter(fontSize: 14, color: RegColors.deepViolet)),
          ),
        ),
      ])),
      if (_fromId != null && _fromId == _toId)
        _banner2('Choose two different stations.'),
      _banner(),
      if (_quote != null)
        _card(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Fare', style: GoogleFonts.inter(color: _muted)),
          Text('LKR ${_quote!.fareLkr}',
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
        ])),
      _quote == null
          ? RegPrimaryButton(
              label: 'Get fare',
              loading: _busy,
              onPressed: _formComplete ? _getQuote : null,
            )
          : RegPrimaryButton(
              label: 'Submit application',
              loading: _busy,
              onPressed: _submit,
            ),
    ]);
  }

  Widget _banner2(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(color: _red)),
      );

  Widget _afterApply(SeasonApplicationInfo app) {
    return Column(children: [
      _card(Column(children: [
        const Icon(Icons.check_circle_rounded, color: _green, size: 48),
        const SizedBox(height: 8),
        Text('Application submitted',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: _navy)),
        const SizedBox(height: 8),
        Text('${app.fromStation} → ${app.toStation}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        Text('${_classes[app.ticketClass] ?? app.ticketClass} · ${app.startDate} to ${app.endDate}',
            style: GoogleFonts.inter(color: _muted, fontSize: 13)),
        const SizedBox(height: 8),
        Text('LKR ${app.fareLkr}',
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
        const SizedBox(height: 8),
        Text(app.statusLabel, style: GoogleFonts.inter(color: _muted)),
      ])),
      _banner(),
      if (app.awaitingOfficer)
        _card(const Text(
            'Your institution must approve this application first. Check "My Pass" later to pay.')),
      if (app.awaitingPayment) ...[
        RegPrimaryButton(
          label: 'Pay now (sandbox)',
          loading: _busy,
          showArrow: false,
          onPressed: () => _pay(),
        ),
        TextButton(
          onPressed: _busy ? null : () => _pay(fail: true),
          child: const Text('Demo: simulate a declined payment'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Sandbox payment: no card details are collected.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12)),
        ),
      ],
      const SizedBox(height: 8),
      TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Back to dashboard')),
    ]);
  }
}
