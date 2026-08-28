import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/sync/offline_first.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/profile/data/datasources/profile_api.dart';
import 'package:camrun/features/profile/data/profile_mappers.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/domain/repositories/profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this.api, this.db);

  static const _cacheKey = 'profile.current';

  final ProfileApi api;
  final AppDatabase db;

  @override
  Future<Result<UserProfile>> fetch() => guard(
    () => readThrough(
      db: db,
      key: _cacheKey,
      fetch: api.me,
      parse: profileFromApi,
    ).last,
  );

  @override
  Future<Result<UserProfile>> save(UserProfile profile) => guard(() async {
    final response = await api.updateMe(profilePatch(profile));
    // El PATCH devuelve la cuenta y su perfil, pero no los complementos
    // (highlights, salud, zapatillas): se conservan los de la cache para no
    // vaciar las tarjetas de la pantalla al guardar el formulario.
    return _cache({...await _cached(), ...response});
  });

  @override
  Future<Result<UserProfile>> uploadAvatar(String filePath) => guard(() async {
    final avatarUrl = await api.uploadAvatar(filePath);
    final cached = await _cached();
    final profile = cached['profile'];
    return _cache({
      ...cached,
      'avatarUrl': avatarUrl,
      if (profile is Map)
        'profile': {...profile.cast<String, dynamic>(), 'avatarUrl': avatarUrl},
    });
  });

  @override
  Future<Result<UserProfile>> addShoe({
    required String brand,
    required String model,
    required double retireAtKm,
  }) => guard(() async {
    await api.addShoe(
      shoePost(brand: brand, model: model, retireAtKm: retireAtKm),
    );
    return _refreshShoes();
  });

  @override
  Future<Result<UserProfile>> removeShoe(String id) => guard(() async {
    await api.deleteShoe(id);
    return _refreshShoes();
  });

  @override
  Future<Result<UserProfile>> saveHealth({
    required List<Injury> injuries,
    required Duration sleep,
    required HydrationHabit hydration,
  }) => guard(() async {
    final health = await api.updateHealth(
      healthPatch(injuries: injuries, sleep: sleep, hydration: hydration),
    );
    return _cache({...await _cached(), 'health': health});
  });

  /// El POST devuelve solo la zapatilla nueva y el DELETE ni eso, y ninguno
  /// dice a quien le quito el `isPrimary`: la lista se relee entera.
  Future<UserProfile> _refreshShoes() async =>
      _cache({...await _cached(), 'shoes': await api.shoes()});

  @override
  Future<Result<ProfilePreferences>> fetchPreferences() => guard(
    () => readThrough(
      db: db,
      key: 'profile.preferences',
      fetch: api.preferences,
      parse: preferencesFromApi,
    ).last,
  );

  @override
  Future<Result<ProfilePreferences>> savePreferences(
    ProfilePreferences prefs,
  ) => guard(() async {
    final response = await api.updatePreferences(preferencesPatch(prefs));
    await db.writeDoc('profile.preferences', response);
    return preferencesFromApi(response);
  });

  Future<Map<String, dynamic>> _cached() async =>
      await db.readDoc(_cacheKey) ?? const {};

  Future<UserProfile> _cache(Map<String, dynamic> doc) async {
    await db.writeDoc(_cacheKey, doc);
    return profileFromApi(doc);
  }
}
