import 'package:camrun/app/router/app_router.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_theme.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CamRunApp extends ConsumerWidget {
  const CamRunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // `null` deja que Flutter resuelva el del dispositivo; cualquier otro
      // valor lo fuerza. Al cambiarlo el arbol entero se reconstruye, que es
      // lo que hace que el cambio de idioma sea en caliente.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // `Fmt` llama a `DateFormat`/`NumberFormat` sin locale explicito, asi
        // que leen el de `Intl`. Se fija aqui, dentro del subarbol que ya
        // resolvio el locale, para que fechas y numeros sigan al selector.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return MediaQuery.withClampedTextScaling(
          // Beyond 1.3 the metric grids stop fitting; clamping keeps the layout
          // intact while still honouring the user's larger-text preference.
          maxScaleFactor: 1.3,
          child: child!,
        );
      },
    );
  }
}
