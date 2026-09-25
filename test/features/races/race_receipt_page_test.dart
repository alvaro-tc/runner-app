import 'dart:async';
import 'dart:typed_data';

import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/theme/app_theme.dart';
import 'package:camrun/features/races/presentation/pages/race_receipt_page.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra carga, error y permite reintentar sin salir del visor', (
    tester,
  ) async {
    final first = Completer<Uint8List>();
    final retry = Completer<Uint8List>();
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceReceiptProvider('r1').overrideWith((ref) {
            attempts++;
            return attempts == 1 ? first.future : retry.future;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RaceReceiptPage(registrationId: 'r1'),
        ),
      ),
    );
    expect(find.byType(Skeleton), findsOneWidget);
    first.completeError(const NetworkFailure());
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.text('Recibo de donación'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(Skeleton), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
