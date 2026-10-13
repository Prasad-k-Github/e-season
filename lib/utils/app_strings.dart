// lib/utils/app_strings.dart
//
// All user-facing strings for registration, season application and validation
// live here so they can be swapped for a localisation solution later.

class AppStrings {
  AppStrings._();

  // ── Registration: shared ──────────────────────────────────────────
  static const createAccount     = 'Create Account';
  static const next              = 'Next';
  static const stepOf            = 'Step {n} of {total}';

  // Step names (shown in the progress header)
  static const stepDetails       = 'Your details';
  static const stepPhoto         = 'Profile photo';
  static const stepNic           = 'NIC images';
  static const stepEmployment    = 'Government employment';
  static const stepPassword      = 'Password';

  // ── Registration: step 1, common details ──────────────────────────
  static const detailsSubtitle   = 'Tell us who you are';
  static const passengerType     = 'Passenger type';
  static const typeGovernment    = 'Government employee';
  static const typeGeneral       = 'Private-sector / general';

  static const fullNameLabel     = 'Full Name';
  static const fullNameHint      = 'e.g. Kasun Perera';
  static const addressLabel      = 'Address';
  static const addressHint       = 'e.g. 25, Galle Rd, Matara';
  static const nicLabel          = 'NIC Number';
  static const nicHint           = 'e.g. 972430039V or 199724300390';
  static const nicIssueDateLabel = 'NIC Issue Date';
  static const nicIssueDateHint  = 'Tap to select';
  static const emailLabel        = 'Email Address';
  static const emailHint         = 'e.g. kasun@gmail.com';
  static const mobileLabel       = 'Mobile Number';
  static const mobileHint        = 'e.g. 0771234567 or +94771234567';
  static const or                = 'or';
  static const signUpWithGoogle  = 'Sign up with Google';

  // ── Registration: step 2, profile photo ───────────────────────────
  static const photoSubtitle =
      'A clear, front-facing photo of your face, without sunglasses.';
  static const profilePhoto      = 'Profile photo';

  // ── Registration: step 3, NIC images ──────────────────────────────
  static const nicSubtitle =
      'Photograph both sides of your NIC. Make sure all text is readable.';
  static const nicFront          = 'NIC front';
  static const nicBack           = 'NIC back';

  // ── Registration: image picking (steps 2 and 3) ───────────────────
  static const tapToAdd          = 'Tap to add';
  static const tapToChange       = 'Tap to change';
  static const takePhoto         = 'Take a photo';
  static const chooseFromGallery = 'Choose from gallery';
  static const imagePickFailed   = 'Could not open camera or gallery';

  // ── Registration: step 4, government employment ───────────────────
  static const employmentSubtitle = 'Details of your government post';
  static const institutionLabel  = 'Institution';
  static const institutionHint   = 'Select your institution';
  static const institutionsLoadFailed = 'Could not load institutions';
  static const ministryLabel     = 'Ministry (optional)';
  static const ministryHint      = 'e.g. Finance';
  static const nearestStationLabel = 'Nearest Railway Station (optional)';
  static const nearestStationHint  = 'e.g. Colombo Fort';
  static const orgCodeLabel      = 'Organisation Authentication Code';
  static const orgCodeHint       = 'Code issued by your institution';

  // ── Registration: password step ───────────────────────────────────
  static const passwordSubtitle  = 'Choose a strong password';
  static const passwordLabel     = 'Password';
  static const passwordHint      = 'At least 12 characters';
  static const confirmPasswordLabel = 'Confirm Password';
  static const confirmPasswordHint  = 'Re-enter password';
  static const consentText =
      'I agree that my personal details, photo and NIC images may be '
      'collected and used to issue and verify my season ticket.';
  static const createAccountButton = 'Create account';
  static const passwordHintBox =
      'We will email a 6-digit code to confirm your address.';
  static const alreadyCreatedHint =
      'Your account is already created. Continue to verify your email.';
  static const submitHint =
      'Complete the password fields and accept the consent to continue.';

