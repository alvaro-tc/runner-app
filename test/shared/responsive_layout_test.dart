import 'package:camrun/app/router/app_router.dart';
import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/presentation/pages/home_page.dart';
import 'package:camrun/features/races/presentation/pages/race_detail_page.dart';
import 'package:camrun/shared/widgets/layout/responsive.dart';
import 'package:camrun/shared/widgets/organisms/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('clases de ventana', () {
    test('se clasifican por ancho, con los cortes de Material 3', () {
      expect(AppBreakpoints.classify(390), WindowClass.compact);
      expect(AppBreakpoints.classify(599), WindowClass.compact);
      expect(AppBreakpoints.classify(600), WindowClass.medium);
      expect(AppBreakpoints.classify(834), WindowClass.medium);
      expect(AppBreakpoints.classify(840), WindowClass.expanded);
      expect(AppBreakpoints.classify(1194), WindowClass.expanded);
      expect(AppBreakpoints.classify(1366), WindowClass.large);
    });

    test('solo gira la tablet: se mide el lado corto de la pantalla', () {
      // Telefonos, de lado o de pie: nunca llegan a 600.
      expect(AppBreakpoints.isTablet(const Size(390, 844)), isFalse);
      expect(AppBreakpoints.isTablet(const Size(932, 430)), isFalse);
      // iPad mini, iPad Pro 11", tablet Android de 600 dp.
      expect(AppBreakpoints.isTablet(const Size(744, 1133)), isTrue);
      expect(AppBreakpoints.isTablet(const Size(1194, 834)), isTrue);
      expect(AppBreakpoints.isTablet(const Size(600, 960)), isTrue);
    });
  });

  group('margenes', () {
    test('en telefono el margen es el de siempre', () {
      expect(
        AppLayout.inset(390, maxWidth: AppSizes.wideMaxWidth),
        AppSpacing.screenH,
      );
    });

    test('en una tablet el contenido se centra sin pasar del tope', () {
      final inset = AppLayout.inset(1106, maxWidth: AppSizes.readableMaxWidth);
      expect(1106 - inset * 2, AppSizes.readableMaxWidth);
    });

    test('un hueco algo mas ancho que el tope se queda con el gutter', () {
      expect(
        AppLayout.inset(780, maxWidth: AppSizes.readableMaxWidth),
        AppSpacing.screenHWide,
      );
    });
  });

  group('columnas', () {
    test('dos metricas por fila en telefono, cuatro en tablet', () {
      expect(AppLayout.columns(350, minItemWidth: 150, maxColumns: 4), 2);
      expect(AppLayout.columns(690, minItemWidth: 150, maxColumns: 4), 4);
    });

    test('nunca menos de una ni mas del tope', () {
      expect(AppLayout.columns(100, minItemWidth: 320), 1);
      expect(AppLayout.columns(5000, minItemWidth: 100), 3);
    });
  });

  group('pantallas de mapa', () {
    test('el telefono vertical lleva los controles abajo', () {
      expect(AppLayout.mapSidePanel(390, 844), isFalse);
      expect(AppLayout.mapSidePanel(834, 1194), isFalse);
    });

    test('con ancho de tablet, o en una ventana baja, van al costado', () {
      expect(AppLayout.mapSidePanel(844, 390), isTrue);
      expect(AppLayout.mapSidePanel(1194, 834), isTrue);
      expect(AppLayout.mapSidePanel(1024, 1366), isTrue);
    });
  });

  group('carrusel de Home', () {
    test('en telefono la tarjeta ocupa casi todo el ancho', () {
      expect(heroViewportFraction(350, 844), heroPhoneFraction);
    });

    test('en una tablet apaisada asoma la siguiente tarjeta', () {
      final fraction = heroViewportFraction(1042, 834);
      expect(fraction, lessThan(0.6));
      expect(fraction, greaterThan(0.4));
    });

    test('en una ventana baja la tarjeta cabe en el alto', () {
      final fraction = heroViewportFraction(692, 390);
      final cardHeight = 692 * fraction * 11 / 16;
      expect(cardHeight, lessThan(390));
    });
  });

  testWidgets('la rejilla reparte las tarjetas en filas de igual ancho', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 700,
            child: ResponsiveGrid(
              minItemWidth: 200,
              children: [
                for (var i = 0; i < 5; i++)
                  SizedBox(key: ValueKey(i), height: 50),
              ],
            ),
          ),
        ),
      ),
    );

    final primera = tester.getRect(find.byKey(const ValueKey(0)));
    final cuarta = tester.getRect(find.byKey(const ValueKey(3)));
    final quinta = tester.getRect(find.byKey(const ValueKey(4)));
    // Tres por fila: la cuarta abre la segunda fila bajo la primera.
    expect(cuarta.left, primera.left);
    expect(cuarta.top, greaterThan(primera.bottom));
    // La ultima fila viene corta y no se estira.
    expect(quinta.width, primera.width);
  });

  group('armazon', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view
        ..physicalSize = size * 2
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final container = await pumpApp(tester, signedIn: true);
      await tester.pump();
      // Fuera de Home: su cuenta atras deja un temporizador vivo que el test
      // no puede descargar.
      container.read(routerProvider).go(Routes.profile);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('en telefono la navegacion va abajo', (tester) async {
      await pumpAt(tester, const Size(390, 844));
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      await drainHome(tester);
    });

    testWidgets('en una tablet va en un rail al costado', (tester) async {
      await pumpAt(tester, const Size(1194, 834));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      await drainHome(tester);
    });

    testWidgets('girar la pantalla no saca a nadie de donde estaba', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844) * 2
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final container = await pumpApp(tester, signedIn: true);
      await tester.pump();
      container.read(routerProvider).go(Routes.raceDetailOf('r0'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RaceDetailPage), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      NavigatorState pestana() => tester.state<NavigatorState>(
        find
            .ancestor(
              of: find.byType(RaceDetailPage),
              matching: find.byType(Navigator),
            )
            .first,
      );
      final antes = pestana();

      // De telefono vertical a tablet apaisada: la barra pasa a rail y la
      // pila de la pestaña sigue intacta.
      tester.view.physicalSize = const Size(1194, 834) * 2;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.byType(RaceDetailPage), findsOneWidget);
      // El mismo navegador, no uno nuevo en la misma ruta: el armazon se
      // reacomoda sin rehacer la pila.
      expect(identical(pestana(), antes), isTrue);
      expect(
        container.read(routerProvider).state.uri.path,
        Routes.raceDetailOf('r0'),
      );
      await drainHome(tester);
    });
  });
}
