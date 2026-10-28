import 'package:camrun/core/constants/cam_contact.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fotos reales del CAM (facebook.com/CAM.BO.LP), una por capitulo.
abstract final class CamPhotos {
  /// La del CAM RUN, sacada del afiche sin sus textos: madre e hija corriendo.
  /// Es la primera que se ve, en la historia y en el login.
  static const run = 'assets/images/cam/cam_run.jpg';
  static const welcome = 'assets/images/cam/cam_welcome.jpg';
  static const motherhood = 'assets/images/cam/cam_motherhood.jpg';
  static const children = 'assets/images/cam/cam_children.jpg';
  static const community = 'assets/images/cam/cam_community.jpg';
}

typedef _Chapter = ({String photo, String eyebrow, String title, String body});

List<_Chapter> _chapters(AppLocalizations t) => [
  (
    photo: CamPhotos.run,
    eyebrow: t.appTitle,
    title: t.storyRunTitle,
    body: t.storyRunBody,
  ),
  (
    photo: CamPhotos.welcome,
    eyebrow: t.authWelcomeCamTitle,
    title: t.camTagline,
    body: t.storyWelcomeBody,
  ),
  (
    photo: CamPhotos.motherhood,
    eyebrow: t.camPillarMotherhoodTitle,
    title: t.storyMotherhoodTitle,
    body: t.camPillarMotherhoodBody,
  ),
  (
    photo: CamPhotos.children,
    eyebrow: t.camPillarChildrenTitle,
    title: t.storyChildrenTitle,
    body: t.camPillarChildrenBody,
  ),
  (
    photo: CamPhotos.community,
    eyebrow: t.storyCommunityEyebrow,
    title: t.storyCommunityTitle,
    body: t.camCommunity,
  ),
];

