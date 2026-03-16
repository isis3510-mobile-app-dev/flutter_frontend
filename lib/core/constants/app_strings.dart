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
  static const String semanticBackButton = 'Back';
  static const String semanticCloseButton = 'Close';
  static const String semanticContinueButton = 'Continue';
  static const String semanticSaveButton = 'Save';
  static const String semanticGetStartedButton = 'Get Started';
  static const String semanticSkipButton = 'Skip';
  static const String semanticSignInButton = 'Sign in';
  static const String semanticAddVaccineButton = 'Add Vaccine';

  // --- Page titles ---
  static const String addVaccineTitle = 'Add New Vaccine';
  static const String healthRecordsTitle = 'Health Records';
  static const String recordsFilterAll = 'All';
  static const String recordsFilterVaccines = 'Vaccines';
  static const String recordsFilterEvents = 'Events';
  static const String recordsFilterSummary = 'Displaying';
  static const String recordCheckup = 'Checkup';
  static const String recordEmergency = 'Emergency';
  static const String recordDental = 'Dental';
  static const String recordPetMax = 'Max';
  static const String recordPetLuna = 'Luna';
  static const String recordClinicHappyPaws = 'Happy Paws Clinic';
  static const String recordClinicCatCare = 'Cat Care Center';
  static const String recordClinicCityEmergency = 'City Animal Emergency';
  static const String recordClinicCityVet = 'City Vet Center';
  static const String recordDateNov19 = 'Nov 19, 2024';
  static const String recordDateOct14 = 'Oct 14, 2024';
  static const String recordDateAug29 = 'Aug 29, 2024';
  static const String recordDateJun4 = 'Jun 4, 2024';
  static const String recordCost120 = '\$120';
  static const String recordCost95 = '\$95';
  static const String recordCost340 = '\$340';
  static const String recordCost280 = '\$280';
  static const String vaccineDetailsTitle = 'Vaccine Details';
  static const String vaccineDetailsSubtitle = 'Max • Dog';
  static const String vaccineStatusCompleted = 'Completed';
  static const String vaccineNameBordetella = 'Bordetella';
  static const String vaccineDateGivenValue = 'Sep 19, 2024';
  static const String vaccineNextDueValue = 'Sep 19, 2025';
  static const String vaccineVeterinarianValue = 'Dr. Smith';
  static const String vaccineClinicValue = 'Happy Paws Clinic';
  static const String vaccineTimelineTitle = 'Timeline';
  static const String vaccineDateGivenLabel = 'Date Given';
  static const String vaccineNextDueLabel = 'Next Due Date';
  static const String vaccineProviderInfoTitle = 'Provider Information';
  static const String vaccineVeterinarianLabel = 'Veterinarian';
  static const String vaccineClinicLabel = 'Clinic';
  static const String vaccineAttachedDocumentTitle = 'Attached Document';
  static const String vaccineNoDocuments = 'No documents attached';
  static const String actionDelete = 'Delete';
  static const String actionEdit = 'Edit';

  // --- Form field labels ---
  static const String labelVaccineName = 'Vaccine Name';
  static const String labelDate = 'Date';
  static const String labelProductName = 'Product Name';
  static const String labelPetName = 'Pet Name';
  static const String labelClinicProvider = 'Clinic / Provider';
  static const String labelDose = 'Dose';
  static const String labelNotes = 'Notes';
  static const String labelAdministeredBy = 'Administered By';
  static const String labelAdditionalFiles = 'Additional Files';

  // --- Form field hints ---
  static const String hintVaccineName = 'e.g. Rabies';
  static const String hintDate = 'dd/mm/yyyy';
  static const String hintProductName = 'e.g. Rabisin';
  static const String hintPetName = 'Max';
  static const String hintClinicProvider = 'e.g. City Vet Clinic';
  static const String hintDose = '1';
  static const String hintNotes = 'Optional notes';
  static const String hintNotProvided = 'Not provided';
  static const String hintAdministeredBy = 'e.g. Doctor Tatiana';
  static const String uploadDocuments = 'Upload Documents';
  static const String uploadHint = 'Tap to upload or take a photo';

  // --- Validation messages ---
  static const String validationRequired = 'This field is required.';
  static const String validationInvalidDate = 'Please enter a valid date.';

  // --- Step names ---
  static const String stepBasicInfo = 'Basic Info';
  static const String stepDetails = 'Details';
  static const String stepOverview = 'Overview';

  // --- Welcome pages ---
  static const String welcomeFirstTitle = 'All your pet\'s health, in one place.';
  static const String welcomeFirstDescription = 'Centralize vaccines, medications, records, and documents. Never miss a dose or appointment again';
  static const String welcomeSecondTitle = 'Track vaccines & medications';
  static const String welcomeSecondDescription = 'Timeline-based vaccine history, smart reminders for medications, and overdue alerts that keep you informed.';
  static const String welcomeThirdTitle = 'NFC tag integration';
  static const String welcomeThirdDescription = 'Write your pet\'s info to an NFC tag. Anyone who finds your pet can contact you instantly.';
  static const String welcomeAlreadyHaveAccount = 'Already have an account?';
}
