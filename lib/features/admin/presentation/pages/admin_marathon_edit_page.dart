import 'dart:convert';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/data/admin_api.dart';
import 'package:camrun/features/admin/data/qr_image_reader.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/pages/admin_route_editor_page.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/admin/presentation/widgets/fade_in_up.dart';
import 'package:camrun/features/admin/presentation/widgets/marathon_image_field.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/branded_qr.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Alta y edicion de una carrera, entera desde el movil.
///
/// Con [marathonId] en `null` es el alta. Es la misma pantalla porque los
/// campos son los mismos: dos formularios paralelos se desincronizan en el
/// primer campo nuevo.
///
/// El formulario va por secciones con un indice arriba (al costado en tablet)
/// que salta a cada una y sigue a la que se esta viendo. Hay dos velocidades:
///
/// * **El contenido se guarda.** Nombre, fecha, precio y demas viajan juntos
///   desde la barra de guardar, que solo aparece cuando hay algo que guardar.
/// * **El estado, las imagenes, categorias y extras son inmediatos**: tienen
///   su propio endpoint y ocurren al momento.
class AdminMarathonEditPage extends ConsumerWidget {
  const AdminMarathonEditPage({this.marathonId, super.key});

  final String? marathonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final id = marathonId;

    if (id == null) return const _Formulario(original: null);

