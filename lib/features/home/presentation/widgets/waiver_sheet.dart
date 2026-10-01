import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Abre el deslinde de responsabilidad. Devuelve `true` solo si el usuario
/// lo leyo hasta el final y pulso aceptar.
Future<bool> showWaiverSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => const _WaiverSheet(),
    ) ??
    false;

class _WaiverSheet extends StatefulWidget {
  const _WaiverSheet();

  @override
  State<_WaiverSheet> createState() => _WaiverSheetState();
}

class _WaiverSheetState extends State<_WaiverSheet> {
  final _scroll = ScrollController();
  bool _leidoHastaAbajo = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_comprobarFinal);
    // En pantallas grandes el texto puede caber entero sin deslizar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _comprobarFinal());
  }

  void _comprobarFinal() {
    if (_leidoHastaAbajo || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - AppSpacing.xl) {
      setState(() => _leidoHastaAbajo = true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final secciones = [
      (t.waiverS1Title, t.waiverS1Body),
      (t.waiverS2Title, t.waiverS2Body),
      (t.waiverS3Title, t.waiverS3Body),
      (t.waiverS4Title, t.waiverS4Body),
      (t.waiverS5Title, t.waiverS5Body),
      (t.waiverS6Title, t.waiverS6Body),
      (t.waiverS7Title, t.waiverS7Body),
      (t.waiverS8Title, t.waiverS8Body),
      (t.waiverS9Title, t.waiverS9Body),
      (t.waiverS10Title, t.waiverS10Body),
      (t.waiverS11Title, t.waiverS11Body),
    ];

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xl,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.waiverTitle, style: context.text.headingMd),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.waiverSubtitle,
                  style: context.text.labelSm.copyWith(color: c.primary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(AppSpacing.screenH),
                children: [
                  Text(t.waiverIntro, style: context.text.bodyMd),
                  for (final (i, (titulo, cuerpo)) in secciones.indexed) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('${i + 1}. $titulo', style: context.text.titleMd),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      cuerpo,
                      style: context.text.bodySm.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_leidoHastaAbajo) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          t.waiverScrollHint,
                          style: context.text.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: t.waiverDecline,
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: t.waiverAccept,
                          onPressed: _leidoHastaAbajo
                              ? () => context.pop(true)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
