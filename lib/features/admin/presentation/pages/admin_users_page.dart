import 'dart:math' as math;

import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Administradores, organizadores y corredores, todos en la misma lista.
///
/// No hay una pestana por rol: son la misma entidad con un campo distinto, y
/// tres listas obligarian a saber de antemano en cual buscar a alguien cuyo rol
/// justamente se quiere cambiar.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _busqueda = TextEditingController();
  String _filtro = '';

  /// null = todos. Viaja al servidor: la lista llega por paginas, y filtrar
  /// aqui perdia a los admins y organizadores, que casi nunca caen en la
  /// primera.
  String? _rol;

  int _pagina = 1;
  int _porPagina = adminPageSizes.first;

  /// Cambiar filtro o tamano de pagina vuelve a la primera: la pagina 4 de otra
  /// busqueda no existe, y quedarse en ella devuelve una lista vacia.
  void _reiniciar(VoidCallback cambio) => setState(() {
    cambio();
    _pagina = 1;
  });

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final consulta = (
      busqueda: _filtro,
      rol: _rol,
      pagina: _pagina,
      porPagina: _porPagina,
    );
    final usuarios = ref.watch(adminUsersProvider(consulta));

    return Scaffold(
      appBar: AppBar(title: Text(t.adminUsersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFicha(context, null),
        icon: const Icon(Icons.person_add_alt_rounded),
        label: Text(t.adminNewUser),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              AppSpacing.sm,
            ),
            child: AppTextField(
              label: t.adminSearch,
              hint: t.adminSearchHint,
              controller: _busqueda,
              suffixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _reiniciar(() => _filtro = v.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              children: [
                for (final rol in <String?>[null, ...adminRoles]) ...[
                  ChoiceChip(
                    label: Text(
                      rol == null ? t.adminRoleAll : roleLabel(t, rol),
                    ),
                    selected: _rol == rol,
                    onSelected: (_) => _reiniciar(() => _rol = rol),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          // Arriba y no al pie: abajo lo tapa el boton de nueva cuenta.
          // Mientras recarga conserva el total anterior, para que los botones
          // no parpadeen de activos a inactivos en cada salto de pagina.
          _Paginador(
            total: usuarios.value?.total,
            pagina: _pagina,
            porPagina: _porPagina,
            onPagina: (p) => setState(() => _pagina = p),
            onPorPagina: (n) => _reiniciar(() => _porPagina = n),
          ),
          Expanded(
            child: usuarios.when(
              loading: () =>
                  const Center(child: Skeleton(width: 180, height: 20)),
              error: (error, _) => ErrorStateView(
                message: error is Failure
                    ? error.localized(t)
                    : t.adminLoadFailed,
                onRetry: () => ref.invalidate(adminUsersProvider(consulta)),
              ),
              data: (pagina) {
                final lista = pagina.usuarios;
                return lista.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_outlined,
                        title: t.adminNoUsersTitle,
                        message: t.adminNoUsersBody,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          0,
                          AppSpacing.screenH,
                          AppSpacing.xxl * 2,
                        ),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const AppDivider(),
                        itemBuilder: (context, i) => _Fila(
                          user: lista[i],
                          onTap: () => _abrirFicha(context, lista[i]),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFicha(BuildContext context, AdminUser? user) async {
    final cambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Ficha(user: user),
    );
    // La familia entera: cambiar el rol de alguien lo mueve de una lista a otra.
    if (cambio ?? false) ref.invalidate(adminUsersProvider);
  }
}

/// Rango, salto de pagina y cuantas filas trae cada una.
///
/// Se esconde mientras no hay total —la primera carga— y cuando no hay
/// resultados: un paginador sobre una lista vacia solo estorba.
class _Paginador extends StatelessWidget {
  const _Paginador({
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
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

class _Fila extends StatelessWidget {
  const _Fila({required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: context.text.bodyMd),
                  Text(
                    user.email ?? user.ci ?? '—',
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            if (user.mustChangePassword)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.key_outlined,
                  size: 16,
                  color: c.warning,
                  semanticLabel: t.adminMustChangePassword,
                ),
              ),
            AppBadge(label: roleLabel(t, user.role), tone: toneOf(user.role)),
          ],
        ),
      ),
    );
  }
}

/// Alta y edicion de una cuenta. En hoja y no en pantalla completa: son cuatro
/// campos y se abre desde una lista a la que se vuelve enseguida.
class _Ficha extends ConsumerStatefulWidget {
  const _Ficha({required this.user});

  final AdminUser? user;

  @override
  ConsumerState<_Ficha> createState() => _FichaState();
}

class _FichaState extends ConsumerState<_Ficha> {
  late final _nombre = TextEditingController(text: widget.user?.name ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  final _password = TextEditingController();
  late String _rol = widget.user?.role ?? 'runner';

  bool _guardando = false;
  String? _error;

  bool get _esAlta => widget.user == null;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final t = context.l10n;
    if (_nombre.text.trim().isEmpty) {
      setState(() => _error = t.adminNameRequired);
      return;
    }
    if (_esAlta && _password.text.length < 8) {
      setState(() => _error = t.adminPasswordTooShort);
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final api = ref.read(adminApiProvider);
    try {
      if (_esAlta) {
        await api.createUser({
          'name': _nombre.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'role': _rol,
        });
      } else {
        await api.updateUser(widget.user!.id, {
          'name': _nombre.text.trim(),
          'role': _rol,
        });
        // La contrasena va por su propio endpoint: es la unica operacion de
        // esta pantalla que deja a alguien fuera de su cuenta, y mezclarla con
        // el resto la haria pasar sin querer en cada guardado.
        if (_password.text.isNotEmpty) {
          await api.setPassword(widget.user!.id, _password.text);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
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
        title: Text(t.adminDeleteUserTitle),
        content: Text(t.adminDeleteUserBody(widget.user!.name)),
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
      await ref.read(adminApiProvider).deleteUser(widget.user!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.localized(context.l10n));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.lg,
        // Sobre el teclado: sin esto los campos de abajo quedan tapados justo
        // cuando se los esta escribiendo.
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _esAlta ? t.adminNewUser : t.adminEditUser,
            style: context.text.titleMd,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: t.adminName, controller: _nombre),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: t.adminEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            // El correo es la identidad de la cuenta: cambiarlo desde aqui
            // seria mudarle la sesion a otra persona sin avisarle a ninguna.
            enabled: _esAlta,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: _esAlta ? t.adminPassword : t.adminNewPassword,
            hint: _esAlta ? null : t.adminPasswordKeepHint,
            controller: _password,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.adminRole, style: context.text.labelSm),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<String>(
            segments: [
              for (final rol in adminRoles)
                ButtonSegment(value: rol, label: Text(roleLabel(t, rol))),
            ],
            selected: {_rol},
            onSelectionChanged: (s) => setState(() => _rol = s.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: context.text.bodySm.copyWith(color: c.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (!_esAlta)
                IconButton(
                  onPressed: _guardando ? null : _borrar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: t.adminDelete,
                ),
              Expanded(
                child: FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: Text(t.commonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El nombre visible de un rol. Sale del ARB y no del servidor: el servidor
/// manda la clave y el idioma lo pone quien pinta.
String roleLabel(AppLocalizations t, String role) => switch (role) {
  'admin' => t.adminRoleAdmin,
  'organizer' => t.adminRoleOrganizer,
  _ => t.adminRoleRunner,
};

AppTone toneOf(String role) => switch (role) {
  'admin' => AppTone.error,
  'organizer' => AppTone.info,
  _ => AppTone.neutral,
};
