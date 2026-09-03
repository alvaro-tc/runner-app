import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/admin/presentation/widgets/admin_paginator.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La cola de cobros del organizador.
///
/// Una sola lista para los dos metodos que se validan a mano —transferencia y
/// QR— porque el trabajo no se organiza por metodo: lo que hay delante es
/// gente que dice haber pagado, y como pago es una columna mas. Dos bandejas
/// obligarian a mirar en las dos para saber si a alguien le falta el visto.
///
/// Cada fila lleva **quien la valido**. Es el dato por el que existe esta
/// pantalla: un cobro acreditado sin nombre detras no se puede auditar.
class OrganizerTicketsPage extends ConsumerStatefulWidget {
  const OrganizerTicketsPage({super.key});

  @override
  ConsumerState<OrganizerTicketsPage> createState() =>
      _OrganizerTicketsPageState();
}

class _OrganizerTicketsPageState extends ConsumerState<OrganizerTicketsPage> {
  /// null = todas. El servidor pagina, asi que el filtro viaja: cortar aqui
  /// dejaria fuera los cobros de la carrera buscada que no cayeran en la
  /// primera pagina.
  String? _maratonId;

  /// Arranca en `pending`: lo que se abre a hacer es lo que falta por validar,
  /// no el historico.
  String? _estado = 'pending';

  int _pagina = 1;
  int _porPagina = adminPageSizes.first;

