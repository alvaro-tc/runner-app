import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart';
import 'package:camrun/shared/widgets/organisms/app_navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Quien pinta el armazon elige tambien el rol, asi que el enum viaja con el:
// importar dos ficheros para montar una pantalla es una pista falsa.
export 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart'
    show AppShellRole;

/// Holds the four tab stacks. Each branch keeps its own navigation state, so
/// switching tabs never resets where the user was.
///
/// La navegacion sigue a la ventana: barra abajo en telefono, rail al costado
/// en cuanto hay ancho de tablet. Las pestanas y su estado son los mismos;
/// girar la tablet no saca a nadie de donde estaba.
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

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final windowClass = context.windowClass;

    if (windowClass.isCompact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: AppBottomNavBar(
          role: role,
          currentIndex: shell.currentIndex,
          onTap: _go,
        ),
      );
    }

    // Cada pagina decide su ancho util (ver `PageInsets`): una lista de
    // ajustes y un mapa en vivo no quieren la misma columna.
    return Scaffold(
      body: Row(
        children: [
          AppNavigationRail(
            role: role,
            currentIndex: shell.currentIndex,
            onTap: _go,
            extended: windowClass == WindowClass.large,
          ),
          Expanded(
            // El rail ya se aparto del borde con la camara.
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              child: shell,
            ),
          ),
        ],
      ),
    );
  }
}
