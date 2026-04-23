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
  static const String homeGreeting = 'Hello,';
  static const String homePetsSection = 'My Pets';
  static const String homeSeeAll = 'See all';
  static const String homeHealthAlerts = 'Health Alerts';
  static const String homeAddPet = 'Add Pet';
  static const String homeOverdueVaccines = 'Overdue Vaccines';
  static const String homeNextVaccine = 'NEXT VACCINE';
  static const String homeActiveEvents = 'Active Events';
  static const String homeViewAll = 'View all';
  static const String homeReminderOn = 'Reminder on';
  static const String homeUpcomingDaysLeft = 'd';
  static const String homeHealthy = 'Healthy';
  static const String homeNeedsAttention = 'Needs Attention';
  static const String homeLost = 'Lost';

  // --- NFC page ---
  static const String nfcTitle = 'NFC Tag';
  static const String nfcReadTag = 'Read Tag';
  static const String nfcWriteTag = 'Write Tag';
  static const String nfcScanTitle = 'Scan NFC Tag';
  static const String nfcScanDescription =
      'Bring your phone close to a PetCare NFC tag to read the pet information';
  static const String nfcHoldNearTag = 'Hold your phone near the NFC tag';
  static const String nfcReadyToWrite =
      'Ready to write. Choose pet data and hold the tag near your phone.';
  static const String nfcSelectPetToLink = 'Select pet to write:';
  static const String nfcDataToWrite = 'Data to write';
  static const String nfcBasicInfoOption = 'Pet Basic Info (Name, Breed)';
  static const String nfcOwnerContactOption = 'Owner Contact (Phone, Email)';
  static const String nfcEmergencyOption =
      'Emergency Medical Info (Allergies, Vet contact)';
  static const String nfcStartScanning = 'Start Scanning';
  static const String nfcWriteToTag = 'Write to Tag';
  static const String nfcStartWriting = 'Start Writing';
  static const String nfcTestReadTag = 'Test / Read Tag';
  static const String nfcWhatDoesReadingDo = 'What does reading do?';
  static const String nfcReadingBenefitOne = "Shows the pet's name and photo";
  static const String nfcReadingBenefitTwo = 'Displays owner contact info';
  static const String nfcReadingBenefitThree = 'Shows emergency medical notes';
  static const String nfcReadingBenefitFour =
      'Allows calling the owner instantly';
  static const String nfcScanning = 'Scanning...';
  static const String nfcWriting = 'Writing...';
  static const String nfcScanningHint = 'Hold your device near the NFC tag';
  static const String nfcCancel = 'Cancel';
  static const String nfcScanSuccess = 'Tag scanned successfully';
  static const String nfcTagWrittenTitle = 'Tag Written!';
  static const String nfcTagWrittenDescriptionSuffix =
      "'s information has been successfully written to the NFC tag. Anyone who scans it can contact you instantly.";
  static const String nfcStoredOnTagTitle = "What's stored on the tag:";
  static const String nfcStoredPetLabel = 'Pet';
  static const String nfcStoredOwnerLabel = 'Owner';
  static const String nfcStoredPhoneLabel = 'Phone';
  static const String nfcStoredMicrochipLabel = 'Microchip';
  static const String nfcStoredMicrochipValue = 'XR123456789';
  static const String nfcWriteAnother = 'Write Another';
  static const String nfcDone = 'Done';
  static const String nfcHealthyStatus = 'Healthy';
  static const String nfcOwnerInformation = 'Owner Information';
  static const String nfcCallOwnerNow = 'Call Owner Now';
  static const String nfcSendSms = 'Send SMS';
  static const String nfcShare = 'Share';
  static const String nfcMedicalNotes = 'Medical Notes';
  static const String nfcMedicalNotesValue =
      'No known allergies. Microchip: XR123456789';
  static const String nfcScanAnotherTag = 'Scan another tag';

  // --- Auth page ---
  static const String authAppName = 'PetCare';
  static const String authSubtitle = 'Your pet\'s health companion';
  static const String authSignIn = 'Sign In';
  static const String authCreateAccount = 'Create Account';
  static const String authFullName = 'Full Name';
  static const String authFullNameHint = 'Sarah Johnson';
  static const String authEmailAddress = 'Email Address';
  static const String authEmailHint = 'you@example.com';
  static const String authPassword = 'Password';
  static const String authPasswordHint = 'Min. 8 characters';
  static const String authForgotPassword = 'Forgot password?';
  static const String authForgotPasswordEnterEmail = 'Enter your email first.';
  static const String authForgotPasswordEmailSent =
      'If an account exists for this email, we sent a password reset link.';
  static const String authOrContinueWith = 'or continue with';
  static const String authContinueWithGoogle = 'Continue with Google';

  // --- Auth error messages ---
  static const String authErrorInvalidEmail = 'The email address is not valid.';
  static const String authErrorUserNotFound =
      'No account found with this email.';
  static const String authErrorWrongPassword = 'Invalid email or password.';
  static const String authErrorEmailInUse =
      'An account with this email already exists.';
  static const String authErrorWeakPassword =
      'Password is too weak. Use at least 6 characters.';
  static const String authErrorAccountExistsDifferentCredential =
      'An account already exists with this email.';
  static const String authErrorTooManyRequests =
      'Too many attempts. Please try again later.';
  static const String authErrorGoogleConfig =
      'Google Sign-In is not configured for this build. Add your Android SHA-1 in Firebase and download an updated google-services.json.';
  static const String authErrorResetPassword =
      'Could not send the password reset email. Please try again.';

  // --- Error messages ---
  static const String errorGeneric = 'An unexpected error occurred.';
  static const String errorNoConnection = 'No internet connection.';
  static const String errorDocumentNoLocalCopyOffline =
      'There is no local copy of this document on your device.';
  static const String attachmentQueuedOffline =
      'No internet. Document saved locally and queued for upload.';
  static const String valueNotAvailable = 'Not available';
  static const String stateEnabled = 'Enabled';
  static const String stateDisabled = 'Disabled';
  static const String nounPets = 'pets';

  // --- Accessibility labels ---
  static const String semanticBackButton = 'Back';
  static const String semanticCloseButton = 'Close';
  static const String semanticContinueButton = 'Continue';
  static const String semanticAddPetButton = 'Add Pet';
  static const String semanticSaveButton = 'Save';
  static const String semanticGetStartedButton = 'Get Started';
  static const String semanticSkipButton = 'Skip';
  static const String semanticSignInButton = 'Sign in';
  static const String semanticAddVaccineButton = 'Add Vaccine';
  static const String semanticUpdateVaccineButton = 'Update Vaccine';
  static const String semanticAddEventButton = 'Add Event';

  // --- Page titles ---
  static const String addVaccineTitle = 'Add New Vaccine';
  static const String addEventTitle = 'Add New Event';
  static const String healthRecordsTitle = 'Health Records';
  static const String calendarTitle = 'Calendar';
  static const String calendarAllPets = 'All Pets';
  static const String calendarNoEventsForDay = 'No events for this day';
  static const String calendarNoEventsHint =
      'Choose another day or add a new event.';
  static const String calendarDateStripUnavailable =
      'Advanced filters are not available yet.';
  static const String calendarEventAnnualVaccination = 'Annual Vaccination';
  static const String calendarEventVetAppointment = 'Vet Appointment';
  static const String calendarEventDentalCleaning = 'Dental Cleaning';
  static const String calendarEventGroomingSession = 'Grooming Session';
  static const String calendarEventBoosterShot = 'Booster Shot';
  static const String calendarFilterAppointments = 'Appointments';
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
  static const String eventDetailsTitle = 'Event Details';
  static const String detailsSubtitle = 'Max • Dog';
  static const String vaccineStatusCompleted = 'Completed';
  static const String vaccineNameBordetella = 'Bordetella';
  static const String vaccineDateGivenValue = 'Sep 19, 2024';
  static const String vaccineNextDueValue = 'Sep 19, 2025';
  static const String vaccineVeterinarianValue = 'Dr. Smith';
  static const String vaccineClinicValue = 'Happy Paws Clinic';
  static const String vaccineTimelineTitle = 'Timeline';
  static const String vaccineDateGivenLabel = 'Date Given';
  static const String vaccineNextDueLabel = 'Next Due Date';
  static const String providerInfoTitle = 'Provider Information';
  static const String veterinarianLabel = 'Veterinarian';
  static const String clinicLabel = 'Clinic';
  static const String vaccineAttachedDocumentTitle = 'Attached Document';
  static const String vaccineNoDocuments = 'No documents attached';
  static const String eventNotesTitle = 'Notes';
  static const String eventDocumentsTitle = 'Documents';
  static const String eventNoNotes = 'No notes provided';
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
  static const String labelEventName = 'Event Name';
  static const String labelEventTime = 'Event Time';
  static const String labelEventType = 'Event Type';
  static const String labelEventPrice = 'Price';
  static const String labelEventProvider = 'Provider';
  static const String labelEventClinic = 'Clinic';
  static const String labelEventFollowUpDate = 'Follow-up Date';
  static const String labelDescription = 'Description';

  // --- Form field hints ---
  static const String hintVaccineName = 'e.g. Rabies';
  static const String hintDate = 'dd/mm/yyyy';
  static const String hintProductName = 'e.g. Rabisin';
  static const String hintPetName = 'Select a pet';
  static const String hintClinicProvider = 'e.g. City Vet Clinic';
  static const String hintDose = '1';
  static const String hintNotes = 'Optional notes';
  static const String hintNotProvided = 'Not provided';
  static const String hintAdministeredBy = 'e.g. Doctor Tatiana';
  static const String uploadDocuments = 'Upload Documents';
  static const String uploadHint = 'Tap to upload or take a photo';
  static const String attachmentSelectFile = 'Select File';
  static const String attachmentSelectFileSubtitle =
      'Choose a PDF or image from your device';
  static const String attachmentTakePhoto = 'Take Photo';
  static const String attachmentTakePhotoSubtitle =
      'Open the camera and attach it right away';
  static const String hintEventName = 'e.g. Vet Appointment';
  static const String hintEventTime = 'e.g. 9:00 AM';
  static const String hintEventType = 'e.g. vet_visit';
  static const String hintEventPrice = 'e.g. 120.00';
  static const String hintEventProvider = 'e.g. Dr. Smith';
  static const String hintEventClinic = 'e.g. Happy Paws Clinic';
  static const String hintEventDescription =
      'Optional description of the event';

  // --- Validation messages ---
  static const String validationRequired = 'This field is required.';
  static const String validationInvalidDate = 'Please enter a valid date.';
  static const String validationInvalidNumber = 'Please enter a valid number.';
  static const String validationFullNameRequired = 'Full name is required.';
  static const String validationEmailRequired = 'Email address is required.';
  static const String validationPasswordRequired = 'Password is required.';
  static const String validationPasswordTooShort =
      'Password must be at least 8 characters.';
  static const String validationPasswordUnsupportedCharacters =
      'Password cannot contain emojis or unsupported characters.';
  static const String validationPhoneInvalid =
      'Phone can only contain numbers and basic dialing characters.';
  static const String validationPetWeightMax =
      'Weight must be less than 100 kg.';
  static const String validationPriceMax = 'Price must be less than 1,000,000.';
  static const String validationSelectPet = 'Please select a pet.';
  static const String validationSelectValidPet = 'Please select a valid pet.';
  static const String validationSelectVaccine = 'Please select a vaccine name.';
  static const String validationSelectProduct =
      'Please select a vaccine product.';
  static const String validationSpeciesRequired = 'Please select a species.';
  static const String validationGenderRequired = 'Please select a gender.';

  // --- Step names ---
  static const String stepBasicInfo = 'Basic Info';
  static const String stepDetails = 'Details';
  static const String stepOverview = 'Overview';

  // --- Pets ---
  static const String petsTitle = 'My Pets';
  static const String petsEmpty = 'No pets yet';
  static const String petsEmptyFiltered = 'No pets match this filter';
  static const String petsRetry = 'Retry';
  static const String petsLoadError = 'Could not load pets. Please try again.';

  // --- Add pet ---
  static const String addPetTitle = 'Add New Pet';
  static const String addPetBackButton = 'Back';
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
  static const String addPetAllergiesHint = 'e.g. None, or Penicillin';
  static const String addPetValidationRequired = 'This field is required.';
  static const String addPetSavedMessage = 'Pet ready to be saved.';
  static const String editPetTitle = 'Edit Pet';
  static const String editPetSavedMessage = 'Pet updated successfully.';
  static const String petDeletedMessage = 'Pet deleted successfully.';
  static const String petDeleteConfirmTitle = 'Delete pet?';
  static const String petDeleteConfirmMessage = 'This action cannot be undone.';
  static const String petDeleteConfirmAction = 'Delete Pet';

  // --- Pet detail ---
  static const String petDetailTabOverview = 'Overview';
  static const String petDetailTabVaccines = 'Vaccines';
  static const String petDetailTabEvents = 'Events';
  static const String petDetailSectionPetInfo = 'Pet Information';
  static const String petDetailSectionHealthSummary = 'Health Summary';
  static const String petDetailSectionHealthAlerts = 'Health Alerts';
  static const String petDetailFieldSpecies = 'Species';
  static const String petDetailFieldBreed = 'Breed';
  static const String petDetailFieldDob = 'Date of Birth';
  static const String petDetailFieldAge = 'Age';
  static const String petDetailFieldWeight = 'Weight';
  static const String petDetailFieldColor = 'Color';
  static const String petDetailFieldGender = 'Gender';
  static const String petDetailFieldMicrochip = 'Microchip';
  static const String petDetailStatusHealthy = 'Healthy';
  static const String petDetailStatusNeedsAttention = 'Needs Attention';
  static const String petDetailStatusLost = 'Lost';
  static const String petLostConfirmTitle = 'Mark as lost?';
  static const String petLostConfirmMessage =
      'Are you sure you want to mark this pet as lost?';
  static const String petLostConfirmCancel = 'Cancel';
  static const String petLostConfirmAction = 'Mark Lost';
  static const String petMarkedAsLostMessage = 'Pet marked as lost.';
  static const String petMarkedAsFoundMessage = 'Pet marked as found.';
  static const String petDetailShareSemantics = 'Share pet';
  static const String petDetailEditSemantics = 'Edit pet';
  static const String petDetailMoreSemantics = 'More options';
  static const String petDetailMenuEdit = 'Edit';
  static const String petDetailMenuDelete = 'Delete';

  // --- Smart alerts ---
  static const String smartAlertsPageTitle = 'All alerts';
  static const String smartAlertsFilterAll = 'All';
  static const String smartAlertsEmpty =
      'No health alerts available right now.';
  static const String smartAlertsShowLess = 'Show less';

  // --- Welcome pages ---
  static const String welcomeFirstTitle =
      'All your pet\'s health, in one place.';
  static const String welcomeFirstDescription =
      'Centralize vaccines, medications, records, and documents. Never miss a dose or appointment again';
  static const String welcomeSecondTitle = 'Track vaccines & medications';
  static const String welcomeSecondDescription =
      'Timeline-based vaccine history, smart reminders for medications, and overdue alerts that keep you informed.';
  static const String welcomeThirdTitle = 'NFC tag integration';
  static const String welcomeThirdDescription =
      'Write your pet\'s info to an NFC tag. Anyone who finds your pet can contact you instantly.';
  static const String welcomeAlreadyHaveAccount = 'Already have an account?';

  // --- Profile page ---
  static const String profileSignOutError =
      'Could not sign out. Please try again.';
  static const String profileLoadError =
      'Could not load profile. Please try again.';
  static const String featureUnavailable = 'This section is not available yet.';
  static const String profileSubtitleAccount = 'Account';
  static const String profileEdit = 'Edit Profile';
  static const String profileEmail = 'Email';
  static const String profilePhone = 'Phone';
  static const String profileSubtitlePreferences = 'Preferences';
  static const String profileDarkMode = 'Dark Mode';
  static const String profileThemeMode = 'Theme';
  static const String profileThemeLight = 'Light';
  static const String profileThemeDark = 'Dark';
  static const String profileThemeSchedule = 'By Time';
  static const String profileThemeSensor = 'Auto';
  static const String profileThemeLightSubtitle = 'Always use the light theme';
  static const String profileThemeDarkSubtitle = 'Always use the dark theme';
  static const String profileThemeScheduleSubtitle =
      'Changes automatically during the day and night';
  static const String profileThemeSensorSubtitle =
      'Adapts to the light around you';
  static const String profileThemeModePickerTitle = 'Choose theme mode';
  static const String profileThemeSummaryLight = 'Light appearance';
  static const String profileThemeSummaryDark = 'Dark appearance';
  static const String profileThemeSummaryByTime =
      'Changes with the time of day';
  static const String profileThemeSummaryAuto =
      'Adjusts to the light around you';
  static const String profileThemeSummaryAutoFallback =
      'Adjusts automatically when possible';
  static const String profileNotifications = 'Notifications';
  static const String profileOffline = 'Offline Mode';
  static const String profileSubtitleSupport = 'Support';
  static const String profileSignOut = 'Sign Out';
  static const String profileEditTitle = 'Edit Profile';
  static const String profileAddress = 'Address';
  static const String profilePhoto = 'Profile Photo';
  static const String profilePhotoUrl = 'Profile Photo URL';
  static const String profileSelectFromGallery = 'Select from gallery';
  static const String profileChangePhoto = 'Change photo';
  static const String profileRemovePhoto = 'Remove photo';
  static const String profilePhotoPickError =
      'Could not open photo gallery. Please try again.';
  static const String profilePhotoUploadError =
      'Could not upload your photo. Please try again.';
  static const String profilePhotoUploading = 'Uploading photo...';
  static const String profileSaveChanges = 'Save Changes';
  static const String profileSaveSuccess = 'Profile updated successfully.';
  static const String profileSaveError =
      'Could not update profile. Please try again.';
  static const String profileReadOnlyGroupInfo =
      'Pets and family group are read-only in this section.';
  static const String profilePetsCount = 'Pets linked';
  static const String profileFamilyGroupCount = 'Family group linked';

  static String validationFieldTooLong(String fieldLabel, int maxLength) {
    return '$fieldLabel must be $maxLength characters or less.';
  }

  static String validationFieldTooShort(String fieldLabel, int minLength) {
    return '$fieldLabel must be at least $minLength characters.';
  }

  static String validationFieldContainsUnsupportedCharacters(
    String fieldLabel,
  ) {
    return '$fieldLabel cannot contain emojis or unsupported characters.';
  }

  static String validationFieldRequired(String fieldLabel) {
    return '$fieldLabel is required.';
  }

  static String validationNumberMustBeAtMost(String maxValue) {
    return 'Value must be at most $maxValue.';
  }
}
