import 'package:cached_network_image/cached_network_image.dart';
import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El catalogo entero, publicado o no.
///
/// Esta es la pestana que en la app del corredor es "Entrenar": mismo sitio en
/// la barra, misma forma de lista. Un admin no entrena desde el panel.
///
/// La lista no es solo un indice. Publicar una carrera y abrir sus
/// inscripciones son las dos cosas que mas veces al dia hace un organizador, y
/// casi nunca a la vez que edita un precio: viven aqui, a un toque, y no
/// escondidas dentro del formulario.
class AdminMarathonsPage extends ConsumerWidget {
  const AdminMarathonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final maratones = ref.watch(adminMarathonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminMarathonsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminMarathonNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.adminNewMarathon),
      ),
      body: maratones.when(
        loading: _Cargando.new,
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => ref.invalidate(adminMarathonsProvider),
        ),
        data: (lista) => lista.isEmpty
            ? EmptyState(
                icon: Icons.emoji_events_outlined,
                title: t.adminNoMarathonsTitle,
                message: t.adminNoMarathonsBody,
                actionLabel: t.adminNewMarathon,
                onAction: () => context.push(Routes.adminMarathonNew),
              )
            : _Lista(lista),
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista(this.maratones);

  final List<AdminMarathon> maratones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;

    // Ya vienen ordenadas del provider; aqui solo se marca donde empieza el
    // archivo para que no parezca que la lista sigue teniendo carreras vivas.
    final corte = maratones.indexWhere((m) => m.past);

    final hijos = <Widget>[];
    for (var i = 0; i < maratones.length; i++) {
      // Los rotulos solo aparecen cuando hay dos mitades que separar. Con todo
      // por delante, un "PROXIMAS" solitario encabezando la lista entera no
      // dice nada que la lista no diga ya.
      if (i == 0 && corte > 0) hijos.add(_Cabecera(t.adminSectionUpcoming));
      if (i == corte) {
        hijos.add(_Cabecera(t.adminSectionPast, primera: i == 0));
      }
      hijos.add(
        _Aparece(
          // La clave va por id y no por posicion: asi el estado de la fila
          // sigue a su carrera si la lista se reordena.
          key: ValueKey(maratones[i].id),
          // Se escalona solo la primera pantalla: al noveno el retardo ya se
          // notaria como lentitud en vez de como entrada.
          delay: AppDurations.fast * (i.clamp(0, 8) / 8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Fila(marathon: maratones[i]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminMarathonsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xxl * 2,
        ),
        children: hijos,
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera(this.label, {this.primera = true});

  final String label;
  final bool primera;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: primera ? 0 : AppSpacing.md,
      bottom: AppSpacing.md,
    ),
    child: Text(
      label.toUpperCase(),
      style: context.text.labelSm.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// Una carrera de la lista: de un vistazo, cuando es, como se llama y en que
/// estado esta; debajo, los dos interruptores.
class _Fila extends ConsumerStatefulWidget {
  const _Fila({required this.marathon});

  final AdminMarathon marathon;

  @override
  ConsumerState<_Fila> createState() => _FilaState();
}

class _FilaState extends ConsumerState<_Fila> {
  /// Un cambio en vuelo. Sin esto, dos toques seguidos mandan dos peticiones
  /// que pueden llegar al reves y dejar el estado al contrario de lo pedido.
  bool _ocupado = false;

  AdminMarathon get _m => widget.marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            onTap: () => context.push(Routes.adminMarathonEditOf(_m.id)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: _Resumen(marathon: _m),
            ),
          ),
          const AppDivider(),
          _BarraDeAcciones(
            marathon: _m,
            ocupado: _ocupado,
            onPublicar: () => _alternar(publicar: true),
            onInscripciones: () => _alternar(publicar: false),
          ),
        ],
      ),
    );
  }

  /// Cambia el estado y cuenta que paso.
  ///
  /// El interruptor ya se movio cuando esto empieza: el provider lo pinta antes
  /// de preguntar. Aqui solo queda avisar —y ofrecer deshacer cuando lo que se
  /// hizo suena peor de lo que es—, o explicar el fallo si el servidor lo
  /// rechazo y el interruptor volvio solo a su sitio.
  Future<void> _alternar({required bool publicar}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);

    final t = context.l10n;
    final notifier = ref.read(adminMarathonsProvider.notifier);
    // El estado al que se va, leido antes de la peticion: despues de ella el
    // widget ya recibio la maraton nueva y `_m` diria lo contrario.
    final activando = publicar ? !_m.published : !_m.registrationsOpen;

    final fallo = publicar
        ? await notifier.setPublished(_m, value: activando)
        : await notifier.setRegistrationsOpen(_m, value: activando);

    if (!mounted) return;
    setState(() => _ocupado = false);

    if (fallo != null) {
      context.showSnack(fallo.localized(t));
      return;
    }

    final mensaje = switch ((publicar, activando)) {
      (true, true) => t.adminPublishedSnack,
      (true, false) => t.adminUnpublishedSnack,
      (false, true) => t.adminRegistrationsOpenedSnack,
      (false, false) => t.adminRegistrationsClosedSnack,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          // Retirar del catalogo y cerrar inscripciones son reversibles, pero
          // no lo parecen: el deshacer esta para que nadie tenga que
          // comprobarlo entrando al detalle.
          action: activando
              ? null
              : SnackBarAction(
                  label: t.commonUndo,
                  onPressed: () => _alternar(publicar: publicar),
                ),
        ),
      );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.marathon});

  final AdminMarathon marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Miniatura(url: marathon.coverUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // La fecha va primero: con trece carreras de nombres
                  // parecidos, lo que las distingue es cuando son.
                  Text(
                    '${Fmt.fullDate(marathon.startsAt)} · ${marathon.city}',
                    style: context.text.labelSm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    marathon.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMd,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (marathon.running)
              AppBadge(
                label: t.adminLive,
                icon: Icons.circle,
                tone: AppTone.success,
              ),
            if (marathon.finished)
              AppBadge(
                label: t.adminFinished,
                icon: Icons.sports_score_rounded,
                tone: AppTone.neutral,
              ),
            _BadgeQueCambia(
              activo: marathon.published,
              activa: (
                label: t.adminPublished,
                icon: Icons.visibility_outlined,
                tone: AppTone.info,
              ),
              inactiva: (
                label: t.adminDraft,
                icon: Icons.edit_note_rounded,
                tone: AppTone.neutral,
              ),
            ),
            _BadgeQueCambia(
              activo: marathon.registrationsOpen,
              activa: (
                label: t.adminRegistrationsOpen,
                icon: Icons.how_to_reg_rounded,
                tone: AppTone.brand,
              ),
              inactiva: (
                label: t.adminRegistrationsClosed,
                icon: Icons.lock_outline_rounded,
                tone: AppTone.warning,
              ),
            ),
            AppBadge(
              tone: AppTone.neutral,
              label: t.adminSlots(marathon.slotsTaken, marathon.capacity),
              icon: Icons.groups_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

typedef _Estado = ({String label, IconData icon, AppTone tone});

/// Badge que se cruza al cambiar de estado.
///
/// El interruptor de abajo cambia el badge de arriba, y sin la transicion el
/// cambio pasa desapercibido justo cuando hay que confirmar que ocurrio.
class _BadgeQueCambia extends StatelessWidget {
  const _BadgeQueCambia({
    required this.activo,
    required this.activa,
    required this.inactiva,
  });

  final bool activo;
  final _Estado activa;
  final _Estado inactiva;

  @override
  Widget build(BuildContext context) {
    final estado = activo ? activa : inactiva;
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppDurations.curve,
      transitionBuilder: (hijo, animacion) => FadeTransition(
        opacity: animacion,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(animacion),
          child: hijo,
        ),
      ),
      child: AppBadge(
        key: ValueKey(activo),
        label: estado.label,
        icon: estado.icon,
        tone: estado.tone,
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String? url;

  static const _lado = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vacia = Icon(
      Icons.image_outlined,
      size: 20,
      color: c.onPrimary.withValues(alpha: 0.7),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: _lado,
        height: _lado,
        decoration: BoxDecoration(gradient: c.routeGradient),
        child: (url ?? '').isEmpty
            ? vacia
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (context, _) => vacia,
                errorWidget: (context, _, _) => vacia,
              ),
      ),
    );
  }
}

/// Los dos interruptores de la fila, al pie y separados del cuerpo que navega.
class _BarraDeAcciones extends StatelessWidget {
  const _BarraDeAcciones({
    required this.marathon,
    required this.ocupado,
    required this.onPublicar,
    required this.onInscripciones,
  });

  final AdminMarathon marathon;
  final bool ocupado;
  final VoidCallback onPublicar;
  final VoidCallback onInscripciones;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _Accion(
            icon: marathon.published
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: marathon.published ? t.adminUnpublish : t.adminPublish,
            onTap: ocupado ? null : onPublicar,
          ),
        ),
        SizedBox(
          height: AppSizes.minTapTarget,
          child: VerticalDivider(width: 1, color: context.colors.border),
        ),
        Expanded(
          child: _Accion(
            icon: marathon.registrationsOpen
                ? Icons.lock_outline_rounded
                : Icons.how_to_reg_rounded,
            label: marathon.registrationsOpen
                ? t.adminCloseRegistrations
                : t.adminOpenRegistrations,
            onTap: ocupado ? null : onInscripciones,
          ),
        ),
      ],
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: SizedBox(
            height: AppSizes.minTapTarget,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: c.primary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSm.copyWith(color: c.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada escalonada. Es lo que hace que la lista se lea de arriba abajo en
/// vez de aparecer de golpe.
class _Aparece extends StatefulWidget {
  const _Aparece({required this.child, required this.delay, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<_Aparece> createState() => _ApareceState();
}

class _ApareceState extends State<_Aparece>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.base,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;

    final curva = CurvedAnimation(parent: _ctrl, curve: AppDurations.curve);
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curva),
        child: widget.child,
      ),
    );
  }
}

/// Carga con la forma de la lista: tres tarjetas del alto real. Un spinner
/// centrado haria saltar el contenido al llegar.
class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.md,
      AppSpacing.screenH,
      AppSpacing.xxl,
    ),
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: context.colors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Skeleton(width: 56, height: 56, radius: AppRadius.lg),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: SkeletonLines(lines: 2)),
                  ],
                ),
                SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Skeleton(width: 90, height: 22, radius: AppRadius.pill),
                    SizedBox(width: AppSpacing.sm),
                    Skeleton(width: 120, height: 22, radius: AppRadius.pill),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
