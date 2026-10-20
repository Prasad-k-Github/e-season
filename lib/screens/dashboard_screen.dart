import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/passenger_profile.dart';
import 'package:e_season/services/profile_repository.dart';
import 'package:e_season/services/session_store.dart';
import 'package:e_season/utils/app_strings.dart';

const _kNavy   = Color(0xFF0A2558);
const _kGold   = Color(0xFFE8A020);
const _kBg     = Color(0xFFF2F5FB);
const _kCard   = Colors.white;
const _kMuted  = Color(0xFF8A94A6);
const _kGreen  = Color(0xFF1DA462);
const _kRed    = Color(0xFFD64545);

/// Home after login. Everything shown comes from the signed-in passenger's
/// profile; until the admin has verified the account every tab shows a message
/// explaining why instead of its content.
class DashboardScreen extends StatefulWidget {
  final ProfileRepository? repo;
  final SessionStore? session;
  const DashboardScreen({super.key, this.repo, this.session});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ProfileRepository _repo = widget.repo ?? createProfileRepository();
  late final SessionStore _session = widget.session ?? SecureSessionStore();

  int _idx = 0;
  bool _loading = true;
  String? _error;
  PassengerProfile? _profile;

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
    String? token;
    try {
      token = await _session.readToken();
    } catch (_) {
      token = null;
    }
    if (token == null) {
      _goToLogin();
      return;
    }
    final result = await _repo.fetch(token);
    if (!mounted) return;
    if (result.sessionExpired) {
      await _logout(message: result.errorMessage);
      return;
    }
    setState(() {
      _loading = false;
      _profile = result.profile;
      _error = result.profile == null ? result.errorMessage : null;
    });
  }

  void _goToLogin() {
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _logout({String? message}) async {
    try {
      await _session.clear();
    } catch (_) {}
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _Header(profile: profile),
          Expanded(child: _body(profile)),
        ]),
      ),
      bottomNavigationBar: profile == null ? null : _bottomNav(),
    );
  }

  Widget _body(PassengerProfile? profile) {
    if (_loading) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: _kNavy),
        const SizedBox(height: 14),
        Text(AppStrings.dashLoading,
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
      ]));
    }
    if (profile == null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        color: _kRed,
        title: _error ?? AppStrings.serverUnreachable,
        message: '',
        actionLabel: AppStrings.dashRetry,
        onAction: _load,
      );
    }
    // The profile tab is always reachable so the passenger can log out.
    if (_idx == 3) return _ProfileTab(profile: profile, onLogout: _logout);
    if (!profile.isVerified) return _lockedMessage(profile);
    if (_idx == 0) return _HomeTab(profile: profile);
    return const _Message(
      icon: Icons.hourglass_empty_rounded,
      color: _kMuted,
      title: AppStrings.dashComingSoon,
      message: '',
    );
  }

  Widget _lockedMessage(PassengerProfile p) {
    final institution = p.verificationStatus == 'pending_institution_approval';
    final rejected = p.isRejected;
    final reason = rejected && p.rejectionReason != null
        ? '\n\n${AppStrings.dashReason}: ${p.rejectionReason}'
        : '';
    return _Message(
      icon: rejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
      color: rejected ? _kRed : _kGold,
      title: rejected
          ? AppStrings.dashRejectedTitle
          : institution
              ? AppStrings.dashInstitutionTitle
              : AppStrings.dashPendingTitle,
      message: (rejected
              ? AppStrings.dashRejectedMessage
              : institution
                  ? AppStrings.dashInstitutionMessage
                  : AppStrings.dashPendingMessage) +
          reason,
      footer: p.referenceNumber == null ? null : 'Ref: ${p.referenceNumber}',
      actionLabel: AppStrings.dashRetry,
      onAction: _load,
    );
  }

  Widget _bottomNav() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
            backgroundColor: Colors.white,
            selectedItemColor: _kNavy,
            unselectedItemColor: _kMuted,
            selectedLabelStyle:
                GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_num_outlined),
                  activeIcon: Icon(Icons.confirmation_num_rounded),
                  label: 'My Pass'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_outlined),
                  activeIcon: Icon(Icons.schedule_rounded),
                  label: 'Schedule'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  Pieces
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final PassengerProfile? profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _kGold,
          child: Text(p?.initial ?? '',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
            Text(p == null || p.fullName.isEmpty ? '…' : p.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        if (p != null) _StatusChip(profile: p),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PassengerProfile profile;
  const _StatusChip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final color = profile.isVerified
        ? const Color(0xFF4CE490)
        : profile.isRejected
            ? const Color(0xFFFF8A8A)
            : _kGold;
    final label = profile.isVerified
        ? 'VERIFIED'
        : profile.isRejected
            ? 'REJECTED'
            : 'PENDING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final PassengerProfile profile;
  const _HomeTab({required this.profile});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2558), Color(0xFF1A4A9C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.verified_user_outlined,
                    color: Color(0xFF4CE490), size: 20),
                const SizedBox(width: 8),
                Text('Account verified',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Text('Hello ${profile.firstName}, you can now apply for a season ticket.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              if (profile.referenceNumber != null) ...[
                const SizedBox(height: 10),
                Text('Ref: ${profile.referenceNumber}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: _kGold, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Quick Actions',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _kNavy)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _QuickAction(
                icon: Icons.add_circle_outline_rounded,
                label: AppStrings.applySeasonAction,
                color: _kGreen,
                onTap: () => Navigator.pushNamed(context, '/apply-season')),
          ]),
        ]),
      );
}

class _ProfileTab extends StatelessWidget {
  final PassengerProfile profile;
  final Future<void> Function({String? message}) onLogout;
  const _ProfileTab({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String label, String? value) => value == null
        ? const SizedBox.shrink()
        : ListTile(
            leading: Icon(icon, color: _kNavy),
            title: Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
            subtitle: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kNavy)),
          );
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        decoration: BoxDecoration(
            color: _kCard, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          row(Icons.person_outline, 'Name', profile.fullName),
          row(Icons.phone_outlined, 'Mobile', profile.phone),
          row(Icons.mail_outline, 'Email', profile.email),
          row(Icons.tag, 'Reference', profile.referenceNumber),
          row(
              Icons.verified_outlined,
              'Status',
              profile.isVerified
                  ? 'Verified'
                  : profile.isRejected
                      ? 'Rejected'
                      : 'Waiting for verification'),
        ]),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => onLogout(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(AppStrings.dashLogout),
      ),
    ]);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, message;
  final String? footer, actionLabel;
  final VoidCallback? onAction;
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.footer,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w800, color: _kNavy)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: _kMuted, height: 1.5)),
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              Text(footer!,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kNavy)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                      height: 1.3)),
            ]),
          ),
        ),
      );
}
