import 'dart:math' as math;

import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:flutter/material.dart';

/// Rango, salto de pagina y cuantas filas trae cada una.
///
/// Lo comparten las dos listas paginadas del panel —usuarios y cobros— porque
/// son la misma barra: dos copias significan que el dia que el rango se pinte
/// mal haya que arreglarlo dos veces, y la segunda se olvida.
///
/// Se esconde mientras no hay total —la primera carga— y cuando no hay
/// resultados: un paginador sobre una lista vacia solo estorba.
class AdminPaginator extends StatelessWidget {
  const AdminPaginator({
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
    super.key,
  });

  final int? total;
  final int pagina;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onPorPagina;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cuantos = total;
    if (cuantos == null || cuantos == 0) return const SizedBox.shrink();

    final desde = (pagina - 1) * porPagina + 1;
    final hasta = math.min(pagina * porPagina, cuantos);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(t.adminPerPage, style: context.text.labelSm),
          const SizedBox(width: AppSpacing.xs),
          DropdownButton<int>(
            value: porPagina,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: context.text.bodySm.copyWith(
              color: context.colors.textPrimary,
            ),
            items: [
              for (final n in adminPageSizes)
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
            onChanged: (n) => n == null ? null : onPorPagina(n),
          ),
          const Spacer(),
          Text(
            t.adminPageRange(desde, hasta, cuantos),
            style: context.text.labelSm.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: t.adminPrevPage,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: pagina > 1 ? () => onPagina(pagina - 1) : null,
          ),
          IconButton(
            tooltip: t.adminNextPage,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: hasta < cuantos ? () => onPagina(pagina + 1) : null,
          ),
        ],
      ),
    );
  }
}
