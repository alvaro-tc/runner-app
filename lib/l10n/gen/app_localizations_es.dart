// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PaceUp';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonOr => 'o';

  @override
  String get commonComingSoon => 'Muy pronto.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navTrain => 'Entrenar';

  @override
  String get navRaces => 'Carreras';

  @override
  String get navProfile => 'Perfil';

  @override
  String get authWelcomeTitle => 'Te damos la\nbienvenida';

  @override
  String get authWelcomeBody =>
      'Tu plan de entrenamiento, tus salidas y tus carreras, todo en un mismo sitio. Empieza donde estás y construye desde ahí.';

  @override
  String get authLogin => 'Iniciar sesión';

  @override
  String get authRegister => 'Crear cuenta';

  @override
  String get authSignInTitle => 'Inicia sesión.';

  @override
  String get authSignInWelcomeBack => 'Qué bueno verte de nuevo';

  @override
  String get authSignInMissed => '¡Te echábamos de menos!';

  @override
  String get authIdentifierLabel => 'Usuario o correo';

  @override
  String get authEmailHint => 'pandu@paceup.app';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordHint => 'Mínimo 8 caracteres';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authNoAccount => '¿Todavía no tienes cuenta?';

  @override
  String authSocialComingSoon(String provider) {
    return 'El acceso con $provider llega pronto. Por ahora usa tu correo.';
  }

  @override
  String get authSignUpTitle => 'Crea tu\ncuenta.';

  @override
  String get authSignUpSubtitle =>
      'Dos minutos ahora, y cada salida que hagas a partir de aquí queda registrada.';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get authFullNameHint => 'Pandu Wirawan';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authConfirmPasswordHint => 'Escríbela una vez más';

  @override
  String get authAcceptTermsSemantics =>
      'Aceptar los términos y la política de privacidad';

  @override
  String get authAcceptTerms =>
      'Acepto los términos del servicio y la política de privacidad.';

  @override
  String get authAcceptTermsRequired =>
      'Acepta los términos para crear tu cuenta.';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authForgotTitle => 'Recupera tu\ncontraseña.';

  @override
  String get authForgotIntro =>
      'Dinos el correo de tu cuenta y te enviamos un enlace para poner una contraseña nueva.';

  @override
  String authForgotSent(String email) {
    return 'Revisa $email. El enlace vale una hora; si caduca, pide otro.';
  }

  @override
  String get authSendResetLink => 'Enviar enlace';

  @override
  String get authSendAgain => 'Enviar de nuevo';

  @override
  String get validationEmailEmpty =>
      'Escribe el correo con el que te registraste.';

  @override
  String get validationEmailInvalid => 'Eso no parece una dirección de correo.';

  @override
  String get validationIdentifierEmpty => 'Escribe tu usuario o tu correo.';

  @override
  String get validationPasswordEmpty => 'Escribe tu contraseña.';

  @override
  String get validationPasswordTooShort => 'Usa al menos 8 caracteres.';

  @override
  String get validationConfirmEmpty => 'Repite tu contraseña.';

  @override
  String get validationConfirmMismatch => 'Las dos contraseñas no coinciden.';

  @override
  String get validationFullNameRequired => 'Escribe tu nombre completo.';

  @override
  String get validationDistanceNotANumber =>
      'Escribe la distancia como número.';

  @override
  String get validationDistanceNotPositive =>
      'La distancia tiene que ser mayor que cero.';

  @override
  String get failureNetwork =>
      'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get failureCache =>
      'No se pudieron leer los datos guardados. Desliza para actualizar.';

  @override
  String get failureNotFound => 'No encontramos lo que buscabas.';

  @override
  String get failurePermission =>
      'El permiso de ubicación está desactivado. Actívalo para grabar tu ruta.';

  @override
  String get failureUnexpected =>
      'Algo se rompió de nuestro lado. Inténtalo en un momento.';

  @override
  String get failureSessionExpired =>
      'Tu sesión caducó. Vuelve a iniciar sesión.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingGetStarted => 'Empezar';

  @override
  String get onboardingPlanTitle => 'Entrena con un plan que se adapta';

  @override
  String get onboardingPlanBody =>
      'Dile a PaceUp qué carrera persigues. Reparte las semanas, mueve las sesiones cuando la vida se cruza y no pierde de vista el objetivo.';

  @override
  String get onboardingTrackTitle => 'Sigue cada salida en tiempo real';

  @override
  String get onboardingTrackBody =>
      'El GPS dibuja tu ruta según avanzas. Ritmo, parciales y tiempo transcurrido siempre en pantalla, para que sepas si apretar o aguantar.';

  @override
  String get onboardingRaceTitle => 'Compite y guarda cada medalla';

  @override
  String get onboardingRaceBody =>
      'Inscríbete en eventos desde la app y guarda tu dorsal, tu tiempo de meta y tus parciales en un mismo sitio.';

  @override
  String get homeUpcomingMarathon => 'Tu próximo maratón en';

  @override
  String homePlanTitleOf(String name) {
    return 'Plan de $name';
  }

  @override
  String get homePlanTitleGeneric => 'Tu plan de entrenamiento';

  @override
  String homeTrainingWeek(int week) {
    return 'Semana $week';
  }

  @override
  String get homeRescheduleComingSoon =>
      'Reprogramar llega con el editor de planes. Empieza la salida cuando mejor te venga hoy.';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDiscard => 'Descartar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSettings => 'Ajustes';

  @override
  String get commonSplits => 'Parciales';

  @override
  String get commonDistance => 'Distancia';

  @override
  String get commonTime => 'Tiempo';

  @override
  String get commonAveragePace => 'Ritmo medio';

  @override
  String get commonAverageSpeed => 'Velocidad media';

  @override
  String get commonElevationGain => 'Desnivel positivo';

  @override
  String get commonCalories => 'Calorías';

  @override
  String get commonFinishTime => 'Tiempo de meta';

  @override
  String commonBib(String number) {
    return 'DORSAL $number';
  }

  @override
  String get commonMoreOptions => 'Más opciones';

  @override
  String get stateErrorTitle => 'Esto no se pudo cargar';

  @override
  String stateSocialContinueWith(String provider) {
    return 'Continuar con $provider';
  }

  @override
  String get sessionTypeEasy => 'Rodaje suave';

  @override
  String get sessionTypeTempo => 'Ritmo controlado';

  @override
  String get sessionTypeIntervals => 'Series';

  @override
  String get sessionTypeRecovery => 'Recuperación';

  @override
  String get sessionTypeLong => 'Tirada larga';

  @override
  String get sessionTypeRest => 'Descanso';

  @override
  String get sessionTypeRace => 'Día de carrera';

  @override
  String get sessionRestDay => 'Día de descanso';

  @override
  String sessionTitle(int km, String type) {
    return '$km km · $type';
  }

  @override
  String get runTitleMorning => 'Salida de la mañana';

  @override
  String get runTitleLunch => 'Salida del mediodía';

  @override
  String get runTitleAfternoon => 'Salida de la tarde';

  @override
  String get runTitleEvening => 'Salida de la noche';

  @override
  String get runTitleTempo => 'Rodaje a ritmo';

  @override
  String get runTitleLong => 'Tirada larga';

  @override
  String get runTitleTrackSession => 'Sesión de pista';

  @override
  String get feelingRough => 'Duro';

  @override
  String get feelingOkay => 'Normal';

  @override
  String get feelingGood => 'Bien';

  @override
  String get feelingStrong => 'Fuerte';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderOther => 'Otro';

  @override
  String get genderUndisclosed => 'Prefiero no decirlo';

  @override
  String get paymentStatusPaid => 'Pagado';

  @override
  String get paymentStatusPending => 'Pago pendiente';

  @override
  String get paymentStatusFailed => 'Pago rechazado';

  @override
  String get paymentStatusRefunded => 'Reembolsado';

  @override
  String get raceEntryStatusUpcoming => 'Próxima';

  @override
  String get raceEntryStatusCompleted => 'Completada';

  @override
  String get raceEntryStatusDnf => 'No terminada';

  @override
  String get raceEntryStatusCancelled => 'Cancelada';

  @override
  String get registrationStatusOpen => 'Inscripciones abiertas';

  @override
  String get registrationStatusClosingSoon => 'Cierra pronto';

  @override
  String get registrationStatusFull => 'Cupo agotado';

  @override
  String get registrationStatusClosed => 'Inscripciones cerradas';

  @override
  String get paymentMethodCard => 'Tarjeta';

  @override
  String get paymentMethodQr => 'QR';

  @override
  String get paymentMethodBankTransfer => 'Transferencia bancaria';

  @override
  String get locationDenied =>
      'Rechazaste el permiso de ubicación. Concédelo para grabar tu ruta.';

  @override
  String get locationDeniedForever =>
      'La ubicación está bloqueada para PaceUp. Actívala en los ajustes del sistema y vuelve.';

  @override
  String get locationBackgroundDenied =>
      'La ubicación en segundo plano está desactivada. La grabación sigue mientras PaceUp esté en pantalla, pero puede pararse si cambias de app.';

  @override
  String get locationServiceDisabled =>
      'La ubicación está desactivada en este dispositivo. Actívala para empezar una salida.';

  @override
  String get trainNoRunsTitle => 'Todavía no hay salidas';

  @override
  String get trainNoRunsMessage =>
      'La primera empieza aquí. Elige un objetivo y sal a correr.';

  @override
  String get trainNoMatchesMessage =>
      'Nada coincide con esos filtros. Amplíalos para ver más.';

  @override
  String get trainStartTraining => 'Empezar a entrenar';

  @override
  String get trainClearFilters => 'Quitar filtros';

  @override
  String get trainReadyToRun => '¿Listo para correr?';

  @override
  String get trainNothingScheduled =>
      'Hoy no hay nada previsto. Una salida libre también cuenta.';

  @override
  String trainTodaysPlan(String title, String duration) {
    return 'Plan de hoy: $title · $duration';
  }

  @override
  String get trainFreeRun => 'Salida libre';

  @override
  String get trainThisWeek => 'Esta semana';

  @override
  String get trainLastWeek => 'Semana pasada';

  @override
  String get trainHistory => 'Historial';

  @override
  String get trainSessions => 'Sesiones';

  @override
  String get filterAllTime => 'Todo el tiempo';

  @override
  String get filterLast30 => 'Últimos 30 días';

  @override
  String get filterLast90 => 'Últimos 3 meses';

  @override
  String get setupTitle => 'Prepara tu salida';

  @override
  String get setupWhatAreYouRunning => '¿Qué vas a correr?';

  @override
  String get setupFreeRunSubtitle =>
      'Sin objetivo. Sal y deja que PaceUp lo registre.';

  @override
  String get setupPlanSession => 'Sesión del plan';

  @override
  String get setupDistanceGoal => 'Objetivo de distancia';

  @override
  String get setupDistanceGoalSubtitle =>
      'Corre hasta alcanzar una distancia fija.';

  @override
  String get setupTimeGoal => 'Objetivo de tiempo';

  @override
  String get setupTimeGoalSubtitle => 'Corre durante un tiempo fijo.';

  @override
  String get setupLocationReady => 'Ubicación lista';

  @override
  String get setupLocationAccess => 'Acceso a la ubicación';

  @override
  String get setupLocationGrantedBody =>
      'PaceUp puede dibujar tu ruta mientras corres.';

  @override
  String get setupLocationRationale =>
      'PaceUp lee tu posición solo mientras grabas una salida, y guarda la ruta en este dispositivo.';

  @override
  String get setupAllowLocation => 'Permitir ubicación';

  @override
  String get setupStartRun => 'Empezar salida';

  @override
  String goalDistanceTitle(String distance) {
    return 'Objetivo de $distance';
  }

  @override
  String goalTimeTitle(String duration) {
    return 'Objetivo de $duration';
  }

  @override
  String get runDiscardTitle => '¿Descartar esta salida?';

  @override
  String get runDiscardBody =>
      'Llevas un rato corriendo. Si sales ahora se pierden la ruta y el tiempo que llevas registrado.';

  @override
  String get runKeepRunning => 'Seguir corriendo';

  @override
  String get runLeaveSemantics => 'Salir de la carrera';

  @override
  String get runRecentre => 'Centrar el mapa';

  @override
  String get runSessionTitle => 'Sesión en curso';

  @override
  String get runSettingsComingSoon =>
      'Los ajustes de la salida llegan pronto. Pausar y terminar están en el panel de abajo.';

  @override
  String runLapProgress(int done, int total) {
    return 'Vuelta $done/$total';
  }

  @override
  String runNextLap(int metres, String pace) {
    return 'Siguiente: $metres m a $pace';
  }

  @override
  String runLapSemantics(int done, int total) {
    return 'Vuelta $done de $total';
  }

  @override
  String get runElapsedTime => 'Tiempo transcurrido';

  @override
  String get runCurrentPace => 'Ritmo actual';

  @override
  String get runLastKm => 'Último km';

  @override
  String get runElevation => 'Desnivel';

  @override
  String get runTotalDistance => 'Distancia total';

  @override
  String runSplitKm(int km) {
    return 'km $km';
  }

  @override
  String get runResume => 'Reanudar';

  @override
  String get runPause => 'Pausar';

  @override
  String get runMusicSemantics => 'Controles de música';

  @override
  String get runMusicComingSoon =>
      'Los controles de música se conectarán con tu reproductor más adelante.';

  @override
  String get runCountdownGo => '¡YA!';

  @override
  String get runHoldToFinishSemantics =>
      'Mantén pulsado para terminar la salida';

  @override
  String get runKeepHolding => 'Sigue pulsando…';

  @override
  String get runHoldToFinish => 'Mantén para terminar';

  @override
  String get summarySaved => 'Salida guardada';

  @override
  String get summaryDeleteTitle => '¿Eliminar esta salida?';

  @override
  String get summaryDeleteBody =>
      'Se van con ella la ruta, los parciales y el tiempo. Esto no se puede deshacer.';

  @override
  String get summaryDiscardBody => 'No se guardará nada de esta salida.';

  @override
  String get summaryKeepIt => 'Conservarla';

  @override
  String get summaryDetailTitle => 'Detalle de la salida';

  @override
  String get summaryTitle => 'Resumen de la salida';

  @override
  String get summaryNotInHistory => 'Esa salida ya no está en tu historial.';

  @override
  String get summaryHowDidItFeel => '¿Cómo te sentiste?';

  @override
  String get summaryNotesLabel => 'Notas';

  @override
  String get summaryNotesHint => 'Piernas, clima, lo que quieras recordar';

  @override
  String get summarySaveRun => 'Guardar salida';

  @override
  String get summaryYourNotes => 'Tus notas';

  @override
  String get summaryDeleteRun => 'Eliminar esta salida';

  @override
  String get splitsTooShort =>
      'Esta salida no llegó al kilómetro, así que todavía no hay parciales.';

  @override
  String get splitsFastestKm => 'Km más rápido';

  @override
  String get splitsUnderAverage => 'Bajo la media';

  @override
  String get splitsOverAverage => 'Sobre la media';

  @override
  String get racesTitle => 'Mis carreras';

  @override
  String get racesUpcoming => 'Próximas';

  @override
  String get racesCompleted => 'Completadas';

  @override
  String get racesNoFinishesTitle => 'Todavía no hay metas';

  @override
  String get racesNoRacesTitle => 'Todavía no hay carreras';

  @override
  String get racesNoFinishesMessage =>
      'Cruza una línea de salida y tu resultado aparecerá aquí.';

  @override
  String get racesNoRacesMessage => 'Busca una y estrena tu primer dorsal.';

  @override
  String get racesBrowseEvents => 'Ver eventos';

  @override
  String get racesJoined => 'Carreras corridas';

  @override
  String get racesDistanceRaced => 'Distancia en carrera';

  @override
  String get racesTotalSpent => 'Total gastado';

  @override
  String get racesNoMarathonYet => 'Todavía no hay ningún maratón terminado.';

  @override
  String racesBestMarathon(String time) {
    return 'Mejor maratón: $time';
  }

  @override
  String racesPaidAmount(String amount) {
    return 'Pagado $amount';
  }

  @override
  String get racesAvgPace => 'Ritmo medio';

  @override
  String racesOfTotal(int total) {
    return 'de $total';
  }

  @override
  String get racesViewDetails => 'Ver detalles';

  @override
  String get raceDetailTitle => 'Mi carrera';

  @override
  String get raceDetailNotFound => 'No encontramos esa inscripción.';

  @override
  String get raceCancelTitle => '¿Cancelar esta inscripción?';

  @override
  String raceCancelBody(String marathon, String method) {
    return 'Tu plaza en $marathon queda libre y la inscripción se reembolsa a $method. Volver a inscribirte depende de que haya cupo.';
  }

  @override
  String get raceKeepMyPlace => 'Conservar mi plaza';

  @override
  String get raceCancelEntry => 'Cancelar inscripción';

  @override
  String get raceCancelled =>
      'Inscripción cancelada. El reembolso está en camino.';

  @override
  String get raceRegistration => 'Inscripción';

  @override
  String get raceRegisteredOn => 'Fecha de inscripción';

  @override
  String get raceAmountPaid => 'Importe pagado';

  @override
  String get raceMethod => 'Método';

  @override
  String get raceStatus => 'Estado';

  @override
  String get raceDownloadReceipt => 'Descargar recibo';

  @override
  String get raceReceiptComingSoon =>
      'Los recibos se descargarán cuando esté conectado el servicio de facturación.';

  @override
  String get raceShareResult => 'Compartir resultado';

  @override
  String get raceShareComingSoon =>
      'La tarjeta de finisher para compartir llega pronto.';

  @override
  String get raceGoToStartLine => 'Ir a la línea de salida';

  @override
  String get raceCancelRegistration => 'Cancelar inscripción';

  @override
  String get raceChipTime => 'Tiempo de chip';

  @override
  String get raceBestKm => 'Mejor km';

  @override
  String get raceOverallRank => 'Puesto general';

  @override
  String get raceAgeGroupRank => 'Puesto en tu categoría';

  @override
  String get raceStartsIn => 'Empieza en';

  @override
  String get raceKitCollection => 'Recogida del kit';

  @override
  String get raceKitCollectionSubtitle =>
      'La expo abre dos días antes, de 10:00 a 20:00';

  @override
  String get raceStartTime => 'Hora de salida';

  @override
  String get raceStartTimeSubtitle =>
      'Los cajones cierran 20 minutos antes de tu oleada';

  @override
  String get raceBagDrop => 'Guardarropa';

  @override
  String get raceBagDropSubtitle =>
      'En la zona de salida, abre 90 minutos antes';

  @override
  String get raceDayTitle => 'Día de carrera';

  @override
  String get raceDayNotLoaded => 'No pudimos cargar esa carrera.';

  @override
  String get raceDayCourseTitle => 'El recorrido oficial está en el mapa';

  @override
  String get raceDayCourseSubtitle =>
      'Tu traza en vivo se dibuja encima según corres';

  @override
  String get raceDayPositionTitle => 'Tu posición se envía mientras corres';

  @override
  String get raceDayPositionSubtitle =>
      'Por lotes, para que la batería aguante toda la carrera';

  @override
  String get raceDaySignalTitle => 'Quedarse sin señal no es problema';

  @override
  String get raceDaySignalSubtitle =>
      'Los puntos se guardan en el teléfono y se suben después';

  @override
  String get raceDayStart => 'Empezar la carrera';

  @override
  String get raceDayAlreadyFinished => 'Ya terminaste esta carrera.';

  @override
  String get raceDayNotReady =>
      'Esta carrera todavía no se puede empezar. Comprueba que tu inscripción esté pagada y confirmada.';

  @override
  String get marathonAbout => 'Sobre la carrera';

  @override
  String get marathonRoute => 'Recorrido';

  @override
  String get marathonSchedule => 'Programa';

  @override
  String get marathonWhatsIncluded => 'Qué incluye';

  @override
  String get marathonEntryFee => 'Inscripción';

  @override
  String marathonPlacesLeft(int left, int total) {
    return 'Quedan $left de $total plazas';
  }

  @override
  String get marathonRegisterNow => 'Inscribirme';

  @override
  String get registerTitle => 'Inscripción';

  @override
  String get registerStepDetails => 'Datos';

  @override
  String get registerStepCategory => 'Categoría';

  @override
  String get registerStepPay => 'Pago';

  @override
  String get registerYourDetails => 'Tus datos';

  @override
  String get registerFromProfile =>
      'Salen de tu perfil. Si algo no está al día, cámbialo en Perfil.';

  @override
  String get registerFullName => 'Nombre completo';

  @override
  String get registerDateOfBirth => 'Fecha de nacimiento';

  @override
  String get registerGender => 'Género';

  @override
  String get registerIdNumber => 'Documento de identidad';

  @override
  String get registerIdNumberHint => 'Va en el registro de tu dorsal';

  @override
  String get registerPhone => 'Teléfono';

  @override
  String get registerEmergencyName => 'Contacto de emergencia';

  @override
  String get registerEmergencyNameHint => '¿A quién llamamos?';

  @override
  String get registerEmergencyPhone => 'Teléfono de emergencia';

  @override
  String get registerShirtSize => 'Talla de camiseta';

  @override
  String get registerCategoryAndExtras => 'Categoría y extras';

  @override
  String registerSingleDistance(String distance) {
    return 'Este evento corre una sola distancia: $distance.';
  }

  @override
  String get registerIncluded => 'Incluido';

  @override
  String get registerOptionalExtras => 'Extras opcionales';

  @override
  String get registerNoExtras => 'Este evento no tiene extras.';

  @override
  String get registerReviewAndPay => 'Revisar y pagar';

  @override
  String registerLineWithQuantity(String label, int quantity) {
    return '$label × $quantity';
  }

  @override
  String get registerServiceFee => 'Cargo por servicio';

  @override
  String get registerPaymentMethod => 'Método de pago';

  @override
  String get registerCardSubtitle =>
      'Se cobra en cuanto tu plaza queda reservada';

  @override
  String get registerQrSubtitle => 'Escanea y paga; esperamos al banco';

  @override
  String get registerBankTransferSubtitle =>
      'Transfiere y espera a que el organizador lo confirme';

  @override
  String get registerAcceptTermsSemantics =>
      'Aceptar las condiciones del evento';

  @override
  String get registerAcceptTerms =>
      'Acepto el reglamento del evento y la política de reembolsos.';

  @override
  String get registerTryAnotherCard => 'Probar otra tarjeta';

  @override
  String get registerPayAndRegister => 'Pagar e inscribirme';

  @override
  String get registerCardNumber => 'Número de tarjeta';

  @override
  String get registerCardholder => 'Titular';

  @override
  String get registerCardholderHint => 'Tal como aparece en la tarjeta';

  @override
  String get registerExpiry => 'Caducidad';

  @override
  String get registerExpiryHint => 'MM/AA';

  @override
  String get registerCvv => 'CVV';

  @override
  String registerReference(String reference) {
    return 'Referencia: $reference';
  }

  @override
  String get registerWaitingForPayment =>
      'Esperando a que se confirme el pago…';

  @override
  String get registerSuccessTitle => '¡Estás dentro!';

  @override
  String registerSuccessBody(String marathon) {
    return 'Tu plaza en $marathon está confirmada.';
  }

  @override
  String get registerViewMyRace => 'Ver mi carrera';

  @override
  String get registerBackToHome => 'Volver al inicio';

  @override
  String get registerDefaultRunnerName => 'Corredor';

  @override
  String get registerDefaultCardHolder => 'CORREDOR PACEUP';

  @override
  String get paymentCardDeclined =>
      'El banco rechazó esta tarjeta. Prueba con otra.';

  @override
  String get paymentExpiredCard => 'Esa tarjeta está caducada.';

  @override
  String get paymentInvalidCard =>
      'Los datos de la tarjeta no parecen correctos.';

  @override
  String get paymentQrExpired =>
      'El QR caducó antes de que se pagara. Genera uno nuevo.';

  @override
  String get paymentFailedGeneric => 'No se pudo completar el pago.';

  @override
  String get profileLogOutTitle => '¿Cerrar sesión?';

  @override
  String get profileLogOutBody =>
      'Tus salidas se quedan en este dispositivo. Tendrás que iniciar sesión otra vez para seguir donde lo dejaste.';

  @override
  String get profileStaySignedIn => 'Seguir con la sesión';

  @override
  String get profileLogOut => 'Cerrar sesión';

  @override
  String get profileEditProfile => 'Editar perfil';

  @override
  String get profileYourWeek => 'Tu semana';

  @override
  String get profileInjuryFlags => 'Avisos de lesión';

  @override
  String get profileSleep => 'Sueño';

  @override
  String get profileSleepSubtitle => 'Media de los últimos 7 días';

  @override
  String get profileHydration => 'Hábito de hidratación';

  @override
  String profileHydrationValue(int days, int window) {
    return '$days de $window días con el objetivo cumplido';
  }

  @override
  String get profileAppearance => 'Apariencia';

  @override
  String get profileUnits => 'Unidades';

  @override
  String get profileNotificationsPrivacyHelp =>
      'Notificaciones, privacidad y ayuda';

  @override
  String get profileStatsComingSoon =>
      'Las estadísticas ampliadas llegan con el próximo informe de entrenamiento.';

  @override
  String get profileRunningHighlight => 'Lo más destacado';

  @override
  String get profileWeeklyMileage => 'Kilómetros semanales';

  @override
  String get profileLongestRun => 'Tirada más larga';

  @override
  String get profilePrimaryShoes => 'Zapatillas principales';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLightDetail => 'Superficies claras, ideal de día.';

  @override
  String get themeDarkDetail => 'Más descansado para las salidas de noche.';

  @override
  String get themeSystemDetail => 'Sigue lo que tengas puesto en el teléfono.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSpanishDetail => 'Toda la app en español.';

  @override
  String get languageEnglishDetail => 'Toda la app en inglés.';

  @override
  String get languageSystemDetail =>
      'Sigue lo que tengas puesto en el teléfono.';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsPlanReminders => 'Recordatorios del plan';

  @override
  String get settingsPlanRemindersSubtitle =>
      'Un aviso la mañana de cada sesión';

  @override
  String get settingsRaceUpdates => 'Avisos de carreras';

  @override
  String get settingsRaceUpdatesSubtitle =>
      'Recogida del kit, horarios de salida y resultados';

  @override
  String get settingsWeeklyReport => 'Informe semanal';

  @override
  String get settingsWeeklyReportSubtitle =>
      'Tu resumen de kilómetros cada lunes';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsShareActivity => 'Compartir actividad';

  @override
  String get settingsShareActivitySubtitle =>
      'Deja que otros corredores vean tus salidas terminadas';

  @override
  String get settingsExportData => 'Exportar mis datos';

  @override
  String get settingsExportComingSoon =>
      'La exportación de datos sale del servicio de cuentas; llega pronto.';

  @override
  String get settingsPreferences => 'Preferencias';

  @override
  String get settingsDistanceUnit => 'Unidad de distancia';

  @override
  String get settingsKilometres => 'Kilómetros';

  @override
  String get settingsMiles => 'Millas';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsHelpCentre => 'Centro de ayuda';

  @override
  String get settingsHelpComingSoon =>
      'El centro de ayuda se abrirá en tu navegador cuando el soporte esté activo.';

  @override
  String get settingsContactSupport => 'Contactar con soporte';

  @override
  String get settingsContactComingSoon =>
      'Escribe a support@paceup.app y te respondemos en menos de un día.';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editDiscardTitle => '¿Descartar los cambios?';

  @override
  String get editDiscardBody =>
      'Tienes cambios sin guardar. Si sales ahora se pierden.';

  @override
  String get editKeepEditing => 'Seguir editando';

  @override
  String get editProfileUpdated => 'Perfil actualizado';

  @override
  String get editPhotoComingSoon =>
      'La subida de foto llega con el servicio de medios.';

  @override
  String get editChangePhoto => 'Cambiar foto';

  @override
  String get editCity => 'Ciudad';

  @override
  String get editCountry => 'País';

  @override
  String get editPickADate => 'Elige una fecha';

  @override
  String get editWeightKg => 'Peso (kg)';

  @override
  String get editHeightCm => 'Altura (cm)';

  @override
  String get editSaveChanges => 'Guardar cambios';

  @override
  String get validationCityRequired => 'Escribe tu ciudad.';

  @override
  String get validationWeightNotANumber => 'Escribe tu peso como número.';

  @override
  String get validationWeightNotPositive =>
      'Tu peso tiene que ser mayor que cero.';

  @override
  String get validationHeightNotANumber => 'Escribe tu altura como número.';

  @override
  String get validationHeightNotPositive =>
      'Tu altura tiene que ser mayor que cero.';

  @override
  String get relativeToday => 'hoy';

  @override
  String relativeInDays(int days) {
    return 'en $days d';
  }

  @override
  String relativeInHours(int hours) {
    return 'en $hours h';
  }

  @override
  String relativeInMinutes(int minutes) {
    return 'en $minutes min';
  }

  @override
  String homeMarkSessionDone(String session) {
    return 'Marcar $session como hecha';
  }

  @override
  String get homeReschedule => 'Mover';

  @override
  String get homeStartRun => 'Empezar salida';

  @override
  String get fieldShowPassword => 'Mostrar la contraseña';

  @override
  String get fieldHidePassword => 'Ocultar la contraseña';

  @override
  String countdownSemantics(String days, String hours, String minutes) {
    return 'Empieza en $days días $hours horas $minutes minutos';
  }

  @override
  String daySemanticsRest(String weekday) {
    return '$weekday, día de descanso';
  }

  @override
  String daySemanticsProgress(String weekday, String label, int percent) {
    return '$weekday, $label $percent por ciento completado';
  }

  @override
  String marathonPredictedFinish(String range) {
    return 'Tiempo de meta previsto $range';
  }
}
