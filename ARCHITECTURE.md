# Arquitectura de PaceUp

Documento de referencia para trabajar en el proyecto: cómo están organizadas las
capas, qué convenciones se siguen, cómo añadir una feature nueva y cómo cambiar
los repositorios falsos por una API real.

---

## 1. Principios

1. **Feature-first con capas.** Cada feature (`onboarding`, `auth`, `home`,
   `train`, `races`, `profile`) contiene su propio `domain`, `data` y
   `presentation`. Lo transversal vive en `core/` y `shared/`.
2. **El dominio no sabe nada de Flutter ni de red.** Sólo entidades inmutables,
   contratos de repositorio y tipos de error.
3. **La presentación nunca toca `data`.** Los widgets leen providers; los
   providers dependen de interfaces del dominio.
4. **Cero valores mágicos en la UI.** Todo color, espacio, radio y estilo sale
   del design system a través de `context.colors` y `context.text`.
5. **Sólo front-end.** Toda la data proviene de repositorios en memoria con
   `Future.delayed` para simular latencia.

## 2. Flujo de dependencias

```
presentation  ──►  domain  ◄──  data
   (widgets)      (contratos)  (implementación)
                     ▲
                     │
              app/dependencies.dart
              (une contrato + implementación)
```

`app/dependencies.dart` es el único punto donde una interfaz se une con su
implementación. Es el contenedor de inyección de dependencias del proyecto.

## 3. Estructura de carpetas

```
lib/
├── main.dart                     # bootstrap(PaceUpApp.new)
├── app/
│   ├── app.dart                  # MaterialApp.router + temas
│   ├── bootstrap.dart            # orientación, system UI, Hive, prefs, overrides
│   ├── dependencies.dart         # contenedor de dependencias
│   └── router/
│       ├── app_router.dart       # GoRouter + StatefulShellRoute.indexedStack
│       ├── app_routes.dart       # constantes de paths
│       └── guards.dart           # redirect de onboarding / sesión
├── core/
│   ├── theme/                    # tokens, tipografía, espaciado, ThemeData
│   ├── error/failure.dart        # jerarquía sellada de errores
│   ├── utils/                    # Result, validators, route_generator
│   ├── extensions/context_x.dart # context.colors / context.text
│   ├── formatters/formatters.dart
│   ├── constants/fake_data_seed.dart
│   └── services/                 # prefs, settings, location
├── shared/widgets/               # atoms · molecules · organisms
└── features/<feature>/
    ├── domain/{entities,repositories}
    ├── data/repositories
    └── presentation/{providers,pages,widgets}
```

## 4. Design system

### Tokens

`core/theme/app_colors.dart` contiene dos clases de tokens crudos
(`LightTokens`, `DarkTokens`) que **nunca** se exponen a la UI. Sobre ellas se
construye `AppPalette`, una `ThemeExtension` con todos los roles semánticos,
incluidos los que Material 3 no cubre: `successFg/successBg`,
`warningFg/warningBg`, `ringTrack`, `mapOverlay`, `inkPill`, `brandGradient`,
`routeGradient`, `heroOverlay`.

La tipografía sigue el mismo patrón: `AppTextStyles` es otra `ThemeExtension`
con la escala completa (`displayLg` … `labelSm`), y `AppTypography.textTheme`
la mapea a los slots de Material 3 para que los widgets de stock la hereden.

### Acceso desde la UI

```dart
Text('12.5 km', style: context.text.displayLg);
Container(color: context.colors.primaryContainer);
```

Nunca `Color(0x…)`, `Colors.*`, `TextStyle(fontSize: …)` ni números sueltos
dentro de un widget de pantalla: usar `AppSpacing`, `AppRadius`, `AppSizes`,
`AppDurations`.

### Elevación

En claro se usan sombras teñidas de `primary` (`cardShadow`, `floatingShadow`).
En oscuro las sombras no se leen, así que `AppShadows` devuelve una lista vacía
y la elevación se comunica con `surfaceElevated` más un borde de 1px.

### Catálogo visual

En modo debug existe `/dev/showcase`: renderiza todos los atoms y molecules y
permite alternar tema. Es la herramienta de verificación visual del sistema.

## 5. Estado

Riverpod 3 con providers escritos a mano.

