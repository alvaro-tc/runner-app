import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/features/races/presentation/widgets/pending_validation.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/marathon_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El afiche de la carrera mas proxima: el logo vertical a lo grande.
///
/// [intro] es la entrada de la pantalla: el afiche se asienta desde un poco
/// mas grande, como una foto que se enfoca. Con movimiento reducido llega ya
/// completo y no se nota.
class FeaturedRacePoster extends StatelessWidget {
  const FeaturedRacePoster({
    required this.marathon,
    required this.intro,
    super.key,
  });

  final Marathon marathon;
  final Animation<double> intro;

  /// Vertical, como un cartel: es la forma del logo vertical.
  static const aspectRatio = 4 / 5;

  /// Cuanto alto de pantalla se lleva el afiche: lo justo para que asome la
  /// cuenta atras y se sepa que hay mas debajo.
  static const maxHeightShare = 0.56;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // La tarjeta entera crece hasta su sitio. Antes la imagen hacia zoom
    // dentro del recorte y al entrar perdia los bordes del cartel.
    final crece = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: intro, curve: Curves.easeOutBack));

    return Semantics(
      button: true,
      label: '${marathon.name}, ${Fmt.fullDate(marathon.date)}',
      child: Pressable(
        onTap: () => context.push(Routes.marathonDetailOf(marathon.id)),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: context.screenSize.height * maxHeightShare,
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ScaleTransition(
                scale: crece,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sheet),
                    boxShadow: c.floatingShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sheet),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MarathonArtworkHero(
                          marathon: marathon,
                          aspectRatio: aspectRatio,
                          radius: AppRadius.sheet,
                        ),
                        _Brillo(intro: intro),
                        Positioned(
                          top: AppSpacing.base,
                          left: AppSpacing.base,
                          child: _InkPill(
                            icon: Icons.bolt_rounded,
                            label: context.l10n.homeNextRaceBadge,
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.base,
                          right: AppSpacing.base,
                          child: _DateStub(date: marathon.date),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un reflejo de luz que cruza el afiche una vez, al final de la entrada:
/// dice "esto se toca" sin parpadear para siempre. Con movimiento reducido la
/// entrada llega ya terminada y el reflejo no se ve.
class _Brillo extends StatelessWidget {
  const _Brillo({required this.intro});

  final Animation<double> intro;

  /// El tramo de la entrada en que cruza: despues de que el afiche se asiente.
  static const _desde = 0.45;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: intro,
      builder: (context, _) {
        final v = intro.value;
        if (v <= _desde || v >= 1) return const SizedBox.shrink();
        // De fuera por la izquierda a fuera por la derecha.
        final p =
            -0.3 +
            1.6 * Curves.easeInOut.transform((v - _desde) / (1 - _desde));
        final luz = context.colors.onImage;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                luz.withValues(alpha: 0),
                luz.withValues(alpha: 0.28),
                luz.withValues(alpha: 0),
              ],
              stops: [
                (p - 0.15).clamp(0.0, 1.0),
                p.clamp(0.0, 1.0),
                (p + 0.15).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Lo justo para decidir si apuntarse, debajo del afiche: nombre, cuando y
/// donde, la cuenta atras y el boton. El resto —plazas, programa, recorrido—
/// vive en el detalle.
class FeaturedRaceSummary extends ConsumerWidget {
  const FeaturedRaceSummary({required this.marathon, super.key});

  final Marathon marathon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;

    // La misma regla que el boton del detalle: con un pago esperando
    // validacion no se ofrece inscribirse otra vez.
    final esperandoValidacion =
        (ref.watch(awaitingValidationProvider).value ?? const []).any(
          (registro) => registro.marathonId == marathon.id,
        );
    final canRegister = marathon.status.acceptsEntries && !esperandoValidacion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(marathon.name, style: context.text.displayMd),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${Fmt.weekdayDayMonth(marathon.date)} · '
          '${Fmt.timeOfDay(marathon.date)} · ${marathon.location}',
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Countdown(marathon: marathon),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(
              label: Fmt.distance(marathon.distanceKm),
              icon: Icons.straighten_rounded,
            ),
            if (marathon.entryFee.amount > 0)
              AppBadge(
                label: Fmt.money(
                  marathon.entryFee.amount,
                  marathon.entryFee.currency,
                ),
                icon: Icons.sell_outlined,
              ),
            AppBadge(
              label: marathon.status.label(t),
              icon: Icons.confirmation_number_outlined,
              tone: switch (marathon.status) {
                RegistrationStatus.open => AppTone.success,
                RegistrationStatus.closingSoon => AppTone.warning,
                RegistrationStatus.full ||
                RegistrationStatus.closed => AppTone.neutral,
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: canRegister ? t.marathonRegisterNow : t.homeViewDetails,
                icon: canRegister ? Icons.favorite_rounded : null,
                onPressed: () => esperandoValidacion
                    ? showPendingValidationDialog(context)
                    : context.push(
                        canRegister
                            ? Routes.marathonRegisterOf(marathon.id)
                            : Routes.marathonDetailOf(marathon.id),
                      ),
              ),
            ),
            if (canRegister) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: t.homeViewDetails,
                  variant: AppButtonVariant.outline,
                  onPressed: () =>
                      context.push(Routes.marathonDetailOf(marathon.id)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Las demas carreras como banners que se pasan con el dedo.
///
/// El banner es solo la imagen —el logo horizontal, entero— y lo que dice de
/// cada carrera va debajo, cambiando con la pagina: nada tapa el logo. Las
/// vecinas asoman a los lados, mas chicas y apagadas, para que se vea que hay
/// mas. No pasa solo: un carrusel que se mueve bajo el dedo de quien lee es
/// justo lo que no se quiere.
class RaceBannerCarousel extends StatefulWidget {
  const RaceBannerCarousel({required this.marathons, super.key});

  final List<Marathon> marathons;

  /// La del logo horizontal, la misma del banner del detalle: el Hero vuela
  /// entre dos huecos de igual forma.
  static const aspectRatio = 16 / 9;

  @override
  State<RaceBannerCarousel> createState() => _RaceBannerCarouselState();
}

class _RaceBannerCarouselState extends State<RaceBannerCarousel> {
  final _paginas = PageController(viewportFraction: 0.86);
  int _actual = 0;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quieto = MediaQuery.disableAnimationsOf(context);
    final lista = widget.marathons;
    final actual = lista[_actual.clamp(0, lista.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: box.maxWidth * 0.86 / RaceBannerCarousel.aspectRatio,
            child: PageView.builder(
              controller: _paginas,
              clipBehavior: Clip.none,
              itemCount: lista.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _paginas,
                builder: (context, child) {
                  // Lo lejos que esta del centro: 0 la que se mira, 1 la de al
                  // lado. Antes del primer frame el controlador no tiene
                  // posicion y vale la pagina inicial.
                  final pagina =
                      _paginas.hasClients && _paginas.position.haveDimensions
                      ? _paginas.page ?? 0
                      : _actual.toDouble();
                  final lejos = (pagina - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - 0.45 * lejos,
                    child: Transform.scale(
                      scale: 1 - 0.08 * lejos,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                  ),
                  child: Semantics(
                    button: true,
                    label: '${lista[i].name}, ${Fmt.fullDate(lista[i].date)}',
                    child: Pressable(
                      onTap: () =>
                          context.push(Routes.marathonDetailOf(lista[i].id)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: c.cardShadow,
                        ),
                        child: MarathonArtworkHero(
                          marathon: lista[i],
                          aspectRatio: RaceBannerCarousel.aspectRatio,
                          radius: AppRadius.xxl,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // La ficha de la que se mira: cambia subiendo al pasar de banner.
        AnimatedSwitcher(
          duration: quieto ? Duration.zero : AppDurations.base,
          switchInCurve: AppDurations.curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (actualHijo, previos) => Stack(
            alignment: Alignment.topLeft,
            children: [...previos, ?actualHijo],
          ),
          child: Padding(
            key: ValueKey(actual.id),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actual.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMd,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${Fmt.weekdayDayMonth(actual.date)} · ${actual.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(
                  label: Fmt.distanceShort(actual.distanceKm),
                  icon: Icons.straighten_rounded,
                ),
              ],
            ),
          ),
        ),
        if (lista.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < lista.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _paginas.animateToPage(
                    i,
                    duration: quieto
                        ? const Duration(milliseconds: 1)
                        : AppDurations.slow,
                    curve: AppDurations.curve,
                  ),
                  // Un punto de 6 pt no se acierta: el area de toque va aparte.
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AnimatedContainer(
                      duration: quieto ? Duration.zero : AppDurations.base,
                      curve: AppDurations.curve,
                      height: 6,
                      width: i == _actual ? 20 : 6,
                      decoration: BoxDecoration(
                        color: i == _actual ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Encoge un poco al pulsar: confirma el toque antes de que llegue la
/// navegacion. Sin movimiento si el sistema lo pide.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, required this.onTap, super.key});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => _set(true),
    onTapUp: (_) => _set(false),
    onTapCancel: () => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.fast,
      curve: AppDurations.curve,
      child: widget.child,
    ),
  );
}

// ─── Piezas ──────────────────────────────────────────────────────────────

class _InkPill extends StatelessWidget {
  const _InkPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: c.inkPill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.primaryLight),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.labelSm.copyWith(color: c.onInkPill)),
        ],
      ),
    );
  }
}

/// El dia en grande, como la matriz de una entrada.
class _DateStub extends StatelessWidget {
  const _DateStub({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Fmt.dayOfMonth(date),
              style: context.text.headingLg.copyWith(height: 1),
            ),
            Text(
              Fmt.monthShort(date).toUpperCase(),
              style: context.text.labelSm.copyWith(color: c.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dias, horas y minutos en tres casillas. Cada cifra entra desde abajo al
/// cambiar, como un marcador: el minuto que pasa se ve pasar.
class _Countdown extends ConsumerWidget {
  const _Countdown({required this.marathon});

  final Marathon marathon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final remaining =
        (TickerMode.valuesOf(context).enabled
            ? ref.watch(countdownProvider(marathon.date)).value
            : null) ??
        marathon.date.difference(ref.watch(nowProvider)());

    if (marathon.isLive || remaining <= Duration.zero) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          t.homeRaceDay,
          textAlign: TextAlign.center,
          style: context.text.headingMd.copyWith(color: c.onPrimary),
        ),
      );
    }

    final partes = Fmt.countdown(remaining);
    return Semantics(
      label: t.countdownSemantics(partes.days, partes.hours, partes.minutes),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: _CountdownCell(
                value: partes.days,
                label: t.homeCountdownDays,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CountdownCell(
                value: partes.hours,
                label: t.homeCountdownHours,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CountdownCell(
                value: partes.minutes,
                label: t.homeCountdownMinutes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownCell extends StatelessWidget {
  const _CountdownCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quieto = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          ClipRect(
            child: AnimatedSwitcher(
              duration: quieto ? Duration.zero : AppDurations.slow,
              switchInCurve: AppDurations.curve,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                // La que entra sube desde abajo; la que sale se va hacia
                // arriba (su animacion corre al reves).
                final entra = child.key == ValueKey(value);
                final desde = Offset(0, entra ? 0.6 : -0.6);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: desde,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                key: ValueKey(value),
                style: context.text.displayLg.copyWith(color: c.primary),
              ),
            ),
          ),
          Text(
            label,
            style: context.text.labelSm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Las ya corridas, en fila y con el dedo: promocion de lo que se hizo, no
/// algo a lo que apuntarse. Por eso no llevan cuenta atras ni precio, solo el
/// logo, el sello de terminada y cuando fue.
class PastRacesStrip extends StatelessWidget {
  const PastRacesStrip({required this.marathons, super.key});

  final List<Marathon> marathons;

  /// Cuanto ancho se lleva cada tarjeta: deja asomar la siguiente.
  static const widthShare = 0.62;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final ancho = box.maxWidth * widthShare;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < marathons.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: ancho,
                child: _PastRaceCard(marathon: marathons[i]),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _PastRaceCard extends StatelessWidget {
  const _PastRaceCard({required this.marathon});

  final Marathon marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Semantics(
      button: true,
      label:
          '${marathon.name}, ${t.homeRaceFinished}, '
          '${Fmt.fullDate(marathon.date)}',
      child: ExcludeSemantics(
        child: Pressable(
          onTap: () => context.push(Routes.marathonDetailOf(marathon.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: c.cardShadow,
                ),
                child: Stack(
                  children: [
                    MarathonArtworkHero(
                      marathon: marathon,
                      aspectRatio: RaceBannerCarousel.aspectRatio,
                      radius: AppRadius.xl,
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _InkPill(
                        icon: Icons.flag_rounded,
                        label: t.homeRaceFinished,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                marathon.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMd,
              ),
              Text(
                '${Fmt.weekdayDayMonth(marathon.date)} · ${marathon.city}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
