import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Shown after the account has been created.
class RegistrationSuccessScreen extends StatelessWidget {
  final String? referenceNumber;

  /// `pending_institution_approval` for government employees, who are checked
  /// by their institution before station staff look at the documents.
  final String? verificationStatus;
  const RegistrationSuccessScreen(
      {super.key, this.referenceNumber, this.verificationStatus});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: RegistrationScaffold(
        title: AppStrings.successTitle,
        showBack: false,
        child: RegCard(
          child: Column(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: RegColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: RegColors.green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.successTitle,
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: RegColors.deepViolet)),
            const SizedBox(height: 8),
            Text(
                verificationStatus == 'pending_institution_approval'
                    ? AppStrings.successMessageGovernment
                    : AppStrings.successMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: RegColors.muted)),
            if (referenceNumber != null && referenceNumber!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${AppStrings.referenceLabel}: $referenceNumber',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RegColors.deepViolet)),
            ],
            const SizedBox(height: 20),
            RegPrimaryButton(
              label: AppStrings.goToDashboard,
              showArrow: false,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/dashboard', (_) => false),
            ),
          ]),
        ),
      ),
    );
  }
}