| Necesidad | Herramienta |
|---|---|
| Datos async de una pantalla | `AsyncNotifierProvider` |
| Estado síncrono (filtros, ajustes) | `NotifierProvider` |
| Valor derivado | `Provider` (con `select` cuando conviene) |
| Dato por id | `Provider.family` / `FutureProvider.family` |
| Flujo continuo (cronómetro) | `StreamProvider.autoDispose.family` |

Los tres estados de carga se resuelven con `AsyncValue.when(...)`, y toda
pantalla con carga async define los tres: **loading** (skeleton shimmer, nunca
un spinner centrado), **empty** (`EmptyState` con CTA) y **error**
(`ErrorStateView` con mensaje accionable y «Try again»).

## 6. Errores

`core/error/failure.dart` define una jerarquía sellada (`NetworkFailure`,
`CacheFailure`, `NotFoundFailure`, `PermissionFailure`, `ValidationFailure`,
`UnexpectedFailure`). Los repositorios devuelven `Result<T>`
(`Success` / `FailureResult`), construido con el helper `guard()`. Las
excepciones no cruzan capas.

En la capa de presentación:

- Dentro del `build` de un `AsyncNotifier` se usa `result.unwrap()`: la
  excepción la captura Riverpod y se convierte en `AsyncError`.
- En acciones puntuales se usa `result.fold(...)` y se devuelve un `String?`
  con el mensaje para mostrarlo en línea.

## 7. Navegación

`GoRouter` con `StatefulShellRoute.indexedStack` y cuatro ramas
(**Home · Train · Races · Profile**). Cada rama conserva su pila al cambiar de
tab.

- `/train/session` se declara con `parentNavigatorKey: _rootKey` para que ocupe
  toda la pantalla y oculte la barra inferior.
- `guards.dart` implementa el `redirect`: sin onboarding → `/onboarding`; sin
  sesión → `/welcome`; con sesión en una ruta de auth → `/home`. Las rutas
  `/dev/*` quedan exentas.
- El router se construye una sola vez; un `ValueNotifier` alimentado por
  `ref.listen` actúa de `refreshListenable` para reevaluar el redirect sin
  perder el estado de navegación.

## 8. Cómo añadir una feature

1. Crear `lib/features/<nombre>/{domain,data,presentation}`.
2. **Domain**: entidad inmutable en `domain/entities/` y contrato
   `abstract interface class XRepository` en `domain/repositories/`.
3. **Data**: `data/repositories/fake_x_repository.dart` implementando el
   contrato con `guard()` y `Future.delayed`.
4. **DI**: añadir el provider en `app/dependencies.dart`, tipado contra la
   interfaz.
5. **Presentation**: `AsyncNotifierProvider` en `presentation/providers/`,
   pantalla en `presentation/pages/`.
6. **Rutas**: constante en `app_routes.dart` y `GoRoute` en `app_router.dart`.
7. **Widgets**: si se usan en dos o más features van a `shared/widgets/`; si no,
   a `features/<nombre>/presentation/widgets/`.

## 9. Sustituir los fakes por una API real

Todo pasa por `app/dependencies.dart`. Por cada repositorio:

```dart
// antes
final marathonRepositoryProvider = Provider<MarathonRepository>(
  (ref) => FakeMarathonRepository(),
);

// después
final marathonRepositoryProvider = Provider<MarathonRepository>(
  (ref) => RemoteMarathonRepository(ref.watch(httpClientProvider)),
);
```

`RemoteMarathonRepository` implementa la misma interfaz, traduce los DTO a
entidades y convierte los fallos HTTP en `Failure`. Ni los providers ni las
pantallas cambian.

Casos particulares:

- **`TrainingRepository`** está respaldado por Hive y su caja se abre en
  `bootstrap()`; el provider se inyecta como override. Para ir a remoto basta
  cambiar ese override (o combinar ambos en un repositorio con caché).
- **`LocationService`** tiene dos implementaciones,
  `GeolocatorLocationService` y `SimulatedLocationService`. El selector es
  `useSimulatedLocationProvider`, que en debug devuelve `true`. Sobrescribirlo
  permite probar GPS real en dispositivo sin tocar ningún call site.
- **`RouteMapView`** encapsula `flutter_map`. Cambiar a
  `google_maps_flutter` es una edición dentro de ese único archivo.

### La capa de red (Fase 19)

