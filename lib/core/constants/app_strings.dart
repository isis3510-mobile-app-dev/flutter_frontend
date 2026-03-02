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
  static const String semanticGetStartedButton = 'Get Started';
  static const String semanticSkipButton = 'Skip';
  static const String semanticSignInButton = 'Sign in';

  // --- Welcome pages ---
  static const String welcomeFirstTitle = 'All your pet\'s health, in one place.';
  static const String welcomeFirstDescription = 'Centralize vaccines, medications, records, and documents. Never miss a dose or appointment again.';
  static const String welcomeSecondTitle = 'Track vaccines & medications';
  static const String welcomeSecondDescription = 'Timeline-based vaccine history, smart reminders for medications, and overdue alerts that keep you informed.';
  static const String welcomeThirdTitle = 'NFC sharing anywhere';
  static const String welcomeThirdDescription = 'Write your pet\'s info to an NFC tag. Anyone who finds your pet can contact you instantly.';
  static const String welcomeAlreadyHaveAccount = 'Already have an account?';
}