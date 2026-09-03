import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Quien pinta el armazon elige tambien el rol, asi que el enum viaja con el:
// importar dos ficheros para montar una pantalla es una pista falsa.
export 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart'
    show AppShellRole;

/// Holds the four tab stacks. Each branch keeps its own navigation state, so
/// switching tabs never resets where the user was.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.shell,
    this.role = AppShellRole.runner,
    super.key,
  });

  final StatefulNavigationShell shell;

  /// Cual de las tres barras pintar. Las tres ramas son cuatro pestanas con la
  /// misma forma, asi que comparten armazon.
  final AppShellRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          // Tablets get a centred column rather than stretched-out rows.
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: shell,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        role: role,
        currentIndex: shell.currentIndex,
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