`core/network/` es el cliente de la API. Un solo `Dio`, inyectado por
`network_providers.dart`, con los interceptores en este orden:

| # | Interceptor | Qué hace |
|---|---|---|
| 1 | `AuthInterceptor` | Adjunta `Bearer <access>` salvo en rutas públicas |
| 2 | `RefreshInterceptor` | Ante `401`, renueva y reintenta la original |
| 3 | `RetryInterceptor` | Backoff exponencial en errores de red y `5xx`, sólo sobre peticiones repetibles |
| 4 | `EnvelopeInterceptor` | Abre el sobre `{ data, meta }` y sincroniza `ServerClock` |
| 5 | `ErrorInterceptor` | Traduce el error a `Failure` mapeando **por `error.code`** |
| 6 | `DebugLogInterceptor` | Log en debug, sin volcar `Authorization` |

Tres detalles que no son negociables:

- **El refresh es single-flight.** El refresh token rota en cada uso: si diez
  peticiones en vuelo reciben `401` y cada una renueva por su cuenta, nueve
  llegan con un token ya rotado, el backend lo lee —bien— como robo y revoca la
  cadena entera del dispositivo. El mutex vive en `SessionController` y hay un
  test que lo comprueba (`test/core/network/network_test.dart`).
- **`SessionController` usa un `Dio` sin interceptores** para llamar a
  `/auth/refresh`. Con ellos, un `401` de ese endpoint dispararía otro refresh.
- **Las cuentas regresivas se calculan con `ServerClock.now()`**, alimentado por
  `meta.timestamp`, no con el reloj del teléfono.

Los tokens y el `deviceId` viven en `flutter_secure_storage`
(`core/storage/token_storage.dart`), nunca en `SharedPreferences`: de ahí un
backup de Android se lleva la sesión. `TokenStorage` es una interfaz para poder
inyectar una versión en memoria en los tests, donde no hay Keychain.

La URL base sale de `--dart-define=API_BASE_URL`; sin definir cae al backend
local (`10.0.2.2` en el emulador de Android, que es el alias del host).

Los modelos de la API son `freezed` + `json_serializable`
(`features/auth/data/models/`, `core/config/app_config.dart`) y hablan en las
unidades crudas del servidor —metros, segundos, centavos, ISO-8601 UTC—. El
formateo es de `core/formatters`.

### Local y offline (Fase 20)

`core/db/app_database.dart` es la base local, en **drift** (SQLite). Tres tablas:

| Tabla | Para qué |
|---|---|
| `outbox_entries` | Escrituras hechas sin red: método, ruta, body, `Idempotency-Key`, intentos y `next_attempt_at` |
| `pending_workouts` | Entrenamientos grabados offline, a la espera de `POST /workouts/sync` |
| `cached_docs` | Respuestas crudas de GET por clave, para que la pantalla abra con datos |

La regla en una línea: **leer de local, refrescar desde red, escribir en la
outbox.** `core/sync/offline_first.dart` implementa la lectura
(`readThrough` emite la cache y después lo fresco; sin red pero con cache el
fallo se traga) y `core/sync/sync_service.dart` el drenado.

Lo que no es negociable:

- **La `Idempotency-Key` se guarda en la fila, no en memoria.** Su trabajo es
  sobrevivir a la conexión que se corta después de mandar el checkout pero
  antes de recibir la respuesta. Si se pierde en ese hueco, el reintento es un
  segundo cobro.
- **Los entrenamientos tienen su propia tabla**, no van por la outbox:
  `/workouts/sync` sube lotes de hasta 50 y resuelve **cada item por separado**
  (`created` / `duplicated` / `rejected`). Una fila de outbox por petición no
  sabría qué hacer con un rechazo en el sexto de cincuenta. `duplicated` no es
  un error: se cierra la fila igual.
- **Un `4xx` se descarta con log.** El servidor no va a cambiar de opinión y
  dejar la entrada en la cola bloquearía para siempre todo lo encolado detrás.
  Sin red o con `5xx`, en cambio, se reintenta con backoff exponencial (5 s,
  doblando, tope de 30 min) y el drenado se corta ahí.

El drenado se dispara al arrancar y cada vez que la app vuelve al frente
(`AppLifecycleListener` en `bootstrap()`). No se escucha la conectividad: es una
dependencia más para adivinar lo que el primer reintento averigua solo.

