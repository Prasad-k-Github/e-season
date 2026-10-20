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
  static const dateOfBirthLabel  = 'Date of birth (optional)';
  static const dateOfBirthHint   = 'Tap to select';
  static const emailLabel        = 'Email (optional)';
  static const emailHint         = 'e.g. kasun@gmail.com';
  static const languageLabel     = 'Preferred language';
  static const languageHint      = 'Select language';
  static const languageEnglish   = 'English';
  static const languageSinhala   = 'සිංහල';
  static const languageTamil     = 'தமிழ்';
  static const employerLabel     = 'Employer (optional)';
  static const employerHint      = 'e.g. ABC Pvt Ltd';
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
  static const imageReadFailed =
      'One of your photos could not be read. Please pick it again.';

  // ── Registration: step 4, government employment ───────────────────
  static const employmentSubtitle = 'Details of your government post';
  static const institutionLabel  = 'Institution';
  static const institutionHint   = 'Select your institution';
  static const institutionsLoadFailed = 'Could not load institutions';
  static const orgCodeLabel      = 'Organisation Authentication Code';
  static const orgCodeHint       = 'Code issued by your institution';
  static const employeeNoLabel   = 'Employee number (optional)';
  static const employeeNoHint    = 'e.g. EMP-1001';
  static const designationLabel  = 'Designation (optional)';
  static const designationHint   = 'e.g. Teacher';

  // ── Registration: password step ───────────────────────────────────
  static const passwordSubtitle  = 'Choose a strong password';
  static const passwordLabel     = 'Password';
  static const passwordHint      = 'At least 12 characters';
  static const confirmPasswordLabel = 'Confirm Password';
  static const confirmPasswordHint  = 'Re-enter password';
  static const consentText =
      'I agree that my personal details, photo and NIC images may be '
      'collected and used to issue and verify my season ticket.';
  static const continueLabel     = 'Continue';
  static const passwordHintBox =
      'Your registration is submitted when you tap the button.';
  static const submitHint =
      'Complete the password fields and accept the consent to continue.';

  // ── Mobile number verification ────────────────────────────────────
  static const otpTitle          = 'Verify your mobile number';
  static const otpSentTo         = 'We sent a 6-digit code to';
  static const otpVerify         = 'Verify';
  static const otpResend         = 'Resend code';
  static const otpResendIn       = 'Resend code in {s}s';
  static const otpDidNotGet      = "Didn't get the code?";
  static const otpSendFailed     = 'Could not send the code.';
  static const otpResent         = 'A new code has been sent';
  static const otpInstruction =
      'Enter the 6-digit code we sent you. Your registration is submitted '
      'only after your number is verified.';
  static const otpSending        = 'Sending code…';
  static const otpDemoCode       = 'Demo mode: your code is {code}';
  static const changePhone       = 'Use a different number';
  static const otpIncorrect      = 'That code is incorrect. Please try again.';
  static const phoneAlreadyRegistered =
      'An account with this mobile number already exists. Please log in.';
  static const verificationExpired =
      'Your mobile verification has expired. Please verify your number again.';
  static const phoneVerifiedTitle = 'Mobile number verified';
  static const phoneVerifiedMessage =
      'Your number is verified. Submit your registration to finish.';
  static const submitRegistration = 'Submit registration';
  static const retryRegistration  = 'Retry submitting';

  // ── Dashboard ─────────────────────────────────────────────────────
  static const sessionExpired    = 'Your session has expired. Please log in again.';
  static const dashLoading       = 'Loading your account…';
  static const dashRetry         = 'Try again';
  static const dashLogout        = 'Log out';
  static const dashPendingTitle  = 'Waiting for verification';
  static const dashPendingMessage =
      'Station staff are checking your documents. You can use this app once '
      'your account is verified by the admin.';
  static const dashInstitutionTitle = 'Waiting for institution approval';
  static const dashInstitutionMessage =
      'Your institution must approve your government employee account, then '
      'station staff will verify it. This screen is unavailable until then.';
  static const dashRejectedTitle = 'Verification was rejected';
  static const dashRejectedMessage =
      'Your documents were not accepted. Please contact the station or '
      'resubmit corrected documents.';
  static const dashReason        = 'Reason';
  static const dashLockedTitle   = 'Account not verified yet';
  static const dashComingSoon    = 'Coming soon';

  // ── Login ─────────────────────────────────────────────────────────
  static const loginPhoneHint    = 'Mobile number';
  static const loginPasswordHint = 'Password';
  static const loginPasswordRequired = 'Enter your password';
  static const loginIncorrect    = 'Incorrect phone number or password';
  static const loginFailed       = 'Could not sign in. Please try again.';
  static const loginAwaitingVerification =
      'Signed in. Your account is still waiting to be verified, so you cannot '
      'apply for a season ticket yet.';

  // ── Registration: result ──────────────────────────────────────────
  static const successTitle      = 'Registration submitted';
  static const successMessage =
      'Your details have been received. Station staff will check your '
      'documents and you will be able to apply for a season ticket once '
      'you are verified.';
  static const successMessageGovernment =
      'Your details have been received. Your institution will confirm your '
      'employment first, then station staff will check your documents.';

  // ── Resume a saved registration ───────────────────────────────────
  static const resumeTitle       = 'Continue your registration?';
  static const resumeMessage =
      'You have an unfinished registration saved on this device. Pick up '
      'where you left off, or start again.';
  static const resumeContinue    = 'Continue';
  static const resumeStartOver   = 'Start over';
  static const referenceLabel    = 'Reference';
  static const goToDashboard     = 'Go to Dashboard';
  static const submitFailed      = 'Registration failed. Please try again.';
  static const serverUnexpected = 'Unexpected reply from the server';
  static const serverUnreachable =
      'Cannot reach the server. Check your connection and try again.';
  static const duplicatePassenger =
      'An account with this mobile number, NIC or email already exists.';
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
  static const addressTooShort   = 'Address must be at least 3 characters';
  static const addressTooLong    = 'Address must be 500 characters or fewer';
  static const dateOfBirthFuture = 'Date of birth cannot be in the future';
  static const nicRequired       = 'NIC number is required';
  static const nicInvalid =
      'Enter a valid NIC (9 digits + V/X, or 12 digits)';
  static const emailRequired     = 'Email is required';
  static const emailInvalid      = 'Enter a valid email';
  static const phoneRequired     = 'Mobile number is required';
  static const phoneInvalid =
      'Enter a valid mobile number (07XXXXXXXX or +947XXXXXXXX)';
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
