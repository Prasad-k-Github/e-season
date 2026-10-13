import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kNavy   = Color(0xFF0A2558);
const _kGold   = Color(0xFFE8A020);
const _kBg     = Color(0xFFF2F5FB);
const _kCard   = Colors.white;
const _kMuted  = Color(0xFF8A94A6);
const _kGreen  = Color(0xFF1DA462);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════════════════
            //  HEADER  — Railway Navy
            // ══════════════════════════════════════════════════
            Container(
              decoration: const BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(children: [
                  // Top row
                  Row(children: [
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _kGold,
                      child: Text('U',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white54)),
                        Text('Kasun Perera',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    )),
                    // Bell
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 20),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                                color: _kGold, shape: BoxShape.circle),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // Search
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: TextField(
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search routes, stations…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white38),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white38, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ══════════════════════════════════════════════════
            //  BODY
            // ══════════════════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active season pass card
                    _PassCard(),
                    const SizedBox(height: 24),

                    // Quick actions
                    _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _QuickAction(icon: Icons.confirmation_num_outlined,
                          label: 'My Pass',    color: _kNavy),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.add_circle_outline_rounded,
                          label: 'New\nBooking', color: _kGreen),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.schedule_rounded,
                          label: 'Schedule',  color: _kGold),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.map_outlined,
                          label: 'Route\nMap', color: const Color(0xFF7B61FF)),
                    ]),
                    const SizedBox(height: 24),

                    // Journey planner promo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kGold.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _kGold.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _kGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.train_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Plan your journey',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kNavy)),
                            Text('Check times & fares',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: _kMuted)),
                          ],
                        )),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _kNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Recent trips
                    _SectionHeader(title: 'Recent Trips'),
                    const SizedBox(height: 12),
                    _TripTile(
                      from: 'Colombo Fort',
                      to: 'Kandy',
                      time: 'Today  ·  08:30 AM',
                      status: 'On time',
                      statusColor: _kGreen,
                    ),
                    const SizedBox(height: 10),
                    _TripTile(
                      from: 'Kandy',
                      to: 'Colombo Fort',
                      time: 'Yesterday  ·  05:45 PM',
                      status: 'Delayed',
                      statusColor: Colors.redAccent,
                    ),
                    const SizedBox(height: 10),
                    _TripTile(
                      from: 'Colombo Fort',
                      to: 'Galle',
                      time: 'Oct 9  ·  07:15 AM',
                      status: 'Completed',
                      statusColor: _kMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
          borderRadius: const BorderRadius.only(
            topLeft:  Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft:  Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Widget components
// ═══════════════════════════════════════════════════════════════

class _PassCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2558), Color(0xFF1A4A9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.train_rounded,
                color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text('Season Pass',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white60)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('ACTIVE',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF4CE490),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 14),
          Text('Colombo Fort → Kandy',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3)),
          const SizedBox(height: 6),

          // Dashed separator
          Row(children: List.generate(
            30,
            (i) => Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: Colors.white.withOpacity(i.isEven ? 0.25 : 0),
              ),
            ),
          )),
          const SizedBox(height: 10),

          Row(children: [
            _PassDetail(
                icon: Icons.calendar_today_outlined,
                label: 'Valid until',
                value: '31 Dec 2026'),
            const SizedBox(width: 20),
            _PassDetail(
                icon: Icons.confirmation_num_outlined,
                label: 'Pass ID',
                value: '#SLR-20481'),
          ]),
        ],
      ),
    );
  }
}

class _PassDetail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _PassDetail(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white54, size: 13),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: Colors.white54)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ]),
      ]);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
                color: _kGold,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kNavy)),
      ]);
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
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

class _TripTile extends StatelessWidget {
  final String from, to, time, status;
  final Color statusColor;
  const _TripTile({
    required this.from, required this.to, required this.time,
    required this.status, required this.statusColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _kNavy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.train_rounded,
                color: _kNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$from  →  $to',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy)),
              const SizedBox(height: 2),
              Text(time,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _kMuted)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
