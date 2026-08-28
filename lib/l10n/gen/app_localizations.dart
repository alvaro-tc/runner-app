import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// App name shown in the OS task switcher. Brand, not translated.
  ///
  /// In en, this message translates to:
  /// **'CamRun'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncStatusPending;

  /// No description provided for @syncStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Sync rejected'**
  String get syncStatusRejected;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get commonComingSoon;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get navTrain;

  /// No description provided for @navRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get navRaces;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Welcome screen headline. The line break is intentional.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nCamRun'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your training plan, your runs and your races — all in one place. Start where you are and build from there.'**
  String get authWelcomeBody;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'\'s Sign you in.'**
  String get authSignInTitle;

  /// No description provided for @authSignInWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInWelcomeBack;

  /// No description provided for @authSignInMissed.
  ///
  /// In en, this message translates to:
  /// **'You\'\'ve been missed!'**
  String get authSignInMissed;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get authIdentifierLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'pandu@camrun.app'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t have an account?'**
  String get authNoAccount;

  /// Snackbar shown when tapping a social sign-in button.
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in is coming soon. Use your email for now.'**
  String authSocialComingSoon(String provider);

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your\naccount.'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two minutes now, and every run you take from here is counted.'**
  String get authSignUpSubtitle;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Pandu Wirawan'**
  String get authFullNameHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Type it once more'**
  String get authConfirmPasswordHint;

  /// No description provided for @authAcceptTermsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Accept terms and privacy policy'**
  String get authAcceptTermsSemantics;

  /// No description provided for @authAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the terms of service and the privacy policy.'**
  String get authAcceptTerms;

  /// No description provided for @authAcceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept the terms to create your account.'**
  String get authAcceptTermsRequired;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your\npassword.'**
  String get authForgotTitle;

  /// No description provided for @authForgotIntro.
  ///
  /// In en, this message translates to:
  /// **'Give us the email on your account and we will send a link to set a new password.'**
  String get authForgotIntro;

  /// No description provided for @authForgotSent.
  ///
  /// In en, this message translates to:
  /// **'Check {email}. The link works for one hour; request another if it expires.'**
  String authForgotSent(String email);

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get authSendAgain;

  /// No description provided for @validationEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with.'**
  String get validationEmailEmpty;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get validationEmailInvalid;

  /// No description provided for @validationIdentifierEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email.'**
  String get validationIdentifierEmpty;

  /// No description provided for @validationPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordEmpty;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get validationPasswordTooShort;

  /// No description provided for @validationConfirmEmpty.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password.'**
  String get validationConfirmEmpty;

  /// No description provided for @validationConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get validationConfirmMismatch;

  /// No description provided for @validationFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get validationFullNameRequired;

  /// No description provided for @validationDistanceNotANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the distance as a number.'**
  String get validationDistanceNotANumber;

  /// No description provided for @validationDistanceNotPositive.
  ///
  /// In en, this message translates to:
  /// **'The distance has to be greater than zero.'**
  String get validationDistanceNotPositive;

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'We could not reach the server. Check your connection and try again.'**
  String get failureNetwork;

  /// No description provided for @failureCache.
  ///
  /// In en, this message translates to:
  /// **'Stored data could not be read. Pull to refresh.'**
  String get failureCache;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you asked for.'**
  String get failureNotFound;

  /// No description provided for @failurePermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off. Enable it to record your route.'**
  String get failurePermission;

  /// No description provided for @failureUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something broke on our side. Try again in a moment.'**
  String get failureUnexpected;

  /// No description provided for @failureSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get failureSessionExpired;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Train with a plan that adapts'**
  String get onboardingPlanTitle;

  /// No description provided for @onboardingPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Tell CamRun the race you are chasing. It lays out the weeks, moves sessions when life gets in the way, and keeps the goal in sight.'**
  String get onboardingPlanBody;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every run in real time'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackBody.
  ///
  /// In en, this message translates to:
  /// **'GPS draws your route as you go. Pace, splits and elapsed time stay on screen, so you always know whether to push or hold back.'**
  String get onboardingTrackBody;

  /// No description provided for @onboardingRaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Race, and keep every medal'**
  String get onboardingRaceTitle;

  /// No description provided for @onboardingRaceBody.
  ///
  /// In en, this message translates to:
  /// **'Enter events from inside the app, then keep your bib, your finish time and your splits together in one place.'**
  String get onboardingRaceBody;

  /// No description provided for @homeUpcomingMarathon.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Marathon In'**
  String get homeUpcomingMarathon;

  /// No description provided for @homePlanTitleOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'\'s Training Plan'**
  String homePlanTitleOf(String name);

  /// No description provided for @homePlanTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your Training Plan'**
  String get homePlanTitleGeneric;

  /// No description provided for @homeTrainingWeek.
  ///
  /// In en, this message translates to:
  /// **'Training Week {week}'**
  String homeTrainingWeek(int week);

  /// No description provided for @homeRescheduleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rescheduling arrives with the plan editor. Start the run whenever suits you today.'**
  String get homeRescheduleComingSoon;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonSplits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get commonSplits;

  /// No description provided for @commonDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get commonDistance;

  /// No description provided for @commonTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get commonTime;

  /// No description provided for @commonAveragePace.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get commonAveragePace;

  /// No description provided for @commonAverageSpeed.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get commonAverageSpeed;

  /// No description provided for @commonElevationGain.
  ///
  /// In en, this message translates to:
  /// **'Elevation gain'**
  String get commonElevationGain;

  /// No description provided for @commonCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get commonCalories;

  /// No description provided for @commonFinishTime.
  ///
  /// In en, this message translates to:
  /// **'Finish time'**
  String get commonFinishTime;

  /// No description provided for @commonBib.
  ///
  /// In en, this message translates to:
  /// **'BIB {number}'**
  String commonBib(String number);

  /// No description provided for @commonMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get commonMoreOptions;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'That did not load'**
  String get stateErrorTitle;

  /// No description provided for @stateSocialContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {provider}'**
  String stateSocialContinueWith(String provider);

  /// No description provided for @sessionTypeEasy.
  ///
  /// In en, this message translates to:
  /// **'Run Easy'**
  String get sessionTypeEasy;

  /// No description provided for @sessionTypeTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get sessionTypeTempo;

  /// No description provided for @sessionTypeIntervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get sessionTypeIntervals;

  /// No description provided for @sessionTypeRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get sessionTypeRecovery;

  /// No description provided for @sessionTypeLong.
  ///
  /// In en, this message translates to:
  /// **'Long Run'**
  String get sessionTypeLong;

  /// No description provided for @sessionTypeRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get sessionTypeRest;

  /// No description provided for @sessionTypeRace.
  ///
  /// In en, this message translates to:
  /// **'Race Day'**
  String get sessionTypeRace;

  /// No description provided for @sessionRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get sessionRestDay;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'{km}km {type}'**
  String sessionTitle(int km, String type);

  /// No description provided for @runTitleMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning Run'**
  String get runTitleMorning;

  /// No description provided for @runTitleLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch Run'**
  String get runTitleLunch;

  /// No description provided for @runTitleAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon Run'**
  String get runTitleAfternoon;

  /// No description provided for @runTitleEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening Run'**
  String get runTitleEvening;

  /// No description provided for @runTitleTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo Run'**
  String get runTitleTempo;

  /// No description provided for @runTitleLong.
  ///
  /// In en, this message translates to:
  /// **'Long Run'**
  String get runTitleLong;

  /// No description provided for @runTitleTrackSession.
  ///
  /// In en, this message translates to:
  /// **'Track Session'**
  String get runTitleTrackSession;

  /// No description provided for @feelingRough.
  ///
  /// In en, this message translates to:
  /// **'Rough'**
  String get feelingRough;

  /// No description provided for @feelingOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get feelingOkay;

  /// No description provided for @feelingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get feelingGood;

  /// No description provided for @feelingStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get feelingStrong;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUndisclosed;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @raceEntryStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get raceEntryStatusUpcoming;

  /// No description provided for @raceEntryStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get raceEntryStatusCompleted;

  /// No description provided for @raceEntryStatusDnf.
  ///
  /// In en, this message translates to:
  /// **'Did not finish'**
  String get raceEntryStatusDnf;

  /// No description provided for @raceEntryStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get raceEntryStatusCancelled;

  /// No description provided for @registrationStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Registration open'**
  String get registrationStatusOpen;

  /// No description provided for @registrationStatusClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get registrationStatusClosingSoon;

  /// No description provided for @registrationStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get registrationStatusFull;

  /// No description provided for @registrationStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Registration closed'**
  String get registrationStatusClosed;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get paymentMethodQr;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was declined. Grant it to record your route.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for CamRun. Turn it on in system settings, then come back.'**
  String get locationDeniedForever;

  /// No description provided for @locationBackgroundDenied.
  ///
  /// In en, this message translates to:
  /// **'Background location is off. Recording keeps working while CamRun is on screen, but may stop if you switch apps.'**
  String get locationBackgroundDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this device. Switch them on to start a run.'**
  String get locationServiceDisabled;

  /// No description provided for @trainNoRunsTitle.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get trainNoRunsTitle;

  /// No description provided for @trainNoRunsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your first one starts here. Pick a goal and head out.'**
  String get trainNoRunsMessage;

  /// No description provided for @trainNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches those filters. Widen them to see more.'**
  String get trainNoMatchesMessage;

  /// No description provided for @trainStartTraining.
  ///
  /// In en, this message translates to:
  /// **'Start training'**
  String get trainStartTraining;

  /// No description provided for @trainClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get trainClearFilters;

  /// No description provided for @trainReadyToRun.
  ///
  /// In en, this message translates to:
  /// **'Ready to run?'**
  String get trainReadyToRun;

  /// No description provided for @trainNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today. A free run still counts.'**
  String get trainNothingScheduled;

  /// No description provided for @trainTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s plan: {title} · {duration}'**
  String trainTodaysPlan(String title, String duration);

  /// No description provided for @trainFreeRun.
  ///
  /// In en, this message translates to:
  /// **'Free run'**
  String get trainFreeRun;

  /// No description provided for @trainThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get trainThisWeek;

  /// No description provided for @trainLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get trainLastWeek;

  /// No description provided for @trainHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get trainHistory;

  /// No description provided for @trainSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get trainSessions;

  /// No description provided for @filterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get filterAllTime;

  /// No description provided for @filterLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30;

  /// No description provided for @filterLast90.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get filterLast90;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your run'**
  String get setupTitle;

  /// No description provided for @setupWhatAreYouRunning.
  ///
  /// In en, this message translates to:
  /// **'What are you running?'**
  String get setupWhatAreYouRunning;

  /// No description provided for @setupFreeRunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No target. Just go and let CamRun record it.'**
  String get setupFreeRunSubtitle;

  /// No description provided for @setupPlanSession.
  ///
  /// In en, this message translates to:
  /// **'Plan session'**
  String get setupPlanSession;

  /// No description provided for @setupDistanceGoal.
  ///
  /// In en, this message translates to:
  /// **'Distance goal'**
  String get setupDistanceGoal;

  /// No description provided for @setupDistanceGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run until you hit a set distance.'**
  String get setupDistanceGoalSubtitle;

  /// No description provided for @setupTimeGoal.
  ///
  /// In en, this message translates to:
  /// **'Time goal'**
  String get setupTimeGoal;

  /// No description provided for @setupTimeGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run for a set amount of time.'**
  String get setupTimeGoalSubtitle;

  /// No description provided for @setupLocationReady.
  ///
  /// In en, this message translates to:
  /// **'Location ready'**
  String get setupLocationReady;

  /// No description provided for @setupLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Location access'**
  String get setupLocationAccess;

  /// No description provided for @setupLocationGrantedBody.
  ///
  /// In en, this message translates to:
  /// **'CamRun can draw your route while you run.'**
  String get setupLocationGrantedBody;

  /// No description provided for @setupLocationRationale.
  ///
  /// In en, this message translates to:
  /// **'CamRun reads your position only while a run is recording, and stores the route on this device.'**
  String get setupLocationRationale;

  /// No description provided for @setupAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get setupAllowLocation;

  /// No description provided for @setupBackgroundLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location in the background'**
  String get setupBackgroundLocationTitle;

  /// No description provided for @setupBackgroundLocationBody.
  ///
  /// In en, this message translates to:
  /// **'To keep drawing your route with the screen off, CamRun needs location access while it runs in the background. It only reads your position while a run is recording.'**
  String get setupBackgroundLocationBody;

  /// No description provided for @setupBackgroundLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupBackgroundLocationContinue;

  /// No description provided for @setupStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get setupStartRun;

  /// No description provided for @goalDistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'{distance} goal'**
  String goalDistanceTitle(String distance);

  /// No description provided for @goalTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'{duration} goal'**
  String goalTimeTitle(String duration);

  /// No description provided for @runDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this run?'**
  String get runDiscardTitle;

  /// No description provided for @runDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You have been running for a while. Leaving now throws away the route and the time you have logged.'**
  String get runDiscardBody;

  /// No description provided for @runKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get runKeepRunning;

  /// No description provided for @runLeaveSemantics.
  ///
  /// In en, this message translates to:
  /// **'Leave the run'**
  String get runLeaveSemantics;

  /// No description provided for @runRecentre.
  ///
  /// In en, this message translates to:
  /// **'Re-centre the map'**
  String get runRecentre;

  /// No description provided for @runSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Running Session'**
  String get runSessionTitle;

  /// No description provided for @runSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Run settings arrive next. Pause and finish work from the sheet below.'**
  String get runSettingsComingSoon;

  /// No description provided for @runLapProgress.
  ///
  /// In en, this message translates to:
  /// **'Lap {done}/{total}'**
  String runLapProgress(int done, int total);

  /// No description provided for @runNextLap.
  ///
  /// In en, this message translates to:
  /// **'Next: {metres}m @ {pace} pace'**
  String runNextLap(int metres, String pace);

  /// No description provided for @runLapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Lap {done} of {total}'**
  String runLapSemantics(int done, int total);

  /// No description provided for @runElapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get runElapsedTime;

  /// No description provided for @runCurrentPace.
  ///
  /// In en, this message translates to:
  /// **'Current Pace'**
  String get runCurrentPace;

  /// No description provided for @runLastKm.
  ///
  /// In en, this message translates to:
  /// **'Last km'**
  String get runLastKm;

  /// No description provided for @runElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get runElevation;

  /// No description provided for @runTotalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get runTotalDistance;

  /// No description provided for @runSplitKm.
  ///
  /// In en, this message translates to:
  /// **'km {km}'**
  String runSplitKm(int km);

  /// No description provided for @runResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get runResume;

  /// No description provided for @runPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runPause;

  /// No description provided for @runMusicSemantics.
  ///
  /// In en, this message translates to:
  /// **'Music controls'**
  String get runMusicSemantics;

  /// No description provided for @runMusicComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Music controls hook into your player in a later release.'**
  String get runMusicComingSoon;

  /// No description provided for @runCountdownGo.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get runCountdownGo;

  /// No description provided for @runHoldToFinishSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hold to finish the run'**
  String get runHoldToFinishSemantics;

  /// No description provided for @runKeepHolding.
  ///
  /// In en, this message translates to:
  /// **'Keep holding…'**
  String get runKeepHolding;

  /// No description provided for @runHoldToFinish.
  ///
  /// In en, this message translates to:
  /// **'Hold to finish'**
  String get runHoldToFinish;

  /// No description provided for @summarySaved.
  ///
  /// In en, this message translates to:
  /// **'Run saved'**
  String get summarySaved;

  /// No description provided for @summaryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this run?'**
  String get summaryDeleteTitle;

  /// No description provided for @summaryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The route, the splits and the time all go with it. This cannot be undone.'**
  String get summaryDeleteBody;

  /// No description provided for @summaryDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing about this run will be kept.'**
  String get summaryDiscardBody;

  /// No description provided for @summaryKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get summaryKeepIt;

  /// No description provided for @summaryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Run detail'**
  String get summaryDetailTitle;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Run summary'**
  String get summaryTitle;

  /// No description provided for @summaryNotInHistory.
  ///
  /// In en, this message translates to:
  /// **'That run is not in your history any more.'**
  String get summaryNotInHistory;

  /// No description provided for @summaryHowDidItFeel.
  ///
  /// In en, this message translates to:
  /// **'How did it feel?'**
  String get summaryHowDidItFeel;

  /// No description provided for @summaryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get summaryNotesLabel;

  /// No description provided for @summaryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Legs, weather, anything worth remembering'**
  String get summaryNotesHint;

  /// No description provided for @summarySaveRun.
  ///
  /// In en, this message translates to:
  /// **'Save run'**
  String get summarySaveRun;

  /// No description provided for @summaryYourNotes.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get summaryYourNotes;

  /// No description provided for @summaryDeleteRun.
  ///
  /// In en, this message translates to:
  /// **'Delete this run'**
  String get summaryDeleteRun;

  /// No description provided for @splitsTooShort.
  ///
  /// In en, this message translates to:
  /// **'This run was shorter than a kilometre, so there are no splits yet.'**
  String get splitsTooShort;

  /// No description provided for @splitsFastestKm.
  ///
  /// In en, this message translates to:
  /// **'Fastest km'**
  String get splitsFastestKm;

  /// No description provided for @splitsUnderAverage.
  ///
  /// In en, this message translates to:
  /// **'Under average'**
  String get splitsUnderAverage;

  /// No description provided for @splitsOverAverage.
  ///
  /// In en, this message translates to:
  /// **'Over average'**
  String get splitsOverAverage;

  /// No description provided for @racesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Races'**
  String get racesTitle;

  /// No description provided for @racesUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get racesUpcoming;

  /// No description provided for @racesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get racesCompleted;

  /// No description provided for @racesNoFinishesTitle.
  ///
  /// In en, this message translates to:
  /// **'No finishes yet'**
  String get racesNoFinishesTitle;

  /// No description provided for @racesNoRacesTitle.
  ///
  /// In en, this message translates to:
  /// **'No races yet'**
  String get racesNoRacesTitle;

  /// No description provided for @racesNoFinishesMessage.
  ///
  /// In en, this message translates to:
  /// **'Cross a start line and your result lands here.'**
  String get racesNoFinishesMessage;

  /// No description provided for @racesNoRacesMessage.
  ///
  /// In en, this message translates to:
  /// **'Find one and pin your first bib.'**
  String get racesNoRacesMessage;

  /// No description provided for @racesBrowseEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse events'**
  String get racesBrowseEvents;

  /// No description provided for @racesJoined.
  ///
  /// In en, this message translates to:
  /// **'Races joined'**
  String get racesJoined;

  /// No description provided for @racesDistanceRaced.
  ///
  /// In en, this message translates to:
  /// **'Distance raced'**
  String get racesDistanceRaced;

  /// No description provided for @racesTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get racesTotalSpent;

  /// No description provided for @racesNoMarathonYet.
  ///
  /// In en, this message translates to:
  /// **'No marathon finish recorded yet.'**
  String get racesNoMarathonYet;

  /// No description provided for @racesBestMarathon.
  ///
  /// In en, this message translates to:
  /// **'Best marathon: {time}'**
  String racesBestMarathon(String time);

  /// No description provided for @racesPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String racesPaidAmount(String amount);

  /// No description provided for @racesAvgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get racesAvgPace;

  /// No description provided for @racesOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String racesOfTotal(int total);

  /// No description provided for @racesViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get racesViewDetails;

  /// No description provided for @raceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'My race'**
  String get raceDetailTitle;

  /// No description provided for @raceDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find that registration.'**
  String get raceDetailNotFound;

  /// No description provided for @raceCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this registration?'**
  String get raceCancelTitle;

  /// No description provided for @raceCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Your place at {marathon} is released and the entry fee is refunded to {method}. Re-entry depends on availability.'**
  String raceCancelBody(String marathon, String method);

  /// No description provided for @raceKeepMyPlace.
  ///
  /// In en, this message translates to:
  /// **'Keep my place'**
  String get raceKeepMyPlace;

  /// No description provided for @raceCancelEntry.
  ///
  /// In en, this message translates to:
  /// **'Cancel entry'**
  String get raceCancelEntry;

  /// No description provided for @raceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Registration cancelled. Refund on its way.'**
  String get raceCancelled;

  /// No description provided for @raceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get raceRegistration;

  /// No description provided for @raceRegisteredOn.
  ///
  /// In en, this message translates to:
  /// **'Registered on'**
  String get raceRegisteredOn;

  /// No description provided for @raceAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get raceAmountPaid;

  /// No description provided for @raceMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get raceMethod;

  /// No description provided for @raceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get raceStatus;

  /// No description provided for @raceDownloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get raceDownloadReceipt;

  /// No description provided for @raceReceiptComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Receipts download once the billing service is connected.'**
  String get raceReceiptComingSoon;

  /// No description provided for @raceShareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get raceShareResult;

  /// No description provided for @raceShareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'A shareable finisher card is on the way.'**
  String get raceShareComingSoon;

  /// No description provided for @raceGoToStartLine.
  ///
  /// In en, this message translates to:
  /// **'Go to the start line'**
  String get raceGoToStartLine;

  /// No description provided for @raceCancelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration'**
  String get raceCancelRegistration;

  /// No description provided for @raceChipTime.
  ///
  /// In en, this message translates to:
  /// **'Chip time'**
  String get raceChipTime;

  /// No description provided for @raceBestKm.
  ///
  /// In en, this message translates to:
  /// **'Best km'**
  String get raceBestKm;

  /// No description provided for @raceOverallRank.
  ///
  /// In en, this message translates to:
  /// **'Overall rank'**
  String get raceOverallRank;

  /// No description provided for @raceAgeGroupRank.
  ///
  /// In en, this message translates to:
  /// **'Age group rank'**
  String get raceAgeGroupRank;

  /// No description provided for @raceStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get raceStartsIn;

  /// No description provided for @raceKitCollection.
  ///
  /// In en, this message translates to:
  /// **'Kit collection'**
  String get raceKitCollection;

  /// No description provided for @raceKitCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expo opens two days before, 10:00–20:00'**
  String get raceKitCollectionSubtitle;

  /// No description provided for @raceStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get raceStartTime;

  /// No description provided for @raceStartTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Corrals close 20 minutes before your wave'**
  String get raceStartTimeSubtitle;

  /// No description provided for @raceBagDrop.
  ///
  /// In en, this message translates to:
  /// **'Bag drop'**
  String get raceBagDrop;

  /// No description provided for @raceBagDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At the start village, opens 90 minutes prior'**
  String get raceBagDropSubtitle;

  /// No description provided for @raceDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Race day'**
  String get raceDayTitle;

  /// No description provided for @raceDayNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'We could not load that race.'**
  String get raceDayNotLoaded;

  /// No description provided for @raceDayCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'The official course is on the map'**
  String get raceDayCourseTitle;

  /// No description provided for @raceDayCourseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your live track is drawn on top of it as you run'**
  String get raceDayCourseSubtitle;

  /// No description provided for @raceDayPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your position is sent while you run'**
  String get raceDayPositionTitle;

  /// No description provided for @raceDayPositionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In batches, so the battery lasts the whole race'**
  String get raceDayPositionSubtitle;

  /// No description provided for @raceDaySignalTitle.
  ///
  /// In en, this message translates to:
  /// **'Losing signal is fine'**
  String get raceDaySignalTitle;

  /// No description provided for @raceDaySignalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Points are stored on the phone and uploaded later'**
  String get raceDaySignalSubtitle;

  /// No description provided for @raceDayStart.
  ///
  /// In en, this message translates to:
  /// **'Start the race'**
  String get raceDayStart;

  /// No description provided for @raceDayAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'You already finished this race.'**
  String get raceDayAlreadyFinished;

  /// No description provided for @raceDayNotReady.
  ///
  /// In en, this message translates to:
  /// **'This race is not ready to start. Check that your entry is paid and confirmed.'**
  String get raceDayNotReady;

  /// No description provided for @marathonAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get marathonAbout;

  /// No description provided for @marathonRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get marathonRoute;

  /// No description provided for @marathonSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get marathonSchedule;

  /// No description provided for @marathonWhatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'\'s included'**
  String get marathonWhatsIncluded;

  /// No description provided for @marathonEntryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get marathonEntryFee;

  /// No description provided for @marathonPlacesLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {total} places left'**
  String marathonPlacesLeft(int left, int total);

  /// No description provided for @marathonRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get marathonRegisterNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registerTitle;

  /// No description provided for @registerStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get registerStepDetails;

  /// No description provided for @registerStepCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get registerStepCategory;

  /// No description provided for @registerStepPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get registerStepPay;

  /// No description provided for @registerYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get registerYourDetails;

  /// No description provided for @registerFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Taken from your profile. Change them in Profile if anything is out of date.'**
  String get registerFromProfile;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullName;

  /// No description provided for @registerDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get registerDateOfBirth;

  /// No description provided for @registerGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get registerGender;

  /// No description provided for @registerIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get registerIdNumber;

  /// No description provided for @registerIdNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Goes on your bib record'**
  String get registerIdNumberHint;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registerPhone;

  /// No description provided for @registerEmergencyName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact name'**
  String get registerEmergencyName;

  /// No description provided for @registerEmergencyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Who should we call?'**
  String get registerEmergencyNameHint;

  /// No description provided for @registerEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get registerEmergencyPhone;

  /// No description provided for @registerShirtSize.
  ///
  /// In en, this message translates to:
  /// **'Shirt size'**
  String get registerShirtSize;

  /// No description provided for @registerCategoryAndExtras.
  ///
  /// In en, this message translates to:
  /// **'Category & extras'**
  String get registerCategoryAndExtras;

  /// No description provided for @registerSingleDistance.
  ///
  /// In en, this message translates to:
  /// **'This event runs a single distance: {distance}.'**
  String registerSingleDistance(String distance);

  /// No description provided for @registerIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get registerIncluded;

  /// No description provided for @registerOptionalExtras.
  ///
  /// In en, this message translates to:
  /// **'Optional extras'**
  String get registerOptionalExtras;

  /// No description provided for @registerNoExtras.
  ///
  /// In en, this message translates to:
  /// **'No add-ons for this event.'**
  String get registerNoExtras;

  /// No description provided for @registerReviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & pay'**
  String get registerReviewAndPay;

  /// No description provided for @registerLineWithQuantity.
  ///
  /// In en, this message translates to:
  /// **'{label} × {quantity}'**
  String registerLineWithQuantity(String label, int quantity);

  /// No description provided for @registerServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get registerServiceFee;

  /// No description provided for @registerPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get registerPaymentMethod;

  /// No description provided for @registerCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charged the moment your place is taken'**
  String get registerCardSubtitle;

  /// No description provided for @registerQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan and pay; we wait for the bank'**
  String get registerQrSubtitle;

  /// No description provided for @registerBankTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer and wait for the organiser to confirm'**
  String get registerBankTransferSubtitle;

  /// No description provided for @registerAcceptTermsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Accept event terms'**
  String get registerAcceptTermsSemantics;

  /// No description provided for @registerAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the event rules and the refund policy.'**
  String get registerAcceptTerms;

  /// No description provided for @registerTryAnotherCard.
  ///
  /// In en, this message translates to:
  /// **'Try another card'**
  String get registerTryAnotherCard;

  /// No description provided for @registerPayAndRegister.
  ///
  /// In en, this message translates to:
  /// **'Pay and register'**
  String get registerPayAndRegister;

  /// No description provided for @registerCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get registerCardNumber;

  /// No description provided for @registerCardholder.
  ///
  /// In en, this message translates to:
  /// **'Cardholder'**
  String get registerCardholder;

  /// No description provided for @registerCardholderHint.
  ///
  /// In en, this message translates to:
  /// **'As printed on the card'**
  String get registerCardholderHint;

  /// No description provided for @registerExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get registerExpiry;

  /// No description provided for @registerExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get registerExpiryHint;

  /// No description provided for @registerCvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get registerCvv;

  /// No description provided for @registerReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {reference}'**
  String registerReference(String reference);

  /// No description provided for @registerWaitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the payment to clear…'**
  String get registerWaitingForPayment;

  /// No description provided for @registerSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'\'re in'**
  String get registerSuccessTitle;

  /// No description provided for @registerSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your place at {marathon} is confirmed.'**
  String registerSuccessBody(String marathon);

  /// No description provided for @registerViewMyRace.
  ///
  /// In en, this message translates to:
  /// **'View my race'**
  String get registerViewMyRace;

  /// No description provided for @registerBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get registerBackToHome;

  /// No description provided for @registerDefaultRunnerName.
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get registerDefaultRunnerName;

  /// No description provided for @registerDefaultCardHolder.
  ///
  /// In en, this message translates to:
  /// **'CAMRUN RUNNER'**
  String get registerDefaultCardHolder;

  /// No description provided for @paymentCardDeclined.
  ///
  /// In en, this message translates to:
  /// **'The bank turned this card down. Try another one.'**
  String get paymentCardDeclined;

  /// No description provided for @paymentExpiredCard.
  ///
  /// In en, this message translates to:
  /// **'That card is expired.'**
  String get paymentExpiredCard;

  /// No description provided for @paymentInvalidCard.
  ///
  /// In en, this message translates to:
  /// **'Those card details do not look right.'**
  String get paymentInvalidCard;

  /// No description provided for @paymentQrExpired.
  ///
  /// In en, this message translates to:
  /// **'The QR expired before it was paid. Generate a new one.'**
  String get paymentQrExpired;

  /// No description provided for @paymentFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed.'**
  String get paymentFailedGeneric;

  /// No description provided for @profileLogOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogOutTitle;

  /// No description provided for @profileLogOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your runs stay on this device. You will need to sign in again to pick up where you left off.'**
  String get profileLogOutBody;

  /// No description provided for @profileStaySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get profileStaySignedIn;

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogOut;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileYourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get profileYourWeek;

  /// No description provided for @profileInjuryFlags.
  ///
  /// In en, this message translates to:
  /// **'Injury Flags'**
  String get profileInjuryFlags;

  /// No description provided for @profileSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get profileSleep;

  /// No description provided for @profileSleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avg in last 7 days'**
  String get profileSleepSubtitle;

  /// No description provided for @profileHydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration Habit'**
  String get profileHydration;

  /// No description provided for @profileHydrationLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get profileHydrationLow;

  /// No description provided for @profileHydrationModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get profileHydrationModerate;

  /// No description provided for @profileHydrationHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get profileHydrationHigh;

  /// No description provided for @profileInjuryNone.
  ///
  /// In en, this message translates to:
  /// **'None reported'**
  String get profileInjuryNone;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get profileUnits;

  /// No description provided for @profileNotificationsPrivacyHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications, privacy and help'**
  String get profileNotificationsPrivacyHelp;

  /// No description provided for @profileStatsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Extended statistics land with the next training report.'**
  String get profileStatsComingSoon;

  /// No description provided for @profileRunningHighlight.
  ///
  /// In en, this message translates to:
  /// **'Running Highlight'**
  String get profileRunningHighlight;

  /// No description provided for @profileWeeklyMileage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Mileage'**
  String get profileWeeklyMileage;

  /// No description provided for @profileLongestRun.
  ///
  /// In en, this message translates to:
  /// **'Longest Run'**
  String get profileLongestRun;

  /// No description provided for @profilePrimaryShoes.
  ///
  /// In en, this message translates to:
  /// **'Primary Shoes'**
  String get profilePrimaryShoes;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLightDetail.
  ///
  /// In en, this message translates to:
  /// **'Bright surfaces, best in daylight.'**
  String get themeLightDetail;

  /// No description provided for @themeDarkDetail.
  ///
  /// In en, this message translates to:
  /// **'Easier on the eyes for evening runs.'**
  String get themeDarkDetail;

  /// No description provided for @themeSystemDetail.
  ///
  /// In en, this message translates to:
  /// **'Follows whatever your phone is set to.'**
  String get themeSystemDetail;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSpanishDetail.
  ///
  /// In en, this message translates to:
  /// **'The whole app in Spanish.'**
  String get languageSpanishDetail;

  /// No description provided for @languageEnglishDetail.
  ///
  /// In en, this message translates to:
  /// **'The whole app in English.'**
  String get languageEnglishDetail;

  /// No description provided for @languageSystemDetail.
  ///
  /// In en, this message translates to:
  /// **'Follows whatever your phone is set to.'**
  String get languageSystemDetail;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPlanReminders.
  ///
  /// In en, this message translates to:
  /// **'Plan reminders'**
  String get settingsPlanReminders;

  /// No description provided for @settingsPlanRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A nudge the morning of each session'**
  String get settingsPlanRemindersSubtitle;

  /// No description provided for @settingsRaceUpdates.
  ///
  /// In en, this message translates to:
  /// **'Race updates'**
  String get settingsRaceUpdates;

  /// No description provided for @settingsRaceUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kit collection, start times and results'**
  String get settingsRaceUpdatesSubtitle;

  /// No description provided for @settingsWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get settingsWeeklyReport;

  /// No description provided for @settingsWeeklyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your mileage summary every Monday'**
  String get settingsWeeklyReportSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsShareActivity.
  ///
  /// In en, this message translates to:
  /// **'Share activity'**
  String get settingsShareActivity;

  /// No description provided for @settingsShareActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let other runners see your finished runs'**
  String get settingsShareActivitySubtitle;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get settingsExportData;

  /// No description provided for @settingsExportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Data export runs from the account service, coming soon.'**
  String get settingsExportComingSoon;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsDistanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance unit'**
  String get settingsDistanceUnit;

  /// No description provided for @settingsKilometres.
  ///
  /// In en, this message translates to:
  /// **'Kilometres'**
  String get settingsKilometres;

  /// No description provided for @settingsMiles.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get settingsMiles;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsHelpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get settingsHelpCentre;

  /// No description provided for @settingsHelpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The help centre opens in your browser once support is live.'**
  String get settingsHelpComingSoon;

  /// No description provided for @settingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContactSupport;

  /// No description provided for @settingsContactComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Write to support@camrun.app and we will answer within a day.'**
  String get settingsContactComingSoon;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editDiscardTitle;

  /// No description provided for @editDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You have edits that are not saved yet. Leaving now loses them.'**
  String get editDiscardBody;

  /// No description provided for @editKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editKeepEditing;

  /// No description provided for @editProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileUpdated;

  /// No description provided for @editPhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get editPhotoFromGallery;

  /// No description provided for @editPhotoTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get editPhotoTakePhoto;

  /// No description provided for @editPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get editPhotoUpdated;

  /// No description provided for @editChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editChangePhoto;

  /// No description provided for @editCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editCity;

  /// No description provided for @editCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get editCountry;

  /// No description provided for @editPickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get editPickADate;

  /// No description provided for @editWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get editWeightKg;

  /// No description provided for @editHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get editHeightCm;

  /// No description provided for @editSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editSaveChanges;

  /// No description provided for @validationCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your city.'**
  String get validationCityRequired;

  /// No description provided for @validationWeightNotANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight as a number.'**
  String get validationWeightNotANumber;

  /// No description provided for @validationWeightNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Your weight has to be greater than zero.'**
  String get validationWeightNotPositive;

  /// No description provided for @validationHeightNotANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your height as a number.'**
  String get validationHeightNotANumber;

  /// No description provided for @validationHeightNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Your height has to be greater than zero.'**
  String get validationHeightNotPositive;

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get relativeToday;

  /// No description provided for @relativeInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days}d'**
  String relativeInDays(int days);

  /// No description provided for @relativeInHours.
  ///
  /// In en, this message translates to:
  /// **'in {hours}h'**
  String relativeInHours(int hours);

  /// No description provided for @relativeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes}m'**
  String relativeInMinutes(int minutes);

  /// No description provided for @homeMarkSessionDone.
  ///
  /// In en, this message translates to:
  /// **'Mark {session} as done'**
  String homeMarkSessionDone(String session);

  /// No description provided for @homeReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get homeReschedule;

  /// No description provided for @homeStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start Run'**
  String get homeStartRun;

  /// No description provided for @fieldShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get fieldShowPassword;

  /// No description provided for @fieldHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get fieldHidePassword;

  /// No description provided for @countdownSemantics.
  ///
  /// In en, this message translates to:
  /// **'Starts in {days} days {hours} hours {minutes} minutes'**
  String countdownSemantics(String days, String hours, String minutes);

  /// No description provided for @daySemanticsRest.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, rest day'**
  String daySemanticsRest(String weekday);

  /// No description provided for @daySemanticsProgress.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {label} {percent} percent done'**
  String daySemanticsProgress(String weekday, String label, int percent);

  /// No description provided for @marathonPredictedFinish.
  ///
  /// In en, this message translates to:
  /// **'Predicted finish time {range}'**
  String marathonPredictedFinish(String range);

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @authIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID number (CI)'**
  String get authIdLabel;

  /// No description provided for @authIdHint.
  ///
  /// In en, this message translates to:
  /// **'1234567 LP'**
  String get authIdHint;

  /// No description provided for @authEmailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get authEmailOptionalLabel;

  /// No description provided for @authEmailOptionalHelp.
  ///
  /// In en, this message translates to:
  /// **'Without it we cannot email you a password reset link, so keep your ID number to hand.'**
  String get authEmailOptionalHelp;

  /// No description provided for @validationIdEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID number.'**
  String get validationIdEmpty;

  /// No description provided for @validationIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Write it as it appears on your ID, e.g. 1234567 LP.'**
  String get validationIdInvalid;

  /// No description provided for @validationCurrentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get validationCurrentPasswordRequired;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your\npassword.'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your account was created with your ID number as both the username and the password. Anyone who has seen your ID knows it, so pick a new one before you go on.'**
  String get changePasswordBody;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Your ID number, if nobody changed it'**
  String get changePasswordCurrentHint;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a number'**
  String get changePasswordNewHint;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Type it once more'**
  String get changePasswordConfirmHint;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get changePasswordSubmit;

  /// No description provided for @homeUpcomingMarathons.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Marathons'**
  String get homeUpcomingMarathons;

  /// No description provided for @racesUpcomingMarathons.
  ///
  /// In en, this message translates to:
  /// **'Upcoming marathons'**
  String get racesUpcomingMarathons;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Where we send your confirmation'**
  String get registerEmailHint;

  /// No description provided for @registerCamTitle.
  ///
  /// In en, this message translates to:
  /// **'About the CAM'**
  String get registerCamTitle;

  /// No description provided for @registerCamKnowsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you know the work the CAM does?'**
  String get registerCamKnowsQuestion;

  /// No description provided for @registerCamDonorQuestion.
  ///
  /// In en, this message translates to:
  /// **'May we call you about becoming a CAM donor?'**
  String get registerCamDonorQuestion;

  /// No description provided for @paymentMethodQrManual.
  ///
  /// In en, this message translates to:
  /// **'Bank QR'**
  String get paymentMethodQrManual;

  /// No description provided for @registerQrManualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with your banking app, then upload the receipt'**
  String get registerQrManualSubtitle;

  /// No description provided for @registerProofSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent. The organiser will check it and confirm your place.'**
  String get registerProofSent;

  /// No description provided for @registerProofUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not upload that receipt.'**
  String get registerProofUploadFailed;

  /// No description provided for @registerPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Payment note'**
  String get registerPaymentNote;

  /// No description provided for @registerPaymentNoteHelp.
  ///
  /// In en, this message translates to:
  /// **'Write it in the transfer detail. It is how the organiser links your payment to this entry.'**
  String get registerPaymentNoteHelp;

  /// No description provided for @registerProofInReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt under review'**
  String get registerProofInReviewTitle;

  /// No description provided for @registerProofInReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your place is not booked yet. The organiser confirms it once they see the money in the account.'**
  String get registerProofInReviewBody;

  /// No description provided for @registerProofRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt rejected'**
  String get registerProofRejectedTitle;

  /// No description provided for @registerProofRejectedFallback.
  ///
  /// In en, this message translates to:
  /// **'Upload a clearer one.'**
  String get registerProofRejectedFallback;

  /// No description provided for @registerProofReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction number (optional)'**
  String get registerProofReferenceLabel;

  /// No description provided for @registerProofReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'From your banking app'**
  String get registerProofReferenceHint;

  /// No description provided for @registerProofUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt'**
  String get registerProofUpload;

  /// No description provided for @registerProofTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get registerProofTakePhoto;

  /// No description provided for @phoneSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get phoneSelectCountry;

  /// No description provided for @countryBO.
  ///
  /// In en, this message translates to:
  /// **'Bolivia'**
  String get countryBO;

  /// No description provided for @countryAR.
  ///
  /// In en, this message translates to:
  /// **'Argentina'**
  String get countryAR;

  /// No description provided for @countryBR.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get countryBR;

  /// No description provided for @countryCL.
  ///
  /// In en, this message translates to:
  /// **'Chile'**
  String get countryCL;

  /// No description provided for @countryCO.
  ///
  /// In en, this message translates to:
  /// **'Colombia'**
  String get countryCO;

  /// No description provided for @countryEC.
  ///
  /// In en, this message translates to:
  /// **'Ecuador'**
  String get countryEC;

  /// No description provided for @countryES.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get countryES;

  /// No description provided for @countryUS.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUS;

  /// No description provided for @countryMX.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get countryMX;

  /// No description provided for @countryPY.
  ///
  /// In en, this message translates to:
  /// **'Paraguay'**
  String get countryPY;

  /// No description provided for @countryPE.
  ///
  /// In en, this message translates to:
  /// **'Peru'**
  String get countryPE;

  /// No description provided for @countryUY.
  ///
  /// In en, this message translates to:
  /// **'Uruguay'**
  String get countryUY;

  /// No description provided for @countryVE.
  ///
  /// In en, this message translates to:
  /// **'Venezuela'**
  String get countryVE;

  /// No description provided for @marathonSlotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} slots left'**
  String marathonSlotsLeft(int left);

  /// No description provided for @authWelcomeCamTitle.
  ///
  /// In en, this message translates to:
  /// **'CAM · Women\'\'s Support Centre'**
  String get authWelcomeCamTitle;

  /// No description provided for @authWelcomeCamBody.
  ///
  /// In en, this message translates to:
  /// **'CamRun is the app of the Centro de Apoyo a la Mujer, a non-profit supporting women in vulnerable situations. Every run you log backs that work.'**
  String get authWelcomeCamBody;

  /// No description provided for @homeNoSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'No session for this day'**
  String get homeNoSessionTitle;

  /// No description provided for @homeNoSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick another day of the week, or head out for a free run whenever you like.'**
  String get homeNoSessionMessage;

  /// No description provided for @homeFreeRun.
  ///
  /// In en, this message translates to:
  /// **'Free run'**
  String get homeFreeRun;

  /// No description provided for @filterWeekdayAll.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get filterWeekdayAll;

  /// No description provided for @adminLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get adminLiveTitle;

  /// No description provided for @adminNavLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get adminNavLive;

  /// No description provided for @adminNavMarathons.
  ///
  /// In en, this message translates to:
  /// **'Marathons'**
  String get adminNavMarathons;

  /// No description provided for @adminNavUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminNavUsers;

  /// No description provided for @adminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Try again.'**
  String get adminLoadFailed;

  /// No description provided for @adminNoMarathonsTitle.
  ///
  /// In en, this message translates to:
  /// **'No marathons yet'**
  String get adminNoMarathonsTitle;

  /// No description provided for @adminNoMarathonsBody.
  ///
  /// In en, this message translates to:
  /// **'Create the first one and it will show up here, ready to publish.'**
  String get adminNoMarathonsBody;

  /// No description provided for @adminRunnersOnCourse.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No runners on course} =1{1 runner on course} other{{count} runners on course}}'**
  String adminRunnersOnCourse(int count);

  /// No description provided for @adminStart.
  ///
  /// In en, this message translates to:
  /// **'Start marathon'**
  String get adminStart;

  /// No description provided for @adminFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get adminFinish;

  /// No description provided for @adminStartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the race?'**
  String get adminStartConfirmTitle;

  /// No description provided for @adminStartConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every entrant in “{name}” will get the race screen and their clock will start. This cannot be undone.'**
  String adminStartConfirmBody(String name);

  /// No description provided for @adminFinishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the race?'**
  String get adminFinishConfirmTitle;

  /// No description provided for @adminFinishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be closed and every runner will see their stats. This cannot be undone.'**
  String adminFinishConfirmBody(String name);

  /// No description provided for @adminAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'This marathon has already finished'**
  String get adminAlreadyFinished;

  /// No description provided for @adminMarathonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Marathons'**
  String get adminMarathonsTitle;

  /// No description provided for @adminNewMarathon.
  ///
  /// In en, this message translates to:
  /// **'New marathon'**
  String get adminNewMarathon;

  /// No description provided for @adminEditMarathon.
  ///
  /// In en, this message translates to:
  /// **'Edit marathon'**
  String get adminEditMarathon;

  /// No description provided for @adminLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get adminLive;

  /// No description provided for @adminFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get adminFinished;

  /// No description provided for @adminPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminPublished;

  /// No description provided for @adminDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminDraft;

  /// No description provided for @adminRegistrationsOpen.
  ///
  /// In en, this message translates to:
  /// **'Registrations open'**
  String get adminRegistrationsOpen;

  /// No description provided for @adminRegistrationsClosed.
  ///
  /// In en, this message translates to:
  /// **'Registrations closed'**
  String get adminRegistrationsClosed;

  /// No description provided for @adminSlots.
  ///
  /// In en, this message translates to:
  /// **'{taken}/{total} slots'**
  String adminSlots(int taken, int total);

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminName;

  /// No description provided for @adminCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get adminCity;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminCapacity.
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get adminCapacity;

  /// No description provided for @adminPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (Bs)'**
  String get adminPrice;

  /// No description provided for @adminStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get adminStartsAt;

  /// No description provided for @adminNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the marathon a name.'**
  String get adminNameRequired;

  /// No description provided for @adminCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the city.'**
  String get adminCityRequired;

  /// No description provided for @adminCapacityRequired.
  ///
  /// In en, this message translates to:
  /// **'Slots must be at least 1.'**
  String get adminCapacityRequired;

  /// No description provided for @adminRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get adminRouteTitle;

  /// No description provided for @adminRouteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to mark the course'**
  String get adminRouteSubtitle;

  /// No description provided for @adminRouteMissing.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminRouteMissing;

  /// No description provided for @adminRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop the first point of the course.'**
  String get adminRouteHint;

  /// No description provided for @adminRoutePoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points · {distance}'**
  String adminRoutePoints(int count, String distance);

  /// No description provided for @adminRouteUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get adminRouteUndo;

  /// No description provided for @adminRouteClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get adminRouteClear;

  /// No description provided for @adminRouteOutAndBack.
  ///
  /// In en, this message translates to:
  /// **'Out and back'**
  String get adminRouteOutAndBack;

  /// No description provided for @adminRouteOutAndBackHint.
  ///
  /// In en, this message translates to:
  /// **'Mark only the outbound leg: the return is the same line reversed and the distance doubles.'**
  String get adminRouteOutAndBackHint;

  /// No description provided for @adminPublishedSwitch.
  ///
  /// In en, this message translates to:
  /// **'Published in the catalogue'**
  String get adminPublishedSwitch;

  /// No description provided for @adminPublishedHint.
  ///
  /// In en, this message translates to:
  /// **'Pulling it does not cancel any entry already sold.'**
  String get adminPublishedHint;

  /// No description provided for @adminRegistrationsSwitch.
  ///
  /// In en, this message translates to:
  /// **'Registrations enabled'**
  String get adminRegistrationsSwitch;

  /// No description provided for @adminRegistrationsHint.
  ///
  /// In en, this message translates to:
  /// **'Close them when you stop taking entries.'**
  String get adminRegistrationsHint;

  /// No description provided for @adminPaymentQr.
  ///
  /// In en, this message translates to:
  /// **'Payment QR'**
  String get adminPaymentQr;

  /// No description provided for @adminQrLoaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get adminQrLoaded;

  /// No description provided for @adminQrMissing.
  ///
  /// In en, this message translates to:
  /// **'No QR'**
  String get adminQrMissing;

  /// No description provided for @adminQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Without a QR this marathon cannot take QR payments'**
  String get adminQrSubtitle;

  /// No description provided for @adminQrAfterSave.
  ///
  /// In en, this message translates to:
  /// **'Save the marathon first to upload the QR'**
  String get adminQrAfterSave;

  /// No description provided for @adminQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Text shown next to the QR'**
  String get adminQrInstructions;

  /// No description provided for @adminQrUploaded.
  ///
  /// In en, this message translates to:
  /// **'QR updated.'**
  String get adminQrUploaded;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminDeleteMarathonTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this marathon?'**
  String get adminDeleteMarathonTitle;

  /// No description provided for @adminDeleteMarathonBody.
  ///
  /// In en, this message translates to:
  /// **'Only possible while it has no entrants. If it does, pull it from the catalogue instead.'**
  String get adminDeleteMarathonBody;

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersTitle;

  /// No description provided for @adminNewUser.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get adminNewUser;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get adminEditUser;

  /// No description provided for @adminSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get adminSearch;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, email or ID'**
  String get adminSearchHint;

  /// No description provided for @adminNoUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get adminNoUsersTitle;

  /// No description provided for @adminNoUsersBody.
  ///
  /// In en, this message translates to:
  /// **'Try another name, email or ID number.'**
  String get adminNoUsersBody;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminRole;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminRoleOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get adminRoleOrganizer;

  /// No description provided for @adminRoleRunner.
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get adminRoleRunner;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminEmail;

  /// No description provided for @adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminPassword;

  /// No description provided for @adminNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get adminNewPassword;

  /// No description provided for @adminPasswordKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep it'**
  String get adminPasswordKeepHint;

  /// No description provided for @adminPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'The password needs at least 8 characters.'**
  String get adminPasswordTooShort;

  /// No description provided for @adminMustChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Still using their ID number as password'**
  String get adminMustChangePassword;

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get adminDeleteUserTitle;

  /// No description provided for @adminDeleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'The account of {name} and everything in it will be deleted. This cannot be undone.'**
  String adminDeleteUserBody(String name);

  /// No description provided for @runRemaining.
  ///
  /// In en, this message translates to:
  /// **'To go'**
  String get runRemaining;

  /// No description provided for @runAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get runAlmostThere;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erase your account and everything in it, for good'**
  String get deleteAccountRowSubtitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account removes it from CamRun and cannot be undone. There is no way to get it back afterwards.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountWhatGoes.
  ///
  /// In en, this message translates to:
  /// **'You will lose your profile, your runs and their routes, your training plan and your race registrations. Payments already made stay in the accounting records of the race organiser, with no account attached to them.'**
  String get deleteAccountWhatGoes;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm it is you'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountSubmit.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountSubmit;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete it for good?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and all your data will be erased. This cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirmAction;

  /// No description provided for @profileShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get profileShoes;

  /// No description provided for @profileShoesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The ones you put the miles on'**
  String get profileShoesSubtitle;

  /// No description provided for @profileHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get profileHealth;

  /// No description provided for @shoesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not added any shoes yet.'**
  String get shoesEmpty;

  /// No description provided for @shoesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the ones you run in and the app tells you when to replace them.'**
  String get shoesEmptyBody;

  /// No description provided for @shoesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add shoes'**
  String get shoesAdd;

  /// No description provided for @shoesBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get shoesBrand;

  /// No description provided for @shoesBrandHint.
  ///
  /// In en, this message translates to:
  /// **'Nike, Asics, Saucony…'**
  String get shoesBrandHint;

  /// No description provided for @shoesModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get shoesModel;

  /// No description provided for @shoesModelHint.
  ///
  /// In en, this message translates to:
  /// **'Pegasus 41'**
  String get shoesModelHint;

  /// No description provided for @shoesRetireAt.
  ///
  /// In en, this message translates to:
  /// **'Replace them at (km)'**
  String get shoesRetireAt;

  /// No description provided for @shoesPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get shoesPrimary;

  /// No description provided for @shoesRetire.
  ///
  /// In en, this message translates to:
  /// **'Retire'**
  String get shoesRetire;

  /// No description provided for @shoesRetireTitle.
  ///
  /// In en, this message translates to:
  /// **'Retire these shoes?'**
  String get shoesRetireTitle;

  /// No description provided for @shoesRetireBody.
  ///
  /// In en, this message translates to:
  /// **'They stop showing on your profile and their distance is not kept.'**
  String get shoesRetireBody;

  /// No description provided for @shoesAdded.
  ///
  /// In en, this message translates to:
  /// **'Shoes added.'**
  String get shoesAdded;

  /// No description provided for @shoesRetired.
  ///
  /// In en, this message translates to:
  /// **'Shoes retired.'**
  String get shoesRetired;

  /// No description provided for @shoesWear.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String shoesWear(String done, String total);

  /// No description provided for @healthTitle.
  ///
  /// In en, this message translates to:
  /// **'Injuries, sleep and hydration'**
  String get healthTitle;

  /// No description provided for @healthInjuryZone.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get healthInjuryZone;

  /// No description provided for @healthInjuryZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Right knee'**
  String get healthInjuryZoneHint;

  /// No description provided for @healthAddInjury.
  ///
  /// In en, this message translates to:
  /// **'Add injury'**
  String get healthAddInjury;

  /// No description provided for @healthNoInjuries.
  ///
  /// In en, this message translates to:
  /// **'No injuries flagged.'**
  String get healthNoInjuries;

  /// No description provided for @healthSleepLabel.
  ///
  /// In en, this message translates to:
  /// **'Average sleep per night'**
  String get healthSleepLabel;

  /// No description provided for @healthSaved.
  ///
  /// In en, this message translates to:
  /// **'Health updated.'**
  String get healthSaved;

  /// No description provided for @validationShoeBrandRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the brand.'**
  String get validationShoeBrandRequired;

  /// No description provided for @validationShoeModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the model.'**
  String get validationShoeModelRequired;

  /// No description provided for @validationInjuryZoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the area of the injury.'**
  String get validationInjuryZoneRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
