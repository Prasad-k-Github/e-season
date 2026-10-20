import 'package:flutter/material.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/services/firebase_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const _kNavy   = Color(0xFF0A2558);
const _kGold   = Color(0xFFE8A020);
const _kBg     = Color(0xFFF2F5FB);
const _kCard   = Colors.white;
const _kMuted = Color(0xFF8A94A6);
const _kGreen  = Color(0xFF1DA462);

class PasswordScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const PasswordScreen({super.key, required this.userData});

  @override
  // ignore: library_private_types_in_public_api
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firebase    = FirebaseService();
  bool _showPass    = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose();
  }

  void _submit() async {

    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    return;
    // ignore: dead_code
    if (_formKey.currentState!.validate()) {
      try {
        await _firebase.addPassenger(
          fullName: widget.userData['fullName'],
          address:  widget.userData['address'],
          nic:      widget.userData['nic'],
          email:    widget.userData['email'],
          phone:    widget.userData['phone'],
          password: _passCtrl.text,
          context:  context,
        );
        _toast('Account created successfully!');
      } catch (e) { _toast('Error: $e'); }
    }
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
      backgroundColor: _kNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      body: Column(
        children: [
          // ── Navy header ──────────────────────────────────────
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
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Set Password',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                  const SizedBox(height: 20),

                  // Step indicator
                  Row(children: [
                    _Step(n: '1', label: 'Your Info', active: false, done: true),
                    Expanded(child: Container(height: 2, color: _kGold)),
                    _Step(n: '2', label: 'Password', active: true, done: false),
                  ]),
                ],
              ),
            ),
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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(children: [
                  // Lock icon
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _kNavy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: _kNavy, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text('Create a secure password',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kNavy)),
                  const SizedBox(height: 4),
                  Text('Minimum 8 characters',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _kMuted)),
                  const SizedBox(height: 28),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        // Password
                        _PassField(
                          controller: _passCtrl,
                          label: 'Password',
                          show: _showPass,
                          onToggle: () =>
                              setState(() => _showPass = !_showPass),
                          validator: ValidationUtils.validatePassword,
                        ),
                        const SizedBox(height: 14),

                        // Confirm
                        _PassField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          validator: (v) =>
                              ValidationUtils.validateConfirmPassword(
                                  _passCtrl.text, v),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password strength hint
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _kGold.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: _kGold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use letters, numbers and symbols for a stronger password.',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF8A6200)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Create account btn
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Create Account',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
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

// ─── Password field widget ────────────────────────────────────────────
class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PassField({
    required this.controller, required this.label, required this.show,
    required this.onToggle, required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      style: GoogleFonts.inter(fontSize: 14, color: _kNavy),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: _kMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: _kMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _kMuted, size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F5FB),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDE3EF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kNavy, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Step dot ────────────────────────────────────────────────────────
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
            : Text(n,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
    ]);
  }
}
