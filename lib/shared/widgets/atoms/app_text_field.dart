import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';

/// Labelled input: the label sits above the field (never as a floating hint),
/// matching the sign-in reference.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofillHints,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? c.error
        : _focus.hasFocus
        ? c.primary
        : c.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: context.text.labelSm.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: _focus.hasFocus && !hasError
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.08),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            style: context.text.bodyMd.copyWith(color: c.textPrimary),
            cursorColor: c.primary,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: widget.hint,
              hintStyle: context.text.bodyMd.copyWith(color: c.textSecondary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base + 1,
              ),
              suffixIcon: _buildSuffix(c.textSecondary),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            widget.errorText!,
            style: context.text.bodySm.copyWith(color: c.error),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix(Color color) {
    if (widget.isPassword) {
      return IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: color,
        ),
        tooltip: _obscure ? 'Show password' : 'Hide password',
      );
    }
    if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixTap,
        icon: Icon(widget.suffixIcon, size: 20, color: color),
      );
    }
    return null;
  }
}