`hive_ce` sigue vivo **sólo** para `HiveTrainingRepository`, que es datos falsos;
desaparece en la Fase 22 cuando ese repositorio pase a drift + API.

### Tracking GPS (Fase 21)

`features/tracking/` graba un entrenamiento: `TrackingService` con
`start` / `pause` / `resume` / `stop` / `discard` y un `stream` de puntos para
el mapa. El GPS lo pone `core/services/location_service.dart` —**`geolocator`,
que ya estaba**: servicio en primer plano en Android y `UIBackgroundModes` en
iOS, sin paquete de pago (el porqué, en `running-api/docs/decisiones.md`).

El camino de un punto:

```
GPS (1 Hz, se descarta accuracy > 30 m)
  └─▶ pending_positions (drift)   ← SIEMPRE, y primero
        └─▶ cada 20 s: POST /tracking/sessions/:id/positions
```

Lo que no es negociable:

- **Primero la fila, después la red.** Un entrenamiento perdido no se puede
  volver a correr. Si la sesión remota ni siquiera pudo abrirse —correr sin
  cobertura—, se graba igual y el entrenamiento entero sube por
  `/workouts/sync` al terminar.
- **La ingesta se autentica con el `ingestToken` de la sesión**, no con el JWT:
  el credencial que sale del teléfono cada veinte segundos durante una carrera
  tiene que ser el de menor alcance posible. El token se guarda **con los
  puntos**, porque la cola puede drenarse horas después. Por eso `/tracking/`
  está en `publicApiPaths`: no lleva JWT, y su 401 no significa que la sesión
  del usuario caducó.
- **Lotes, nunca punto por punto.** El envío lo hace el mismo `SyncService` que
  todo lo demás, así que reintentos y backoff viven en un único sitio. Un lote
  reenviado es inofensivo: el servidor deduplica por `clientPointId`.
- **Sesión cerrada o token inválido → el lote se descarta.** Esos puntos no van
  a entrar nunca y dejarlos bloquearía la cola de las sesiones siguientes.
- **En pausa se apaga el sensor entero**, que ahorra más que cualquier
  `distanceFilter`. Pausar, reanudar y descartar, si fallan, van a la outbox:
  no valen un entrenamiento y su error no sube a la UI.
- **Permisos en dos tiempos**: `whileInUse` para empezar, y `always` después,
  cuando ya hay una grabación que lo justifica. Denegado el segundo, se graba
  igual y se avisa (`backgroundDenied`); no se bloquea nada.

### Auth conectado (Fase 22.1)

`RemoteAuthRepository` sustituye al fake: `AuthApi` para hablar, `SessionController`
para guardar el par de tokens, `AppDatabase.wipe()` para borrar lo local.

- **La sesión inicial se resuelve en `bootstrap()`**, leyendo el refresh token
  del almacén seguro (`initialSessionProvider`). Es una lectura asíncrona y el
  guard del router es síncrono: sin ese dato, quien ya estaba dentro vería
  Welcome un instante antes del primer frame de Home.
- **Cerrar sesión borra el dispositivo pase lo que pase.** Si `/auth/logout`
  falla, el peor caso es un refresh token vivo que ya nadie tiene; al revés
  —tokens y caché que se quedan porque no había red— es la sesión de uno
  visible para el siguiente.
- **La sesión también muere sola**: `AuthNotifier` escucha
  `SessionController.expired` (refresh rechazado), pone el estado a `false` y
  limpia la caché. El router hace el resto.
- `onboardingSeenAt` llega en el usuario del login: quien ya vio los slides no
  los vuelve a ver aunque haya reinstalado.

Los tests de widget no abren sockets: `pumpApp` inyecta un `Dio` con
`FakeAdapter` y un `TokenStorage` en memoria.

## 10. Datos de prueba

`core/constants/fake_data_seed.dart` genera todo el dataset anclado a
`DateTime.now()`, para que las cuentas atrás y la agrupación por semana sean
correctas se abra cuando se abra la app:

- 6 maratones: 2 abiertas, 1 «closing soon», 1 llena, 2 pasadas.
- Plan de 12 semanas con la semana 4 activa (la que contiene hoy).
- 25 entrenamientos repartidos en 8 semanas, con rutas GPS sintéticas
  coherentes generadas por `RouteGenerator` (bucles cerrados, no ruido).
