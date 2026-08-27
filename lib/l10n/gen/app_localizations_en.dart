// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CamRun';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonBack => 'Go back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNext => 'Next';

  @override
  String get commonOr => 'or';

  @override
  String get commonComingSoon => 'Coming soon.';

  @override
  String get navHome => 'Home';

  @override
  String get navTrain => 'Train';

  @override
  String get navRaces => 'Races';

  @override
  String get navProfile => 'Profile';

  @override
  String get authWelcomeTitle => 'Welcome to\nCamRun';

  @override
  String get authWelcomeBody =>
      'Your training plan, your runs and your races — all in one place. Start where you are and build from there.';

  @override
  String get authLogin => 'Login';

  @override
  String get authRegister => 'Register';

  @override
  String get authSignInTitle => 'Let\'s Sign you in.';

  @override
  String get authSignInWelcomeBack => 'Welcome back';

  @override
  String get authSignInMissed => 'You\'ve been missed!';

  @override
  String get authIdentifierLabel => 'Username or Email';

  @override
  String get authEmailHint => 'pandu@camrun.app';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String authSocialComingSoon(String provider) {
    return '$provider sign-in is coming soon. Use your email for now.';
  }

  @override
  String get authSignUpTitle => 'Create your\naccount.';

  @override
  String get authSignUpSubtitle =>
      'Two minutes now, and every run you take from here is counted.';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameHint => 'Pandu Wirawan';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'Type it once more';

  @override
  String get authAcceptTermsSemantics => 'Accept terms and privacy policy';

  @override
  String get authAcceptTerms =>
      'I accept the terms of service and the privacy policy.';

  @override
  String get authAcceptTermsRequired =>
      'Accept the terms to create your account.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authForgotTitle => 'Reset your\npassword.';

  @override
  String get authForgotIntro =>
      'Give us the email on your account and we will send a link to set a new password.';

  @override
  String authForgotSent(String email) {
    return 'Check $email. The link works for one hour; request another if it expires.';
  }

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authSendAgain => 'Send it again';

  @override
  String get validationEmailEmpty => 'Enter the email you signed up with.';

  @override
  String get validationEmailInvalid =>
      'That does not look like an email address.';

  @override
  String get validationIdentifierEmpty => 'Enter your username or email.';

  @override
  String get validationPasswordEmpty => 'Enter your password.';

  @override
  String get validationPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get validationConfirmEmpty => 'Repeat your password.';

  @override
  String get validationConfirmMismatch => 'The two passwords do not match.';

  @override
  String get validationFullNameRequired => 'Enter your full name.';

  @override
  String get validationDistanceNotANumber => 'Enter the distance as a number.';

  @override
  String get validationDistanceNotPositive =>
      'The distance has to be greater than zero.';

  @override
  String get failureNetwork =>
      'We could not reach the server. Check your connection and try again.';

  @override
  String get failureCache => 'Stored data could not be read. Pull to refresh.';

  @override
  String get failureNotFound => 'We could not find what you asked for.';

  @override
  String get failurePermission =>
      'Location permission is off. Enable it to record your route.';

  @override
  String get failureUnexpected =>
      'Something broke on our side. Try again in a moment.';

  @override
  String get failureSessionExpired => 'Your session expired. Sign in again.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPlanTitle => 'Train with a plan that adapts';

  @override
  String get onboardingPlanBody =>
      'Tell CamRun the race you are chasing. It lays out the weeks, moves sessions when life gets in the way, and keeps the goal in sight.';

  @override
  String get onboardingTrackTitle => 'Track every run in real time';

  @override
  String get onboardingTrackBody =>
      'GPS draws your route as you go. Pace, splits and elapsed time stay on screen, so you always know whether to push or hold back.';

  @override
  String get onboardingRaceTitle => 'Race, and keep every medal';

  @override
  String get onboardingRaceBody =>
      'Enter events from inside the app, then keep your bib, your finish time and your splits together in one place.';

  @override
  String get homeUpcomingMarathon => 'Upcoming Marathon In';

  @override
  String homePlanTitleOf(String name) {
    return '$name\'s Training Plan';
  }

  @override
  String get homePlanTitleGeneric => 'Your Training Plan';

  @override
  String homeTrainingWeek(int week) {
    return 'Training Week $week';
  }

  @override
  String get homeRescheduleComingSoon =>
      'Rescheduling arrives with the plan editor. Start the run whenever suits you today.';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonSplits => 'Splits';

  @override
  String get commonDistance => 'Distance';

  @override
  String get commonTime => 'Time';

  @override
  String get commonAveragePace => 'Average pace';

  @override
  String get commonAverageSpeed => 'Average speed';

  @override
  String get commonElevationGain => 'Elevation gain';

  @override
  String get commonCalories => 'Calories';

  @override
  String get commonFinishTime => 'Finish time';

  @override
  String commonBib(String number) {
    return 'BIB $number';
  }

  @override
  String get commonMoreOptions => 'More options';

  @override
  String get stateErrorTitle => 'That did not load';

  @override
  String stateSocialContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get sessionTypeEasy => 'Run Easy';

  @override
  String get sessionTypeTempo => 'Tempo';

  @override
  String get sessionTypeIntervals => 'Intervals';

  @override
  String get sessionTypeRecovery => 'Recovery';

  @override
  String get sessionTypeLong => 'Long Run';

  @override
  String get sessionTypeRest => 'Rest';

  @override
  String get sessionTypeRace => 'Race Day';

  @override
  String get sessionRestDay => 'Rest day';

  @override
  String sessionTitle(int km, String type) {
    return '${km}km $type';
  }

  @override
  String get runTitleMorning => 'Morning Run';

  @override
  String get runTitleLunch => 'Lunch Run';

  @override
  String get runTitleAfternoon => 'Afternoon Run';

  @override
  String get runTitleEvening => 'Evening Run';

  @override
  String get runTitleTempo => 'Tempo Run';

  @override
  String get runTitleLong => 'Long Run';

  @override
  String get runTitleTrackSession => 'Track Session';

  @override
  String get feelingRough => 'Rough';

  @override
  String get feelingOkay => 'Okay';

  @override
  String get feelingGood => 'Good';

  @override
  String get feelingStrong => 'Strong';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Other';

  @override
  String get genderUndisclosed => 'Prefer not to say';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusPending => 'Payment pending';

  @override
  String get paymentStatusFailed => 'Payment failed';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get raceEntryStatusUpcoming => 'Upcoming';

  @override
  String get raceEntryStatusCompleted => 'Completed';

  @override
  String get raceEntryStatusDnf => 'Did not finish';

  @override
  String get raceEntryStatusCancelled => 'Cancelled';

  @override
  String get registrationStatusOpen => 'Registration open';

  @override
  String get registrationStatusClosingSoon => 'Closing soon';

  @override
  String get registrationStatusFull => 'Sold out';

  @override
  String get registrationStatusClosed => 'Registration closed';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodQr => 'QR';

  @override
  String get paymentMethodBankTransfer => 'Bank transfer';

  @override
  String get locationDenied =>
      'Location permission was declined. Grant it to record your route.';

  @override
  String get locationDeniedForever =>
      'Location is blocked for CamRun. Turn it on in system settings, then come back.';

  @override
  String get locationBackgroundDenied =>
      'Background location is off. Recording keeps working while CamRun is on screen, but may stop if you switch apps.';

  @override
  String get locationServiceDisabled =>
      'Location services are off on this device. Switch them on to start a run.';

  @override
  String get trainNoRunsTitle => 'No runs yet';

  @override
  String get trainNoRunsMessage =>
      'Your first one starts here. Pick a goal and head out.';

  @override
  String get trainNoMatchesMessage =>
      'Nothing matches those filters. Widen them to see more.';

  @override
  String get trainStartTraining => 'Start training';

  @override
  String get trainClearFilters => 'Clear filters';

  @override
  String get trainReadyToRun => 'Ready to run?';

  @override
  String get trainNothingScheduled =>
      'Nothing scheduled today. A free run still counts.';

  @override
  String trainTodaysPlan(String title, String duration) {
    return 'Today\'s plan: $title · $duration';
  }

  @override
  String get trainFreeRun => 'Free run';

  @override
  String get trainThisWeek => 'This week';

  @override
  String get trainLastWeek => 'Last week';

  @override
  String get trainHistory => 'History';

  @override
  String get trainSessions => 'Sessions';

  @override
  String get filterAllTime => 'All time';

  @override
  String get filterLast30 => 'Last 30 days';

  @override
  String get filterLast90 => 'Last 3 months';

  @override
  String get setupTitle => 'Set up your run';

  @override
  String get setupWhatAreYouRunning => 'What are you running?';

  @override
  String get setupFreeRunSubtitle =>
      'No target. Just go and let CamRun record it.';

  @override
  String get setupPlanSession => 'Plan session';

  @override
  String get setupDistanceGoal => 'Distance goal';

  @override
  String get setupDistanceGoalSubtitle => 'Run until you hit a set distance.';

  @override
  String get setupTimeGoal => 'Time goal';

  @override
  String get setupTimeGoalSubtitle => 'Run for a set amount of time.';

  @override
  String get setupLocationReady => 'Location ready';

  @override
  String get setupLocationAccess => 'Location access';

  @override
  String get setupLocationGrantedBody =>
      'CamRun can draw your route while you run.';

  @override
  String get setupLocationRationale =>
      'CamRun reads your position only while a run is recording, and stores the route on this device.';

  @override
  String get setupAllowLocation => 'Allow location';

  @override
  String get setupStartRun => 'Start run';

  @override
  String goalDistanceTitle(String distance) {
    return '$distance goal';
  }

  @override
  String goalTimeTitle(String duration) {
    return '$duration goal';
  }

  @override
  String get runDiscardTitle => 'Discard this run?';

  @override
  String get runDiscardBody =>
      'You have been running for a while. Leaving now throws away the route and the time you have logged.';

  @override
  String get runKeepRunning => 'Keep running';

  @override
  String get runLeaveSemantics => 'Leave the run';

  @override
  String get runRecentre => 'Re-centre the map';

  @override
  String get runSessionTitle => 'Running Session';

  @override
  String get runSettingsComingSoon =>
      'Run settings arrive next. Pause and finish work from the sheet below.';

  @override
  String runLapProgress(int done, int total) {
    return 'Lap $done/$total';
  }

  @override
  String runNextLap(int metres, String pace) {
    return 'Next: ${metres}m @ $pace pace';
  }

  @override
  String runLapSemantics(int done, int total) {
    return 'Lap $done of $total';
  }

  @override
  String get runElapsedTime => 'Elapsed Time';

  @override
  String get runCurrentPace => 'Current Pace';

  @override
  String get runLastKm => 'Last km';

  @override
  String get runElevation => 'Elevation';

  @override
  String get runTotalDistance => 'Total Distance';

  @override
  String runSplitKm(int km) {
    return 'km $km';
  }

  @override
  String get runResume => 'Resume';

  @override
  String get runPause => 'Pause';

  @override
  String get runMusicSemantics => 'Music controls';

  @override
  String get runMusicComingSoon =>
      'Music controls hook into your player in a later release.';

  @override
  String get runCountdownGo => 'GO';

  @override
  String get runHoldToFinishSemantics => 'Hold to finish the run';

  @override
  String get runKeepHolding => 'Keep holding…';

  @override
  String get runHoldToFinish => 'Hold to finish';

  @override
  String get summarySaved => 'Run saved';

  @override
  String get summaryDeleteTitle => 'Delete this run?';

  @override
  String get summaryDeleteBody =>
      'The route, the splits and the time all go with it. This cannot be undone.';

  @override
  String get summaryDiscardBody => 'Nothing about this run will be kept.';

  @override
  String get summaryKeepIt => 'Keep it';

  @override
  String get summaryDetailTitle => 'Run detail';

  @override
  String get summaryTitle => 'Run summary';

  @override
  String get summaryNotInHistory => 'That run is not in your history any more.';

  @override
  String get summaryHowDidItFeel => 'How did it feel?';

  @override
  String get summaryNotesLabel => 'Notes';

  @override
  String get summaryNotesHint => 'Legs, weather, anything worth remembering';

  @override
  String get summarySaveRun => 'Save run';

  @override
  String get summaryYourNotes => 'Your notes';

  @override
  String get summaryDeleteRun => 'Delete this run';

  @override
  String get splitsTooShort =>
      'This run was shorter than a kilometre, so there are no splits yet.';

  @override
  String get splitsFastestKm => 'Fastest km';

  @override
  String get splitsUnderAverage => 'Under average';

  @override
  String get splitsOverAverage => 'Over average';

  @override
  String get racesTitle => 'My Races';

  @override
  String get racesUpcoming => 'Upcoming';

  @override
  String get racesCompleted => 'Completed';

  @override
  String get racesNoFinishesTitle => 'No finishes yet';

  @override
  String get racesNoRacesTitle => 'No races yet';

  @override
  String get racesNoFinishesMessage =>
      'Cross a start line and your result lands here.';

  @override
  String get racesNoRacesMessage => 'Find one and pin your first bib.';

  @override
  String get racesBrowseEvents => 'Browse events';

  @override
  String get racesJoined => 'Races joined';

  @override
  String get racesDistanceRaced => 'Distance raced';

  @override
  String get racesTotalSpent => 'Total spent';

  @override
  String get racesNoMarathonYet => 'No marathon finish recorded yet.';

  @override
  String racesBestMarathon(String time) {
    return 'Best marathon: $time';
  }

  @override
  String racesPaidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String get racesAvgPace => 'Avg pace';

  @override
  String racesOfTotal(int total) {
    return 'of $total';
  }

  @override
  String get racesViewDetails => 'View details';

  @override
  String get raceDetailTitle => 'My race';

  @override
  String get raceDetailNotFound => 'We could not find that registration.';

  @override
  String get raceCancelTitle => 'Cancel this registration?';

  @override
  String raceCancelBody(String marathon, String method) {
    return 'Your place at $marathon is released and the entry fee is refunded to $method. Re-entry depends on availability.';
  }

  @override
  String get raceKeepMyPlace => 'Keep my place';

  @override
  String get raceCancelEntry => 'Cancel entry';

  @override
  String get raceCancelled => 'Registration cancelled. Refund on its way.';

  @override
  String get raceRegistration => 'Registration';

  @override
  String get raceRegisteredOn => 'Registered on';

  @override
  String get raceAmountPaid => 'Amount paid';

  @override
  String get raceMethod => 'Method';

  @override
  String get raceStatus => 'Status';

  @override
  String get raceDownloadReceipt => 'Download receipt';

  @override
  String get raceReceiptComingSoon =>
      'Receipts download once the billing service is connected.';

  @override
  String get raceShareResult => 'Share result';

  @override
  String get raceShareComingSoon => 'A shareable finisher card is on the way.';

  @override
  String get raceGoToStartLine => 'Go to the start line';

  @override
  String get raceCancelRegistration => 'Cancel registration';

  @override
  String get raceChipTime => 'Chip time';

  @override
  String get raceBestKm => 'Best km';

  @override
  String get raceOverallRank => 'Overall rank';

  @override
  String get raceAgeGroupRank => 'Age group rank';

  @override
  String get raceStartsIn => 'Starts in';

  @override
  String get raceKitCollection => 'Kit collection';

  @override
  String get raceKitCollectionSubtitle =>
      'Expo opens two days before, 10:00–20:00';

  @override
  String get raceStartTime => 'Start time';

  @override
  String get raceStartTimeSubtitle =>
      'Corrals close 20 minutes before your wave';

  @override
  String get raceBagDrop => 'Bag drop';

  @override
  String get raceBagDropSubtitle =>
      'At the start village, opens 90 minutes prior';

  @override
  String get raceDayTitle => 'Race day';

  @override
  String get raceDayNotLoaded => 'We could not load that race.';

  @override
  String get raceDayCourseTitle => 'The official course is on the map';

  @override
  String get raceDayCourseSubtitle =>
      'Your live track is drawn on top of it as you run';

  @override
  String get raceDayPositionTitle => 'Your position is sent while you run';

  @override
  String get raceDayPositionSubtitle =>
      'In batches, so the battery lasts the whole race';

  @override
  String get raceDaySignalTitle => 'Losing signal is fine';

  @override
  String get raceDaySignalSubtitle =>
      'Points are stored on the phone and uploaded later';

  @override
  String get raceDayStart => 'Start the race';

  @override
  String get raceDayAlreadyFinished => 'You already finished this race.';

  @override
  String get raceDayNotReady =>
      'This race is not ready to start. Check that your entry is paid and confirmed.';

  @override
  String get marathonAbout => 'About';

  @override
  String get marathonRoute => 'Route';

  @override
  String get marathonSchedule => 'Schedule';

  @override
  String get marathonWhatsIncluded => 'What\'s included';

  @override
  String get marathonEntryFee => 'Entry fee';

  @override
  String marathonPlacesLeft(int left, int total) {
    return '$left of $total places left';
  }

  @override
  String get marathonRegisterNow => 'Register now';

  @override
  String get registerTitle => 'Registration';

  @override
  String get registerStepDetails => 'Details';

  @override
  String get registerStepCategory => 'Category';

  @override
  String get registerStepPay => 'Pay';

  @override
  String get registerYourDetails => 'Your details';

  @override
  String get registerFromProfile =>
      'Taken from your profile. Change them in Profile if anything is out of date.';

  @override
  String get registerFullName => 'Full name';

  @override
  String get registerDateOfBirth => 'Date of birth';

  @override
  String get registerGender => 'Gender';

  @override
  String get registerIdNumber => 'ID number';

  @override
  String get registerIdNumberHint => 'Goes on your bib record';

  @override
  String get registerPhone => 'Phone';

  @override
  String get registerEmergencyName => 'Emergency contact name';

  @override
  String get registerEmergencyNameHint => 'Who should we call?';

  @override
  String get registerEmergencyPhone => 'Emergency contact phone';

  @override
  String get registerShirtSize => 'Shirt size';

  @override
  String get registerCategoryAndExtras => 'Category & extras';

  @override
  String registerSingleDistance(String distance) {
    return 'This event runs a single distance: $distance.';
  }

  @override
  String get registerIncluded => 'Included';

  @override
  String get registerOptionalExtras => 'Optional extras';

  @override
  String get registerNoExtras => 'No add-ons for this event.';

  @override
  String get registerReviewAndPay => 'Review & pay';

  @override
  String registerLineWithQuantity(String label, int quantity) {
    return '$label × $quantity';
  }

  @override
  String get registerServiceFee => 'Service fee';

  @override
  String get registerPaymentMethod => 'Payment method';

  @override
  String get registerCardSubtitle => 'Charged the moment your place is taken';

  @override
  String get registerQrSubtitle => 'Scan and pay; we wait for the bank';

  @override
  String get registerBankTransferSubtitle =>
      'Transfer and wait for the organiser to confirm';

  @override
  String get registerAcceptTermsSemantics => 'Accept event terms';

  @override
  String get registerAcceptTerms =>
      'I accept the event rules and the refund policy.';

  @override
  String get registerTryAnotherCard => 'Try another card';

  @override
  String get registerPayAndRegister => 'Pay and register';

  @override
  String get registerCardNumber => 'Card number';

  @override
  String get registerCardholder => 'Cardholder';

  @override
  String get registerCardholderHint => 'As printed on the card';

  @override
  String get registerExpiry => 'Expiry';

  @override
  String get registerExpiryHint => 'MM/YY';

  @override
  String get registerCvv => 'CVV';

  @override
  String registerReference(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get registerWaitingForPayment => 'Waiting for the payment to clear…';

  @override
  String get registerSuccessTitle => 'You\'re in';

  @override
  String registerSuccessBody(String marathon) {
    return 'Your place at $marathon is confirmed.';
  }

  @override
  String get registerViewMyRace => 'View my race';

  @override
  String get registerBackToHome => 'Back to home';

  @override
  String get registerDefaultRunnerName => 'Runner';

  @override
  String get registerDefaultCardHolder => 'CAMRUN RUNNER';

  @override
  String get paymentCardDeclined =>
      'The bank turned this card down. Try another one.';

  @override
  String get paymentExpiredCard => 'That card is expired.';

  @override
  String get paymentInvalidCard => 'Those card details do not look right.';

  @override
  String get paymentQrExpired =>
      'The QR expired before it was paid. Generate a new one.';

  @override
  String get paymentFailedGeneric => 'Payment could not be completed.';

  @override
  String get profileLogOutTitle => 'Log out?';

  @override
  String get profileLogOutBody =>
      'Your runs stay on this device. You will need to sign in again to pick up where you left off.';

  @override
  String get profileStaySignedIn => 'Stay signed in';

  @override
  String get profileLogOut => 'Log out';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileYourWeek => 'Your week';

  @override
  String get profileInjuryFlags => 'Injury Flags';

  @override
  String get profileSleep => 'Sleep';

  @override
  String get profileSleepSubtitle => 'Avg in last 7 days';

  @override
  String get profileHydration => 'Hydration Habit';

  @override
  String profileHydrationValue(int days, int window) {
    return '$days/$window days hit target';
  }

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileUnits => 'Units';

  @override
  String get profileNotificationsPrivacyHelp =>
      'Notifications, privacy and help';

  @override
  String get profileStatsComingSoon =>
      'Extended statistics land with the next training report.';

  @override
  String get profileRunningHighlight => 'Running Highlight';

  @override
  String get profileWeeklyMileage => 'Weekly Mileage';

  @override
  String get profileLongestRun => 'Longest Run';

  @override
  String get profilePrimaryShoes => 'Primary Shoes';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLightDetail => 'Bright surfaces, best in daylight.';

  @override
  String get themeDarkDetail => 'Easier on the eyes for evening runs.';

  @override
  String get themeSystemDetail => 'Follows whatever your phone is set to.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSpanishDetail => 'The whole app in Spanish.';

  @override
  String get languageEnglishDetail => 'The whole app in English.';

  @override
  String get languageSystemDetail => 'Follows whatever your phone is set to.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPlanReminders => 'Plan reminders';

  @override
  String get settingsPlanRemindersSubtitle =>
      'A nudge the morning of each session';

  @override
  String get settingsRaceUpdates => 'Race updates';

  @override
  String get settingsRaceUpdatesSubtitle =>
      'Kit collection, start times and results';

  @override
  String get settingsWeeklyReport => 'Weekly report';

  @override
  String get settingsWeeklyReportSubtitle =>
      'Your mileage summary every Monday';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsShareActivity => 'Share activity';

  @override
  String get settingsShareActivitySubtitle =>
      'Let other runners see your finished runs';

  @override
  String get settingsExportData => 'Export my data';

  @override
  String get settingsExportComingSoon =>
      'Data export runs from the account service, coming soon.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsDistanceUnit => 'Distance unit';

  @override
  String get settingsKilometres => 'Kilometres';

  @override
  String get settingsMiles => 'Miles';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsHelpCentre => 'Help centre';

  @override
  String get settingsHelpComingSoon =>
      'The help centre opens in your browser once support is live.';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsContactComingSoon =>
      'Write to support@camrun.app and we will answer within a day.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editDiscardTitle => 'Discard changes?';

  @override
  String get editDiscardBody =>
      'You have edits that are not saved yet. Leaving now loses them.';

  @override
  String get editKeepEditing => 'Keep editing';

  @override
  String get editProfileUpdated => 'Profile updated';

  @override
  String get editPhotoComingSoon =>
      'Photo upload arrives with the media service.';

  @override
  String get editChangePhoto => 'Change photo';

  @override
  String get editCity => 'City';

  @override
  String get editCountry => 'Country';

  @override
  String get editPickADate => 'Pick a date';

  @override
  String get editWeightKg => 'Weight (kg)';

  @override
  String get editHeightCm => 'Height (cm)';

  @override
  String get editSaveChanges => 'Save changes';

  @override
  String get validationCityRequired => 'Enter your city.';

  @override
  String get validationWeightNotANumber => 'Enter your weight as a number.';

  @override
  String get validationWeightNotPositive =>
      'Your weight has to be greater than zero.';

  @override
  String get validationHeightNotANumber => 'Enter your height as a number.';

  @override
  String get validationHeightNotPositive =>
      'Your height has to be greater than zero.';

  @override
  String get relativeToday => 'today';

  @override
  String relativeInDays(int days) {
    return 'in ${days}d';
  }

  @override
  String relativeInHours(int hours) {
    return 'in ${hours}h';
  }

  @override
  String relativeInMinutes(int minutes) {
    return 'in ${minutes}m';
  }

  @override
  String homeMarkSessionDone(String session) {
    return 'Mark $session as done';
  }

  @override
  String get homeReschedule => 'Reschedule';

  @override
  String get homeStartRun => 'Start Run';

  @override
  String get fieldShowPassword => 'Show password';

  @override
  String get fieldHidePassword => 'Hide password';

  @override
  String countdownSemantics(String days, String hours, String minutes) {
    return 'Starts in $days days $hours hours $minutes minutes';
  }

  @override
  String daySemanticsRest(String weekday) {
    return '$weekday, rest day';
  }

  @override
  String daySemanticsProgress(String weekday, String label, int percent) {
    return '$weekday, $label $percent percent done';
  }

  @override
  String marathonPredictedFinish(String range) {
    return 'Predicted finish time $range';
  }

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get authIdLabel => 'ID number (CI)';

  @override
  String get authIdHint => '1234567 LP';

  @override
  String get authEmailOptionalLabel => 'Email (optional)';

  @override
  String get authEmailOptionalHelp =>
      'Without it we cannot email you a password reset link, so keep your ID number to hand.';

  @override
  String get validationIdEmpty => 'Enter your ID number.';

  @override
  String get validationIdInvalid =>
      'Write it as it appears on your ID, e.g. 1234567 LP.';

  @override
  String get validationCurrentPasswordRequired =>
      'Enter your current password.';

  @override
  String get changePasswordTitle => 'Choose your\npassword.';

  @override
  String get changePasswordBody =>
      'Your account was created with your ID number as both the username and the password. Anyone who has seen your ID knows it, so pick a new one before you go on.';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordCurrentHint =>
      'Your ID number, if nobody changed it';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordNewHint =>
      'At least 8 characters, with a letter and a number';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordConfirmHint => 'Type it once more';

  @override
  String get changePasswordSubmit => 'Save and continue';

  @override
  String get homeUpcomingMarathons => 'Upcoming Marathons';

  @override
  String get racesUpcomingMarathons => 'Upcoming marathons';

  @override
  String get registerEmailHint => 'Where we send your confirmation';

  @override
  String get registerCamTitle => 'About the CAM';

  @override
  String get registerCamKnowsQuestion => 'Do you know the work the CAM does?';

  @override
  String get registerCamDonorQuestion =>
      'May we call you about becoming a CAM donor?';

  @override
  String get paymentMethodQrManual => 'Bank QR';

  @override
  String get registerQrManualSubtitle =>
      'Pay with your banking app, then upload the receipt';

  @override
  String get registerProofSent =>
      'Receipt sent. The organiser will check it and confirm your place.';

  @override
  String get registerProofUploadFailed => 'We could not upload that receipt.';

  @override
  String get registerPaymentNote => 'Payment note';

  @override
  String get registerPaymentNoteHelp =>
      'Write it in the transfer detail. It is how the organiser links your payment to this entry.';

  @override
  String get registerProofInReviewTitle => 'Receipt under review';

  @override
  String get registerProofInReviewBody =>
      'Your place is not booked yet. The organiser confirms it once they see the money in the account.';

  @override
  String get registerProofRejectedTitle => 'Receipt rejected';

  @override
  String get registerProofRejectedFallback => 'Upload a clearer one.';

  @override
  String get registerProofReferenceLabel => 'Transaction number (optional)';

  @override
  String get registerProofReferenceHint => 'From your banking app';

  @override
  String get registerProofUpload => 'Upload receipt';

  @override
  String get registerProofTakePhoto => 'Take a photo';

  @override
  String get phoneSelectCountry => 'Select a country';

  @override
  String get countryBO => 'Bolivia';

  @override
  String get countryAR => 'Argentina';

  @override
  String get countryBR => 'Brazil';

  @override
  String get countryCL => 'Chile';

  @override
  String get countryCO => 'Colombia';

  @override
  String get countryEC => 'Ecuador';

  @override
  String get countryES => 'Spain';

  @override
  String get countryUS => 'United States';

  @override
  String get countryMX => 'Mexico';

  @override
  String get countryPY => 'Paraguay';

  @override
  String get countryPE => 'Peru';

  @override
  String get countryUY => 'Uruguay';

  @override
  String get countryVE => 'Venezuela';

  @override
  String marathonSlotsLeft(int left) {
    return '$left slots left';
  }
}
