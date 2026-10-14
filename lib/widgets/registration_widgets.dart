// lib/widgets/registration_widgets.dart
//
// Look-and-feel shared by every registration page, the email OTP page and the
// season application page (violet + gold, matching the login screen).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:e_season/utils/app_strings.dart';

class RegColors {
  RegColors._();
  static const deepViolet = Color(0xFF1A0533);
  static const gold       = Color(0xFFE8A020);
  static const amethyst   = Color(0xFF9B59B6);
  static const bg         = Color(0xFFF5F3F9);
  static const card       = Colors.white;
  static const muted      = Color(0xFF8A94A6);
  static const border     = Color(0xFFDDE3EF);
  static const green      = Color(0xFF1DA462);
}

InputDecoration regFieldDec(String label, String hint, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: RegColors.muted, fontSize: 13),
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: RegColors.muted.withValues(alpha: 0.55), fontSize: 13),
      prefixIcon: Icon(icon, color: RegColors.muted, size: 20),
      filled: true,
      fillColor: RegColors.bg,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RegColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RegColors.deepViolet, width: 1.8),
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

void showRegToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Expanded(child: Text(msg, style: GoogleFonts.inter())),
      IconButton(
        icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
        onPressed: () => Clipboard.setData(ClipboardData(text: msg)),
      ),
    ]),
    behavior: SnackBarBehavior.floating,
    backgroundColor: RegColors.deepViolet,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

/// Page frame: violet header with back button, title and step progress, and a
/// rounded white sheet that scrolls.
class RegistrationScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// 1-based position in the flow; leave null for pages outside the wizard.
  final int? step;
  final int? totalSteps;
  final bool showBack;
  final Widget child;

  const RegistrationScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.step,
    this.totalSteps,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegColors.deepViolet,
      body: Column(
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/background02.jpg',
                    fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        RegColors.deepViolet.withValues(alpha: 0.60),
                        RegColors.deepViolet.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (showBack) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(title,
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ]),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitle!,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white60)),
                      ],
                      if (step != null && totalSteps != null) ...[
                        const SizedBox(height: 16),
                        StepProgress(step: step!, total: totalSteps!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: RegColors.bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Step 2 of 5" with a segmented bar.
class StepProgress extends StatelessWidget {
  final int step, total;
  const StepProgress({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        AppStrings.stepOf
            .replaceAll('{n}', '$step')
            .replaceAll('{total}', '$total'),
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: RegColors.gold,
            letterSpacing: 0.3),
      ),
      const SizedBox(height: 6),
      Row(children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? RegColors.gold : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total) const SizedBox(width: 4),
        ],
      ]),
    ]);
  }
}

class RegCard extends StatelessWidget {
  final Widget child;
  const RegCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: RegColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: RegColors.amethyst.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
}

class RegSectionTitle extends StatelessWidget {
  final String text;
  const RegSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: RegColors.muted));
}

class RegField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final String? Function(String?) validator;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;

  const RegField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.type = TextInputType.text,
    this.obscure = false,
    this.onToggleObscure,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        onChanged: onChanged,
        decoration: regFieldDec(label, hint, icon).copyWith(
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: RegColors.muted,
                      size: 20),
                  onPressed: onToggleObscure,
                ),
        ),
        style: GoogleFonts.inter(fontSize: 14, color: RegColors.deepViolet),
        validator: validator,
      );
}

class RegDropdown extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validator;

  /// Shown instead of the validator result, e.g. when loading items failed.
  final String? forcedError;

  const RegDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
    this.forcedError,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        // Rebuild when async items arrive so the field picks them up.
        key: ValueKey('$label-${items.length}'),
        initialValue: value,
        isExpanded: true,
        decoration: regFieldDec(label, hint, icon)
            .copyWith(errorText: forcedError),
        style: GoogleFonts.inter(fontSize: 14, color: RegColors.deepViolet),
        items: items
            .map((i) => DropdownMenuItem(
                value: i, child: Text(i, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      );
}

/// Full-width violet button with a gold arrow, a loading state and a disabled
/// state (pass null for [onPressed]).
class RegPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool showArrow;

  const RegPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: RegColors.deepViolet,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                RegColors.deepViolet.withValues(alpha: loading ? 0.85 : 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            color: RegColors.gold,
                            borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 15),
                      ),
                    ],
                  ],
                ),
        ),
      );
}

/// Asks camera or gallery, then picks. Returns the file path, or null when the
/// user cancelled or picking failed (a toast is shown for failures).
Future<String?> pickImageWithSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: RegColors.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined,
              color: RegColors.deepViolet),
          title: Text(AppStrings.takePhoto, style: GoogleFonts.inter()),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined,
              color: RegColors.deepViolet),
          title: Text(AppStrings.chooseFromGallery, style: GoogleFonts.inter()),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (source == null || !context.mounted) return null;
  try {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    return file?.path;
  } catch (_) {
    // Deliberately not logged: the error can include file paths.
    if (context.mounted) showRegToast(context, AppStrings.imagePickFailed);
    return null;
  }
}

/// Tappable tile that shows an empty state or a preview of the picked image.
class ImagePickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final String? errorText;
  final double aspectRatio;
  final VoidCallback onTap;

  const ImagePickTile({
    super.key,
    required this.label,
    required this.icon,
    required this.path,
    required this.onTap,
    this.errorText,
    this.aspectRatio = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RegColors.deepViolet)),
      const SizedBox(height: 8),
      AspectRatio(
        aspectRatio: aspectRatio,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: RegColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: hasError ? Colors.redAccent : RegColors.border,
                  width: 1.5),
            ),
            child: path == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: RegColors.muted, size: 34),
                      const SizedBox(height: 6),
                      Text(AppStrings.tapToAdd,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: RegColors.muted)),
                    ],
                  )
                : Stack(fit: StackFit.expand, children: [
                    // Decode at preview size; full camera resolution would
                    // cost ~33 MB of memory per image.
                    Image.file(File(path!), fit: BoxFit.cover, cacheWidth: 900),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color:
                                RegColors.deepViolet.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.edit_rounded,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(AppStrings.tapToChange,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ]),
          ),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
        ),
    ]);
  }
}
