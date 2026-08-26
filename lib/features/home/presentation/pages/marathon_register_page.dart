import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/presentation/providers/marathon_providers.dart';
import 'package:paceup/features/profile/domain/entities/user_profile.dart';
import 'package:paceup/features/profile/presentation/providers/profile_provider.dart';
import 'package:paceup/features/races/domain/entities/registration.dart';
import 'package:paceup/features/races/presentation/providers/registration_provider.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/phone_field.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

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
  final _proofReference = TextEditingController();
  final _cardNumber = TextEditingController(text: _tarjetaDeEjemplo);
  final _cardHolder = TextEditingController();
  final _cardExpiry = TextEditingController(text: '12/30');
  final _cardCvv = TextEditingController(text: '123');

  int _step = 0;
  String _shirtSize = 'M';
  String? _categoryId;
  final _selectedExtras = <String>{};
  RacePaymentMethod _method = RacePaymentMethod.card;
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
    _proofReference.dispose();
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
        extras: [
          for (final id in _selectedExtras) ExtraSelection(extraId: id),
        ],
      ),
      _ => false,
    };

    if (ok && mounted) _goTo(_step + 1);
  }

  RegistrationPersonalData _datosPersonales(UserProfile? profile) =>
      RegistrationPersonalData(
        fullName: profile?.fullName.trim().isNotEmpty ?? false
            ? profile!.fullName
            : 'Corredor',
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

    final ok = await _flow.uploadProof(
      filePath: imagen.path,
      reference: _proofReference.text.trim(),
    );
    if (!mounted) return;

    context.showSnack(
      ok
          ? 'Receipt sent. The organiser will check it and confirm your place.'
          : ref.read(registrationFlowProvider).error?.message ??
                'We could not upload that receipt.',
    );
  }

  /// La caducidad se escribe `MM/AA` y viaja como dos enteros.
  CardDetails _tarjeta() {
    final partes = _cardExpiry.text.split('/');
    final mes = int.tryParse(partes.first.trim()) ?? 12;
    final anio = int.tryParse(partes.length > 1 ? partes[1].trim() : '') ?? 30;

    return CardDetails(
      number: _cardNumber.text,
      holder: _cardHolder.text.trim().isEmpty
          ? 'CORREDOR PACEUP'
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
            semanticsLabel: 'Go back',
            onPressed: () => _step == 0 ? context.pop() : _goTo(_step - 1),
          ),
        ),
        title: const Text('Registration'),
      ),
      body: marathon.when(
        loading: () => const Center(child: Skeleton(width: 200, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
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
        _footer(marathon, profile, flow),
      ],
    );
  }

  // ------------------------------------------------------------- step one

  Widget _detailsStep(UserProfile? profile) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Your details', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Taken from your profile. Change them in Profile if anything is out '
          'of date.',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReadOnlyField(label: 'Full name', value: profile?.fullName ?? '—'),
        _ReadOnlyField(
          label: 'Date of birth',
          value: profile == null ? '—' : Fmt.fullDate(profile.birthDate),
        ),
        _ReadOnlyField(label: 'Gender', value: profile?.gender.label ?? '—'),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'ID number',
          controller: _docId,
          hint: 'Goes on your bib record',
          textInputAction: TextInputAction.next,
          // El boton de continuar depende de este campo: sin repintar, se
          // quedaria gris con el documento ya escrito.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        PhoneField(
          label: 'Phone',
          controller: _phone,
          hint: '70000000',
          textInputAction: TextInputAction.next,
          // Igual que el documento: el botón de continuar depende de él.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email (optional)',
          controller: _email,
          hint: 'Where we send your confirmation',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('About the CAM', style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        _YesNo(
          question: 'Do you know the work the CAM does?',
          value: _knowsCam,
          onChanged: (v) => setState(() => _knowsCam = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _YesNo(
          question:
              'May we call you about becoming a CAM donor?',
          value: _acceptsDonorCall,
          onChanged: (v) => setState(() => _acceptsDonorCall = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'Emergency contact name',
          controller: _emergencyName,
          hint: 'Who should we call?',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Emergency contact phone',
          controller: _emergencyPhone,
          hint: '+591 70000001',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Shirt size', style: context.text.labelSm),
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Category & extras', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.lg),
        if (marathon.categories.isEmpty)
          Text(
            'This event runs a single distance: '
            '${Fmt.distance(marathon.distanceKm)}.',
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          )
        else
          for (final category in marathon.categories)
            _SelectableTile(
              title: category.label,
              subtitle: Fmt.distance(category.distanceKm),
              trailing: category.surcharge.amount == 0
                  ? 'Included'
                  : Fmt.money(
                      category.surcharge.amount,
                      category.surcharge.currency,
                    ),
              selected: _categoryId == category.id,
              onTap: () => setState(() => _categoryId = category.id),
            ),
        const SizedBox(height: AppSpacing.lg),
        Text('Optional extras', style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        if (marathon.extras.isEmpty)
          Text(
            'No add-ons for this event.',
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

  Widget _reviewStep(Marathon marathon, RegistrationFlowState flow) {
    final c = context.colors;
    final quote = flow.quote;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Review & pay', style: context.text.headingMd),
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
                            ? '${linea.label} × ${linea.quantity}'
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
                        label: quote.serviceFeeLabel ?? 'Service fee',
                        value: Fmt.money(
                          quote.serviceFee!.amount,
                          quote.serviceFee!.currency,
                        ),
                      ),
                    const AppDivider(),
                    SessionSummaryRow(
                      label: 'Total',
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
        Text('Payment method', style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        // El QR del organizador sólo se ofrece si esta carrera tiene uno
        // cargado: enseñarlo si no, sería prometer un pago que el servidor va a
        // rechazar en el último paso.
        for (final method in RacePaymentMethod.values)
          if (method != RacePaymentMethod.qrManual || marathon.acceptsQrPayment)
            _SelectableTile(
              title: method.label,
              subtitle: switch (method) {
                RacePaymentMethod.card =>
                  'Charged the moment your place is taken',
                RacePaymentMethod.qr => 'Scan and pay; we wait for the bank',
                RacePaymentMethod.bankTransfer =>
                  'Transfer and wait for the organiser to confirm',
                RacePaymentMethod.qrManual =>
                  'Pay with your banking app, then upload the receipt',
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
          if (flow.payment!.method.needsProof)
            _ManualQrPayment(
              payment: flow.payment!,
              reference: _proofReference,
              busy: flow.busy,
              onUpload: _subirComprobante,
            )
          else
            _PendingPayment(payment: flow.payment!),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppCheckbox(
              value: _acceptedTerms,
              semanticsLabel: 'Accept event terms',
              onChanged: (v) => setState(() => _acceptedTerms = v),
            ),
            Expanded(
              child: Text(
                'I accept the event rules and the refund policy.',
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        if (flow.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _mensajeDeError(flow),
            style: context.text.bodySm.copyWith(color: c.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Try another card',
            variant: AppButtonVariant.outline,
            onPressed: _flow.retryPayment,
          ),
        ],
      ],
    );
  }

  /// El texto del servidor ya es humano; lo que se traduce aqui es el motivo
  /// del rechazo, que llega como codigo estable.
  String _mensajeDeError(RegistrationFlowState flow) {
    final motivo = flow.payment?.failureReason;

    return switch (motivo) {
      'card_declined' => 'The bank turned this card down. Try another one.',
      'expired_card' => 'That card is expired.',
      'invalid_card' => 'Those card details do not look right.',
      'qr_expired' => 'The QR expired before it was paid. Generate a new one.',
      _ => flow.error?.message ?? 'Payment could not be completed.',
    };
  }

  Widget _footer(
    Marathon marathon,
    UserProfile? profile,
    RegistrationFlowState flow,
  ) {
    final c = context.colors;
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
                  'Total',
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
                label: isLast ? 'Pay and register' : 'Continue',
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
    return Column(
      children: [
        AppTextField(
          label: 'Card number',
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
          label: 'Cardholder',
          controller: holder,
          hint: 'As printed on the card',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Expiry',
                controller: expiry,
                hint: 'MM/YY',
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'CVV',
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
          if (payment.qrImageUrl != null)
            Image.network(
              payment.qrImageUrl!,
              height: 180,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          if (payment.bankReference != null)
            Text(
              'Reference: ${payment.bankReference}',
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
                'Waiting for the payment to clear…',
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
              label: 'Yes',
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'No',
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
    required this.reference,
    required this.busy,
    required this.onUpload,
  });

  final PaymentInfo payment;
  final TextEditingController reference;
  final bool busy;
  final Future<void> Function(ImageSource) onUpload;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final proof = payment.proof;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (payment.qrImageUrl != null)
            Center(
              child: ColoredBox(
                // Un QR sobre fondo de color no siempre lo lee el escáner: el
                // contraste es parte del código, no decoración.
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Image.network(
                    payment.qrImageUrl!,
                    height: 200,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          if (payment.qrInstructions != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              payment.qrInstructions!,
              style: context.text.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
          if (payment.qrReference != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Payment note', style: context.text.labelSm),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              payment.qrReference!,
              style: context.text.headingMd,
            ),
            Text(
              'Write it in the transfer detail. It is how the organiser links '
              'your payment to this entry.',
              style: context.text.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Lo que subió, no solo que subió algo: sin la imagen a la vista no
          // hay forma de comprobar que se mandó la captura correcta.
          if (proof != null) _UploadedProof(imageUrl: proof.imageUrl),
          if (proof?.state == ProofState.inReview)
            _ProofStatus(
              icon: Icons.hourglass_top_rounded,
              title: 'Receipt under review',
              detail:
                  'Your place is not booked yet. The organiser confirms it '
                  'once they see the money in the account.',
              tone: c.textSecondary,
            )
          else ...[
            if (proof?.state == ProofState.rejected)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProofStatus(
                  icon: Icons.error_outline_rounded,
                  title: 'Receipt rejected',
                  // El motivo lo escribió el organizador: se pinta tal cual,
                  // porque es lo único que le dice al corredor qué corregir.
                  detail: proof?.note ?? 'Upload a clearer one.',
                  tone: c.error,
                ),
              ),
            AppTextField(
              label: 'Transaction number (optional)',
              controller: reference,
              hint: 'From your banking app',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Upload receipt',
              icon: Icons.photo_library_outlined,
              isLoading: busy,
              onPressed: () => onUpload(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Take a photo',
              variant: AppButtonVariant.outline,
              icon: Icons.photo_camera_outlined,
              onPressed: busy ? null : () => onUpload(ImageSource.camera),
            ),
          ],
        ],
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
              child: Image.network(imageUrl, errorBuilder: (_, _, _) => const SizedBox.shrink()),
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

  static const _labels = ['Details', 'Category', 'Pay'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.base,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
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
                    _labels[i],
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
              "You're in",
              style: context.text.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your place at $marathonName is confirmed.',
              textAlign: TextAlign.center,
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.base),
            AppBadge(
              label: 'BIB $bibNumber',
              icon: Icons.confirmation_num_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'View my race', onPressed: onViewRace),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Back to home',
              variant: AppButtonVariant.ghost,
              onPressed: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
