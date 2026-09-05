import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/data/admin_api.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El puesto de mando: donde va cada corredor, y el boton que da la largada.
///
/// La maraton se elige arriba porque puede haber varias abiertas a la vez —una
/// corriendo y dos cargadas para el mes que viene— y el mapa solo puede mirar
/// una: sin selector habria que adivinar cual, y adivinar mal el dia de la
/// carrera es quedarse mirando un mapa vacio.
class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({this.readOnly = false, super.key});

  /// El puesto de mando del organizador: el mismo mapa y el mismo selector,
  /// sin los botones que mueven la carrera. Es una bandera y no una pantalla
  /// aparte porque lo unico que cambia es la barra de abajo, y una copia se
  /// quedaria sin los arreglos que reciba esta.
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final maratones = ref.watch(adminMarathonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminLiveTitle)),
      body: maratones.when(
        // Un refresco de fondo no vacia una pantalla que ya tiene datos.
        skipLoadingOnReload: true,
        loading: () => const Center(child: Skeleton(width: 180, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => ref.invalidate(adminMarathonsProvider),
        ),
        data: (lista) => lista.isEmpty
            ? EmptyState(
                icon: Icons.map_outlined,
                title: t.adminNoMarathonsTitle,
                message: t.adminNoMarathonsBody,
              )
            : _Tablero(marathons: lista, readOnly: readOnly),
      ),
    );
  }
}

class _Tablero extends ConsumerWidget {
  const _Tablero({required this.marathons, this.readOnly = false});

  final List<AdminMarathon> marathons;
  final bool readOnly;

  /// La que el selector deja elegida. Por defecto, la que se esta corriendo o
  /// preparando: el dia de la carrera es lo unico que se quiere ver al abrir la
  /// app, y en preparacion es justo cuando el mapa decide si se larga o se
  /// espera. Sin la preparacion aqui, el panel abria en otra maraton cualquiera
  /// —la primera de la lista— y el corral entero parecia vacio.
  AdminMarathon _elegida(String? id) {
    if (id != null) {
      for (final m in marathons) {
        if (m.id == id) return m;
      }
    }
    for (final m in marathons) {
      if (m.running) return m;
    }
    for (final m in marathons) {
      if (m.preparing) return m;
    }
    return marathons.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maraton = _elegida(ref.watch(selectedMarathonProvider));
    // El detalle es el unico que trae el trazado; la lista no. Sin el, el mapa
    // pinta corredores flotando sobre ninguna ruta.
    final detalle = ref.watch(adminMarathonProvider(maraton.id));
    final tablero = ref.watch(liveBoardProvider(maraton.id));

    return Column(
      children: [
        _Selector(marathons: marathons, current: maraton),
        Expanded(
          child: _Mapa(route: detalle.value?.route ?? const [], board: tablero),
        ),
        if (readOnly)
          _Estado(marathon: detalle.value ?? maraton, board: tablero)
        else
          _Controles(marathon: detalle.value ?? maraton, board: tablero),
      ],
    );
  }
}

class _Selector extends ConsumerWidget {
  const _Selector({required this.marathons, required this.current});

