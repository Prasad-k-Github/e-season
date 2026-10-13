import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:flutter/services.dart';
import 'package:e_season/screens/password_screen.dart';
import 'package:e_season/services/firebase_service.dart';

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
const _kGreen      = Color(0xFF1DA462);

InputDecoration _fieldDec(String label, String hint, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: _kMuted, fontSize: 13),
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: _kMuted.withOpacity(0.55), fontSize: 13),
      prefixIcon: Icon(icon, color: _kMuted, size: 20),
      filled: true,
      fillColor: _kBg,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _nicCtrl         = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _firebaseService = FirebaseService();

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _nicCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PasswordScreen(userData: {
          'fullName': _nameCtrl.text,
          'address':  _addressCtrl.text,
          'nic':      _nicCtrl.text,
          'email':    _emailCtrl.text,
          'phone':    _phoneCtrl.text,
        }),
      ));
    }
  }

  void _googleRegister() async {
    try {
      User? user = await _firebaseService.signInWithGoogle();
      if (user != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PasswordScreen(userData: {
            'fullName': user.displayName ?? '',
            'address':  '',
            'nic':      '',
            'email':    user.email ?? '',
            'phone':    user.phoneNumber ?? '',
          }),
        ));
      }
    } catch (e) { _toast('Error: $e'); }
  }

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
              // Dark violet overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _kDeepViolet.withValues(alpha: 0.60),
                        _kDeepViolet.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Header content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Create Account',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                      const SizedBox(height: 20),

                      // Step indicator
                      Row(children: [
                        _Step(n: '1', label: 'Your Info', active: true, done: false),
                        Expanded(child: Container(height: 2,
                            color: Colors.white.withOpacity(0.2))),
                        _Step(n: '2', label: 'Password', active: false, done: false),
                      ]),
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
                child: Column(children: [
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _kAmethyst.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        _Field(controller: _nameCtrl,    label: 'Full Name',     hint: 'e.g. Kasun Perera',       icon: Icons.person_outline_rounded,  type: TextInputType.name,          validator: ValidationUtils.validateName),
                        const SizedBox(height: 12),
                        _Field(controller: _addressCtrl, label: 'Address',       hint: 'e.g. 25, Galle Rd, Matara', icon: Icons.home_outlined,           type: TextInputType.streetAddress, validator: ValidationUtils.validateAddress),
                        const SizedBox(height: 12),
                        _Field(controller: _nicCtrl,     label: 'NIC Number',    hint: 'e.g. 972430039V',         icon: Icons.credit_card_outlined,    type: TextInputType.text,          validator: ValidationUtils.validateNIC),
                        const SizedBox(height: 12),
                        _Field(controller: _emailCtrl,   label: 'Email Address', hint: 'e.g. kasun@gmail.com',    icon: Icons.email_outlined,          type: TextInputType.emailAddress,  validator: ValidationUtils.validateEmail),
                        const SizedBox(height: 12),
                        _Field(controller: _phoneCtrl,   label: 'Phone Number',  hint: 'e.g. +94769087940',       icon: Icons.phone_outlined,          type: TextInputType.phone,         validator: ValidationUtils.validatePhone),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Next btn
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDeepViolet,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Next',
                              style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                                color: _kGold,
                                borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: _kBorder, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _kMuted)),
                    ),
                    const Expanded(child: Divider(color: _kBorder, thickness: 1)),
                  ]),
                  const SizedBox(height: 20),

                  // Google sign up
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _googleRegister,
                      icon: Image.asset('assets/images/google_logo.png',
                          height: 20),
                      label: Text('Sign up with Google',
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
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ──────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String n, label;
  final bool active, done;
  const _Step({required this.n, required this.label,
    required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final Color bg = done ? _kGreen : active ? _kGold : Colors.white24;
    final Color fg = (done || active) ? Colors.white : Colors.white54;
    return Column(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(n, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(
          fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─── Reusable field ───────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final String? Function(String?) validator;
  const _Field({
    required this.controller, required this.label, required this.hint,
    required this.icon, required this.type, required this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: _fieldDec(label, hint, icon),
        style: GoogleFonts.inter(fontSize: 14, color: _kDeepViolet),
        validator: validator,
      );
}