    final carrera = ref.watch(adminMarathonProvider(id));
    return carrera.when(
      // Al refrescar tras subir una imagen se sigue pintando el formulario con
      // lo anterior: cambiarlo por el esqueleto lo desmontaria y se perderia lo
      // que hubiera escrito sin guardar.
      skipLoadingOnReload: true,
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

/// Las secciones del formulario, en el orden en que se pintan.
enum _Seccion {
  general,
  imagenes,
  recorrido,
  inscripcion,
  programa,
  cobro,
  estado,
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
  // El precio se edita en bolivianos y viaja en centavos.
  late final _precio = TextEditingController(
    text: _m == null ? '' : (_m!.priceCents / 100).toStringAsFixed(2),
  );

  /// Lo que mide **una vuelta**, no la carrera: en un circuito el trazado se
  /// repite, y es el trazado lo que el organizador mide.
  late final _distancia = TextEditingController(
    text: _m == null ? '' : _m!.lapDistanceKm.toStringAsFixed(2),
  );
  late final _vueltas = TextEditingController(text: '${_m?.laps ?? 1}');
  late final _qrTexto = TextEditingController(
    text: _m?.paymentQrInstructions ?? '',
  );

  late final _controles = [
    _nombre,
    _ciudad,
    _descripcion,
    _cupo,
    _precio,
    _distancia,
    _vueltas,
    _qrTexto,
  ];

  late DateTime _fecha =
      _m?.startsAt ?? DateTime.now().add(const Duration(days: 30));
  late List<GeoPoint> _ruta = _m?.route ?? const [];

  /// Cronograma y "que incluye" son campos `jsonb` de la propia carrera: viajan
  /// con el guardado. Categorias y extras son tablas aparte y van al momento.
  late List<AdminScheduleItem> _cronograma = _m?.schedule ?? const [];
  late List<String> _incluye = _m?.includes ?? const [];

  /// Como estaba todo al abrir. Contra esto se decide que viaja: mandar el
  /// objeto entero pisaria con valores viejos lo que otro haya cambiado.
  late final Map<String, Object?> _inicial = _instantanea();

  bool _guardando = false;
  Failure? _errorGuardado;

  /// Ya se decidio salir (guardado o descartado): el aviso de cambios sin
  /// guardar no tiene que saltar.
  bool _saliendo = false;

  /// Cada hueco de imagen sube, falla y se reintenta por su cuenta.
  final _estadoFoto = <MarathonImageSlot, ImageSlotStatus>{};

  /// El ultimo archivo elegido para cada hueco: reintentar reenvia **ese**.
  final _ultimaFoto = <MarathonImageSlot, String>{};

  /// El contenido del QR de cobro. De la foto solo queda el texto.
  late String? _qrPayload = _m?.paymentQrPayload;
  bool _leyendoQr = false;

  bool _cambiandoEstado = false;

  final _scroll = ScrollController();
  final _vista = GlobalKey();
  late final _anclas = {for (final s in _secciones) s: GlobalKey()};
  late final _chips = {for (final s in _secciones) s: GlobalKey()};
  _Seccion _activa = _Seccion.general;

  AdminMarathon? get _m => widget.original;

  bool get _esAlta => _m == null;

  /// El estado de la carrera no existe en el alta.
  List<_Seccion> get _secciones => [
    for (final s in _Seccion.values)
      if (s != _Seccion.estado || !_esAlta) s,
  ];

  @override
  void initState() {
    super.initState();
    // Se fuerza aqui a proposito: `_inicial` es perezoso y, sin este toque, se
    // calcularia ya con los cambios dentro.
    _inicial;
    for (final c in _controles) {
      c.addListener(_refrescar);
    }
    _scroll.addListener(_seguirSeccion);
  }

  @override
  void dispose() {
    for (final c in _controles) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  // ─── Lo que el formulario vale ahora ──────────────────────────────────────

  double get _distanciaDelTrazado {
    var metros = 0.0;
    for (var i = 1; i < _ruta.length; i++) {
      metros += _ruta[i - 1].distanceTo(_ruta[i]);
    }
    return metros / 1000;
  }

  /// Metros de una vuelta: el total lo hace la API multiplicando por vueltas.
  int get _metros =>
      ((double.tryParse(_distancia.text.trim()) ?? 0) * 1000).round();

  int get _numeroDeVueltas => int.tryParse(_vueltas.text.trim()) ?? 0;

  double get _totalKm => _metros * _numeroDeVueltas / 1000;

  bool get _esCircular =>
      isClosedLoop([for (final p in _ruta) (lat: p.lat, lng: p.lng)]);

  Map<String, Object?> _instantanea() => {
    'name': _nombre.text.trim(),
    'city': _ciudad.text.trim(),
    'description': _descripcion.text.trim(),
    'startsAt': _fecha.toUtc().toIso8601String(),
    'capacity': int.tryParse(_cupo.text.trim()) ?? 0,
    'priceCents': ((double.tryParse(_precio.text.trim()) ?? 0) * 100).round(),
    'distanceMeters': _metros,
    'laps': _numeroDeVueltas,
    'paymentQrPayload': _qrPayload ?? '',
    'paymentQrInstructions': _qrTexto.text.trim(),
    // Las listas se comparan por su JSON: es lo mismo que se va a mandar.
    'schedule': jsonEncode([for (final i in _cronograma) i.toJson()]),
    'includes': jsonEncode(_incluye),
    // El trazado se compara por su forma: son miles de puntos.
    'routeGeoJson': _huellaDeRuta(_ruta),
  };

  static String _huellaDeRuta(List<GeoPoint> puntos) {
    if (puntos.isEmpty) return '';
    final a = puntos.first;
    final z = puntos.last;
    return '${puntos.length}:${a.lat},${a.lng}:${z.lat},${z.lng}';
  }

  /// Lo que cambio desde que se abrio. Tambien sirve en el alta: ahi decide
  /// si salir pierde algo.
  Map<String, Object?> get _cambios {
    final ahora = _instantanea();
    return {
      for (final e in ahora.entries)
        if (e.value != _inicial[e.key]) e.key: e.value,
    };
  }

  /// Solo lo que cambio. En el alta no hay contra que comparar: va todo.
  Map<String, dynamic> _cuerpo() {
    final campos = _esAlta ? _instantanea() : _cambios;
    return {
      for (final e in campos.entries)
        if (e.key != 'routeGeoJson') e.key: _paraLaApi(e.key, e.value),
      if (campos.containsKey('routeGeoJson') && (!_esAlta || _ruta.length > 1))
        'routeGeoJson': _ruta.length > 1 ? routeToGeoJson(_ruta) : null,
    };
  }

  static Object? _paraLaApi(String campo, Object? valor) =>
      const {'schedule', 'includes'}.contains(campo)
      ? jsonDecode(valor! as String)
      : valor;

  // ─── Navegacion por secciones ─────────────────────────────────────────────

  Duration get _movimiento =>
      context.reduceMotion ? Duration.zero : AppDurations.slow;

  Future<void> _irA(_Seccion s) async {
    final destino = _anclas[s]!.currentContext;
    if (destino == null) return;
    setState(() => _activa = s);
    await Scrollable.ensureVisible(
      destino,
      duration: _movimiento,
      curve: AppDurations.curve,
    );
  }

  /// La seccion activa es la ultima cuyo inicio ya paso bajo el borde de
  /// arriba. Al final de la lista manda la ultima: la mas corta no llegaria
  /// nunca a ese borde.
  void _seguirSeccion() {
    final vista = _vista.currentContext?.findRenderObject() as RenderBox?;
    if (vista == null || !_scroll.hasClients) return;

    var activa = _secciones.first;
    if (_scroll.position.extentAfter < 4) {
      activa = _secciones.last;
    } else {
      for (final s in _secciones) {
        final caja =
            _anclas[s]!.currentContext?.findRenderObject() as RenderBox?;
        if (caja == null || !caja.attached) continue;
        final y = caja.localToGlobal(Offset.zero, ancestor: vista).dy;
        if (y <= _umbralDeSeccion) activa = s;
      }
    }
    if (activa == _activa) return;
    setState(() => _activa = activa);

    // El chip de la seccion activa se trae a la vista en la tira de arriba.
    final chip = _chips[activa]!.currentContext;
    if (chip != null) {
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: context.reduceMotion ? Duration.zero : AppDurations.base,
        curve: AppDurations.curve,
      );
    }
  }

  static const _umbralDeSeccion = 96.0;

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
      // La distancia sigue al trazado: un numero a mano que no cuadre con la
      // linea deja una carrera cuya meta no esta en el mapa.
      if (trazado.length > 1) {
        _distancia.text = _distanciaDelTrazado.toStringAsFixed(2);
      }
    });
  }

  /// Sube una imagen. Con [fuente] abre camara o galeria; con [reintentar]
  /// reenvia el archivo ya elegido. No vuelve a `idle` hasta releer el
  /// detalle: lo que se ve al terminar es la imagen guardada.
  Future<void> _subirImagen(
    MarathonImageSlot hueco, {
    ImageSource? fuente,
    bool reintentar = false,
  }) async {
    final id = _m?.id;
    if (id == null) return;

    final ruta = reintentar
        ? _ultimaFoto[hueco]
        : (fuente == null
              ? null
              : (await ImagePicker().pickImage(source: fuente))?.path);
    if (ruta == null || !mounted) return;

    setState(() {
      _ultimaFoto[hueco] = ruta;
      _estadoFoto[hueco] = ImageSlotStatus.uploading;
    });

    try {
      await ref.read(adminApiProvider).uploadMarathonImage(id, hueco, ruta);
      ref.invalidate(adminMarathonProvider(id));
      await ref.read(adminMarathonProvider(id).future);
      ref.invalidate(adminMarathonsProvider);

      if (!mounted) return;
      setState(() {
        _estadoFoto[hueco] = ImageSlotStatus.idle;
        _ultimaFoto.remove(hueco);
      });
      context.showSnack(context.l10n.adminCoverUploaded);
    } on Failure {
      if (mounted) {
        setState(() => _estadoFoto[hueco] = ImageSlotStatus.failed);
      }
    }
  }

  /// Quitar una imagen es vaciar su campo por la edicion normal.
  Future<void> _quitarImagen(MarathonImageSlot hueco) async {
    final id = _m?.id;
    if (id == null) return;

    setState(() => _estadoFoto[hueco] = ImageSlotStatus.uploading);

    try {
      await ref.read(adminApiProvider).updateMarathon(id, {hueco.field: null});
      ref.invalidate(adminMarathonProvider(id));
      await ref.read(adminMarathonProvider(id).future);
      ref.invalidate(adminMarathonsProvider);
    } on Failure catch (f) {
      // Quitar no deja nada que reintentar: el hueco vuelve a como estaba.
      if (mounted) context.showSnack(f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _estadoFoto[hueco] = ImageSlotStatus.idle);
    }
  }

  /// Lee el QR de una foto y se queda **solo con su texto**: la imagen no se
  /// sube; lo que se redibuja en el movil del corredor es lo que llevaba.
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

  Future<void> _cambiarEstado({
    required bool publicar,
    required bool valor,
  }) async {
    final carrera = _m;
    if (carrera == null || _cambiandoEstado) return;

    setState(() => _cambiandoEstado = true);
    final notifier = ref.read(adminMarathonsProvider.notifier);
    final fallo = publicar
        ? await notifier.setPublished(carrera, value: valor)
        : await notifier.setRegistrationsOpen(carrera, value: valor);

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
    if (_numeroDeVueltas < 1 || _numeroDeVueltas > 100) {
      return t.adminLapsRequired;
    }
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
        _saliendo = true;
        // Se entra directo a la edicion de la recien creada: imagenes,
        // categorias y QR necesitan que exista.
        if (id != null) {
          context
            ..pushReplacement(Routes.adminMarathonEditOf(id))
            ..showSnack(context.l10n.adminMarathonCreated);
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
      _saliendo = true;
      context
        ..showSnack(context.l10n.adminMarathonSaved)
        ..pop();
    } on Failure catch (f) {
      if (mounted) setState(() => _errorGuardado = f);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrar() async {
    final t = context.l10n;
    final confirmado = await _confirmar(
      t.adminDeleteMarathonTitle,
      t.adminDeleteMarathonBody,
      t.adminDelete,
    );
    if (!confirmado || !mounted) return;

    setState(() => _guardando = true);
    try {
      await ref.read(adminApiProvider).deleteMarathon(_m!.id);
      ref.invalidate(adminMarathonsProvider);
      _saliendo = true;
      if (mounted) context.pop();
    } on Failure catch (f) {
      // El servidor niega el borrado si ya hay inscritos: su mensaje lo explica.
      if (mounted) setState(() => _errorGuardado = f);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Salir con cambios sin guardar pregunta antes: lo escrito no vive en
  /// ningun otro sitio.
  Future<void> _alSalir(bool didPop, Object? _) async {
    if (didPop) return;
    final t = context.l10n;
    final descartar = await _confirmar(
      t.editDiscardTitle,
      t.editDiscardBody,
      t.commonDiscard,
    );
    if (!descartar || !mounted) return;
    setState(() => _saliendo = true);
    context.pop();
  }

  // ─── Pintado ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final hayCambios = _cambios.isNotEmpty;
    final barraVisible =
        _esAlta || hayCambios || _errorGuardado != null || _guardando;

    return PopScope(
      canPop: !hayCambios || _saliendo,
      onPopInvokedWithResult: _alSalir,
      child: Scaffold(
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
        body: LayoutBuilder(
          builder: (context, box) {
            final ancho = box.maxWidth >= _conIndiceLateral;
            final contenido = _contenido(t, ancho: ancho);

            return Stack(
              children: [
                if (ancho)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _indiceAncho,
                        child: _IndiceLateral(
                          secciones: _secciones,
                          activa: _activa,
                          onTap: _irA,
                        ),
                      ),
                      Expanded(child: contenido),
                    ],
                  )
                else
                  Column(
                    children: [
                      _TiraDeSecciones(
                        secciones: _secciones,
                        activa: _activa,
                        claves: _chips,
                        onTap: _irA,
                      ),
                      Expanded(child: contenido),
                    ],
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BarraDeGuardado(
                    visible: barraVisible,
                    esAlta: _esAlta,
                    guardando: _guardando,
                    failure: _errorGuardado,
                    onSave: _guardar,
                    onDismissError: () => setState(() => _errorGuardado = null),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A partir de este ancho el indice va al costado en vez de arriba.
  static const _conIndiceLateral = 960.0;
  static const _indiceAncho = 232.0;

  Widget _contenido(AppLocalizations t, {required bool ancho}) {
    final bloques = <Widget>[
      for (final (i, s) in _secciones.indexed)
        FadeInUp(
          // Solo se escalona la entrada: al noveno ya se notaria como lentitud.
          delay: AppDurations.fast * (i.clamp(0, 6) / 3),
          child: Padding(
            key: _anclas[s],
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: _seccion(t, s),
          ),
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.readableMaxWidth),
        child: SingleChildScrollView(
          key: _vista,
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            ancho ? AppSpacing.screenHWide : AppSpacing.screenH,
            AppSpacing.base,
            ancho ? AppSpacing.screenHWide : AppSpacing.screenH,
            // Lo que ocupa la barra de guardar, para que no tape lo ultimo.
            AppSpacing.xxxl * 3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(
                nombre: _nombre.text.trim(),
                ciudad: _ciudad.text.trim(),
                fecha: _fecha,
                marathon: _m,
              ),
              const SizedBox(height: AppSpacing.base),
              ...bloques,
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(AppLocalizations t, _Seccion s) => switch (s) {
    _Seccion.general => _seccionGeneral(t),
    _Seccion.imagenes => _seccionImagenes(t),
    _Seccion.recorrido => _seccionRecorrido(t),
    _Seccion.inscripcion => _seccionInscripcion(t),
    _Seccion.programa => _seccionPrograma(t),
    _Seccion.cobro => _seccionCobro(t),
    _Seccion.estado => _seccionEstado(t),
  };

  Widget _seccionGeneral(AppLocalizations t) => _Bloque(
    seccion: _Seccion.general,
    children: [
      AppTextField(label: t.adminName, controller: _nombre),
      const SizedBox(height: AppSpacing.md),
      AppTextField(label: t.adminCity, controller: _ciudad),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        label: t.adminDescription,
        controller: _descripcion,
        maxLines: 4,
      ),
      const SizedBox(height: AppSpacing.xs),
      StatRow(
        icon: Icons.event_outlined,
        title: t.adminStartsAt,
        value: '${Fmt.fullDate(_fecha)} · ${Fmt.timeOfDay(_fecha)}',
        onTap: _elegirFecha,
        trailing: Icon(
          Icons.edit_calendar_outlined,
          size: 18,
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );

  Widget _seccionImagenes(AppLocalizations t) {
    final c = context.colors;
    return _Bloque(
      seccion: _Seccion.imagenes,
      children: [
        if (_esAlta) ...[
          _Aviso(icon: Icons.info_outline_rounded, text: t.adminCoverAfterSave),
          const SizedBox(height: AppSpacing.base),
        ],
        // Los dos cuadrados: el logo de las vistas previas y el del QR.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ConRotulo(
                title: t.adminCoverTitle,
                hint: t.adminCoverHint,
                child: _hueco(
                  t,
                  MarathonImageSlot.logo,
                  _m?.coverUrl,
                  1,
                  t.adminCoverEmpty,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ConRotulo(
                title: t.adminQrLogoTitle,
                hint: t.adminQrLogoHint,
                child: _hueco(
                  t,
                  MarathonImageSlot.qrLogo,
                  _m?.logoQrUrl,
                  1,
                  t.adminQrLogoEmpty,
                  icon: Icons.qr_code_2_rounded,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          child: Divider(height: 1, color: c.border),
        ),
        _ConRotulo(
          title: t.adminLogosTitle,
          hint: t.adminLogosHint,
          // Cada hueco con la forma de su arte: lo que se ve aqui es como
          // quedara en la app.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _hueco(
                  t,
                  MarathonImageSlot.logoVertical,
                  _m?.logoVerticalUrl,
                  4 / 5,
                  t.adminLogoVertical,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: _hueco(
                  t,
                  MarathonImageSlot.logoHorizontal,
                  _m?.logoHorizontalUrl,
                  16 / 10,
                  t.adminLogoHorizontal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hueco(
    AppLocalizations t,
    MarathonImageSlot hueco,
    String? url,
    double aspectRatio,
    String label, {
    IconData icon = Icons.add_photo_alternate_outlined,
  }) => MarathonImageField(
    imageUrl: url,
    status: _estadoFoto[hueco] ?? ImageSlotStatus.idle,
    aspectRatio: aspectRatio,
    isLogo: true,
    emptyLabel: label,
    emptyIcon: icon,
    enabled: !_esAlta,
    onPick: (fuente) => _subirImagen(hueco, fuente: fuente),
    onRetry: () => _subirImagen(hueco, reintentar: true),
    onRemove: () => _quitarImagen(hueco),
  );

  Widget _seccionRecorrido(AppLocalizations t) {
    final c = context.colors;
    final tieneRuta = _ruta.length > 1;

    return _Bloque(
      seccion: _Seccion.recorrido,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: _mapaAlto,
            child: tieneRuta
                ? RouteMapView(
                    // La clave sigue al trazado: el mapa encuadra al montarse,
                    // y uno nuevo tiene que volver a encuadrarse.
                    key: ValueKey(_huellaDeRuta(_ruta)),
                    route: const [],
                    guideRoute: _ruta,
                    interactive: false,
                    // Previsualizacion de gestion: el trazado solo.
                    tiles: false,
                  )
                : Material(
                    color: c.surfaceElevated,
                    child: InkWell(
                      onTap: _marcarRuta,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_location_alt_outlined,
                              size: 28,
                              color: c.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              t.adminRouteMissing,
                              style: context.text.labelSm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (tieneRuta)
              AppBadge(
                label: Fmt.distance(_distanciaDelTrazado),
                icon: Icons.straighten_rounded,
                tone: AppTone.neutral,
              ),
            if (tieneRuta && _esCircular)
              AppBadge(
                label: t.adminRouteModeLoop,
                icon: Icons.loop_rounded,
                tone: AppTone.info,
              ),
          ],
        ),
        if (tieneRuta) const SizedBox(height: AppSpacing.md),
        AppButton(
          label: tieneRuta ? t.adminRouteEdit : t.adminRouteDraw,
          icon: Icons.edit_road_rounded,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.md,
          onPressed: _marcarRuta,
        ),
        const SizedBox(height: AppSpacing.base),
        // Distancia y vueltas juntas, y debajo lo que suman: solo se entienden
        // como pareja.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: _numeroDeVueltas > 1
                    ? t.adminDistancePerLap
                    : t.adminDistance,
                controller: _distancia,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: t.adminLaps,
                controller: _vueltas,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _numeroDeVueltas > 1
              ? t.adminCircuitTotal(
                  Fmt.distance(_metros / 1000),
                  '$_numeroDeVueltas',
                  Fmt.distance(_totalKm),
                )
              : t.adminLapsSingle,
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }

  static const _mapaAlto = 200.0;

  Widget _seccionInscripcion(AppLocalizations t) => _Bloque(
    seccion: _Seccion.inscripcion,
    children: [
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
      _ListaEditable(
        title: t.adminCategoriesTitle,
        hint: t.adminCategoriesHint,
        emptyLabel: t.adminCategoriesEmpty,
        addLabel: t.adminCategoryAdd,
        icon: Icons.groups_outlined,
        enabled: !_esAlta && !_guardando,
        disabledHint: _esAlta ? t.adminAfterSave : null,
        onAdd: _editarCategoria,
        rows: [
          for (final c in _m?.categories ?? const <AdminCategory>[])
            (
              title: c.name,
              subtitle: c.extraPriceCents == 0
                  ? t.adminCategoryFree
                  : '+ ${Fmt.money(c.extraPriceCents / 100, _moneda)}',
              onEdit: () => _editarCategoria(actual: c),
              onDelete: () => _borrarFila(
                nombre: c.name,
                cuerpo: t.adminDeleteCategoryBody,
                borrar: (api) => api.deleteCategory(c.id),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _ListaEditable(
        title: t.adminExtrasTitle,
        hint: t.adminExtrasHint,
        emptyLabel: t.adminExtrasEmpty,
        addLabel: t.adminExtraAdd,
        icon: Icons.shopping_bag_outlined,
        enabled: !_esAlta && !_guardando,
        disabledHint: _esAlta ? t.adminAfterSave : null,
        onAdd: _editarExtra,
        rows: [
          for (final e in _m?.extras ?? const <AdminExtra>[])
            (
              title: e.name,
              subtitle: [
                Fmt.money(e.priceCents / 100, _moneda),
                if (e.stock != null) t.adminExtraStockLeft(e.stock!),
              ].join('  ·  '),
              onEdit: () => _editarExtra(actual: e),
              onDelete: () => _borrarFila(
                nombre: e.name,
                cuerpo: t.adminDeleteExtraBody,
                borrar: (api) => api.deleteExtra(e.id),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _seccionPrograma(AppLocalizations t) => _Bloque(
    seccion: _Seccion.programa,
    children: [
      _ListaEditable(
        title: t.adminScheduleTitle,
        hint: t.adminScheduleHint,
        emptyLabel: t.adminScheduleEmpty,
        addLabel: t.adminScheduleAdd,
        icon: Icons.schedule_rounded,
        onAdd: _editarActividad,
        rows: [
          for (final (i, item) in _cronograma.indexed)
            (
              title: [
                item.time,
                item.title,
              ].where((x) => x.isNotEmpty).join('  ·  '),
              subtitle: item.detail.isEmpty ? null : item.detail,
              onEdit: () => _editarActividad(indice: i),
              onDelete: () =>
                  setState(() => _cronograma = [..._cronograma]..removeAt(i)),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _ListaEditable(
        title: t.adminIncludesTitle,
        hint: t.adminIncludesHint,
        emptyLabel: t.adminIncludesEmpty,
        addLabel: t.adminIncludesAdd,
        icon: Icons.check_circle_outline_rounded,
        onAdd: _editarIncluye,
        rows: [
          for (final (i, linea) in _incluye.indexed)
            (
              title: linea,
              subtitle: null,
              onEdit: () => _editarIncluye(indice: i),
              onDelete: () =>
                  setState(() => _incluye = [..._incluye]..removeAt(i)),
            ),
        ],
      ),
    ],
  );

  /// El QR de cobro: la foto solo trae el texto, y lo que se ve es el QR
  /// **redibujado** desde ese texto, con el logo encima — el mismo que vera el
  /// corredor. Si este se escanea bien, el guardado tambien.
  Widget _seccionCobro(AppLocalizations t) {
    final c = context.colors;
    return _Bloque(
      seccion: _Seccion.cobro,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: _qrLado,
              child: _QrSlot(
                payload: _qrPayload,
                logoUrl: _m?.logoQrUrl,
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
        const SizedBox(height: AppSpacing.md),
        _Aviso(
          icon: (_qrPayload ?? '').isEmpty
              ? Icons.info_outline_rounded
              : Icons.check_circle_outline_rounded,
          text: (_qrPayload ?? '').isEmpty
              ? t.adminQrPayloadMissing
              : t.adminQrPayloadHelp,
          tone: (_qrPayload ?? '').isEmpty ? c.textSecondary : c.success,
        ),
      ],
    );
  }

  static const _qrLado = 132.0;

  Widget _seccionEstado(AppLocalizations t) {
    final c = context.colors;
    return _Bloque(
      seccion: _Seccion.estado,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _m!.published,
          // Un ensayo no se publica nunca: el servidor lo rechazaria.
          onChanged: _cambiandoEstado || _m!.isRehearsal
              ? null
              : (v) => _cambiarEstado(publicar: true, valor: v),
          title: Text(t.adminPublishedSwitch, style: context.text.bodyMd),
          subtitle: Text(
            t.adminPublishedHint,
            style: context.text.bodySm.copyWith(color: c.textSecondary),
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
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  // ─── Filas: cronograma, incluye, categorias y extras ──────────────────────

  Future<void> _editarActividad({int? indice}) async {
    final t = context.l10n;
    final actual = indice == null ? null : _cronograma[indice];
    final valores = await _pedirCampos(
      title: t.adminScheduleTitle,
      campos: [
        (
          label: t.adminScheduleTime,
          value: actual?.time ?? '',
          numeric: false,
          obligatorio: true,
        ),
        (
          label: t.adminScheduleName,
          value: actual?.title ?? '',
          numeric: false,
          obligatorio: true,
        ),
        (
          label: t.adminScheduleDetail,
          value: actual?.detail ?? '',
          numeric: false,
          obligatorio: false,
        ),
      ],
    );
    if (valores == null) return;

    final item = AdminScheduleItem(
      time: valores[0],
      title: valores[1],
      detail: valores[2],
    );
    setState(() {
      final lista = [..._cronograma];
      if (indice == null) {
        lista.add(item);
      } else {
        lista[indice] = item;
      }
      _cronograma = lista;
    });
  }

  Future<void> _editarIncluye({int? indice}) async {
    final t = context.l10n;
    final valores = await _pedirCampos(
      title: t.adminIncludesTitle,
      campos: [
        (
          label: t.adminIncludesLabel,
          value: indice == null ? '' : _incluye[indice],
          numeric: false,
          obligatorio: true,
        ),
      ],
    );
    if (valores == null) return;

    setState(() {
      final lista = [..._incluye];
      if (indice == null) {
        lista.add(valores[0]);
      } else {
        lista[indice] = valores[0];
      }
      _incluye = lista;
    });
  }

  Future<void> _editarCategoria({AdminCategory? actual}) async {
    final t = context.l10n;
    final valores = await _pedirCampos(
      title: t.adminCategoriesTitle,
      campos: [
        (
          label: t.adminCategoryName,
          value: actual?.name ?? '',
          numeric: false,
          obligatorio: true,
        ),
        (
          label: t.adminCategorySurcharge,
          value: actual == null
              ? ''
              : (actual.extraPriceCents / 100).toStringAsFixed(2),
          numeric: true,
          obligatorio: false,
        ),
      ],
    );
    if (valores == null) return;

    final cuerpo = <String, dynamic>{
      'name': valores[0],
      'extraPriceCents': _aCentavos(valores[1]) ?? 0,
    };
    await _guardarFila(
      (api, id) => actual == null
          ? api.createCategory(id, cuerpo)
          : api.updateCategory(actual.id, cuerpo),
    );
  }

  Future<void> _editarExtra({AdminExtra? actual}) async {
    final t = context.l10n;
    final valores = await _pedirCampos(
      title: t.adminExtrasTitle,
      campos: [
        (
          label: t.adminExtraName,
          value: actual?.name ?? '',
          numeric: false,
          obligatorio: true,
        ),
        (
          label: t.adminExtraPrice,
          value: actual == null
              ? ''
              : (actual.priceCents / 100).toStringAsFixed(2),
          numeric: true,
          obligatorio: true,
        ),
        (
          label: t.adminExtraStock,
          value: actual?.stock?.toString() ?? '',
          numeric: true,
          obligatorio: false,
        ),
      ],
    );
    if (valores == null) return;

    // Stock vacio es `null` ("sin limite"), no cero ("agotado").
    final stock = valores[2].trim();
    final cuerpo = <String, dynamic>{
      'name': valores[0],
      'priceCents': _aCentavos(valores[1]) ?? 0,
      'stock': stock.isEmpty ? null : int.tryParse(stock),
    };
    await _guardarFila(
      (api, id) => actual == null
          ? api.createExtra(id, cuerpo)
          : api.updateExtra(actual.id, cuerpo),
    );
  }

  String get _moneda => _m?.currency ?? 'BOB';

  static int? _aCentavos(String texto) {
    final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
    return valor == null ? null : (valor * 100).round();
  }

  /// Manda, relee el detalle y **espera** a que llegue: lo que se pinta es la
  /// lista del servidor, no una copia optimista.
  Future<void> _guardarFila(
    Future<void> Function(AdminApi api, String marathonId) enviar,
  ) async {
    final id = _m?.id;
    if (id == null) return;

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });
    try {
      await enviar(ref.read(adminApiProvider), id);
      ref.invalidate(adminMarathonProvider(id));
      await ref.read(adminMarathonProvider(id).future);
      ref.invalidate(adminMarathonsProvider);
    } on Failure catch (f) {
      if (mounted) setState(() => _errorGuardado = f);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrarFila({
    required String nombre,
    required String cuerpo,
    required Future<void> Function(AdminApi api) borrar,
  }) async {
    final confirmado = await _confirmar(
      context.l10n.adminDeleteRowTitle(nombre),
      cuerpo,
      context.l10n.adminDelete,
    );
    if (!confirmado || !mounted) return;
    await _guardarFila((api, _) => borrar(api));
  }

  /// Un si/no destructivo: borrar la carrera, una fila o descartar cambios.
  Future<bool> _confirmar(String titulo, String cuerpo, String accion) async {
    final t = context.l10n;
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(titulo),
        content: Text(cuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(accion),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  Future<List<String>?> _pedirCampos({
    required String title,
    required List<CampoDeDialogo> campos,
  }) => showDialog<List<String>>(
    context: context,
    builder: (_) => _DialogoDeCampos(title: title, campos: campos),
  );
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

extension on _Seccion {
  IconData get icon => switch (this) {
    _Seccion.general => Icons.badge_outlined,
    _Seccion.imagenes => Icons.image_outlined,
    _Seccion.recorrido => Icons.route_outlined,
    _Seccion.inscripcion => Icons.confirmation_number_outlined,
    _Seccion.programa => Icons.event_note_outlined,
    _Seccion.cobro => Icons.qr_code_2_rounded,
    _Seccion.estado => Icons.toggle_on_outlined,
  };

  String label(AppLocalizations t) => switch (this) {
    _Seccion.general => t.adminSectionGeneral,
    _Seccion.imagenes => t.adminSectionImages,
    _Seccion.recorrido => t.adminRouteTitle,
    _Seccion.inscripcion => t.adminSectionSales,
    _Seccion.programa => t.adminSectionProgram,
    _Seccion.cobro => t.adminSectionPayment,
    _Seccion.estado => t.adminSectionStatus,
  };
}

/// La carrera de un vistazo arriba del formulario: logo, nombre y estado. El
/// nombre sigue a lo que se escribe, asi el titulo nunca miente.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.ciudad,
    required this.fecha,
    required this.marathon,
  });

  final String nombre;
  final String ciudad;
  final DateTime fecha;
  final AdminMarathon? marathon;

  static const _lado = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final m = marathon;
    final logo = m?.coverUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox.square(
              dimension: _lado,
              child: logo.isEmpty
                  ? DecoratedBox(
                      decoration: BoxDecoration(gradient: c.routeGradient),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: c.onPrimary,
                      ),
                    )
                  : EventImage(
                      imageUrl: logo,
                      fit: BoxFit.contain,
                      icon: Icons.image_outlined,
                      background: c.logoBackdrop,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? t.adminNewMarathon : nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMd,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  [
                    Fmt.fullDate(fecha),
                    if (ciudad.isNotEmpty) ciudad,
                  ].join(' · '),
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
                if (m != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs + 2,
                    children: [
                      if (m.isRehearsal)
                        AppBadge(
                          label: t.adminRehearsalBadge,
                          icon: Icons.science_outlined,
                        ),
                      AppBadge(
                        label: m.published ? t.adminPublished : t.adminDraft,
                        icon: m.published
                            ? Icons.visibility_outlined
                            : Icons.edit_note_rounded,
                        tone: m.published ? AppTone.info : AppTone.neutral,
                      ),
                      AppBadge(
                        label: m.registrationsOpen
                            ? t.adminRegistrationsOpen
                            : t.adminRegistrationsClosed,
                        icon: m.registrationsOpen
                            ? Icons.how_to_reg_rounded
                            : Icons.lock_outline_rounded,
                        tone: m.registrationsOpen
                            ? AppTone.brand
                            : AppTone.warning,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El indice en telefono: una tira de chips fija bajo la barra.
class _TiraDeSecciones extends StatelessWidget {
  const _TiraDeSecciones({
    required this.secciones,
    required this.activa,
    required this.claves,
    required this.onTap,
  });

  final List<_Seccion> secciones;
  final _Seccion activa;
  final Map<_Seccion, GlobalKey> claves;
  final ValueChanged<_Seccion> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SizedBox(
        height: AppSizes.minTapTarget + AppSpacing.base,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          itemCount: secciones.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) {
            final s = secciones[i];
            return Center(
              child: AppChip(
                key: claves[s],
                label: s.label(t),
                icon: s.icon,
                selected: s == activa,
                onTap: () => onTap(s),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// El indice en tablet: una lista al costado, con una marca que se desliza
/// hasta la seccion activa.
class _IndiceLateral extends StatelessWidget {
  const _IndiceLateral({
    required this.secciones,
    required this.activa,
    required this.onTap,
  });

  final List<_Seccion> secciones;
  final _Seccion activa;
  final ValueChanged<_Seccion> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final duracion = context.reduceMotion ? Duration.zero : AppDurations.base;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          for (final s in secciones)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Semantics(
                button: true,
                selected: s == activa,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => onTap(s),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: AnimatedContainer(
                      duration: duracion,
                      curve: AppDurations.curve,
                      height: AppSizes.minTapTarget,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: s == activa
                            ? c.primary.withValues(alpha: 0.12)
                            : c.primary.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            s.icon,
                            size: 20,
                            color: s == activa ? c.primary : c.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              s.label(t),
                              style: context.text.labelSm.copyWith(
                                color: s == activa ? c.primary : c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una seccion del formulario: tarjeta con su icono y su titulo.
class _Bloque extends StatelessWidget {
  const _Bloque({required this.seccion, required this.children});

  final _Seccion seccion;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // `Material` y no una caja pintada: dentro hay filas con salpicadura, que
    // se dibuja en el `Material` mas cercano.
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(seccion.icon, size: 19, color: c.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    seccion.label(context.l10n),
                    style: context.text.headingMd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Titulo y pista sobre un campo que no es de texto (imagenes, listas).
class _ConRotulo extends StatelessWidget {
  const _ConRotulo({
    required this.title,
    required this.hint,
    required this.child,
  });

  final String title;
  final String hint;
  final Widget child;

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
      const SizedBox(height: AppSpacing.md),
      child,
    ],
  );
}

/// Una linea informativa con icono, dentro de una seccion.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icon, required this.text, this.tone});

  final IconData icon;
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = tone ?? c.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// La barra de guardar. Entra desde abajo cuando hay algo que guardar y sale
/// cuando no: un boton siempre visible no dice si queda trabajo pendiente.
class _BarraDeGuardado extends StatelessWidget {
  const _BarraDeGuardado({
    required this.visible,
    required this.esAlta,
    required this.guardando,
    required this.failure,
    required this.onSave,
    required this.onDismissError,
  });

  final bool visible;
  final bool esAlta;
  final bool guardando;
  final Failure? failure;
  final VoidCallback onSave;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final duracion = context.reduceMotion ? Duration.zero : AppDurations.base;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.2),
        duration: duracion,
        curve: visible ? AppDurations.curve : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duracion,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
              boxShadow: c.floatingShadow,
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.readableMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BannerDeError(
                          failure: failure,
                          onDismiss: onDismissError,
                        ),
                        Row(
                          children: [
                            if (!esAlta) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  t.adminUnsavedChanges,
                                  style: context.text.labelSm.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                            ],
                            Expanded(
                              flex: esAlta ? 1 : 0,
                              child: AppButton(
                                label: esAlta
                                    ? t.adminCreateMarathon
                                    : t.commonSave,
                                icon: Icons.check_rounded,
                                size: AppButtonSize.md,
                                isFullWidth: esAlta,
                                isLoading: guardando,
                                onPressed: guardando ? null : onSave,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El QR de cobro **redibujado desde su texto**, con el logo encima: lo que se
/// ve aqui es exactamente lo que se pintara en el movil del corredor.
class _QrSlot extends StatelessWidget {
  const _QrSlot({
    required this.payload,
    required this.logoUrl,
    required this.reading,
    required this.onTap,
  });

  final String? payload;
  final String? logoUrl;
  final bool reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final tiene = (payload ?? '').isNotEmpty;

    return Semantics(
      button: true,
      label: tiene ? t.adminImageChange : t.adminQrEmpty,
      child: Material(
        // Blanco en los dos temas: un QR es contraste antes que adorno.
        color: tiene ? Colors.white : c.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: AnimatedSwitcher(
              duration: context.reduceMotion
                  ? Duration.zero
                  : AppDurations.base,
              child: switch ((reading, tiene)) {
                (true, _) => Center(
                  key: const ValueKey('leyendo'),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: c.primary,
                    ),
                  ),
                ),
                (_, true) => BrandedQr(
                  key: ValueKey('$payload|$logoUrl'),
                  data: payload!,
                  logoUrl: logoUrl,
                ),
                _ => Column(
                  key: const ValueKey('vacio'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 28,
                      color: c.primary,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.adminQrEmpty,
                      textAlign: TextAlign.center,
                      style: context.text.labelSm.copyWith(color: c.primary),
                    ),
                  ],
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Una fila de cualquiera de las cuatro listas del formulario.
typedef FilaEditable = ({
  String title,
  String? subtitle,
  VoidCallback onEdit,
  VoidCallback onDelete,
});

/// Un campo del dialogo de alta/edicion.
typedef CampoDeDialogo = ({
  String label,
  String value,
  bool numeric,
  bool obligatorio,
});

/// Una lista corta que se edita a mano: cronograma, "que incluye", categorias
/// y extras. Las cuatro se pintan igual; cambia de donde salen las filas.
class _ListaEditable extends StatelessWidget {
  const _ListaEditable({
    required this.title,
    required this.hint,
    required this.emptyLabel,
    required this.addLabel,
    required this.rows,
    required this.icon,
    required this.onAdd,
    this.enabled = true,
    this.disabledHint,
  });

  final String title;
  final String hint;
  final String emptyLabel;
  final String addLabel;
  final List<FilaEditable> rows;
  final IconData icon;
  final VoidCallback onAdd;

  /// En el alta, categorias y extras todavia no se pueden crear: no hay
  /// carrera a la que colgarlas. [disabledHint] dice por que.
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ConRotulo(
      title: title,
      hint: hint,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    disabledHint ?? emptyLabel,
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ),
              for (final (i, fila) in rows.indexed) ...[
                if (i > 0) const AppDivider(),
                StatRow(
                  icon: icon,
                  title: fila.title,
                  subtitle: fila.subtitle,
                  onTap: enabled ? fila.onEdit : null,
                  trailing: IconButton(
                    onPressed: enabled ? fila.onDelete : null,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: c.textSecondary,
                    tooltip: context.l10n.adminDelete,
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: AppButton(
                    label: addLabel,
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    isFullWidth: false,
                    onPressed: enabled ? onAdd : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El dialogo de alta/edicion de una fila. Devuelve los valores en el mismo
/// orden en que se le pidieron los campos, o `null` si se cancelo.
class _DialogoDeCampos extends StatefulWidget {
  const _DialogoDeCampos({required this.title, required this.campos});

  final String title;
  final List<CampoDeDialogo> campos;

  @override
  State<_DialogoDeCampos> createState() => _DialogoDeCamposState();
}

class _DialogoDeCamposState extends State<_DialogoDeCampos> {
  late final _controles = [
    for (final campo in widget.campos) TextEditingController(text: campo.value),
  ];

  /// Obligatorios vacios. Solo se mira tras intentar aceptar: senalar en rojo
  /// lo que aun no se escribio es reganar antes de tiempo.
  var _faltan = <int>{};

  @override
  void dispose() {
    for (final control in _controles) {
      control.dispose();
    }
    super.dispose();
  }

  void _aceptar() {
    final faltan = {
      for (final (i, campo) in widget.campos.indexed)
        if (campo.obligatorio && _controles[i].text.trim().isEmpty) i,
    };
    if (faltan.isNotEmpty) {
      setState(() => _faltan = faltan);
      return;
    }
    Navigator.of(context).pop([for (final c in _controles) c.text.trim()]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, campo) in widget.campos.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: campo.label,
                  controller: _controles[i],
                  errorText: _faltan.contains(i) ? t.adminRequiredField : null,
                  keyboardType: campo.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonCancel),
        ),
        TextButton(onPressed: _aceptar, child: Text(t.commonSave)),
      ],
    );
  }
}

/// El fallo de guardado, empujando la barra hacia arriba.
class _BannerDeError extends StatelessWidget {
  const _BannerDeError({required this.failure, required this.onDismiss});

  final Failure? failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedSize(
      duration: context.reduceMotion ? Duration.zero : AppDurations.fast,
      curve: AppDurations.curve,
      alignment: Alignment.bottomCenter,
      child: failure == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.only(left: AppSpacing.md),
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

/// Carga con la forma del formulario: la cabecera y las secciones.
class _CargandoDetalle extends StatelessWidget {
  const _CargandoDetalle();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.readableMaxWidth),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          const Row(
            children: [
              Skeleton(width: 64, height: 64, radius: AppRadius.lg),
              SizedBox(width: AppSpacing.base),
              Expanded(child: SkeletonLines()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < 3; i++) ...[
            const Skeleton(width: 140, height: 24),
            const SizedBox(height: AppSpacing.base),
            for (var j = 0; j < 2; j++) ...[
              const Skeleton(
                width: double.infinity,
                height: AppSizes.controlHeight,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    ),
  );
}
