import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/screens/login_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  E-Season – Premium Home / Onboarding Screen
//  Colour Palette:
//    Deep Violet  #1A0533  – rich royal purple for authority
//    Mid Violet   #2D1B69  – vibrant purple mid-tone
//    Gold         #E8A020  – warm signal-gold accent
//    Light Gold   #F5C563  – luminous gold highlight
//    Amethyst     #9B59B6  – soft purple accent
// ═══════════════════════════════════════════════════════════════════════════

const _kDeepViolet = Color(0xFF1A0533);
const _kGold = Color(0xFFE8A020);
const _kLightGold = Color(0xFFF5C563);
const _kAmethyst = Color(0xFF9B59B6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // ── Master animation orchestrator ────────────────────────────────────
  late AnimationController _masterCtrl;
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _pillsFade;
  late Animation<double> _ctaScale;

  // ── Floating particle controller ─────────────────────────────────────
  late AnimationController _particleCtrl;

  // ── CTA shimmer ──────────────────────────────────────────────────────
  late AnimationController _shimmerCtrl;

  // ── Glow pulse for logo ──────────────────────────────────────────────
  late AnimationController _glowCtrl;

  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();

    // ── Master stagger (1800ms total) ────────────────────────────────
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.15, 0.50, curve: Curves.elasticOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.40, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.50, 0.72, curve: Curves.easeOut),
      ),
    );
    _pillsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOut),
      ),
    );
    _ctaScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.68, 0.95, curve: Curves.elasticOut),
      ),
    );

    _masterCtrl.forward();

    // ── Particles ────────────────────────────────────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: _rng.nextDouble() * 3.0 + 0.6,
        speed: _rng.nextDouble() * 0.12 + 0.03,
        opacity: _rng.nextDouble() * 0.35 + 0.06,
        phase: _rng.nextDouble() * 2 * pi,
        isGold: _rng.nextDouble() > 0.6,
      ));
    }

    // ── CTA shimmer ──────────────────────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // ── Logo glow pulse ──────────────────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_masterCtrl, _particleCtrl, _glowCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              // ═══════════ BACKGROUND IMAGE ═══════════════════════════
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value,
                  child: Image.asset(
                    'assets/images/background01.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ── Dark gradient overlay for readability ─────────────────
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _kDeepViolet.withValues(alpha: 0.55),
                          _kDeepViolet.withValues(alpha: 0.75),
                          _kDeepViolet.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Decorative radial glow behind logo area (gold) ────────
              Positioned(
                top: mq.size.height * 0.10,
                left: mq.size.width * 0.5 - 180,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _kGold.withValues(
                            alpha: 0.10 + 0.06 * _glowCtrl.value),
                        _kGold.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Decorative radial glow bottom-left (amethyst) ─────────
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _kAmethyst.withValues(
                            alpha: 0.10 + 0.04 * _glowCtrl.value),
                        _kAmethyst.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Decorative radial glow bottom-right (gold) ────────────
              Positioned(
                bottom: -60,
                right: -50,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _kGold.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Floating particles ───────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),

              // ── Subtle geometric lines (rail tracks) ─────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrackLinePainter(),
                ),
              ),

              // ═══════════ MAIN CONTENT ════════════════════════════════
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [

                      const Spacer(flex: 2),

                      // ── Hero logo (E-Season2.png ticket) ─────────────
                      Transform.scale(
                        scale: _logoScale.value.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: _logoScale.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _kGold.withValues(
                                      alpha:
                                          0.35 + 0.18 * _glowCtrl.value),
                                  blurRadius: 48 + 16 * _glowCtrl.value,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: _kAmethyst.withValues(
                                      alpha:
                                          0.15 + 0.08 * _glowCtrl.value),
                                  blurRadius: 60,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/E-Season2.png',
                                width: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Title ────────────────────────────────────────
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity:
                              (1.0 - _titleSlide.value / 40).clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              Text(
                                'Ride Smarter,',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [_kGold, _kLightGold],
                                ).createShader(bounds),
                                child: Text(
                                  'Book Faster.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Subtitle ─────────────────────────────────────
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Text(
                          'Your Season Ticket,\nJust a Click Away!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white60,
                            height: 1.55,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── Feature pills ────────────────────────────────
                      Opacity(
                        opacity: _pillsFade.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 14 * (1 - _pillsFade.value)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FeatureChip(
                                  icon: Icons.bolt_rounded,
                                  label: 'Instant'),
                              SizedBox(width: 10),
                              _FeatureChip(
                                  icon: Icons.verified_rounded,
                                  label: 'Official'),
                              SizedBox(width: 10),
                              _FeatureChip(
                                  icon: Icons.lock_rounded,
                                  label: 'Secure'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── CTA Button ───────────────────────────────────
                      Transform.scale(
                        scale: _ctaScale.value.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: _ctaScale.value.clamp(0.0, 1.0),
                          child: _ShimmerButton(
                            shimmerCtrl: _shimmerCtrl,
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                                reverseTransitionDuration:
                                    const Duration(milliseconds: 400),
                                pageBuilder: (_, __, ___) =>
                                    const LoginScreen(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Trust line ───────────────────────────────────
                      Opacity(
                        opacity: _ctaScale.value.clamp(0.0, 1.0),
                        child: Text(
                          'Free to download  ·  Paperless  ·  Live Alerts',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Subtle decorative rail-track lines
// ═══════════════════════════════════════════════════════════════════════════
class _TrackLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Diagonal lines from top-right
    for (int i = 0; i < 6; i++) {
      final startX = size.width * 0.6 + i * 35;
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX - size.height * 0.3, size.height),
        paint,
      );
    }

    // Horizontal sleeper-like marks
    final sleeperPaint = Paint()
      ..color = _kAmethyst.withValues(alpha: 0.04)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final y = size.height * 0.2 + i * (size.height * 0.18);
      canvas.drawLine(
        Offset(size.width * 0.7, y),
        Offset(size.width * 0.95, y),
        sleeperPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Floating light-bokeh particles (gold & violet mix)
// ═══════════════════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, radius, speed, opacity, phase;
  final bool isGold;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
    this.isGold = false,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width +
          sin(t * 2 * pi * p.speed + p.phase) * 22;
      final dy = (p.y * size.height - t * p.speed * size.height * 0.5) %
          size.height;
      final alpha = p.opacity * (0.5 + 0.5 * sin(t * 2 * pi + p.phase));
      final baseColor = p.isGold ? _kLightGold : Colors.white;
      final paint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.isGold ? 3 : 2);
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Feature chip (glassmorphism pill with violet tint)
// ═══════════════════════════════════════════════════════════════════════════
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kAmethyst.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _kAmethyst.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CTA "Get Started" button with animated shimmer sweep
// ═══════════════════════════════════════════════════════════════════════════
class _ShimmerButton extends StatelessWidget {
  final AnimationController shimmerCtrl;
  final VoidCallback onTap;
  const _ShimmerButton({required this.shimmerCtrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedBuilder(
            animation: shimmerCtrl,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [_kGold, _kLightGold],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withValues(alpha: 0.50),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _kAmethyst.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Shimmer sweep
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            final double sweep =
                                shimmerCtrl.value * (bounds.width + 120) -
                                    60;
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              transform: _SweepTransform(sweep),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white),
                        ),
                      ),
                      // Label
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _kDeepViolet,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _kDeepViolet.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: _kDeepViolet,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Translates a [LinearGradient] horizontally for the shimmer effect.
class _SweepTransform extends GradientTransform {
  final double dx;
  const _SweepTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
