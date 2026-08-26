import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';

/// Codigo de pais para el selector del telefono. La bandera sale de los
/// indicadores regionales Unicode: no hace falta empaquetar iconos.
class PhoneCountry {
  const PhoneCountry({
    required this.name,
    required this.iso2,
    required this.dialCode,
  });

  final String name;
  final String iso2;
  final String dialCode;

  String get flag => String.fromCharCodes(
    iso2.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 0x41)),
  );

  @override
  bool operator ==(Object other) => other is PhoneCountry && other.iso2 == iso2;

  @override
  int get hashCode => iso2.hashCode;
}

/// Bolivia primero: es el pais por defecto de la app. El resto son los
/// paises de los que llega gente a correr en Bolivia, ordenados alfabeticamente.
const kPhoneCountries = <PhoneCountry>[
  PhoneCountry(name: 'Bolivia', iso2: 'BO', dialCode: '+591'),
  PhoneCountry(name: 'Argentina', iso2: 'AR', dialCode: '+54'),
  PhoneCountry(name: 'Brasil', iso2: 'BR', dialCode: '+55'),
  PhoneCountry(name: 'Chile', iso2: 'CL', dialCode: '+56'),
  PhoneCountry(name: 'Colombia', iso2: 'CO', dialCode: '+57'),
  PhoneCountry(name: 'Ecuador', iso2: 'EC', dialCode: '+593'),
  PhoneCountry(name: 'España', iso2: 'ES', dialCode: '+34'),
  PhoneCountry(name: 'Estados Unidos', iso2: 'US', dialCode: '+1'),
  PhoneCountry(name: 'México', iso2: 'MX', dialCode: '+52'),
  PhoneCountry(name: 'Paraguay', iso2: 'PY', dialCode: '+595'),
  PhoneCountry(name: 'Perú', iso2: 'PE', dialCode: '+51'),
  PhoneCountry(name: 'Uruguay', iso2: 'UY', dialCode: '+598'),
  PhoneCountry(name: 'Venezuela', iso2: 'VE', dialCode: '+58'),
];

/// Campo de telefono con selector de codigo de pais.
///
/// El numero completo (codigo + numero local, separados por un espacio) es lo
/// que se escribe en [controller]: quien lo consume no necesita saber que hay
/// un selector detras. Por defecto arranca en Bolivia (+591), que es el pais
/// de la app.
class PhoneField extends StatefulWidget {
  const PhoneField({
    required this.controller,
    required this.label,
    this.errorText,
    this.hint,
    this.textInputAction,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? hint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late PhoneCountry _country;
  late final TextEditingController _number;

  @override
  void initState() {
    super.initState();
    final partido = _partir(widget.controller.text);
    _country = partido.$1;
    _number = TextEditingController(text: partido.$2)..addListener(_sync);
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  /// Separa un numero completo ("+591 70000000") en pais y resto. Sin
  /// coincidencia, Bolivia y el texto tal cual: es lo que arranca vacio.
  (PhoneCountry, String) _partir(String texto) {
    final limpio = texto.trim();
    for (final pais in kPhoneCountries) {
      if (limpio.startsWith(pais.dialCode)) {
        return (pais, limpio.substring(pais.dialCode.length).trim());
      }
    }
    return (kPhoneCountries.first, limpio);
  }

  void _sync() {
    widget.controller.text = '${_country.dialCode} ${_number.text.trim()}';
    widget.onChanged?.call(widget.controller.text);
  }

  Future<void> _elegirPais() async {
    final elegido = await showModalBottomSheet<PhoneCountry>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CountryPickerSheet(selected: _country),
    );
    if (elegido == null || !mounted) return;
    setState(() => _country = elegido);
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppTextField(
      label: widget.label,
      controller: _number,
      hint: widget.hint,
      errorText: widget.errorText,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _sync(),
      prefix: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.base),
        child: InkWell(
          onTap: _elegirPais,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_country.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _country.dialCode,
                  style: context.text.bodyMd.copyWith(color: c.textPrimary),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(Icons.expand_more, size: 18, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.sm,
            ),
            child: Text('Select a country', style: context.text.titleMd),
          ),
          for (final pais in kPhoneCountries)
            ListTile(
              leading: Text(pais.flag, style: const TextStyle(fontSize: 22)),
              title: Text(pais.name, style: context.text.bodyMd),
              trailing: Text(
                pais.dialCode,
                style: context.text.bodyMd.copyWith(color: c.textSecondary),
              ),
              selected: pais == selected,
              onTap: () => Navigator.of(context).pop(pais),
            ),
        ],
      ),
    );
  }
}
