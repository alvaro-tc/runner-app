import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
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
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final maratones = ref.watch(adminMarathonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminLiveTitle)),
      body: maratones.when(
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
            : _Tablero(marathons: lista),
      ),
    );
  }
}

class _Tablero extends ConsumerWidget {
  const _Tablero({required this.marathons});

  final List<AdminMarathon> marathons;

  /// La que el selector deja elegida. Por defecto, la que se esta corriendo:
  /// el dia de la carrera es lo unico que se quiere ver al abrir la app.
  AdminMarathon _elegida(String? id) {
    if (id != null) {
      for (final m in marathons) {
        if (m.id == id) return m;
      }
    }
    for (final m in marathons) {
      if (m.running) return m;
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
                          if (m.running)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: c.success,
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
                  child: _Dorsal(bib: corredor.bib),
                ),
            ],
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.screenH,
          child: _Contador(
            board: board,
            label: t.adminRunnersOnCourse(board.runners.length),
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
  const _Dorsal({required this.bib});

  final String? bib;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.primary,
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
  const _Contador({required this.board, required this.label});

  final LiveBoard board;
  final String label;

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
        ],
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

    setState(() => _enviando = true);
    final api = ref.read(adminApiProvider);
    try {
      if (largar) {
        await api.startMarathon(widget.marathon.id);
      } else {
        await api.finishMarathon(widget.marathon.id);
      }
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
            : Row(
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
      ),
    );
  }
}
