/// Centralized string constants for the app.
/// Keeping all user-facing text here makes it easy to:
/// - Avoid typos caused by repeated inline strings
/// - Prepare for localization (i18n) in the future
/// - Update copy from one place
abstract class AppStrings {
  // --- General ---
  // static const String appName = 'My App';
  // static const String ok = 'OK';
  // static const String cancel = 'Cancel';
  // static const String confirm = 'Confirm';
  // static const String retry = 'Retry';
  // static const String loading = 'Loading...';
  // static const String somethingWentWrong = 'Something went wrong. Please try again.';

  // --- Home page ---
  static const String homeTitle = 'Home';
  static const String homeWelcome = 'Welcome back!';

  // --- Error messages ---
  static const String errorGeneric = 'An unexpected error occurred.';
  static const String errorNoConnection = 'No internet connection.';

  // --- Accessibility labels ---
  static const String semanticBackButton = 'Go back';
  static const String semanticCloseButton = 'Close';
  static const String semanticContinueButton = 'Continue';
  static const String semanticAddPetButton = 'Add Pet';
  static const String semanticGetStartedButton = 'Get Started';
  static const String semanticSkipButton = 'Skip';
  static const String semanticSignInButton = 'Sign in';

  // --- Pets ---
  static const String petsTitle = 'My Pets';
  static const String petsEmpty = 'No pets yet';
  static const String petsEmptyFiltered = 'No pets match this filter';
  static const String petsRetry = 'Retry';

  // --- Add pet ---
  static const String addPetTitle = 'Add New Pet';
  static const String addPetStepBasicInfo = 'Basic Info';
  static const String addPetStepDetails = 'Details';
  static const String addPetStepMedical = 'Medical';
  static const String addPetPhotoTitle = 'Add Photo';
  static const String addPetPhotoHint = 'Tap to upload or take a photo';
  static const String addPetNameLabel = 'Pet Name';
  static const String addPetBreedLabel = 'Breed';
  static const String addPetSpeciesLabel = 'Species';
  static const String addPetSpeciesDog = 'Dog';
  static const String addPetSpeciesCat = 'Cat';
  static const String addPetDobLabel = 'Date of Birth';
  static const String addPetGenderLabel = 'Gender';
  static const String addPetGenderMale = 'Male';
  static const String addPetGenderFemale = 'Female';
  static const String addPetWeightLabel = 'Weight (kg)';
  static const String addPetColorLabel = 'Color / Markings';
  static const String addPetVeterinarianLabel = 'Veterinarian';
  static const String addPetClinicLabel = 'Clinic Name';
  static const String addPetAllergiesLabel = 'Known Allergies';
  static const String addPetAlmostDoneTitle = 'Almost done!';
  static const String addPetAlmostDoneMessage =
      'Add optional medical info. You can always update this later from the pet\'s profile.';
  static const String addPetNfcTitle = 'Set up NFC tag later?';
  static const String addPetNfcMessage =
      'Write your pet\'s info to an NFC tag from their profile.';
  static const String addPetNameHint = 'e.g. Max';
  static const String addPetBreedHint = 'e.g. Golden Retriever';
  static const String addPetDobHint = 'dd/mm/yyyy';
  static const String addPetWeightHint = 'e.g. 12.5';
  static const String addPetColorHint = 'e.g. Brown with white paws';
  static const String addPetVeterinarianHint = 'e.g. Dr. Smith';
  static const String addPetClinicHint = 'e.g. Happy Paws Clinic';
  static const String addPetAllergiesHint = 'Optional notes';
  static const String addPetValidationRequired = 'This field is required.';
  static const String addPetSavedMessage = 'Pet ready to be saved.';

  // --- Welcome pages ---
  static const String welcomeFirstTitle =
      'All your pet\'s health, in one place.';
  static const String welcomeFirstDescription =
      'Centralize vaccines, medications, records, and documents. Never miss a dose or appointment again.';
  static const String welcomeSecondTitle = 'Track vaccines & medications';
  static const String welcomeSecondDescription =
      'Timeline-based vaccine history, smart reminders for medications, and overdue alerts that keep you informed.';
  static const String welcomeThirdTitle = 'NFC sharing anywhere';
  static const String welcomeThirdDescription =
      'Write your pet\'s info to an NFC tag. Anyone who finds your pet can contact you instantly.';
  static const String welcomeAlreadyHaveAccount = 'Already have an account?';
}
