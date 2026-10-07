import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Hoja desde abajo en telefono; dialogo centrado en cuanto la ventana es
/// ancha.
///
/// En una tablet una hoja nace lejos de donde se toco y ocupa media pantalla
/// para cuatro campos. El contenido es el mismo en los dos casos: quien lo
/// cierra con `Navigator.pop(valor)` no tiene que saber cual le toco.
///
/// [showDragHandle] es para el contenido que cuenta con el asa encima y por
/// eso no deja margen arriba; en el dialogo se le reserva ese mismo aire.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = false,
}) {
  if (context.windowClass.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: showDragHandle,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
        // El dialogo ya se aparta de la barra de estado y del teclado: un
        // `SafeArea` del contenido le sumaria otra franja vacia por dentro.
        child: MediaQuery.removePadding(
          context: dialogContext,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: showDragHandle ? AppSpacing.xl : 0),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}