  final List<AdminMarathon> marathons;
  final AdminMarathon current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.sm,
      ),
      color: c.surface,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current.id,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                items: [
                  for (final m in marathons)
                    DropdownMenuItem(
                      value: m.id,
                      child: Row(
                        children: [
                          if (m.running || m.preparing)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: m.running ? c.success : c.warning,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              m.name,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMd,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (id) =>
                    ref.read(selectedMarathonProvider.notifier).select(id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({required this.route, required this.board});

  final List<GeoPoint> route;
  final LiveBoard board;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Stack(
      children: [
        Positioned.fill(
          child: RouteMapView(
            route: const [],
            guideRoute: route,
            markerEveryKm: 5,
            pins: [
              for (final corredor in board.runners.values)
                MapPin(
                  lat: corredor.lat,
                  lng: corredor.lng,
                  size: 34,
                  child: _Dorsal(
                    bib: corredor.bib,
                    // Ya cruzo la meta: sigue en el mapa —el organizador
                    // quiere ver donde esta todo el mundo— pero deja de
                    // contar como gente en carrera.
                    finished: board.finishedBibs.contains(corredor.key),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.screenH,
          child: _Contador(
            board: board,
            label: t.adminRunnersOnCourse(
              board.runners.length - board.finishedBibs.length,
            ),
            finished: board.finishedBibs.length,
          ),
        ),
        if (board.loading)
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.screenH,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// La chinche de un corredor. Solo el dorsal: es lo unico que manda el
/// servidor, y es lo unico que hace falta para gritarle a alguien por radio.
class _Dorsal extends StatelessWidget {
  const _Dorsal({required this.bib, this.finished = false});

  final String? bib;

  /// Ya llego a meta. Ver `LiveBoard.finishedBibs`.
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: finished ? c.success : c.primary,
        border: Border.all(color: c.surface, width: 2),
      ),
      child: Text(
        // El dorsal completo no entra en 34 px: los ultimos digitos son los que
        // distinguen a dos corredores del mismo evento.
        bib == null || bib!.isEmpty
            ? '·'
            : bib!.substring(bib!.length > 3 ? bib!.length - 3 : 0),
        style: context.text.labelSm.copyWith(color: c.onPrimary, fontSize: 9),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.board,
    required this.label,
    this.finished = 0,
  });

  final LiveBoard board;
  final String label;

  /// Cuantos ya cruzaron la meta. Cero = no se pinta: en una carrera que
  /// acaba de largar el numero solo ocupa sitio.
  final int finished;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: board.running ? c.success : c.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.text.labelSm),
          if (finished > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.sports_score_rounded, size: 14, color: c.success),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$finished',
              style: context.text.labelSm.copyWith(color: c.success),
            ),
          ],
        ],
      ),
    );
  }
}

/// El pie de solo lectura: en que fase esta la carrera, sin botones.
///
/// No es un `_Controles` con los botones apagados. Un boton gris invita a
/// pulsarlo y a preguntar por que no funciona; el organizador no puede dar la
/// largada y punto, asi que lo que ve es el estado, que es lo que si necesita.
class _Estado extends StatelessWidget {
  const _Estado({required this.marathon, required this.board});

  final AdminMarathon marathon;
  final LiveBoard board;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    // Manda el socket: la maraton se cargo hace rato y puede haber arrancado
    // desde el telefono del admin mientras tanto.
    final fase = board.loading ? marathon.phase : board.phase;
    final (texto, icono, color) = switch (fase) {
      MarathonPhase.finished => (
        t.adminAlreadyFinished,
        Icons.sports_score_rounded,
        c.textSecondary,
      ),
      MarathonPhase.inProgress => (
        t.organizerStateRunning,
        Icons.play_circle_outline_rounded,
        c.success,
      ),
      MarathonPhase.preparing => (
        t.adminPreparingNotice,
        Icons.hourglass_top_rounded,
        c.warning,
      ),
      MarathonPhase.notStarted => (
        t.organizerStateNotStarted,
        Icons.schedule_rounded,
        c.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: context.text.bodySm.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.organizerCannotStart,
              textAlign: TextAlign.center,
              style: context.text.labelSm.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Largar y cortar. Los dos piden confirmacion: uno arranca el cronometro de
/// todo el mundo y el otro lo para, y ninguno de los dos se deshace.
class _Controles extends ConsumerStatefulWidget {
  const _Controles({required this.marathon, required this.board});

  final AdminMarathon marathon;
  final LiveBoard board;

  @override
  ConsumerState<_Controles> createState() => _ControlesState();
}

class _ControlesState extends ConsumerState<_Controles> {
  bool _enviando = false;

  /// El estado que manda es el del socket: el objeto de la maraton se cargo
  /// hace rato y puede haber arrancado desde otro dispositivo mientras tanto.
  bool get _corriendo => widget.board.running || widget.marathon.running;

  bool get _terminada =>
      widget.board.finishedAt != null || widget.marathon.finished;

  /// Igual que [_corriendo]: manda el socket, que es lo ultimo que se supo.
  bool get _preparando =>
      !_corriendo &&
      !_terminada &&
      (widget.board.preparingAt != null || widget.marathon.preparing);

  String? get _mensaje =>
      widget.board.preparingMessage ?? widget.marathon.preparingMessage;

  /// Pone o quita la preparacion. Al ponerla se pregunta por el aviso: es el
  /// unico texto que van a leer los inscritos durante la espera, y escribirlo
  /// en ese momento —con el arco delante— sale mejor que dejarlo redactado la
  /// semana pasada.
  Future<void> _preparar({required bool activar}) async {
    final t = context.l10n;

    if (!activar) {
      final confirmado = await _confirmar(
        titulo: t.adminPrepareCancelConfirmTitle,
        cuerpo: t.adminPrepareCancelConfirmBody(widget.marathon.name),
        accion: t.adminPrepareCancel,
      );
      if (confirmado != true || !mounted) return;
      await _enviar((api) => api.cancelPreparation(widget.marathon.id));
      return;
    }

    final mensaje = await showDialog<String>(
      context: context,
      builder: (dialogo) => _DialogoDeAviso(
        inicial: _mensaje ?? '',
        marathonName: widget.marathon.name,
      ),
    );
    if (mensaje == null || !mounted) return;

    await _enviar(
      (api) => api.prepareMarathon(
        widget.marathon.id,
        // Vacio es "sin aviso propio": la app pinta su texto por defecto, en
        // el idioma de cada corredor, que es mejor que un hueco en blanco.
        message: mensaje.trim().isEmpty ? null : mensaje.trim(),
      ),
    );
  }

  Future<bool?> _confirmar({
    required String titulo,
    required String cuerpo,
    required String accion,
  }) {
    final t = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(titulo),
        content: Text(cuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: Text(accion),
          ),
        ],
      ),
    );
  }

  /// Manda la orden y refresca. Un solo sitio que sepa apagar el boton y
  /// contar el fallo: las cuatro acciones del panel fallan igual.
  Future<void> _enviar(Future<void> Function(AdminApi) accion) async {
    setState(() => _enviando = true);
    try {
      await accion(ref.read(adminApiProvider));
      // La lista lleva el estado en vivo de cada carrera y acaba de quedar
      // vieja; el tablero se entera solo, por el socket.
      ref
        ..invalidate(adminMarathonsProvider)
        ..invalidate(adminMarathonProvider(widget.marathon.id));
    } on Failure catch (f) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.localized(context.l10n))));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _pulsar({required bool largar}) async {
    final t = context.l10n;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(
          largar ? t.adminStartConfirmTitle : t.adminFinishConfirmTitle,
        ),
        content: Text(
          largar
              ? t.adminStartConfirmBody(widget.marathon.name)
              : t.adminFinishConfirmBody(widget.marathon.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: Text(largar ? t.adminStart : t.adminFinish),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    await _enviar(
      (api) => largar
          ? api.startMarathon(widget.marathon.id)
          : api.finishMarathon(widget.marathon.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: _terminada
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_score_rounded,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    t.adminAlreadyFinished,
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // La preparacion va arriba y sola: es el paso previo a la
                  // largada y es el que apaga la app de todos los inscritos.
                  // Compartir fila con "largar" invita a pulsar el que no era.
                  if (!_corriendo) ...[
                    if (_preparando)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          t.adminPreparingNotice,
                          textAlign: TextAlign.center,
                          style: context.text.bodySm.copyWith(color: c.warning),
                        ),
                      ),
                    AppButton(
                      label: _preparando
                          ? t.adminPrepareCancel
                          : t.adminPrepare,
                      icon: _preparando
                          ? Icons.lock_open_rounded
                          : Icons.hourglass_top_rounded,
                      variant: AppButtonVariant.secondary,
                      isLoading: _enviando,
                      onPressed: _enviando
                          ? null
                          : () => _preparar(activar: !_preparando),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: t.adminStart,
                          icon: Icons.flag_rounded,
                          isLoading: _enviando && !_corriendo,
                          onPressed: _corriendo || _enviando
                              ? null
                              : () => _pulsar(largar: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: t.adminFinish,
                          icon: Icons.stop_rounded,
                          variant: AppButtonVariant.danger,
                          isLoading: _enviando && _corriendo,
                          onPressed: !_corriendo || _enviando
                              ? null
                              : () => _pulsar(largar: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// El aviso que van a leer los inscritos mientras esperan la largada.
///
/// Se pregunta al **poner** la preparacion y no en la ficha de la carrera: es
/// el momento en que el organizador sabe que decir —"el arco esta en la plaza",
/// "salimos con veinte minutos de retraso"— y es la ultima pantalla que esa
/// gente va a ver hasta que suene el disparo. Dejarlo vacio es una respuesta
/// valida: la app pone su texto por defecto en el idioma de cada corredor.
class _DialogoDeAviso extends StatefulWidget {
  const _DialogoDeAviso({required this.inicial, required this.marathonName});

  final String inicial;
  final String marathonName;

  @override
  State<_DialogoDeAviso> createState() => _DialogoDeAvisoState();
}

class _DialogoDeAvisoState extends State<_DialogoDeAviso> {
  late final _texto = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return AlertDialog(
      title: Text(t.adminPrepareConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.adminPrepareConfirmBody(widget.marathonName),
            style: context.text.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _texto,
            maxLines: 4,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: t.adminPrepareMessageLabel,
              hintText: t.adminPrepareMessageHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_texto.text),
          child: Text(t.adminPrepare),
        ),
      ],
    );
  }
}
