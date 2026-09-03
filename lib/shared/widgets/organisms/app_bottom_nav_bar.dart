import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Quien esta mirando la app. Decide las cuatro pestanas de abajo.
///
/// Un enum y no dos banderas: `admin: true, organizer: true` no significa
/// nada, y con banderas ese estado imposible se puede escribir.
enum AppShellRole { runner, admin, organizer }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.role = AppShellRole.runner,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Cual de las tres barras. Son cuatro pestanas en los tres casos y ocupan
  /// el mismo sitio; lo que cambia es que del lado de quien gestiona se
  /// administra lo que del lado del corredor se usa.
  final AppShellRole role;

  /// Los iconos son fijos; la etiqueta se resuelve por `build` para que el
  /// cambio de idioma llegue tambien a la barra.
  static List<({String label, IconData icon, IconData active})> _items(
    AppLocalizations t,
    AppShellRole role,
  ) => switch (role) {
    AppShellRole.admin => [
      (
        label: t.adminNavLive,
        icon: Icons.map_outlined,
        active: Icons.map_rounded,
      ),
      (
        label: t.adminNavMarathons,
        icon: Icons.emoji_events_outlined,
        active: Icons.emoji_events_rounded,
      ),
      (
        label: t.adminNavUsers,
        icon: Icons.group_outlined,
        active: Icons.group_rounded,
      ),
      (
        label: t.navProfile,
        icon: Icons.person_outline_rounded,
        active: Icons.person_rounded,
      ),
    ],
    // El organizador mira la carrera pero no la mueve, y en el sitio que el
    // admin usa para el catalogo lleva su cola de cobros: es su trabajo del
    // dia, no una pantalla secundaria.
    AppShellRole.organizer => [
      (
        label: t.adminNavLive,
        icon: Icons.map_outlined,
        active: Icons.map_rounded,
      ),
      (
        label: t.organizerNavTickets,
        icon: Icons.receipt_long_outlined,
        active: Icons.receipt_long_rounded,
      ),
      (
        label: t.organizerNavRunners,
        icon: Icons.group_outlined,
        active: Icons.group_rounded,
      ),
      (
        label: t.navProfile,
        icon: Icons.person_outline_rounded,
        active: Icons.person_rounded,
      ),
    ],
    AppShellRole.runner => [
      (label: t.navHome, icon: Icons.home_outlined, active: Icons.home_rounded),
      (
        label: t.navTrain,
        icon: Icons.directions_run_outlined,
        active: Icons.directions_run_rounded,
      ),
      (
        label: t.navRaces,
        icon: Icons.emoji_events_outlined,
        active: Icons.emoji_events_rounded,
      ),
      (
        label: t.navProfile,
        icon: Icons.person_outline_rounded,
        active: Icons.person_rounded,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _items(context.l10n, role);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: c.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({String label, IconData icon, IconData active}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Icon(
                selected ? item.active : item.icon,
                key: ValueKey(selected),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.label,
              style: context.text.labelSm.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
