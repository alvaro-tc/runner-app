import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_colors.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/data/qr_image_reader.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/pages/admin_route_editor_page.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/admin/presentation/widgets/marathon_image_field.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
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
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Alta y edicion de una maraton, entera desde el movil.
///
/// Con [marathonId] en `null` es el alta. Es la misma pantalla porque los
/// campos son los mismos: dos formularios paralelos se desincronizan en el
/// primer campo nuevo, y entonces el panel puede crear algo que no puede editar.
///
/// Hay dos velocidades conviviendo, y la diferencia es deliberada:
///
/// * **El contenido se guarda.** Nombre, fecha, precio y demas se editan y
///   viajan juntos al pulsar Guardar, y solo viaja lo que se toco.
/// * **El estado y las imagenes son inmediatos.** Publicar, abrir inscripciones
///   y subir una foto tienen su propio endpoint y ocurren al momento. Meterlos
///   en el boton de guardar obligaria a explicar por que una foto que ya se ve
///   todavia no esta subida.
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
      // Al refrescar tras subir una imagen se sigue pintando el formulario con
      // lo anterior: cambiarlo por el esqueleto lo desmontaria y se perderia lo
      // que hubiera escrito sin guardar.
      skipLoadingOnRefresh: true,
      loading: () => Scaffold(
        appBar: AppBar(title: Text(t.adminEditMarathon)),
        body: const _CargandoDetalle(),
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
  late final _distancia = TextEditingController(
    text: _m == null ? '' : _m!.distanceKm.toStringAsFixed(2),
  );
  late final _qrTexto = TextEditingController(
    text: _m?.paymentQrInstructions ?? '',
  );

  late DateTime _fecha =
      _m?.startsAt ?? DateTime.now().add(const Duration(days: 30));
  late List<GeoPoint> _ruta = _m?.route ?? const [];

  /// Como estaba todo al abrir. Es contra esto que se decide que viaja: la
  /// edicion es parcial, y mandar el objeto entero pisaria con valores viejos
  /// lo que otro haya cambiado mientras tanto.
  late final Map<String, Object?> _inicial = _instantanea();

  bool _guardando = false;
  Failure? _errorGuardado;

  var _estadoFoto = ImageSlotStatus.idle;

  /// El ultimo archivo elegido para el afiche. Reintentar una subida que fallo
  /// tiene que reenviar **ese** archivo, no abrir la galeria otra vez.
  String? _ultimaFoto;

  /// El contenido del QR de cobro. De la foto que elige el organizador solo
  /// queda esto: la imagen se lee y se tira, y lo que se guarda es el texto.
  late String? _qrPayload = _m?.paymentQrPayload;
  bool _leyendoQr = false;

  bool _cambiandoEstado = false;

  AdminMarathon? get _m => widget.original;

  bool get _esAlta => _m == null;

  @override
  void initState() {
    super.initState();
    // Se fuerza aqui a proposito. `_inicial` es `late final`, o sea perezoso:
    // sin este toque se calcularia en el primer guardado —ya con los cambios
    // dentro— y la comparacion no encontraria nunca nada que mandar.
    _inicial;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _ciudad.dispose();
    _descripcion.dispose();
    _cupo.dispose();
    _precio.dispose();
    _distancia.dispose();
    _qrTexto.dispose();
    super.dispose();
  }

  // ─── Lo que el formulario vale ahora ──────────────────────────────────────

  double get _distanciaDelTrazado {
    var metros = 0.0;
    for (var i = 1; i < _ruta.length; i++) {
      metros += _ruta[i - 1].distanceTo(_ruta[i]);
    }
    return metros / 1000;
  }

  int get _metros =>
      ((double.tryParse(_distancia.text.trim()) ?? 0) * 1000).round();

  Map<String, Object?> _instantanea() => {
    'name': _nombre.text.trim(),
    'city': _ciudad.text.trim(),
    'description': _descripcion.text.trim(),
    'startsAt': _fecha.toUtc().toIso8601String(),
    'capacity': int.tryParse(_cupo.text.trim()) ?? 0,
    'priceCents': ((double.tryParse(_precio.text.trim()) ?? 0) * 100).round(),
    'distanceMeters': _metros,
    'paymentQrPayload': _qrPayload ?? '',
    'paymentQrInstructions': _qrTexto.text.trim(),
    // El trazado se compara por su forma, no por la lista entera: son miles de
    // puntos y basta con saber si cambio.
    'routeGeoJson': _huellaDeRuta(_ruta),
  };

  static String _huellaDeRuta(List<GeoPoint> puntos) {
    if (puntos.isEmpty) return '';
    final a = puntos.first;
    final z = puntos.last;
    return '${puntos.length}:${a.lat},${a.lng}:${z.lat},${z.lng}';
  }

  /// Solo lo que cambio. En el alta no hay contra que comparar, asi que va todo.
  Map<String, dynamic> _cuerpo() {
    final ahora = _instantanea();

    if (_esAlta) {
      return {
        for (final e in ahora.entries)
          if (e.key != 'routeGeoJson') e.key: e.value,
        if (_ruta.length > 1) 'routeGeoJson': routeToGeoJson(_ruta),
      };
    }

    final cambios = <String, dynamic>{};
    for (final e in ahora.entries) {
      if (e.value == _inicial[e.key]) continue;
      cambios[e.key] = e.key == 'routeGeoJson'
          ? (_ruta.length > 1 ? routeToGeoJson(_ruta) : null)
          : e.value;
    }
    return cambios;
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

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
    if (trazado == null || !mounted) return;

    setState(() {
      _ruta = trazado;
      // La distancia sigue al trazado: un numero escrito a mano que no cuadre
      // con la linea deja una carrera cuya meta no esta en el mapa. Se puede
      // corregir despues a mano, pero el punto de partida es lo que se midio.
      if (trazado.length > 1) {
        _distancia.text = _distanciaDelTrazado.toStringAsFixed(2);
      }
    });
  }

  /// Sube el afiche.
  ///
  /// Con [fuente] abre camara o galeria; con [reintentar] reenvia el archivo
  /// que ya se habia elegido. El estado no vuelve a `idle` hasta que el detalle
  /// se releyo del servidor: asi lo que se ve al terminar es la imagen
  /// guardada, y no la del telefono.
  Future<void> _subirPortada({
    ImageSource? fuente,
    bool reintentar = false,
  }) async {
    final id = _m?.id;
    if (id == null) return;

    final ruta = reintentar
        ? _ultimaFoto
        : (fuente == null
              ? null
              : (await ImagePicker().pickImage(source: fuente))?.path);
    if (ruta == null || !mounted) return;

    setState(() {
      _ultimaFoto = ruta;
      _estadoFoto = ImageSlotStatus.uploading;
    });

    try {
      await ref.read(adminApiProvider).uploadCover(id, ruta);
      // Se espera la relectura, no solo se pide: mientras no llegue, la URL
      // que hay en pantalla sigue siendo la anterior.
      ref.invalidate(adminMarathonProvider(id));
      await ref.read(adminMarathonProvider(id).future);
      ref.invalidate(adminMarathonsProvider);

      if (!mounted) return;
      setState(() {
        _estadoFoto = ImageSlotStatus.idle;
        _ultimaFoto = null;
      });
      context.showSnack(context.l10n.adminCoverUploaded);
    } on Failure {
      if (mounted) setState(() => _estadoFoto = ImageSlotStatus.failed);
    }
  }

  /// Quitar el afiche es vaciar su campo, y eso si va por la edicion normal:
  /// no hay endpoint que borre un archivo, ni hace falta.
  Future<void> _quitarPortada() async {
    final id = _m?.id;
    if (id == null) return;

    setState(() => _estadoFoto = ImageSlotStatus.uploading);

    try {
      await ref.read(adminApiProvider).updateMarathon(id, {'coverUrl': null});
      ref.invalidate(adminMarathonProvider(id));
      await ref.read(adminMarathonProvider(id).future);
      ref.invalidate(adminMarathonsProvider);
    } on Failure catch (f) {
      // Quitar no deja nada que reintentar —no hay archivo—, asi que el hueco
      // vuelve a como estaba, con su imagen, y el fallo se cuenta aparte. El
      // estado `failed` pintaria un boton de reintentar que no haria nada.
      if (mounted) context.showSnack(f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _estadoFoto = ImageSlotStatus.idle);
    }
  }

  /// Lee el QR de una foto y se queda **solo con su texto**.
  ///
  /// La imagen no se sube ni se guarda en ningun sitio: es el vehiculo para
  /// que el organizador no tenga que copiar a mano el contenido del QR que le
  /// dio su banca. Lo que se guarda —y lo que luego se redibuja en el movil
  /// del corredor— es el texto que llevaba dentro.
  Future<void> _leerQr(ImageSource fuente) async {
    final foto = await ImagePicker().pickImage(source: fuente);
    if (foto == null || !mounted) return;

    setState(() => _leyendoQr = true);
    final texto = await readQrFromImage(foto.path);
    if (!mounted) return;

    setState(() {
      _leyendoQr = false;
      if (texto != null) _qrPayload = texto;
    });
    if (texto == null) context.showSnack(context.l10n.adminQrUnreadable);
  }

  Future<void> _cambiarEstado({
    required bool publicar,
    required bool valor,
  }) async {
    final maraton = _m;
    if (maraton == null || _cambiandoEstado) return;

    setState(() => _cambiandoEstado = true);
    final notifier = ref.read(adminMarathonsProvider.notifier);
    final fallo = publicar
        ? await notifier.setPublished(maraton, value: valor)
        : await notifier.setRegistrationsOpen(maraton, value: valor);

    if (!mounted) return;
    setState(() => _cambiandoEstado = false);
    if (fallo != null) context.showSnack(fallo.localized(context.l10n));
  }

  String? _validar() {
    final t = context.l10n;
    if (_nombre.text.trim().isEmpty) return t.adminNameRequired;
    if (_ciudad.text.trim().isEmpty) return t.adminCityRequired;
    if ((int.tryParse(_cupo.text.trim()) ?? 0) < 1) {
      return t.adminCapacityRequired;
    }
    if (_metros < 1) return t.adminDistanceRequired;
    return null;
  }

  Future<void> _guardar() async {
    final problema = _validar();
    if (problema != null) {
      setState(() => _errorGuardado = ValidationFailure(problema));
      return;
    }

    final cuerpo = _cuerpo();
    if (!_esAlta && cuerpo.isEmpty) {
      context.showSnack(context.l10n.adminNothingChanged);
      return;
    }

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });

    final api = ref.read(adminApiProvider);
    try {
      if (_esAlta) {
        final creada = await api.createMarathon(cuerpo);
        ref.invalidate(adminMarathonsProvider);
        if (!mounted) return;
        final id = creada['id'] as String?;
        // Se entra directo a la edicion de la recien creada: la foto y el QR
        // necesitan que exista, y devolver a la lista obligaria a buscarla
        // para hacer lo unico que queda por hacer.
        if (id != null) {
          context.pushReplacement(Routes.adminMarathonEditOf(id));
          context.showSnack(context.l10n.adminMarathonCreated);
        } else {
          context.pop();
        }
        return;
      }

      await api.updateMarathon(_m!.id, cuerpo);
      ref
        ..invalidate(adminMarathonProvider(_m!.id))
        ..invalidate(adminMarathonsProvider);
      if (!mounted) return;
      context.showSnack(context.l10n.adminMarathonSaved);
      context.pop();
    } on Failure catch (f) {
      if (mounted) setState(() => _errorGuardado = f);
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
      if (mounted) context.pop();
    } on Failure catch (f) {
      // El servidor niega el borrado si ya hay inscritos: el mensaje que trae
      // explica por que mejor que cualquier texto de aqui.
      if (mounted) setState(() => _errorGuardado = f);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ─── Pintado ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          _seccionFoto(t),
          const SizedBox(height: AppSpacing.lg),
          _seccionDatos(t),
          const SizedBox(height: AppSpacing.lg),
          _seccionFechaYRuta(t),
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
          if (!_esAlta) ...[
            const SizedBox(height: AppSpacing.lg),
            _seccionEstado(t),
          ],
          const SizedBox(height: AppSpacing.lg),
          _seccionQr(t),
          _BannerDeError(
            failure: _errorGuardado,
            onDismiss: () => setState(() => _errorGuardado = null),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _esAlta ? t.adminCreateMarathon : t.commonSave,
            icon: Icons.check_rounded,
            isLoading: _guardando,
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }

  Widget _seccionFoto(AppLocalizations t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Rotulo(title: t.adminCoverTitle, hint: t.adminCoverHint),
      const SizedBox(height: AppSpacing.md),
      MarathonImageField(
        imageUrl: _m?.coverUrl,
        status: _estadoFoto,
        aspectRatio: 16 / 9,
        emptyLabel: t.adminCoverEmpty,
        enabled: !_esAlta,
        disabledHint: _esAlta ? t.adminCoverAfterSave : null,
        onPick: (fuente) => _subirPortada(fuente: fuente),
        onRetry: () => _subirPortada(reintentar: true),
        onRemove: _quitarPortada,
      ),
    ],
  );

  Widget _seccionDatos(AppLocalizations t) => _Tarjeta(
    children: [
      const SizedBox(height: AppSpacing.base),
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
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        label: t.adminDistance,
        controller: _distancia,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: AppSpacing.base),
    ],
  );

  Widget _seccionFechaYRuta(AppLocalizations t) => _Tarjeta(
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
            : Fmt.distance(_distanciaDelTrazado),
        subtitle: t.adminRouteSubtitle,
        onTap: _marcarRuta,
      ),
    ],
  );

  Widget _seccionEstado(AppLocalizations t) => _Tarjeta(
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _m!.published,
        onChanged: _cambiandoEstado
            ? null
            : (v) => _cambiarEstado(publicar: true, valor: v),
        title: Text(t.adminPublishedSwitch, style: context.text.bodyMd),
        subtitle: Text(
          t.adminPublishedHint,
          style: context.text.bodySm.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
      const AppDivider(),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _m!.registrationsOpen,
        onChanged: _cambiandoEstado
            ? null
            : (v) => _cambiarEstado(publicar: false, valor: v),
        title: Text(t.adminRegistrationsSwitch, style: context.text.bodyMd),
        subtitle: Text(
          t.adminRegistrationsHint,
          style: context.text.bodySm.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ],
  );

  /// El QR de cobro. A diferencia del afiche, aqui no se sube nada: la foto
  /// solo sirve para sacarle el texto, y el que se ve es un QR **redibujado**
  /// desde ese texto —el mismo que vera el corredor—. Si el de la pantalla se
  /// escanea bien, el guardado tambien.
  Widget _seccionQr(AppLocalizations t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Rotulo(title: t.adminPaymentQr, hint: t.adminQrSubtitle),
      const SizedBox(height: AppSpacing.md),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: _QrSlot(
              payload: _qrPayload,
              reading: _leyendoQr,
              onTap: _leyendoQr ? null : _elegirQr,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppTextField(
              label: t.adminQrInstructions,
              controller: _qrTexto,
              maxLines: 4,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        (_qrPayload ?? '').isEmpty
            ? t.adminQrPayloadMissing
            : t.adminQrPayloadHelp,
        style: context.text.bodySm.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );

  Future<void> _elegirQr() async {
    final accion = await pickImageSource(
      context,
      canRemove: (_qrPayload ?? '').isNotEmpty,
    );
    switch (accion) {
      case ImagePick.camera:
        await _leerQr(ImageSource.camera);
      case ImagePick.gallery:
        await _leerQr(ImageSource.gallery);
      case ImagePick.remove:
        setState(() => _qrPayload = null);
      case null:
        break;
    }
  }
}

/// El QR de cobro **redibujado desde su texto**, no la foto que se subio.
///
/// Es a proposito: la foto ya cumplio su papel —traer el contenido— y lo que
/// hay que comprobar antes de guardar es que lo leido es lo correcto. Lo que
/// se ve aqui es exactamente lo que se pintara en el movil del corredor.
///
/// El violeta de marca va sobre blanco **siempre**, en los dos temas: un QR es
/// contraste antes que adorno, y el violeta claro del tema oscuro sobre fondo
/// oscuro no lo lee ningun escaner.
class _QrSlot extends StatelessWidget {
  const _QrSlot({
    required this.payload,
    required this.reading,
    required this.onTap,
  });

  final String? payload;
  final bool reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final tiene = (payload ?? '').isNotEmpty;

    return Semantics(
      button: true,
      label: tiene ? t.adminImageChange : t.adminQrEmpty,
      child: Material(
        color: tiene ? Colors.white : context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: switch ((reading, tiene)) {
              (true, _) => Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colors.primary,
                  ),
                ),
              ),
              (_, true) => QrImageView(
                data: payload!,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: LightTokens.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: LightTokens.primary,
                ),
              ),
              _ => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 28,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    t.adminQrEmpty,
                    textAlign: TextAlign.center,
                    style: context.text.bodySm.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: context.text.titleMd),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        hint,
        style: context.text.bodySm.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}

/// El fallo de guardado, empujando el contenido en vez de apareciendo encima.
class _BannerDeError extends StatelessWidget {
  const _BannerDeError({required this.failure, required this.onDismiss});

  final Failure? failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedSize(
      duration: AppDurations.fast,
      curve: AppDurations.curve,
      alignment: Alignment.topCenter,
      child: failure == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: c.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        failure!.localized(context.l10n),
                        style: context.text.bodySm.copyWith(color: c.error),
                      ),
                    ),
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: c.error,
                      tooltip: context.l10n.commonClose,
                    ),
                  ],
                ),
              ),
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

/// Carga con la forma del formulario: el afiche arriba y los campos debajo.
class _CargandoDetalle extends StatelessWidget {
  const _CargandoDetalle();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.md,
      AppSpacing.screenH,
      AppSpacing.xxl,
    ),
    children: [
      const AspectRatio(
        aspectRatio: 16 / 9,
        child: Skeleton(
          width: double.infinity,
          height: double.infinity,
          radius: AppRadius.xl,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      for (var i = 0; i < 4; i++) ...[
        const Skeleton(width: double.infinity, height: AppSizes.controlHeight),
        const SizedBox(height: AppSpacing.md),
      ],
    ],
  );
}
