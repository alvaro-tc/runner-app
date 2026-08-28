import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_colors.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/presentation/providers/profile_provider.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:camrun/features/races/presentation/providers/registration_provider.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/phone_field.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Alta en una maraton, en los mismos tres pasos que lleva el servidor:
/// datos, categoria y extras, y pago.
///
/// **Aqui no se suma dinero.** Cada paso guarda contra la API y devuelve el
/// desglose vigente; lo que se pinta es ese desglose. Un total calculado en el
/// movil se desvia en cuanto cambia un precio o un cargo por servicio, y el
/// usuario acabaria viendo un numero y pagando otro.
///
/// El pago es **simulado**: el proveedor responde por el numero de tarjeta
/// (4242…4242 aprueba, 4000…0002 rechaza, 4000…0069 dice vencida), asi que los
/// tres caminos se pueden probar de verdad sin un banco detras.
class MarathonRegisterPage extends ConsumerStatefulWidget {
  const MarathonRegisterPage({required this.marathonId, super.key});

  final String marathonId;

  @override
  ConsumerState<MarathonRegisterPage> createState() =>
      _MarathonRegisterPageState();
}

class _MarathonRegisterPageState extends ConsumerState<MarathonRegisterPage> {
  static const _shirtSizes = ['XS', 'S', 'M', 'L', 'XL'];

  /// Tarjeta que el proveedor simulado aprueba. Va precargada porque este
  /// checkout es de prueba y escribir dieciseis digitos a mano en cada pasada
  /// no prueba nada que no pruebe esto.
  static const _tarjetaDeEjemplo = '4242 4242 4242 4242';

  final _page = PageController();
  final _docId = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _cardNumber = TextEditingController(text: _tarjetaDeEjemplo);
  final _cardHolder = TextEditingController();
  final _cardExpiry = TextEditingController(text: '12/30');
  final _cardCvv = TextEditingController(text: '123');

  int _step = 0;
  String _shirtSize = 'M';
  String? _categoryId;
  final _selectedExtras = <String>{};
  // Hoy solo se cobra por QR: ver `RacePaymentMethod.offered`. No se elige
  // "el primero de la lista" para que apagar o encender un metodo alli sea el
  // unico cambio necesario.
  RacePaymentMethod _method = RacePaymentMethod.offered.first;
  bool _acceptedTerms = false;

  // Las dos preguntas del CAM. Empiezan sin responder y no en `false`: "no
  // contesto" y "dijo que no" no son lo mismo, y menos en un consentimiento
  // para llamarle por telefono.
  bool? _knowsCam;
  bool? _acceptsDonorCall;

  @override
  void dispose() {
    _page.dispose();
    _docId.dispose();
    _phone.dispose();
    _email.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _cardNumber.dispose();
    _cardHolder.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  RegistrationFlowNotifier get _flow =>
      ref.read(registrationFlowProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Descarta el borrador de otra maraton que hubiera quedado a medias en esta
    // misma pantalla. Con la misma maraton no toca nada: el flujo se retoma.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _flow.openFor(widget.marathonId),
    );
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _page.animateToPage(
      step,
      duration: AppDurations.base,
      curve: AppDurations.curve,
    );
  }

  /// Guarda el paso actual contra la API y solo entonces avanza.
  ///
  /// Avanzar primero y guardar despues dejaria al usuario en la pantalla de
  /// pago con un borrador que el servidor no llego a aceptar.
  Future<void> _next(Marathon marathon, UserProfile? profile) async {
    final ok = switch (_step) {
      0 => await _flow.submitPersonalData(_datosPersonales(profile)),
      1 => await _flow.submitCategoryAndExtras(
        categoryId: _categoryId,
        extras: [for (final id in _selectedExtras) ExtraSelection(extraId: id)],
      ),
      _ => false,
    };

    if (ok && mounted) _goTo(_step + 1);
  }

  RegistrationPersonalData _datosPersonales(UserProfile? profile) =>
      RegistrationPersonalData(
        fullName: profile?.fullName.trim().isNotEmpty ?? false
            ? profile!.fullName
            : context.l10n.registerDefaultRunnerName,
        docId: _docId.text.trim(),
        phone: _phone.text.trim(),
        // El footer no deja llegar aqui sin las dos respuestas; el `?? false`
        // es solo para que el tipo cierre.
        knowsCam: _knowsCam ?? false,
        acceptsDonorCall: _acceptsDonorCall ?? false,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        emergencyContactName: _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim(),
        shirtSize: _shirtSize,
      );

