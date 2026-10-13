import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/models/season_application.dart';
import 'package:e_season/services/mock_season_repository.dart';
import 'package:e_season/services/season_repository.dart';
import 'package:e_season/utils/app_strings.dart';
import 'package:e_season/utils/registration_options.dart';
import 'package:e_season/utils/validation_utils.dart';
import 'package:e_season/widgets/registration_widgets.dart';

/// Apply for a season ticket: class, season type and route. This is where the
/// journey details live now; they are no longer asked at registration.
class ApplySeasonScreen extends StatefulWidget {
  final SeasonRepository repository;
  const ApplySeasonScreen(
      {super.key, this.repository = const MockSeasonRepository()});

  @override
  State<ApplySeasonScreen> createState() => _ApplySeasonScreenState();
}

class _ApplySeasonScreenState extends State<ApplySeasonScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  String? _travelClass, _seasonType;
  bool _submitting = false;
  String? _referenceNumber; // set once the application succeeds

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.repository.apply(SeasonApplication(
        travelClass:  _travelClass!,
        seasonType:   _seasonType!,
        startStation: _startCtrl.text.trim(),
        endStation:   _endCtrl.text.trim(),
      ));
      if (!mounted) return;
      if (result.success) {
        setState(() => _referenceNumber = result.referenceNumber ?? '');
      } else {
        showRegToast(context, result.errorMessage ?? AppStrings.applyFailed);
      }
    } catch (_) {
      if (mounted) showRegToast(context, AppStrings.applyFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _referenceNumber != null;
    return RegistrationScaffold(
      title: AppStrings.applySeasonTitle,
      subtitle: AppStrings.applySeasonSubtitle,
      child: done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() => AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(children: [
            RegCard(
              child: Column(children: [
                RegDropdown(
                  label: AppStrings.classLabel,
                  hint: AppStrings.classHint,
                  icon: Icons.airline_seat_recline_normal_outlined,
                  value: _travelClass,
                  items: RegistrationOptions.travelClasses,
                  onChanged: (v) => setState(() => _travelClass = v),
                  validator: ValidationUtils.validateTravelClass,
                ),
                const SizedBox(height: 12),
                RegDropdown(
                  label: AppStrings.seasonTypeLabel,
                  hint: AppStrings.seasonTypeHint,
                  icon: Icons.date_range_outlined,
                  value: _seasonType,
                  items: RegistrationOptions.seasonTypes,
                  onChanged: (v) => setState(() => _seasonType = v),
                  validator: ValidationUtils.validateSeasonType,
                ),
                const SizedBox(height: 12),
                RegField(
                  controller: _startCtrl,
                  label: AppStrings.startStationLabel,
                  hint: AppStrings.startStationHint,
                  icon: Icons.trip_origin_rounded,
                  validator: ValidationUtils.validateStation,
                ),
                const SizedBox(height: 12),
                RegField(
                  controller: _endCtrl,
                  label: AppStrings.endStationLabel,
                  hint: AppStrings.endStationHint,
                  icon: Icons.place_outlined,
                  validator: (v) =>
                      ValidationUtils.validateEndStation(_startCtrl.text, v),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            RegPrimaryButton(
              label: AppStrings.applySubmit,
              loading: _submitting,
              onPressed: _submit,
            ),
          ]),
        ),
      );

  Widget _buildSuccess() => RegCard(
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
          Text(AppStrings.applySuccessTitle,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: RegColors.deepViolet)),
          const SizedBox(height: 8),
          Text(AppStrings.applySuccessMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: RegColors.muted)),
          if (_referenceNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${AppStrings.referenceLabel}: $_referenceNumber',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RegColors.deepViolet)),
          ],
          const SizedBox(height: 20),
          RegPrimaryButton(
            label: AppStrings.backToDashboard,
            showArrow: false,
            onPressed: () => Navigator.pop(context),
          ),
        ]),
      );
}
