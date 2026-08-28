import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/pages/admin_route_editor_page.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alta y edicion de una maraton, entera desde el movil.
///
/// Con [marathonId] en `null` es el alta. Es la misma pantalla porque los
/// campos son los mismos: dos formularios paralelos se desincronizan en el
/// primer campo nuevo, y entonces el panel puede crear algo que no puede editar.
class AdminMarathonEditPage extends ConsumerWidget {
  const AdminMarathonEditPage({this.marathonId, super.key});

  final String? marathonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final id = marathonId;

    if (id == null) return const _Formulario(original: null);

    final maraton = ref.watch(adminMarathonProvider(id));
    return maraton.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.adminEditMarathon)),
        body: const Center(child: Skeleton(width: 180, height: 20)),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(t.adminEditMarathon)),
        body: ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => ref.invalidate(adminMarathonProvider(id)),
        ),
      ),
      data: (m) => _Formulario(original: m),
    );
  }
}

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({required this.original});

  final AdminMarathon? original;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _nombre = TextEditingController(text: _m?.name ?? '');
  late final _ciudad = TextEditingController(text: _m?.city ?? '');
  late final _descripcion = TextEditingController(text: _m?.description ?? '');
  late final _cupo = TextEditingController(
    text: _m == null ? '' : '${_m!.capacity}',
  );
  // El precio se edita en bolivianos y viaja en centavos: la conversion vive en
  // la frontera, como en el resto de la app.
  late final _precio = TextEditingController(
    text: _m == null ? '' : (_m!.priceCents / 100).toStringAsFixed(2),
  );
  late final _qrTexto = TextEditingController(
    text: _m?.paymentQrInstructions ?? '',
  );
  // El QR **como texto**: es lo que la app dibuja en el checkout, y sin esto la
  // maraton no admite el pago por QR. Ver `docs/pago-qr-manual.md` en la API.
  late final _qrPayload = TextEditingController(
    text: _m?.paymentQrPayload ?? '',
  );

  late DateTime _fecha =
      _m?.startsAt ?? DateTime.now().add(const Duration(days: 30));
  late List<GeoPoint> _ruta = _m?.route ?? const [];
  late bool _publicada = _m?.published ?? false;
  late bool _inscripciones = _m?.registrationsOpen ?? true;

  bool _guardando = false;
  String? _error;

  AdminMarathon? get _m => widget.original;

  bool get _esAlta => _m == null;

  @override
  void dispose() {
    _nombre.dispose();
    _ciudad.dispose();
    _descripcion.dispose();
    _cupo.dispose();
    _precio.dispose();
    _qrTexto.dispose();
    _qrPayload.dispose();
    super.dispose();
  }

  double get _distanciaKm {
    var metros = 0.0;
    for (var i = 1; i < _ruta.length; i++) {
      metros += _ruta[i - 1].distanceTo(_ruta[i]);
    }
    return metros / 1000;
  }

  Future<void> _elegirFecha() async {
    final dia = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dia == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
    );
    if (!mounted) return;

    setState(() {
      _fecha = DateTime(
        dia.year,
        dia.month,
        dia.day,
        hora?.hour ?? _fecha.hour,
        hora?.minute ?? _fecha.minute,
      );
    });
  }

  Future<void> _marcarRuta() async {
    final trazado = await Navigator.of(context).push<List<GeoPoint>>(
      MaterialPageRoute(builder: (_) => AdminRouteEditorPage(initial: _ruta)),
    );
    if (trazado != null && mounted) setState(() => _ruta = trazado);
  }

  /// Lo que viaja al servidor. Solo lo que el formulario controla: mandar todo
  /// el objeto pisaria campos que esta pantalla ni muestra.
  Map<String, dynamic> _cuerpo() {
    final metros = (_distanciaKm * 1000).round();
    return {
      'name': _nombre.text.trim(),
      'city': _ciudad.text.trim(),
      'description': _descripcion.text.trim(),
      'startsAt': _fecha.toUtc().toIso8601String(),
      'capacity': int.tryParse(_cupo.text.trim()) ?? 0,
      'priceCents': ((double.tryParse(_precio.text.trim()) ?? 0) * 100).round(),
      'paymentQrInstructions': _qrTexto.text.trim(),
      // Vacio = sin QR, y el servidor rechaza el cobro. Se manda igual: es como
      // se apaga el metodo en una carrera que dejo de cobrar por ahi.
      'paymentQrPayload': _qrPayload.text.trim(),
      'published': _publicada,
      // `registrationStatus` guarda la intencion del admin; el resto lo deriva
      // el servidor de cupos y fechas.
      'registrationStatus': _inscripciones ? 'open' : 'closed',
      if (_ruta.length > 1) ...{
        'routeGeoJson': routeToGeoJson(_ruta),
        // La distancia sale del trazado y no de un campo: un numero escrito a
        // mano que no cuadre con la linea deja una carrera cuya meta no esta en
        // el mapa.
        'distanceMeters': metros,
      } else if (_esAlta)
        // Sin recorrido el servidor exige la distancia. Una maraton sin trazado
        // ni distancia no se puede ni listar.
        'distanceMeters': _m?.distanceMeters ?? 42195,
    };
  }

  String? _validar() {
    final t = context.l10n;
    if (_nombre.text.trim().isEmpty) return t.adminNameRequired;
    if (_ciudad.text.trim().isEmpty) return t.adminCityRequired;
    if ((int.tryParse(_cupo.text.trim()) ?? 0) < 1) {
      return t.adminCapacityRequired;
    }
    return null;
  }

  Future<void> _guardar() async {
    final problema = _validar();
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final api = ref.read(adminApiProvider);
    try {
      if (_esAlta) {
        await api.createMarathon(_cuerpo());
      } else {
        await api.updateMarathon(_m!.id, _cuerpo());
        ref.invalidate(adminMarathonProvider(_m!.id));
      }
      ref.invalidate(adminMarathonsProvider);
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrar() async {
    final t = context.l10n;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(t.adminDeleteMarathonTitle),
        content: Text(t.adminDeleteMarathonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: Text(t.adminDelete),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _guardando = true);
    try {
      await ref.read(adminApiProvider).deleteMarathon(_m!.id);
      ref.invalidate(adminMarathonsProvider);
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (f) {
      // El servidor niega el borrado si ya hay inscritos: el mensaje que trae
      // explica por que mejor que cualquier texto de aqui.
      if (mounted) setState(() => _error = f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esAlta ? t.adminNewMarathon : t.adminEditMarathon),
        actions: [
          if (!_esAlta)
            IconButton(
              onPressed: _guardando ? null : _borrar,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: t.adminDelete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xxl,
        ),
        children: [
          AppTextField(label: t.adminName, controller: _nombre),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: t.adminCity, controller: _ciudad),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: t.adminDescription,
            controller: _descripcion,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: t.adminCapacity,
                  controller: _cupo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: t.adminPrice,
                  controller: _precio,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Tarjeta(
            children: [
              StatRow(
                icon: Icons.event_outlined,
                title: t.adminStartsAt,
                value: '${Fmt.fullDate(_fecha)} · ${Fmt.timeOfDay(_fecha)}',
                onTap: _elegirFecha,
              ),
              const AppDivider(),
              StatRow(
                icon: Icons.route_outlined,
                title: t.adminRouteTitle,
                value: _ruta.length < 2
                    ? t.adminRouteMissing
                    : Fmt.distance(_distanciaKm),
                subtitle: t.adminRouteSubtitle,
                onTap: _marcarRuta,
              ),
            ],
          ),
          if (_ruta.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: SizedBox(
                height: 180,
                child: RouteMapView(
                  route: const [],
                  guideRoute: _ruta,
                  interactive: false,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _Tarjeta(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _publicada,
                onChanged: (v) => setState(() => _publicada = v),
                title: Text(t.adminPublishedSwitch, style: context.text.bodyMd),
                subtitle: Text(
                  t.adminPublishedHint,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
              const AppDivider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _inscripciones,
                onChanged: (v) => setState(() => _inscripciones = v),
                title: Text(
                  t.adminRegistrationsSwitch,
                  style: context.text.bodyMd,
                ),
                subtitle: Text(
                  t.adminRegistrationsHint,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Tarjeta(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AppTextField(
                  label: t.adminQrInstructions,
                  controller: _qrTexto,
                  maxLines: 2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AppTextField(
                  label: t.adminQrPayload,
                  controller: _qrPayload,
                  hint: t.adminQrPayloadHint,
                  maxLines: 3,
                ),
              ),
              // Se dice aqui y no en un error del corredor tres pantallas mas
              // tarde: sin este texto la carrera no cobra.
              Text(
                _qrPayload.text.trim().isEmpty
                    ? t.adminQrPayloadMissing
                    : t.adminQrPayloadHelp,
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: context.text.bodySm.copyWith(color: c.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: t.commonSave,
            icon: Icons.check_rounded,
            isLoading: _guardando,
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(children: children),
    );
  }
}