  Future<void> _pay(Marathon marathon) async {
    final confirmada = await _flow.pay(
      method: _method,
      card: _method == RacePaymentMethod.card ? _tarjeta() : null,
    );
    if (!mounted) return;

    final estado = ref.read(registrationFlowProvider);
    if (!confirmada) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        bibNumber: estado.registration?.bibNumber ?? '—',
        marathonName: marathon.name,
        onViewRace: () => context
          ..pop()
          ..go(Routes.raceDetailOf(estado.registration!.id)),
        onHome: () => context
          ..pop()
          ..go(Routes.home),
      ),
    );
  }

  /// Coge una imagen y la sube como comprobante. **Temporal**: ver
  /// `docs/pago-qr-manual.md` en la API.
  ///
  /// Subirla no confirma nada — el cobro sigue pendiente hasta que un
  /// organizador la mire— y el mensaje lo dice tal cual: prometer aquí una
  /// inscripción confirmada es exactamente el malentendido que hay que evitar.
  Future<void> _subirComprobante(ImageSource source) async {
    final imagen = await ImagePicker().pickImage(
      source: source,
      // Se manda ya reducida: el servidor la vuelve a reescalar, pero subir
      // 12 MP por datos móviles desde la calle es lo que hace que el usuario
      // abandone en esta pantalla.
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (imagen == null || !mounted) return;

    final ok = await _flow.uploadProof(filePath: imagen.path);
    if (!mounted) return;

    context.showSnack(
      ok
          ? context.l10n.registerProofSent
          : ref.read(registrationFlowProvider).error?.message ??
                context.l10n.registerProofUploadFailed,
    );
  }

  /// Cancela el pago abierto, y con él la inscripción.
  ///
  /// Pregunta antes porque no tiene vuelta atrás: el servidor cierra el cobro
  /// —después de esto ya no se admite ningún comprobante— y suelta el borrador.
  /// Reinscribirse es empezar de cero.
  Future<void> _cancelarPago() async {
    final t = context.l10n;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.registerCancelPaymentTitle),
        content: Text(t.registerCancelPaymentBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.registerCancelPaymentKeep),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(t.registerCancelPaymentConfirm),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final ok = await _flow.cancelRegistration();
    if (!mounted) return;

    if (!ok) {
      context.showSnack(
        ref.read(registrationFlowProvider).error?.localized(t) ??
            t.registerCancelPaymentFailed,
      );
      return;
    }

    // Se sale de la pantalla: el borrador ya no existe, y quedarse en el paso 3
    // con los datos pintados invita a pagar algo que el servidor va a rechazar.
    context
      ..showSnack(t.registerCancelPaymentDone)
      ..go(Routes.home);
  }

  /// La caducidad se escribe `MM/AA` y viaja como dos enteros.
  CardDetails _tarjeta() {
    final partes = _cardExpiry.text.split('/');
    final mes = int.tryParse(partes.first.trim()) ?? 12;
    final anio = int.tryParse(partes.length > 1 ? partes[1].trim() : '') ?? 30;

    return CardDetails(
      number: _cardNumber.text,
      holder: _cardHolder.text.trim().isEmpty
          ? context.l10n.registerDefaultCardHolder
          : _cardHolder.text.trim(),
      expMonth: mes,
      // Dos digitos son este siglo: `30` es 2030, no el ano 30.
      expYear: anio < 100 ? 2000 + anio : anio,
      cvv: _cardCvv.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marathon = ref.watch(marathonProvider(widget.marathonId));
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: context.l10n.commonBack,
            onPressed: () => _step == 0 ? context.pop() : _goTo(_step - 1),
          ),
        ),
        title: Text(context.l10n.registerTitle),
      ),
      body: marathon.when(
        loading: () => const Center(child: Skeleton(width: 200, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error.localized(context.l10n),
          onRetry: () => ref.invalidate(marathonProvider(widget.marathonId)),
        ),
        data: (data) => _body(data, profile),
      ),
    );
  }

  Widget _body(Marathon marathon, UserProfile? profile) {
    _categoryId ??= marathon.categories.firstOrNull?.id;
    final flow = ref.watch(registrationFlowProvider);

    return Column(
      children: [
        _Stepper(step: _step),
        Expanded(
          child: PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _detailsStep(profile),
              _categoryStep(marathon),
              _reviewStep(marathon, flow),
            ],
          ),
        ),
        if (!_enPagoQr(flow)) _footer(marathon, profile, flow),
      ],
    );
  }

  // ------------------------------------------------------------- step one

  Widget _detailsStep(UserProfile? profile) {
    final c = context.colors;
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text(t.registerYourDetails, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.registerFromProfile,
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReadOnlyField(
          label: t.registerFullName,
          value: profile?.fullName ?? '—',
        ),
        _ReadOnlyField(
          label: t.registerDateOfBirth,
          value: profile?.birthDate == null
              ? '—'
              : Fmt.fullDate(profile!.birthDate!),
        ),
        _ReadOnlyField(
          label: t.registerGender,
          value: profile?.gender.label(t) ?? '—',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: t.registerIdNumber,
          controller: _docId,
          hint: t.registerIdNumberHint,
          textInputAction: TextInputAction.next,
          // El boton de continuar depende de este campo: sin repintar, se
          // quedaria gris con el documento ya escrito.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        PhoneField(
          label: t.registerPhone,
          controller: _phone,
          hint: '70000000',
          textInputAction: TextInputAction.next,
          // Igual que el documento: el botón de continuar depende de él.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.authEmailOptionalLabel,
          controller: _email,
          hint: t.registerEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(t.registerCamTitle, style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        _YesNo(
          question: t.registerCamKnowsQuestion,
          value: _knowsCam,
          onChanged: (v) => setState(() => _knowsCam = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _YesNo(
          question: t.registerCamDonorQuestion,
          value: _acceptsDonorCall,
          onChanged: (v) => setState(() => _acceptsDonorCall = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: t.registerEmergencyName,
          controller: _emergencyName,
          hint: t.registerEmergencyNameHint,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.registerEmergencyPhone,
          controller: _emergencyPhone,
          hint: '+591 70000001',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.registerShirtSize, style: context.text.labelSm),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final size in _shirtSizes)
              AppChip(
                label: size,
                selected: _shirtSize == size,
                onTap: () => setState(() => _shirtSize = size),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step two

  Widget _categoryStep(Marathon marathon) {
    final c = context.colors;
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text(t.registerCategoryAndExtras, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.lg),
        if (marathon.categories.isEmpty)
          Text(
            t.registerSingleDistance(Fmt.distance(marathon.distanceKm)),
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          )
        else
          for (final category in marathon.categories)
            _SelectableTile(
              title: category.label,
              subtitle: Fmt.distance(category.distanceKm),
              trailing: category.surcharge.amount == 0
                  ? t.registerIncluded
                  : Fmt.money(
                      category.surcharge.amount,
                      category.surcharge.currency,
                    ),
              selected: _categoryId == category.id,
              onTap: () => setState(() => _categoryId = category.id),
            ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.registerOptionalExtras, style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        if (marathon.extras.isEmpty)
          Text(
            t.registerNoExtras,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          )
        else
          for (final extra in marathon.extras)
            _SelectableTile(
              title: extra.label,
              subtitle: extra.description,
              trailing: Fmt.money(extra.price.amount, extra.price.currency),
              selected: _selectedExtras.contains(extra.id),
              isCheckbox: true,
              onTap: () => setState(() {
                _selectedExtras.contains(extra.id)
                    ? _selectedExtras.remove(extra.id)
                    : _selectedExtras.add(extra.id);
              }),
            ),
      ],
    );
  }

  // ----------------------------------------------------------- step three

  /// Con un cobro por QR abierto la pantalla es **solo** el QR y los dos
  /// botones para mandar el comprobante. El desglose, los metodos y los
  /// terminos ya se aceptaron un paso antes: dejarlos ahi solo empuja hacia
  /// abajo lo unico que queda por hacer.
  bool _enPagoQr(RegistrationFlowState flow) =>
      flow.isAwaitingPayment && flow.payment!.method.needsProof;

  Widget _reviewStep(Marathon marathon, RegistrationFlowState flow) {
    final c = context.colors;
    final t = context.l10n;
    final quote = flow.quote;

    if (_enPagoQr(flow)) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          _ManualQrPayment(
            payment: flow.payment!,
            busy: flow.busy,
            onUpload: _subirComprobante,
            onCancel: _cancelarPago,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text(t.registerReviewAndPay, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          // El desglose es el que devolvio el servidor, linea por linea. Es lo
          // mismo que va a cobrar, asi que no puede diferir.
          child: quote == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Skeleton(width: 160, height: 16),
                )
              : Column(
                  children: [
                    for (final linea in quote.lines)
                      SessionSummaryRow(
                        label: linea.quantity > 1
                            ? t.registerLineWithQuantity(
                                linea.label,
                                linea.quantity,
                              )
                            : linea.label,
                        value: Fmt.money(
                          linea.amount.amount,
                          linea.amount.currency,
                        ),
                      ),
                    // Sin cargo por servicio la linea **no se pinta**: un
                    // "Bs 0,00" promete un cargo que hoy no se cobra.
                    if (quote.serviceFee != null)
                      SessionSummaryRow(
                        label: quote.serviceFeeLabel ?? t.registerServiceFee,
                        value: Fmt.money(
                          quote.serviceFee!.amount,
                          quote.serviceFee!.currency,
                        ),
                      ),
                    const AppDivider(),
                    SessionSummaryRow(
                      label: t.commonTotal,
                      value: Fmt.money(
                        quote.total.amount,
                        quote.total.currency,
                      ),
                      emphasise: true,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.registerPaymentMethod, style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        // El QR del organizador sólo se ofrece si esta carrera tiene uno
        // cargado: enseñarlo si no, sería prometer un pago que el servidor va a
        // rechazar en el último paso.
        if (!marathon.acceptsQrPayment)
          _ProofStatus(
            icon: Icons.info_outline_rounded,
            title: t.registerNoPaymentMethodTitle,
            detail: t.registerNoPaymentMethodBody,
            tone: c.textSecondary,
          )
        else
          for (final method in RacePaymentMethod.offered)
            _SelectableTile(
              title: method.label(t),
              subtitle: switch (method) {
                RacePaymentMethod.card => t.registerCardSubtitle,
                RacePaymentMethod.qr => t.registerQrSubtitle,
                RacePaymentMethod.bankTransfer =>
                  t.registerBankTransferSubtitle,
                RacePaymentMethod.qrManual => t.registerQrManualSubtitle,
              },
              selected: _method == method,
              onTap: () => setState(() => _method = method),
            ),
        if (_method == RacePaymentMethod.card) ...[
          const SizedBox(height: AppSpacing.md),
          _CardForm(
            number: _cardNumber,
            holder: _cardHolder,
            expiry: _cardExpiry,
            cvv: _cardCvv,
          ),
        ],
        if (flow.isAwaitingPayment) ...[
          const SizedBox(height: AppSpacing.md),
          _PendingPayment(payment: flow.payment!),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppCheckbox(
              value: _acceptedTerms,
              semanticsLabel: t.registerAcceptTermsSemantics,
              onChanged: (v) => setState(() => _acceptedTerms = v),
            ),
            Expanded(
              child: Text(
                t.registerAcceptTerms,
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        if (flow.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _mensajeDeError(flow, t),
            style: context.text.bodySm.copyWith(color: c.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.registerTryAnotherCard,
            variant: AppButtonVariant.outline,
            onPressed: _flow.retryPayment,
          ),
        ],
      ],
    );
  }

  /// El texto del servidor ya es humano; lo que se traduce aqui es el motivo
  /// del rechazo, que llega como codigo estable.
  String _mensajeDeError(RegistrationFlowState flow, AppLocalizations t) {
    final motivo = flow.payment?.failureReason;

    return switch (motivo) {
      'card_declined' => t.paymentCardDeclined,
      'expired_card' => t.paymentExpiredCard,
      'invalid_card' => t.paymentInvalidCard,
      'qr_expired' => t.paymentQrExpired,
      _ => flow.error?.localized(t) ?? t.paymentFailedGeneric,
    };
  }

  Widget _footer(
    Marathon marathon,
    UserProfile? profile,
    RegistrationFlowState flow,
  ) {
    final c = context.colors;
    final t = context.l10n;
    final isLast = _step == 2;
    final total = flow.quote?.total;
    final puedeAvanzar = switch (_step) {
      0 =>
        _docId.text.trim().isNotEmpty &&
            _phone.text.trim().isNotEmpty &&
            _knowsCam != null &&
            _acceptsDonorCall != null,
      1 => marathon.categories.isEmpty || _categoryId != null,
      _ => _acceptedTerms && !flow.isAwaitingPayment,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.commonTotal,
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
                ),
                Text(
                  total == null
                      // Antes del paso 1 no hay borrador: lo unico honesto que
                      // se puede mostrar es el precio de catalogo.
                      ? Fmt.money(
                          marathon.entryFee.amount,
                          marathon.entryFee.currency,
                        )
                      : Fmt.money(total.amount, total.currency),
                  style: context.text.headingMd,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: AppButton(
                label: isLast ? t.registerPayAndRegister : t.commonContinue,
                isLoading: flow.busy,
                onPressed: !puedeAvanzar
                    ? null
                    : isLast
                    ? () => _pay(marathon)
                    : () => _next(marathon, profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de tarjeta. Viajan una sola vez y no se guardan: de todo esto solo
/// sobreviven la marca y los cuatro ultimos digitos, y eso lo decide el
/// servidor.
class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.number,
    required this.holder,
    required this.expiry,
    required this.cvv,
  });

  final TextEditingController number;
  final TextEditingController holder;
  final TextEditingController expiry;
  final TextEditingController cvv;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      children: [
        AppTextField(
          label: t.registerCardNumber,
          controller: number,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
            LengthLimitingTextInputFormatter(23),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.registerCardholder,
          controller: holder,
          hint: t.registerCardholderHint,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: t.registerExpiry,
                controller: expiry,
                hint: t.registerExpiryHint,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: t.registerCvv,
                controller: cvv,
                isPassword: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cobro abierto: QR que hay que escanear, o transferencia por confirmar.
///
/// La pantalla sondea sola —lo hace el notifier— asi que aqui no hay ningun
/// boton de "ya pague": lo unico que se puede hacer es esperar.
class _PendingPayment extends StatelessWidget {
  const _PendingPayment({required this.payment});

  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          if (payment.bankReference != null)
            Text(
              context.l10n.registerReference(payment.bankReference!),
              style: context.text.titleMd,
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.registerWaitingForPayment,
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pregunta de sí/no sin respuesta por defecto.
///
/// Sin valor inicial a propósito: una de las dos es un consentimiento para
/// llamar por teléfono, y un "no" premarcado o un "sí" premarcado son las dos
/// formas de responder por el usuario.
class _YesNo extends StatelessWidget {
  const _YesNo({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: context.text.bodyMd),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppChip(
              label: context.l10n.commonYes,
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: context.l10n.commonNo,
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cobro por QR del organizador, verificado a mano. **Temporal**: ver
/// `docs/pago-qr-manual.md` en la API.
///
/// Aquí sí hay botón, al revés que en [_PendingPayment]: al otro lado no hay un
/// banco que responda solo, hay una persona esperando una imagen. Sin ese botón
/// la pantalla se quedaría girando para siempre.
class _ManualQrPayment extends StatelessWidget {
  const _ManualQrPayment({
    required this.payment,
    required this.busy,
    required this.onUpload,
    required this.onCancel,
  });

  final PaymentInfo payment;
  final bool busy;
  final Future<void> Function(ImageSource) onUpload;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final proof = payment.proof;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El QR lo dibuja la app con el texto que mandó la API. No hay
        // version imagen: el QR es texto y nada mas.
        if (payment.qrPayload != null)
          Center(child: _QrCode(data: payment.qrPayload!)),
        if (payment.qrReference != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            t.registerPaymentNote,
            style: context.text.labelSm,
            textAlign: TextAlign.center,
          ),
          SelectableText(
            payment.qrReference!,
            style: context.text.titleMd,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // Lo que subió, no solo que subió algo: sin la imagen a la vista no hay
        // forma de comprobar que se mandó la captura correcta.
        if (proof != null) _UploadedProof(imageUrl: proof.imageUrl),
        if (proof?.state == ProofState.inReview)
          _ProofStatus(
            icon: Icons.hourglass_top_rounded,
            title: t.registerProofInReviewTitle,
            detail: t.registerProofInReviewBody,
            tone: c.textSecondary,
          )
        else ...[
          if (proof?.state == ProofState.rejected)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ProofStatus(
                icon: Icons.error_outline_rounded,
                title: t.registerProofRejectedTitle,
                // El motivo lo escribió el organizador: se pinta tal cual,
                // porque es lo único que le dice al corredor qué corregir.
                detail: proof?.note ?? t.registerProofRejectedFallback,
                tone: c.error,
              ),
            ),
          AppButton(
            label: t.registerProofUpload,
            icon: Icons.photo_library_outlined,
            isLoading: busy,
            onPressed: () => onUpload(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.registerProofTakePhoto,
            variant: AppButtonVariant.outline,
            icon: Icons.photo_camera_outlined,
            onPressed: busy ? null : () => onUpload(ImageSource.camera),
          ),
        ],
        if (payment.qrInstructions != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            payment.qrInstructions!,
            style: context.text.bodySm.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Salida del flujo. Va siempre, también con un comprobante en revisión:
        // quien pagó de más o se equivocó de carrera necesita poder cerrar
        // esto, y sin botón la única salida es abandonar la pantalla y dejar un
        // cobro abierto colgando para siempre.
        AppButton(
          label: t.registerCancelPayment,
          variant: AppButtonVariant.ghost,
          onPressed: busy ? null : onCancel,
        ),
      ],
    );
  }
}

/// El QR de cobro, dibujado en el móvil desde el texto que manda la API.
///
/// Se dibuja y no se descarga: el texto son unos bytes donde la imagen son
/// cientos de KB, sale nítido a cualquier tamaño y se pinta aunque la conexión
/// esté caída — que es justo lo que pasa cuando alguien saca el teléfono para
/// pagar.
///
/// El violeta de marca va sobre blanco **siempre**, en los dos temas: un QR es
/// un contraste antes que un adorno, y el violeta claro del tema oscuro sobre
/// fondo oscuro no lo lee ningún escáner. La corrección de errores alta es lo
/// que deja teñir los módulos sin que deje de leerse.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    const tinta = LightTokens.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: QrImageView(
        data: data,
        size: 220,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        // Sin margen propio: el padding blanco del contenedor ya es la zona
        // silenciosa que el escáner necesita alrededor del código.
        padding: EdgeInsets.zero,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: tinta),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: tinta,
        ),
      ),
    );
  }
}

/// Miniatura del comprobante ya subido, con toque para verlo entero.
///
/// Es la respuesta a "¿y qué mandé?": sin esto el corredor solo tiene la
/// palabra del estado, y una captura equivocada se descubre recién cuando el
/// organizador la rechaza.
class _UploadedProof extends StatelessWidget {
  const _UploadedProof({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            imageUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _ProofStatus extends StatelessWidget {
  const _ProofStatus({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: tone),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleMd.copyWith(color: tone)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: context.text.bodySm.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final labels = [
      t.registerStepDetails,
      t.registerStepCategory,
      t.registerStepPay,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.base,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDurations.base,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? c.primary : c.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    labels[i],
                    style: context.text.labelSm.copyWith(
                      color: i <= step ? c.primary : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSm),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md + 2,
            ),
            decoration: BoxDecoration(
              color: c.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(value, style: context.text.bodyMd),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isCheckbox = false,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final bool isCheckbox;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Row(
              children: [
                Icon(
                  isCheckbox
                      ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                      : (selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded),
                  size: 20,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMd),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.text.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: context.text.titleMd.copyWith(color: c.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.bibNumber,
    required this.marathonName,
    required this.onViewRace,
    required this.onHome,
  });

  final String bibNumber;
  final String marathonName;
  final VoidCallback onViewRace;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppDurations.slow,
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.successBg,
                ),
                child: Icon(Icons.check_rounded, size: 38, color: c.success),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.registerSuccessTitle,
              style: context.text.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.registerSuccessBody(marathonName),
              textAlign: TextAlign.center,
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.base),
            AppBadge(
              label: context.l10n.commonBib(bibNumber),
              icon: Icons.confirmation_num_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.l10n.registerViewMyRace,
              onPressed: onViewRace,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.l10n.registerBackToHome,
              variant: AppButtonVariant.ghost,
              onPressed: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