- 4 inscripciones: 2 completadas con resultados, 1 próxima pagada, 1 pendiente
  de pago.

`RouteGenerator` construye un bucle armónico, lo escala al kilometraje pedido y
reparte marcas de tiempo según el ritmo objetivo con una deriva de ±4 %. De ahí
salen distancia (Haversine), desnivel y splits por kilómetro.

## 11. Pruebas

| Tipo | Qué cubre |
|---|---|
| Unitarias | formatters, Haversine, generación de splits, totales de Races |
| Widget | `AppButton`, `AppProgressRing`, `CountdownPill`, `RaceCard` |
| Golden | Home, Races y Profile en claro y oscuro |
| Integración | onboarding → welcome → sign in → home, con guards |

Los goldens se regeneran con `flutter test --update-goldens`. Cargan Poppins y
MaterialIcons explícitamente; sin eso el texto y los iconos saldrían como cajas.
El reloj se congela con `nowProvider`, así que la cuenta atrás de Home no cambia
entre ejecuciones.

**Limitación conocida:** `FakeDataSeed` se ancla a `DateTime.now()`, de modo que
la fecha de la sesión del día y el día resaltado de la tira semanal cambian al
cambiar el día natural. Los goldens de Home hay que regenerarlos si se ejecutan
en otra fecha. Para fijarlos en CI habría que inyectar también la fecha base del
seed.

**La sesión en vivo no tiene golden a propósito**: su capa de mapa descarga
tiles de OpenStreetMap, así que no puede renderizarse de forma determinista sin
red. Se cubre con el modo de GPS simulado y con pruebas de widget.

Las pantallas que mantienen temporizadores vivos (la cuenta atrás de Home) no
se pueden `pumpAndSettle`: se avanzan con `pump(Duration)` y se descargan con el
helper `drainHome` de `test/helpers.dart`.

## 12. Decisiones tomadas y desviaciones respecto al brief

| Decisión | Motivo |
|---|---|
| **Riverpod 3 sin codegen** | `riverpod_generator` ≥ 4.0.6 exige `analyzer ^13` y `freezed` (máx. 3.2.5) tope en `analyzer <11`: no existe combinación que resuelva. Se optó por providers escritos a mano, igual de type-safe y sin paso de build. |
| **Sin `freezed` ni `json_serializable`** | Al caer el codegen de Riverpod, mantener `build_runner` sólo por `copyWith` no compensaba. Las entidades son clases inmutables con `copyWith` a mano, y `toJson/fromJson` sólo en lo que se persiste (`TrainingRun`, `UserProfile`). Los estados sellados usan `sealed class` de Dart 3. |
| **`hive_ce` en lugar de `hive`** | `hive` está discontinuado; `hive_ce` es el fork mantenido con la misma API. |
| **Poppins empaquetado en `assets/fonts/`** | `google_fonts` descarga en el primer arranque; con la fuente local la app es correcta sin red y los goldens son deterministas. |
| **`flutter_lints` estricto en vez de `very_good_analysis`** | Cubre las reglas exigidas (`prefer_const_constructors`, `always_use_package_imports`, `require_trailing_commas`) más `strict-casts/inference/raw-types`, sin ruido añadido. |
| **Ilustraciones y fotos generadas por `CustomPainter`** | No hay assets de diseño disponibles. `BlobIllustration` y `EventImage` dibujan marcadores de posición con la paleta de marca; `EventImage` usa `cached_network_image` en cuanto `heroImageUrl` no esté vacío, así que enchufar imágenes reales no requiere tocar las pantallas. |
| **Anillos del plan semanal de tamaño adaptativo** | Siete anillos de 56pt no caben en 390pt. Se reducen hasta 40pt y, por debajo de eso, la tira pasa a scroll horizontal. Prioriza legibilidad sobre el tamaño fijo del diseño. |
| **Sin golden de la sesión en vivo** | Ver §11. |

## 13. Accesibilidad

- Contraste AA verificado en ambos temas.
- `Semantics` en todos los iconos-botón (`semanticsLabel` es obligatorio en
  `AppIconButton`).
- Objetivos táctiles ≥ 48×48.
- `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` en la raíz: respeta
  la preferencia del usuario sin romper las rejillas de métricas.
- `context.reduceMotion` consulta `MediaQuery.disableAnimations`; los skeletons
  y los anillos animados lo respetan.