  /// Cambiar de filtro vuelve a la primera pagina: la pagina 4 de otra
  /// consulta no existe y devuelve una lista vacia.
  void _reiniciar(VoidCallback cambio) => setState(() {
    cambio();
    _pagina = 1;
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final consulta = (
      marathonId: _maratonId,
      estado: _estado,
      pagina: _pagina,
      porPagina: _porPagina,
    );
    final tickets = ref.watch(adminTicketsProvider(consulta));
    final maratones = ref.watch(adminMarathonsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(t.organizerTicketsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              0,
            ),
            child: DropdownButtonFormField<String?>(
              initialValue: _maratonId,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.organizerMarathon),
              items: [
                DropdownMenuItem(child: Text(t.organizerAllMarathons)),
                for (final m in maratones)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => _reiniciar(() => _maratonId = id),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final estado in <String?>[null, ...adminPaymentStatuses])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(
                        estado == null
                            ? t.adminRoleAll
                            : paymentStatusLabel(t, estado),
                      ),
                      selected: _estado == estado,
                      onSelected: (_) => _reiniciar(() => _estado = estado),
                    ),
                  ),
              ],
            ),
          ),
          AdminPaginator(
            total: tickets.value?.total,
            pagina: _pagina,
            porPagina: _porPagina,
            onPagina: (p) => setState(() => _pagina = p),
            onPorPagina: (n) => _reiniciar(() => _porPagina = n),
          ),
          Expanded(
            child: tickets.when(
              loading: () =>
                  const Center(child: Skeleton(width: 180, height: 20)),
              error: (error, _) => ErrorStateView(
                message: error is Failure
                    ? error.localized(t)
                    : t.adminLoadFailed,
                onRetry: () => ref.invalidate(adminTicketsProvider(consulta)),
              ),
              data: (pagina) => pagina.tickets.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: t.organizerNoTicketsTitle,
                      message: t.organizerNoTicketsBody,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        0,
                        AppSpacing.screenH,
                        AppSpacing.xxl,
                      ),
                      itemCount: pagina.tickets.length,
                      separatorBuilder: (_, _) => const AppDivider(),
                      itemBuilder: (context, i) => _Fila(
                        ticket: pagina.tickets[i],
                        onTap: () => _abrir(pagina.tickets[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrir(AdminTicket ticket) async {
    final cambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Ficha(ticket: ticket),
    );
    // La familia entera: acreditar un cobro lo saca de "pendientes" y lo mete
    // en "pagados", que es otra consulta.
    if (cambio ?? false) ref.invalidate(adminTicketsProvider);
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.ticket, required this.onTap});

  final AdminTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.runner, style: context.text.bodyMd),
                  Text(
                    '${ticket.marathon} · ${paymentMethodLabel(t, ticket.method)}',
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  // La auditoria en la propia fila y no solo al abrir: la
                  // pregunta que se hace sobre un pago acreditado es quien lo
                  // aprobo, y tener que tocar cada uno para verlo convierte
                  // una revision en una tarde.
                  Text(
                    auditLine(t, ticket),
                    style: context.text.labelSm.copyWith(
                      color: switch (ticket) {
                        final x when x.refundedBy != null => c.warning,
                        final x when x.validatedBy != null => c.success,
                        _ => c.textSecondary,
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.money(ticket.amountCents / 100, ticket.currency),
                  style: context.text.bodyMd,
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppBadge(
                  label: paymentStatusLabel(t, ticket.status),
                  tone: paymentStatusTone(ticket.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El comprobante y los dos botones que cierran el cobro.
///
/// En hoja y no en pantalla completa: se abre desde una cola a la que se
/// vuelve enseguida, y lo que se mira es una imagen y cuatro datos.
class _Ficha extends ConsumerStatefulWidget {
  const _Ficha({required this.ticket});

  final AdminTicket ticket;

  @override
  ConsumerState<_Ficha> createState() => _FichaState();
}

class _FichaState extends ConsumerState<_Ficha> {
  bool _enviando = false;
  String? _error;

  /// Manda la orden y cierra. Un solo sitio que sepa apagar los botones y
  /// contar el fallo: las tres acciones de esta hoja fallan igual.
  Future<void> _enviar(Future<void> Function() accion) async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await accion();
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _aprobar() async {
    final t = context.l10n;
    final ticket = widget.ticket;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(t.organizerApproveTitle),
        content: Text(
          t.organizerApproveBody(
            ticket.runner,
            Fmt.money(ticket.amountCents / 100, ticket.currency),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: Text(t.organizerApprove),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final api = ref.read(adminApiProvider);
    // Dos caminos porque son dos cosas distintas: aprobar la captura que subio
    // el corredor, o dar por buena una transferencia que nunca trajo imagen.
    // Los dos acaban acreditando por la misma via en el servidor.
    await _enviar(
      () => ticket.proofId != null
          ? api.approveProof(ticket.proofId!)
          : api.confirmTransfer(ticket.id, reference: ticket.proofReference),
    );
  }

  Future<void> _rechazar() async {
    final t = context.l10n;
    final motivo = await _pedirMotivo(
      titulo: t.organizerRejectTitle,
      cuerpo: t.organizerRejectBody,
      etiqueta: t.organizerRejectHint,
      accion: t.organizerReject,
      vacio: t.organizerRejectRequired,
    );
    if (motivo == null || !mounted) return;

    await _enviar(
      () => ref
          .read(adminApiProvider)
          .rejectProof(widget.ticket.proofId!, motivo),
    );
  }

  /// Devolver el dinero. **Anula la inscripcion**: el cupo vuelve al pozo, asi
  /// que el aviso lo dice con todas las letras antes de pedir el motivo.
  Future<void> _devolver() async {
    final t = context.l10n;
    final ticket = widget.ticket;
    final motivo = await _pedirMotivo(
      titulo: t.organizerRefundTitle,
      cuerpo: t.organizerRefundBody(
        ticket.runner,
        Fmt.money(ticket.amountCents / 100, ticket.currency),
      ),
      etiqueta: t.organizerRefundHint,
      accion: t.organizerRefund,
      vacio: t.organizerRefundRequired,
    );
    if (motivo == null || !mounted) return;

    await _enviar(
      () => ref.read(adminApiProvider).refundPayment(ticket.id, motivo),
    );
  }

  /// Las dos acciones que hace falta explicar piden lo mismo: un motivo que
  /// alguien va a leer despues. Un solo dialogo con dos textos, no dos
  /// dialogos identicos que se separan en cuanto uno se toca.
  Future<String?> _pedirMotivo({
    required String titulo,
    required String cuerpo,
    required String etiqueta,
    required String accion,
    required String vacio,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _DialogoDeMotivo(
      titulo: titulo,
      cuerpo: cuerpo,
      etiqueta: etiqueta,
      accion: accion,
      vacio: vacio,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final ticket = widget.ticket;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ticket.runner, style: context.text.titleMd),
                  ),
                  AppBadge(
                    label: paymentStatusLabel(t, ticket.status),
                    tone: paymentStatusTone(ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Dato(label: t.organizerMarathon, value: ticket.marathon),
              _Dato(
                label: t.organizerAmount,
                value: Fmt.money(ticket.amountCents / 100, ticket.currency),
              ),
              _Dato(
                label: t.organizerMethod,
                value: paymentMethodLabel(t, ticket.method),
              ),
              if ((ticket.runnerCi ?? '').isNotEmpty)
                _Dato(label: t.organizerCi, value: ticket.runnerCi!),
              if ((ticket.runnerEmail ?? '').isNotEmpty)
                _Dato(label: t.adminEmail, value: ticket.runnerEmail!),
              if ((ticket.runnerPhone ?? '').isNotEmpty)
                _Dato(label: t.organizerPhone, value: ticket.runnerPhone!),
              if ((ticket.bibNumber ?? '').isNotEmpty)
                _Dato(label: t.organizerBib, value: ticket.bibNumber!),
              if ((ticket.proofReference ?? '').isNotEmpty)
                _Dato(
                  label: t.organizerReference,
                  value: ticket.proofReference!,
                ),
              // La auditoria, con el nombre completo y la fecha: es lo que se
              // le ensena a quien pregunta quien acredito este dinero. Aprobar
              // y devolver son dos asientos distintos y se pintan los dos: a
              // veces son dos personas, y quedarse con el ultimo borraria la
              // mitad de la historia.
              _Dato(
                label: t.organizerAudit,
                value: ticket.validatedBy == null
                    ? t.organizerNotValidated
                    : _firma(ticket.validatedBy!, ticket.validatedAt),
              ),
              if (ticket.refundedBy != null)
                _Dato(
                  label: t.organizerRefundedLabel,
                  value: _firma(ticket.refundedBy!, ticket.refundedAt),
                ),
              if ((ticket.refundReason ?? '').isNotEmpty)
                _Dato(
                  label: t.organizerRefundReason,
                  value: ticket.refundReason!,
                ),
              if ((ticket.proofNote ?? '').isNotEmpty)
                _Dato(label: t.organizerNote, value: ticket.proofNote!),
              const SizedBox(height: AppSpacing.md),
              if (ticket.hasProof)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.network(
                    ticket.proofImageUrl!,
                    fit: BoxFit.contain,
                    // Sin recorte: lo unico que importa de esta imagen es que
                    // el numero de transaccion siga siendo legible.
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        t.organizerProofUnavailable,
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  t.organizerProofNone,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: context.text.bodySm.copyWith(color: c.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (ticket.canReviewProof || ticket.canConfirmTransfer)
                AppButton(
                  label: t.organizerApprove,
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _enviando,
                  onPressed: _enviando ? null : _aprobar,
                ),
              if (ticket.canReviewProof) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: t.organizerReject,
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  isLoading: _enviando,
                  onPressed: _enviando ? null : _rechazar,
                ),
              ],
              // Cobrado: lo que queda por hacer es devolverlo. Va en rojo y
              // pide motivo porque no es cerrar una tarea, es anularle la
              // inscripcion a alguien.
              if (ticket.canRefund)
                AppButton(
                  label: t.organizerRefund,
                  icon: Icons.undo_rounded,
                  variant: AppButtonVariant.danger,
                  isLoading: _enviando,
                  onPressed: _enviando ? null : _devolver,
                ),
              if (!ticket.pending && !ticket.canRefund)
                Text(
                  t.organizerAlreadySettled,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: context.text.labelSm.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: context.text.bodySm)),
        ],
      ),
    );
  }
}

/// Pide un motivo y no deja seguir sin el.
///
/// Lo comparten rechazar y devolver: en el rechazo el motivo lo lee el corredor
/// —sin el vuelve a subir la misma captura— y en la devolucion queda en la
/// auditoria. Es la misma pantalla con otras palabras.
class _DialogoDeMotivo extends StatefulWidget {
  const _DialogoDeMotivo({
    required this.titulo,
    required this.cuerpo,
    required this.etiqueta,
    required this.accion,
    required this.vacio,
  });

  final String titulo;
  final String cuerpo;
  final String etiqueta;
  final String accion;

  /// Lo que se dice cuando lo dejan en blanco.
  final String vacio;

  @override
  State<_DialogoDeMotivo> createState() => _DialogoDeMotivoState();
}

class _DialogoDeMotivoState extends State<_DialogoDeMotivo> {
  final _texto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.cuerpo, style: context.text.bodySm),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: widget.etiqueta,
            controller: _texto,
            maxLines: 3,
            errorText: _error,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        TextButton(
          onPressed: () {
            final motivo = _texto.text.trim();
            if (motivo.isEmpty) {
              setState(() => _error = widget.vacio);
              return;
            }
            Navigator.of(context).pop(motivo);
          },
          child: Text(widget.accion),
        ),
      ],
    );
  }
}

/// El nombre visible de un estado de cobro. Sale del ARB: el servidor manda la
/// clave y el idioma lo pone quien pinta.
String paymentStatusLabel(AppLocalizations t, String status) =>
    switch (status) {
      'paid' => t.organizerStatusPaid,
      'failed' => t.organizerStatusFailed,
      'refunded' => t.organizerStatusRefunded,
      _ => t.organizerStatusPending,
    };

AppTone paymentStatusTone(String status) => switch (status) {
  'paid' => AppTone.success,
  'failed' => AppTone.error,
  'refunded' => AppTone.neutral,
  _ => AppTone.warning,
};

String paymentMethodLabel(AppLocalizations t, String method) =>
    switch (method) {
      'qr_manual' => t.organizerMethodQr,
      'bank_transfer' => t.organizerMethodTransfer,
      'card' => t.organizerMethodCard,
      _ => t.organizerMethodOther,
    };

/// «Nombre · 4 mar 18:20». Sin fecha, solo el nombre: es el dato que se
/// pregunta, y una fecha inventada seria peor que ninguna.
String _firma(String nombre, DateTime? cuando) => cuando == null
    ? nombre
    : '$nombre · ${Fmt.dayMonth(cuando)} ${Fmt.timeOfDay(cuando)}';

/// Lo que dice la fila sobre quien decidio este cobro.
///
/// La devolucion manda sobre la aprobacion: es lo ultimo que le paso al dinero,
/// y pintar «validado por» sobre un cobro devuelto es contar la mitad.
String auditLine(AppLocalizations t, AdminTicket ticket) {
  if (ticket.refundedBy != null) {
    return t.organizerRefundedBy(ticket.refundedBy!);
  }
  if (ticket.validatedBy != null) {
    return t.organizerValidatedBy(ticket.validatedBy!);
  }
  return t.organizerNotValidated;
}
