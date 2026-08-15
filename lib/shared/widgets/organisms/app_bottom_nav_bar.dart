import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <({String label, IconData icon, IconData active})>[
    (label: 'Home', icon: Icons.home_outlined, active: Icons.home_rounded),
    (
      label: 'Train',
      icon: Icons.directions_run_outlined,
      active: Icons.directions_run_rounded,
    ),
    (
      label: 'Races',
      icon: Icons.emoji_events_outlined,
      active: Icons.emoji_events_rounded,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: _items[i],
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