  // ── Email OTP ─────────────────────────────────────────────────────
  static const otpTitle          = 'Verify your email';
  static const otpSentTo         = 'We sent a 6-digit code to';
  static const otpVerify         = 'Verify';
  static const otpResend         = 'Resend code';
  static const otpResendIn       = 'Resend code in {s}s';
  static const otpDidNotGet      = "Didn't get the code?";
  static const otpSendFailed     = 'Could not send the code.';
  static const otpResent         = 'A new code has been sent';
  static const otpAccountCreated =
      'Your account has been created. Enter the code we emailed you to '
      'verify your email address.';
  static const otpIncorrect =
      'That code is incorrect or has expired. Request a new one if needed.';

  // ── Registration: result ──────────────────────────────────────────
  static const successTitle      = 'Email verified';
  static const successMessage =
      'Your email is verified. Your registration is now pending approval.';
  static const referenceLabel    = 'Reference';
  static const goToDashboard     = 'Go to Dashboard';
  static const submitFailed      = 'Registration failed. Please try again.';
  static const serverUnreachable =
      'Cannot reach the server. Check your connection and try again.';
  static const duplicatePassenger =
      'An account with this NIC or email already exists.';
  static const rateLimited =
      'Too many attempts. Please wait a few minutes and try again.';
  static const serverRejectedFields = 'The server rejected these fields:';

  // ── Apply for season ──────────────────────────────────────────────
  static const applySeasonTitle  = 'Apply for Season';
  static const applySeasonSubtitle = 'Choose your class and route';
  static const applySeasonAction = 'Apply\nSeason';
  static const classLabel        = 'Class';
  static const classHint         = 'Select class';
  static const seasonTypeLabel   = 'Season Type';
  static const seasonTypeHint    = 'Select season type';
  static const startStationLabel = 'Start Station';
  static const startStationHint  = 'e.g. Colombo Fort';
  static const endStationLabel   = 'End Station';
  static const endStationHint    = 'e.g. Kandy';
  static const applySubmit       = 'Submit application';
  static const applyFailed       = 'Could not submit your application. Please try again.';
  static const applySuccessTitle = 'Application submitted';
  static const applySuccessMessage =
      'Your season application has been received.';
  static const backToDashboard   = 'Back to Dashboard';

  // ── Validation ────────────────────────────────────────────────────
  static const nameRequired      = 'Name is required';
  static const nameTooShort      = 'Name must be at least 3 characters';
  static const nameInvalid       = 'Name can contain letters and spaces only';
  static const addressRequired   = 'Address is required';
  static const nicRequired       = 'NIC number is required';
  static const nicInvalid =
      'Enter a valid NIC (9 digits + V/X, or 12 digits)';
  static const emailRequired     = 'Email is required';
  static const emailInvalid      = 'Enter a valid email';
  static const phoneRequired     = 'Mobile number is required';
  static const phoneInvalid =
      'Enter a valid mobile number (07XXXXXXXX or +947XXXXXXXX)';
  static const nicIssueDateRequired = 'NIC issue date is required';
  static const nicIssueDateFuture   = 'Issue date cannot be in the future';
  static const classRequired     = 'Please select a class';
  static const stationRequired   = 'Station is required';
  static const tooLong           = 'Must be 100 characters or fewer';
  static const stationsSame      = 'Start and end stations must differ';
  static const seasonTypeRequired = 'Please select a season type';
  static const institutionRequired = 'Please select your institution';
  static const orgCodeRequired   = 'Authentication code is required';
  static const imageRequired     = 'Please add this image';
  static const otpRequired       = 'Enter the 6-digit code';
  static const passwordRequired  = 'Password is required';
  static const passwordTooShort  = 'Password must be at least 12 characters long';
  static const passwordTooLong   = 'Password must be at most 128 characters';
  static const passwordWeak =
      'Password must contain at least one uppercase letter, one lowercase '
      'letter, one number, and one special character';
  static const confirmPasswordRequired = 'Confirm Password is required';
  static const passwordsDoNotMatch = 'Passwords do not match';
}
