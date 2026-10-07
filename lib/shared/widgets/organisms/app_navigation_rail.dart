import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// La navegacion de las pantallas anchas: las mismas cuatro pestanas que
/// [AppBottomNavBar], en una columna al costado.
///
/// En una tablet apaisada una barra abajo se estira a lo ancho y le quita
/// alto justo a lo que mas escasea; al costado sobra sitio. Con [extended]
/// las etiquetas van al lado del icono, para las ventanas mas grandes.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    required this.currentIndex,
    required this.onTap,
    this.role = AppShellRole.runner,
    this.extended = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppShellRole role;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = appNavDestinations(context.l10n, role);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      // El rail va pegado al borde: si el sistema reserva ahi una franja, se
      // respeta.
      child: SafeArea(
        right: false,
        child: NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          extended: extended,
          // En una ventana baja el logo y las cuatro pestanas tienen que poder
          // deslizarse antes que cortarse.
          scrollable: true,
          minWidth: AppSizes.navRail,
          minExtendedWidth: AppSizes.navRailExtended,
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          backgroundColor: Colors.transparent,
          indicatorColor: c.primaryContainer,
          selectedIconTheme: IconThemeData(color: c.primary),
          unselectedIconTheme: IconThemeData(color: c.textSecondary),
          selectedLabelTextStyle: context.text.labelSm.copyWith(
            color: c.primary,
          ),
          unselectedLabelTextStyle: context.text.labelSm.copyWith(
            color: c.textSecondary,
          ),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
            child: _Brand(extended: extended),
          ),
          destinations: [
            for (final item in items)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.active),
                label: Text(item.label),
              ),
          ],
        ),
      ),
    );
  }
}

/// El icono de la app arriba del rail: en la barra de abajo no habia sitio
/// para la marca, aqui si.
class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(
        'assets/icons/icono-tienda-1024.png',
        width: _size,
        height: _size,
        // Es el icono de tienda, a 1024 px: se decodifica al tamano en que se
        // pinta y no entero.
        cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      ),
    );
    if (!extended) return ExcludeSemantics(child: logo);

    return SizedBox(
      width: AppSizes.navRailExtended - AppSpacing.xl * 2,
      child: Row(
        children: [
          ExcludeSemantics(child: logo),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              context.l10n.appTitle,
              style: context.text.headingMd,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
