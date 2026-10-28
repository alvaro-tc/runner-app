import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/auth/presentation/widgets/cam_story.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shared chrome for sign-in, sign-up and password recovery: back arrow,
/// screen gutter, and a scroll view so the keyboard never causes an overflow.
///
/// Con [title] el movil abre con una foto del CAM y el titulo encima, y el
/// formulario sube en una hoja por delante de la foto.
///
/// En una tablet apaisada el formulario solo seria una columna perdida en el
/// medio: se parte en dos, con la marca a la izquierda y el formulario a la
/// derecha, cada uno en su mitad.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.children,
    this.title,
    this.photo = CamPhotos.run,
    super.key,
  });

  final List<Widget> children;
  final String? title;

  /// La foto de la cabecera en movil; solo cuenta con [title].
  final String photo;

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.welcome);

  @override
  Widget build(BuildContext context) {
    final wide = context.windowClass.isAtLeast(WindowClass.expanded);
    if (title != null && !wide) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: _PhotoLayout(
          title: title!,
          photo: photo,
          onBack: () => _back(context),
          children: children,
        ),
      );
    }

    final form = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    style: AppIconButtonStyle.plain,
                    semanticsLabel: context.l10n.commonBack,
                    onPressed: () => _back(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (title != null) ...[
                  Text(title!, style: context.text.displayMd),
                  const SizedBox(height: AppSpacing.xl),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: wide
          ? Row(
              children: [
                const Expanded(child: AuthBrandPanel()),
                Expanded(child: form),
              ],
            )
          : form,
    );
  }
}

/// Movil con [AuthScaffold.title]: foto arriba que se asienta, titulo que
/// sube sobre ella y la hoja del formulario, que entra por detras con sus
/// campos escalonados.
class _PhotoLayout extends StatefulWidget {
  const _PhotoLayout({
    required this.title,
    required this.photo,
    required this.onBack,
    required this.children,
  });

  final String title;
  final String photo;
  final VoidCallback onBack;
  final List<Widget> children;

  @override
  State<_PhotoLayout> createState() => _PhotoLayoutState();
}

class _PhotoLayoutState extends State<_PhotoLayout>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Cuanto se mete la hoja por encima de la foto.
  static const _overlap = AppSpacing.xxl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 1;
    } else if (_c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _span(double from, double to) => CurvedAnimation(
    parent: _c,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  /// Aparece y sube [dy] en su tramo del controlador.
  Widget _rise(Animation<double> a, double dy, Widget child) => AnimatedBuilder(
    animation: a,
    builder: (context, child) => Opacity(
      opacity: a.value,
      child: Transform.translate(
        offset: Offset(0, (1 - a.value) * dy),
        child: child,
      ),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      220.0,
      340.0,
    );
    final settle = _span(0, 1);
    final n = widget.children.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height + _overlap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: AnimatedBuilder(
                      animation: settle,
                      // La foto llega un poco cerca y se aleja hasta su
                      // sitio: da profundidad sin moverse despues.
                      builder: (context, child) => Transform.scale(
                        scale: 1.12 - 0.12 * settle.value,
                        child: child,
                      ),
                      child: Image.asset(
                        widget.photo,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, 0.1),
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  ColoredBox(color: c.imageTint),
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: c.storyScrim),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.screenH,
                        _overlap + AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: widget.onBack,
                            tooltip: context.l10n.commonBack,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: c.onImage,
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.screenH - AppSpacing.sm,
                            ),
                            child: _rise(
                              _span(0.2, 0.7),
                              AppSpacing.xl,
                              Text(
                                widget.title,
                                style: context.text.displayMd.copyWith(
                                  color: c.onImage,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: _rise(
                _span(0.1, 0.6),
                AppSpacing.xxxl,
                Container(
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sheet),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.xl,
                    AppSpacing.screenH,
                    AppSpacing.xxl,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cada campo entra un poco despues que el de
                            // arriba; con muchos, el desfase se reparte.
                            for (var i = 0; i < n; i++)
                              _rise(
                                _span(0.25 + 0.4 * i / n, 0.65 + 0.35 * i / n),
                                AppSpacing.base,
                                widget.children[i],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La mitad de marca de las pantallas de acceso en tablet: una foto del CAM
/// bajo el velo de la marca, con el logo, el nombre y el lema.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  static const _logoSize = 72.0;

  /// Una linea de texto comoda de leer, aunque la mitad de la tablet sea mas
  /// ancha.
  static const _textMaxWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          CamPhotos.run,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        ColoredBox(color: c.imageTint),
        DecoratedBox(decoration: BoxDecoration(gradient: c.storyScrim)),
        SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _textMaxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Image.asset(
                        'assets/icons/icono-tienda-1024.png',
                        width: _logoSize,
                        height: _logoSize,
                        cacheWidth:
                            (_logoSize * MediaQuery.devicePixelRatioOf(context))
                                .ceil(),
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      t.camTagline,
                      style: context.text.displayMd.copyWith(color: c.onImage),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.authWelcomeCamBody,
                      style: context.text.bodyMd.copyWith(
                        color: c.onImage.withValues(alpha: 0.88),
                      ),
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

/// Two hairlines with the word `or` between them.
class AuthDivider extends StatelessWidget {
  const AuthDivider({this.label, super.key});

  /// Por defecto, el `o` traducido del idioma activo.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            label ?? context.l10n.commonOr,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}