/// La puerta de la app: el CAM contado en fotos, como una historia. Cada
/// capitulo dura [_chapterLength]; tocar a la derecha adelanta, a la izquierda
/// vuelve y mantener pulsado pausa. Con "reducir movimiento" no avanza solo ni
/// hay zoom: se pasa tocando.
class CamStory extends StatefulWidget {
  const CamStory({
    required this.onCreateAccount,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  @override
  State<CamStory> createState() => _CamStoryState();
}

class _CamStoryState extends State<CamStory>
    with SingleTickerProviderStateMixin {
  static const _chapterLength = Duration(seconds: 6);
  static const _count = 5;

  late final _progress = AnimationController(
    vsync: this,
    duration: _chapterLength,
  )..addStatusListener(_onStatus);
  int _index = 0;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Sin esto la primera vuelta parpadea: cada foto se decodifica justo
      // cuando le toca entrar.
      for (final c in _chapters(context.l10n)) {
        precacheImage(AssetImage(c.photo), context);
      }
    }
    if (context.reduceMotion) {
      _progress.stop();
    } else if (!_progress.isAnimating) {
      _progress.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _go(1);
  }

  /// Avanza o retrocede [delta] capitulos; al final vuelve al primero.
  void _go(int delta) {
    setState(() => _index = (_index + delta) % _count);
    _progress.value = 0;
    if (!context.reduceMotion) _progress.forward();
  }

  void _pause() => _progress.stop();

  void _resume() {
    if (!context.reduceMotion) _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final reduce = context.reduceMotion;
    final chapters = _chapters(t);
    final chapter = chapters[_index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fotos: se funden una en otra mientras cada una se acerca despacio.
          AnimatedSwitcher(
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 900),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _KenBurns(
              key: ValueKey(chapter.photo),
              photo: chapter.photo,
              // Alterna el punto de fuga para que no todas empujen igual.
              alignment: _index.isEven
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: _chapterLength + const Duration(seconds: 1),
            ),
          ),
          ColoredBox(color: c.imageTint),
          DecoratedBox(decoration: BoxDecoration(gradient: c.storyScrim)),

          // Zonas de toque: un tercio para volver, el resto para avanzar.
          Semantics(
            button: true,
            label: t.commonNext,
            onTap: () => _go(1),
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) =>
                    _go(d.localPosition.dx < box.maxWidth / 3 ? -1 : 1),
                onLongPressStart: (_) => _pause(),
                onLongPressEnd: (_) => _resume(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressBars(
                    count: _count,
                    index: _index,
                    progress: _progress,
                    reduce: reduce,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _TopBar(),
                  const Spacer(),
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.contentMaxWidth,
                      ),
                      child: IgnorePointer(
                        child: AnimatedSwitcher(
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 700),
                          // Sale mas rapido de lo que entra: el texto nuevo
                          // nunca se pisa con el viejo.
                          reverseDuration: const Duration(milliseconds: 180),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.bottomStart,
                            children: [...previous, ?current],
                          ),
                          child: _ChapterCopy(
                            key: ValueKey(_index),
                            chapter: chapter,
                            animate: !reduce,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.contentMaxWidth,
                    ),
                    child: _Rise(
                      delay: const Duration(milliseconds: 350),
                      animate: !reduce,
                      child: Column(
                        children: [
                          AppButton(
                            label: t.authRegister,
                            onPressed: widget.onCreateAccount,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _OnImageButton(
                            label: t.authLogin,
                            onPressed: widget.onSignIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto a pantalla completa que se acerca despacio una sola vez.
class _KenBurns extends StatelessWidget {
  const _KenBurns({
    required this.photo,
    required this.alignment,
    required this.duration,
    super.key,
  });

  final String photo;
  final Alignment alignment;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      photo,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
    if (context.reduceMotion) return image;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1.14),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, alignment: alignment, child: child),
      child: image,
    );
  }
}

/// Las barras de arriba: una por capitulo, la actual se llena con el tiempo.
class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
    required this.reduce,
  });

  final int count;
  final int index;
  final Animation<double> progress;
  final bool reduce;

  static const _height = 3.0;

  @override
  Widget build(BuildContext context) {
    final fg = context.colors.onImage;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    minHeight: _height,
                    value: i < index
                        ? 1
                        : i > index
                        ? 0
                        // Sin avance automatico, el capitulo actual se ve
                        // lleno: no hay nada que esperar.
                        : reduce
                        ? 1
                        : progress.value,
                    color: fg,
                    backgroundColor: fg.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Logo del CAM a la izquierda y, a la derecha, la ayuda por WhatsApp: quien
/// la necesita no tiene que crearse una cuenta para pedirla.
class _TopBar extends StatelessWidget {
  const _TopBar();

  static const _logo = 36.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.asset(
            'assets/icons/icono-tienda-1024.png',
            width: _logo,
            height: _logo,
            cacheWidth: (_logo * MediaQuery.devicePixelRatioOf(context)).ceil(),
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            t.appTitle,
            style: context.text.titleMd.copyWith(color: c.onImage),
          ),
        ),
        Material(
          color: c.onImage.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => context.openExternal(CamContact.whatsapp),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_rounded, size: 16, color: c.onImage),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      t.storyHelp,
                      style: context.text.labelSm.copyWith(color: c.onImage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// El texto de un capitulo: la etiqueta, el titular y el cuerpo entran uno
/// detras de otro, subiendo.
class _ChapterCopy extends StatefulWidget {
  const _ChapterCopy({required this.chapter, required this.animate, super.key});

  final _Chapter chapter;
  final bool animate;

  @override
  State<_ChapterCopy> createState() => _ChapterCopyState();
}

class _ChapterCopyState extends State<_ChapterCopy>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    widget.animate ? _c.forward() : _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _part(double start, Widget child) {
    final a = CurvedAnimation(
      parent: _c,
      curve: Interval(start, start + 0.6, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ch = widget.chapter;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _part(
          0,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            // `primary` con `onPrimary` y no el degradado: en oscuro el
            // degradado acaba en lila claro y el blanco encima no se lee.
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_rounded, size: 14, color: c.onPrimary),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    ch.eyebrow,
                    style: context.text.labelSm.copyWith(color: c.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _part(
          0.15,
          Text(
            ch.title,
            style: context.text.displayMd.copyWith(
              color: c.onImage,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _part(
          0.3,
          Text(
            ch.body,
            style: context.text.bodyMd.copyWith(
              color: c.onImage.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sube y aparece una vez, tras [delay].
class _Rise extends StatelessWidget {
  const _Rise({
    required this.delay,
    required this.animate,
    required this.child,
  });

  final Duration delay;
  final bool animate;
  final Widget child;

  static const _length = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    final total = delay + _length;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * AppSpacing.xxl),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Boton secundario sobre la foto: contorno claro, legible en los dos temas.
class _OnImageButton extends StatelessWidget {
  const _OnImageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = context.colors.onImage;
    final radius = BorderRadius.circular(AppRadius.pill);
    return Material(
      color: fg.withValues(alpha: 0.12),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        splashColor: fg.withValues(alpha: 0.16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: fg.withValues(alpha: 0.7), width: 1.5),
          ),
          child: SizedBox(
            height: AppSizes.controlHeight,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: context.text.button.copyWith(color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
