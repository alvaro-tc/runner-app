import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.admin = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// La barra del panel. Son cuatro pestanas en los dos casos y ocupan el mismo
  /// sitio —mapa, catalogo, gente, perfil—; lo que cambia es que del lado del
  /// admin se gestiona lo que del lado del corredor se usa.
  final bool admin;

  /// Los iconos son fijos; la etiqueta se resuelve por `build` para que el
  /// cambio de idioma llegue tambien a la barra.
  static List<({String label, IconData icon, IconData active})> _items(
    AppLocalizations t,
    bool admin,
  ) => admin
      ? [
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
        ]
      : [
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
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _items(context.l10n, admin);
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
