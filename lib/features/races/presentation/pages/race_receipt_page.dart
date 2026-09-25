import 'dart:typed_data';

import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class RaceReceiptPage extends ConsumerWidget {
  const RaceReceiptPage({required this.registrationId, super.key});

  final String registrationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final provider = raceReceiptProvider(registrationId);
    return Scaffold(
      appBar: AppBar(title: Text(t.raceReceiptTitle)),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const _ReceiptLoading(),
              error: (error, _) => ErrorStateView(
                message: error is Failure
                    ? error.localized(t)
                    : t.raceReceiptFailed,
                onRetry: () => ref.invalidate(provider),
              ),
              data: (bytes) => _ReceiptDocument(
                bytes: bytes,
                filename: 'recibo-$registrationId.pdf',
                onRetry: () => ref.invalidate(provider),
              ),
            ),
      ),
    );
  }
}

class _ReceiptLoading extends StatelessWidget {
  const _ReceiptLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.screenH),
    child: AspectRatio(
      aspectRatio: 828 / 495,
      child: Skeleton(width: double.infinity, height: double.infinity),
    ),
  );
}

class _ReceiptDocument extends StatefulWidget {
  const _ReceiptDocument({
    required this.bytes,
    required this.filename,
    required this.onRetry,
  });
  final Uint8List bytes;
  final String filename;
  final VoidCallback onRetry;

  @override
  State<_ReceiptDocument> createState() => _ReceiptDocumentState();
}

class _ReceiptDocumentState extends State<_ReceiptDocument> {
  bool _busy = false;

  Future<void> _export({required bool print}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) async => widget.bytes,
          name: widget.filename,
          dynamicLayout: false,
        );
      } else {
        final box = context.findRenderObject() as RenderBox?;
        await Printing.sharePdf(
          bytes: widget.bytes,
          filename: widget.filename,
          bounds: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (_) {
      if (mounted) context.showSnack(context.l10n.raceReceiptActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      children: [
        Expanded(
          child: PdfPreview(
            build: (_) async => widget.bytes,
            useActions: false,
            canDebug: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            dynamicLayout: false,
            loadingWidget: const _ReceiptLoading(),
            scrollViewDecoration: BoxDecoration(color: context.colors.surface),
            onError: (context, _) => ErrorStateView(
              message: t.raceReceiptFailed,
              onRetry: widget.onRetry,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: t.raceReceiptSave,
                icon: Icons.ios_share_rounded,
                isLoading: _busy,
                onPressed: _busy ? null : () => _export(print: false),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: t.raceReceiptPrint,
                variant: AppButtonVariant.outline,
                icon: Icons.print_outlined,
                onPressed: _busy ? null : () => _export(print: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
