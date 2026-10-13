import 'package:e_season/models/registration_data.dart';
import 'package:e_season/screens/register_screen.dart';
import 'package:e_season/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/utils/validation_utils.dart';

// ─── Premium Violet + Gold tokens (matching home screen) ─────────────
const _kDeepViolet = Color(0xFF1A0533);
const _kMidViolet  = Color(0xFF2D1B69);
const _kGold       = Color(0xFFE8A020);
const _kLightGold  = Color(0xFFF5C563);
const _kAmethyst   = Color(0xFF9B59B6);
const _kBg         = Color(0xFFF5F3F9);
const _kCard       = Colors.white;
const _kMuted      = Color(0xFF8A94A6);
const _kBorder     = Color(0xFFDDE3EF);

InputDecoration _fieldDec(String hint, IconData icon, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _kMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: _kMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kBg,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDeepViolet, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _emailCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  // ignore: unused_field -- used again once the TEMP login bypass is removed
  final _firebaseService  = FirebaseService();
  bool _showPass    = false;
  bool _isLoginTab  = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // TEMP: bypassed for UI testing
  void _login() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  // TEMP: bypassed for UI testing
  Future<void> _googleSignIn() async {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  // ignore: unused_element -- used again once the TEMP login bypass is removed
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Expanded(child: Text(msg, style: GoogleFonts.inter())),
        IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
          onPressed: () => Clipboard.setData(ClipboardData(text: msg)),
        ),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _kDeepViolet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepViolet,
      body: Column(
        children: [
          // ── Header with background image ────────────────────────
          Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background02.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Dark violet overlay — richer gradient for depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _kDeepViolet.withValues(alpha: 0.45),
                        _kMidViolet.withValues(alpha: 0.70),
                        _kDeepViolet.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Header content — premium
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: back ──────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Gold badge pill ───────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kGold, _kLightGold],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _kGold.withValues(alpha: 0.40),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded,
                              size: 12, color: _kDeepViolet),
                          const SizedBox(width: 5),
                          Text('Premium Train Season',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kDeepViolet,
                                  letterSpacing: 0.3)),
                        ]),
                      ),

                      const SizedBox(height: 14),

                      // ── Title ─────────────────────────────────────
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.6),
                          children: [
                            TextSpan(
                              text: _isLoginTab
                                  ? 'Welcome\n'
                                  : 'Join\n',
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: _isLoginTab ? 'Back.' : 'E-Season.',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [_kGold, _kLightGold],
                                  ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 40)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Subtitle ──────────────────────────────────
                      Text(
                        _isLoginTab
                            ? 'Sign in to manage your season tickets'
                            : 'Create your account and ride smarter',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white60,
                            height: 1.4),
                      ),

                      const SizedBox(height: 6),

                      // ── Thin gold accent line ─────────────────────
                      Container(
                        width: 40,
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kGold, _kLightGold],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── White sheet ──────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  children: [
                    // Tab switcher
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(children: [
                        _Tab(label: 'Login',
                            active: _isLoginTab,
                            onTap: () => setState(() => _isLoginTab = true)),
                        _Tab(label: 'Sign Up',
                            active: !_isLoginTab,
                            onTap: () => setState(() => _isLoginTab = false)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _kAmethyst.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isLoginTab
                          ? _buildLoginForm()
                          : _buildSignupOptions(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDec('Email address', Icons.email_outlined),
          style: GoogleFonts.inter(fontSize: 14, color: _kDeepViolet),
          validator: ValidationUtils.validateEmail,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _passwordCtrl,
          obscureText: !_showPass,
          decoration: _fieldDec(
            'Password',
            Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: _kMuted, size: 20,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: _kDeepViolet),
          validator: ValidationUtils.validatePassword,
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Forgot password?',
                style: GoogleFonts.inter(
                    fontSize: 13, color: _kGold, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),

        // Login btn
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDeepViolet,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Login',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),

        // Divider
        _Divider(),
        const SizedBox(height: 20),

        // Google
        _GoogleBtn(onPressed: _googleSignIn),
      ]),
    );
  }

  Widget _buildSignupOptions() {
    return Column(children: [
      _OptionCard(
        icon: Icons.person_outline_rounded,
        title: 'General Passenger',
        subtitle: 'Standard season ticket',
        color: _kDeepViolet,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>
              const RegisterScreen(initialType: PassengerType.general)),
        ),
      ),
      const SizedBox(height: 12),
      _OptionCard(
        icon: Icons.badge_outlined,
        title: 'Government Passenger',
        subtitle: 'Subsidised season ticket',
        color: const Color(0xFF1DA462),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>
              const RegisterScreen(initialType: PassengerType.government)),
        ),
      ),
      const SizedBox(height: 24),
      _Divider(label: 'or continue with'),
      const SizedBox(height: 20),
      _GoogleBtn(onPressed: _googleSignIn),
    ]);
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: active ? _kDeepViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : _kMuted)),
          ),
        ),
      );
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: _kDeepViolet)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: _kMuted, size: 20),
          ]),
        ),
      );
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({this.label = 'or'});

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: _kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
        ),
        const Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ]);
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Image.asset('assets/images/google_logo.png', height: 20),
          label: Text('Continue with Google',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDeepViolet)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kBorder, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
          ),
        ),
      );
}
