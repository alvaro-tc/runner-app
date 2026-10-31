import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/admin/presentation/widgets/fade_in_up.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/layout/responsive.dart';
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
    final carreras = ref.watch(adminMarathonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminMarathonsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminMarathonNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.adminNewMarathon),
      ),
      body: carreras.when(
        // Un refresco de fondo no vacia una pantalla que ya tiene datos.
        skipLoadingOnReload: true,
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

class _Lista extends ConsumerStatefulWidget {
  const _Lista(this.todas);

  final List<AdminMarathon> todas;

  @override
  ConsumerState<_Lista> createState() => _ListaState();
}

class _ListaState extends ConsumerState<_Lista> {
  String _busqueda = '';

  /// `null` = todas; si no, solo las publicadas (`true`) o los borradores.
  bool? _publicadas;

  /// Se filtra aqui y no en el servidor: la lista del panel llega entera.
  List<AdminMarathon> get _filtradas {
    final q = _busqueda.trim().toLowerCase();
    return [
      for (final m in widget.todas)
        if ((_publicadas == null || m.published == _publicadas) &&
            (q.isEmpty ||
                m.name.toLowerCase().contains(q) ||
                m.city.toLowerCase().contains(q)))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final carreras = _filtradas;

    // Ya vienen ordenadas del provider; aqui solo se marca donde empieza el
    // archivo para que no parezca que la lista sigue teniendo carreras vivas.
    final corte = carreras.indexWhere((m) => m.past);

    Widget fila(int i) => FadeInUp(
      // La clave va por id y no por posicion: asi el estado de la fila
      // sigue a su carrera si la lista se reordena.
      key: ValueKey(carreras[i].id),
      // Se escalona solo la primera pantalla: al noveno el retardo ya se
      // notaria como lentitud en vez de como entrada.
      delay: AppDurations.fast * (i.clamp(0, 8) / 8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _Fila(marathon: carreras[i]),
      ),
    );

    // En telefono una columna; en una tablet, las tarjetas que quepan por
    // fila. Cada mitad —proximas y archivo— es su propia rejilla, para que el
    // rotulo no quede en medio de una fila.
    Widget rejilla(int desde, int hasta) => ResponsiveGrid(
      minItemWidth: _tarjetaMinWidth,
      runSpacing: 0,
      children: [for (var i = desde; i < hasta; i++) fila(i)],
    );

    final filtros = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: t.adminSearchMarathons,
            prefix: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ),
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (valor, label, icon) in [
                (null, t.adminFilterAll, Icons.apps_rounded),
                (true, t.adminPublished, Icons.visibility_outlined),
                (false, t.adminDraft, Icons.edit_note_rounded),
              ])
                AppChip(
                  label: label,
                  icon: icon,
                  selected: _publicadas == valor,
                  onTap: () => setState(() => _publicadas = valor),
                ),
            ],
          ),
        ],
      ),
    );

    final hijos = <Widget>[
      filtros,
      if (carreras.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Text(
            t.adminNoMatches,
            textAlign: TextAlign.center,
            style: context.text.bodyMd.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      // Los rotulos solo aparecen cuando hay dos mitades que separar. Con todo
      // por delante, un "PROXIMAS" solitario encabezando la lista entera no
      // dice nada que la lista no diga ya.
      if (corte > 0) _Cabecera(t.adminSectionUpcoming),
      if (carreras.isNotEmpty) rejilla(0, corte < 0 ? carreras.length : corte),
      if (corte >= 0) ...[
        _Cabecera(t.adminSectionPast, primera: corte == 0),
        rejilla(corte, carreras.length),
      ],
    ];

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminMarathonsProvider.future),
      child: PageInsets(
        maxWidth: AppSizes.wideMaxWidth,
        builder: (context, inset) => ListView(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.md,
            inset,
            AppSpacing.xxl * 2,
          ),
          children: hijos,
        ),
      ),
    );
  }

  /// Lo que pide una tarjeta para que el nombre y los dos interruptores de
  /// abajo no se aprieten.
  static const _tarjetaMinWidth = 360.0;
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
    // widget ya recibio la carrera nueva y `_m` diria lo contrario.
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
            _Miniatura(marathon: marathon),
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
            if (marathon.isRehearsal)
              AppBadge(
                label: t.adminRehearsalBadge,
                icon: Icons.science_outlined,
              ),
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
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Cupos(marathon: marathon),
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
  const _Miniatura({required this.marathon});

  final AdminMarathon marathon;

  static const _lado = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // El logo pequeno, que existe para esto; si falta, el material
    // promocional. Entero siempre: nunca `cover`, que recorta.
    final url = [
      marathon.coverUrl,
      marathon.logoHorizontalUrl,
      marathon.logoVerticalUrl,
    ].firstWhere((u) => (u ?? '').isNotEmpty, orElse: () => null);
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
            // Como en la ficha: en web `CachedNetworkImage` choca con la falta
            // de CORS de `/uploads`.
            : EventImage(
                imageUrl: url!,
                icon: Icons.image_outlined,
                fit: BoxFit.contain,
                background: c.logoBackdrop,
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
            // Un ensayo no se publica nunca: el servidor lo rechazaria.
            onTap: ocupado || marathon.isRehearsal ? null : onPublicar,
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

/// Cuanto se lleno: la barra se lee de un vistazo donde un "84/120" obliga
/// a hacer la cuenta.
class _Cupos extends StatelessWidget {
  const _Cupos({required this.marathon});

  final AdminMarathon marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lleno = marathon.capacity == 0
        ? 0.0
        : (marathon.slotsTaken / marathon.capacity).clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(Icons.groups_outlined, size: 16, color: c.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: lleno),
              duration: context.reduceMotion
                  ? Duration.zero
                  : AppDurations.slow,
              curve: AppDurations.curve,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: c.ringTrack,
                color: lleno >= 1 ? c.warning : c.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.adminSlots(marathon.slotsTaken, marathon.capacity),
          style: context.text.labelSm.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// Carga con la forma de la lista: tres tarjetas del alto real. Un spinner
/// centrado haria saltar el contenido al llegar.
class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => PageListView(
    maxWidth: AppSizes.wideMaxWidth,
    top: AppSpacing.md,
    bottom: AppSpacing.xxl,
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
                    Skeleton(width: 64, height: 64, radius: AppRadius.lg),
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
