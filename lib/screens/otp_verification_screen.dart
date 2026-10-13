import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kNavy   = Color(0xFF0A2558);
const _kGold   = Color(0xFFE8A020);
const _kBg     = Color(0xFFF2F5FB);
const _kMuted  = Color(0xFF8A94A6);
const _kBorder = Color(0xFFDDE3EF);

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final f in _nodes) f.dispose();
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 24),

                  // Icon in header
                  Center(
                    child: Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: _kGold.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_outlined,
                          color: _kGold, size: 34),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('Verify your number',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Code sent to ',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.white60),
                        children: [
                          TextSpan(
                            text: '+94769087940',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _kGold,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White sheet ──────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                child: Column(
                  children: [
                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 64, height: 68,
                          margin: EdgeInsets.only(right: i < 3 ? 14 : 0),
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _kNavy),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _kBorder, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _kNavy, width: 2.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onChanged: (v) => _onChanged(i, v),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Didn't receive the code? ",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: _kMuted)),
                        GestureDetector(
                          onTap: () {},
                          child: Text('Resend OTP',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _kGold,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Verify btn
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Verify & Continue',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Expiry note
                    Text('Code expires in 5:00',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _kMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
