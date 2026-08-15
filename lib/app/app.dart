import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/router/app_router.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_theme.dart';

class PaceUpApp extends ConsumerWidget {
  const PaceUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PaceUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // Beyond 1.3 the metric grids stop fitting; clamping keeps the layout
        // intact while still honouring the user's larger-text preference.
        maxScaleFactor: 1.3,
        child: child!,
      ),
    );
  }
}
