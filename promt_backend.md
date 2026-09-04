# PaceUp — Guía de arranque de la API

Para quien va a construir una app (móvil o web) desde cero contra el backend de
PaceUp. **No es la referencia de endpoints**: la referencia vive en Swagger y se
genera desde el código, así que no puede desincronizarse. Este documento explica
lo que Swagger no cuenta —las reglas transversales, los tres flujos de negocio y
en qué orden implementarlos— y te dice **exactamente a qué URL ir** para el
contrato exacto de cada operación.

---

## 0. Dónde está la documentación de verdad

| Qué | Dónde | Para qué |
|---|---|---|
| **Swagger UI** | **https://cam-run.tumype.com/api/docs** | Navegar los 129 endpoints, ver request/response de cada uno y **probarlos en vivo** con el botón *Authorize* |
| **OpenAPI JSON** | **https://cam-run.tumype.com/api/docs-json** | Generar un cliente tipado (`openapi-generator`, `swagger-codegen`, `openapi_generator` de Dart) |
| OpenAPI YAML versionado | `running-api/api/openapi.yaml` | Igual, sin levantar nada. Se regenera con `npm run openapi:export` |
| Contrato en prosa | `running-api/docs/api.md` | El porqué de cada regla, sección por sección |
| Integración cliente | `running-api/docs/flutter-integracion.md` | Interceptores, mutex de refresh, offline-first, deep links |
| Pago QR manual | `running-api/docs/pago-qr-manual.md` | El flujo de cobro que se usa **hoy** en producción |
| Tracking GPS | `running-api/docs/tracking.md` | Ingesta de posiciones, OsmAnd, live tracking por WebSocket |

**Regla de uso de este documento:** léelo entero una vez para entender el modelo.
A partir de ahí, cada vez que necesites el cuerpo exacto de una petición, ve a
`/api/docs` y busca la operación por su tag. Cada sección de abajo te dice qué
tag mirar.

> ⚠️ **El YAML del repo puede ir por detrás.** `api/openapi.yaml` se exporta a
> mano. Hoy `POST /admin/payments/:id/refund` y `GET /admin/payments` existen en
> el código (`src/modules/admin/admin.controller.ts`) pero **no** están ni en el
> YAML ni en el despliegue: el commit que los añadió aún no se desplegó. Ante la
> duda, **`/api/docs-json` del entorno contra el que trabajas es la verdad**.

---

## 1. Entornos y URL base

| Entorno | URL base | Notas |
|---|---|---|
| **Producción** | `https://cam-run.tumype.com/api/v1` | Swagger en `/api/docs`, panel admin en `/admin` |
| Local (`npm run dev`) | `http://localhost:3000/api/v1` | |
| Emulador Android | `http://10.0.2.2:3000/api/v1` | El emulador no ve `localhost` como tu máquina |
| Dispositivo físico | `http://<IP-de-tu-PC>:3000/api/v1` | |

Fuera del prefijo versionado, a propósito:

| Ruta | Qué es |
|---|---|
| `GET /health`, `GET /ready` | Healthchecks para la infraestructura |
| `GET /api/docs`, `/api/docs-json` | Swagger |
| `GET /admin` | Panel web de administración (HTML) |
| `/uploads/**` | Binarios públicos: avatares, QR, comprobantes PDF, tarjetas |
| `GET /api/v1/links/**` | Páginas HTML de deep link (Open Graph). No devuelven JSON |
| `/live` (WebSocket) | Namespace de socket.io para el seguimiento en vivo |

**Nunca hardcodees la URL base en el código.** Va en una constante de
compilación (`--dart-define`, variable de entorno, `.env`).

---

## 2. Reglas que valen para todos los endpoints

### 2.1 Sobre de respuesta

Todo éxito:

```json
{ "data": { }, "meta": { "requestId": "c1f3a0d2-…", "timestamp": "2026-08-18T14:03:22.118Z" } }
```

Todo error:

```json
{ "error": { "code": "MARATHON_FULL", "message": "…", "details": [] },
  "meta": { "requestId": "c1f3a0d2-…", "timestamp": "…" } }
```

Dos reglas no negociables del lado cliente:

1. **Mapea por `error.code`, nunca por `error.message`.** El mensaje es texto
   humano y puede cambiar o traducirse; el código es estable.
2. **`meta.timestamp` es la hora del servidor.** Las cuentas regresivas (largada,
   vencimiento del QR) se calculan contra ese valor, no contra el reloj del
   teléfono.

`meta.requestId` viaja también en la cabecera `x-request-id` y aparece en cada
línea de log del servidor. Muéstralo en las pantallas de error: con él se
encuentra la traza completa.

Excepciones al sobre: `GET /admin/marathons/:id/registrants.csv` (devuelve un
archivo), `GET /api/v1/links/**` (devuelve HTML) y `POST /payments/webhook`.

### 2.2 Unidades

El servidor **nunca formatea**. Devuelve magnitudes crudas; el cliente decide si
muestra km o millas, `5:30/km` o `Bs 150,00`.

| Magnitud | Unidad | Ejemplo |
|---|---|---|
| Distancia | metros, entero | `42195` |
| Duración | segundos, entero | `12600` |
| Ritmo | segundos por kilómetro | `330` → 5:30/km |
| Velocidad | metros por segundo | `3.03` |
| Dinero | **centavos, entero** + `currency` | `15000` + `"BOB"` → Bs 150,00 |
| Fechas | ISO-8601 en **UTC** | `2026-08-18T14:03:22.118Z` |
| Coordenadas | GeoJSON, orden **`[lng, lat]`** | `[-68.1335, -16.4957]` |

Nunca uses `float` para dinero. Cada maratón trae además su `timezone` IANA
(`America/La_Paz` por defecto) para mostrar la hora local de la carrera.

### 2.3 Validación estricta

Los DTO corren con `whitelist` + `forbidNonWhitelisted`: **un campo no declarado
no se ignora, hace fallar la petición** con `VALIDATION_ERROR` (400). Es
deliberado (impide colar `"role": "admin"` en el registro), pero significa que
tu serializador no puede mandar campos de más.

`error.details` trae un mensaje por campo:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "…",
             "details": ["El email no tiene un formato valido"] } }
```

### 2.4 PATCH parciales: `null` ≠ ausente

| Se envía | Efecto |
|---|---|
| `{ "city": "La Paz" }` | Escribe el valor |
| `{ "city": null }` | **Vacía** el campo |
| No se menciona `city` | Lo deja como está |

**Trampa clásica:** un modelo que serialice todos los campos siempre, con los
vacíos en `null`, **borra en cada guardado lo que el usuario no tocó**. Manda
solo lo que cambió.

### 2.5 Paginación

Cursor, no offset: `?limit=&cursor=`, y la respuesta trae `meta.nextCursor`.
**Pagina hasta que `nextCursor` sea `null`**, nunca hasta que una página venga
vacía — al filtrar por `status` una página puede venir corta o vacía y traer
`nextCursor` igual. Un cursor inválido o vencido no da error: empieza de cero.

Excepción: `/admin/users` y `/admin/payments` usan `page`/`pageSize` con
`meta.total`, porque un panel necesita saltar a la página 7.

### 2.6 Idempotencia

Los endpoints que cobran o suben datos en bloque exigen la cabecera
`Idempotency-Key` (8–128 caracteres, un UUID v4 sirve, **la genera el cliente**):

- `POST /registrations/:id/checkout` — **obligatoria**
- `POST /workouts/sync` — obligatoria

**Guárdala junto al borrador en disco, no en memoria.** Su trabajo es sobrevivir
exactamente a lo que no controlas: la conexión que se corta después de mandar el
checkout pero antes de recibir la respuesta. Si se pierde en ese hueco, el
reintento es un segundo cobro.

Una clave se **quema con su resultado**, aprobado o rechazado: reintentar un
rechazo con la misma clave devuelve el mismo rechazo aunque cambies de tarjeta.
Para probar con otro medio de pago hay que **generar una clave nueva**.

### 2.7 Rate limits

| Ámbito | Límite |
|---|---|
| Global | 120 req/min por IP |
| `/auth/*` (register, login, forgot, reset, change) | 10 req/min por IP |
| `/admin/*` | 60 req/min |
| `/public/registrations` | 5 req/min por IP (crea cuentas sin token) |
| Ingesta de tracking | 20 lotes/min **por sesión** |
| OsmAnd | 120 puntos/min por dispositivo |

Al pasarse: `429 RATE_LIMITED`. Reintenta con backoff.

### 2.8 Códigos de error

La fuente es `src/common/errors/error-codes.ts`. Los genéricos:

| Código | HTTP | Qué hacer |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Mostrar `details` junto a los campos |
| `UNAUTHORIZED` | 401 | Disparar **un** refresh y reintentar |
| `FORBIDDEN` / `INSUFFICIENT_ROLE` | 403 | No reintentar |
| `NOT_FOUND` | 404 | No existe, **o existe y no es tuyo**. No reintentar |
| `CONFLICT` | 409 | Releer el estado y reintentar |
| `RATE_LIMITED` | 429 | Backoff |
| `SERVICE_UNAVAILABLE` | 503 | Backoff |
| `INTERNAL_ERROR` | 500 | Error genérico + mostrar `requestId` |

Los específicos de cada dominio están en las secciones de abajo. El catálogo
completo, en `docs/api.md` § *Catálogo de códigos de error*.

**Un recurso ajeno responde `404`, no `403`** (inscripciones, workouts, planes,
pagos): así la API no confirma que exista.

---

## 3. Lo primero que hace la app al arrancar

1. **`GET /config/app`** — público, sin token, **antes de pintar nada**.
2. **Comparar `minAppVersion`** con la versión del paquete. Si la del cliente es
   menor: bloquear y mandar a actualizar.
3. **`POST /auth/refresh`** con el refresh guardado → si funciona, Home; si no,
   Welcome.
4. **`onboardingSeenAt`** sale de `GET /users/me/preferences`, no solo de local:
   así el onboarding no reaparece tras reinstalar.

```json
// GET /config/app
{ "currency": "BOB", "timezone": "America/La_Paz", "defaultLocale": "es-BO",
  "minAppVersion": "1.0.0", "deepLinkScheme": "paceup",
  "serviceFee": { "label": "Cargo por servicio" },
  "tracking": { "maxAccuracyMeters": 30, "maxBatchesPerMinute": 20, "suggestedBatchSeconds": 30 },
  "limits": { "avatarMaxBytes": 5242880, "requestsPerMinute": 120, "shoeAlertThresholdMeters": 800000 },
  "features": { "gpsSimulation": true, "liveTracking": true, "socialLogin": false } }
```

**Nada de esto se hardcodea.** Todo puede cambiar sin publicar una versión nueva.
`serviceFee: null` significa cargo apagado — **ausencia, no `{ enabled: false }`**.

---

## 4. Usuarios: cómo funcionan

> Swagger: tags **auth** y **users**.

### 4.1 Modelo mental

Una cuenta se identifica por **email o CI (cédula de identidad), al menos uno**.
El email es **opcional** a propósito: hay corredores que no tienen o no lo dan.
La CI se guarda normalizada (mayúsculas, sin espacios ni guiones ni puntos), así
que `1234567 LP`, `1234567-lp` y `1234567LP` son la misma persona.

Todo el perfil cuelga de `/users/me` y **no existen endpoints por `userId`**:
el usuario del token es el único que se puede leer o escribir. Así no existe la
clase de bug donde un id mal armado toca la cuenta de otro.

### 4.2 Endpoints de autenticación

| Método | Ruta | Token | Qué hace |
|---|---|---|---|
| POST | `/auth/register` | — | Crea cuenta y **devuelve la sesión ya iniciada** |
| POST | `/auth/login` | — | Inicia sesión en un dispositivo |
| POST | `/auth/refresh` | — | Rota el par de tokens |
| POST | `/auth/logout` | — | Cierra la sesión de este dispositivo (idempotente) |
| GET | `/auth/sessions` | Sí | Dispositivos con sesión activa |
| DELETE | `/auth/sessions/:id` | Sí | Cierra la sesión de otro dispositivo |
| POST | `/auth/forgot-password` | — | Pide enlace de recuperación |
| POST | `/auth/reset-password` | — | Cambia contraseña con el token del correo |
| POST | `/auth/change-password` | Sí | Cambia contraseña con sesión abierta |
| GET | `/auth/me` | Sí | Datos del usuario autenticado |

```jsonc
// POST /auth/register
{ "deviceId": "<uuid v4 persistido>",   // obligatorio
  "deviceName": "Pixel 8", "platform": "android",
  "email": "ana@example.com",            // email O ci, al menos uno
  "ci": "1234567LP",
  "password": "…", "name": "Ana Quispe",
  "birthDate": "1994-03-11", "gender": "female" }

// POST /auth/login
{ "deviceId": "…", "identifier": "ana@example.com", "password": "…" }
```

**`identifier` es un solo campo.** Si lleva `@` se trata como email; si no, como
CI. Se decide por el carácter y no consultando la base: un endpoint que responde
distinto según cuál acertó sería un comprobador gratuito de quién tiene cuenta.

### 4.3 Ciclo de vida de los tokens

```
login/register  ──▶  accessToken (15 min)  +  refreshToken (60 días)
                            │  caduca a los 15 min
                            ▼
                     401 UNAUTHORIZED
                            │
  POST /auth/refresh { refreshToken }  ──▶  par NUEVO, 60 días desde ahora
                            │
                 el refresh viejo queda MUERTO
```

**El refresh rota siempre.** Guarda el nuevo antes de hacer nada más.

Lo que tu interceptor HTTP tiene que hacer bien:

1. Adjuntar `Authorization: Bearer <accessToken>` en cada petición.
2. Ante `401`, disparar **un solo** refresh aunque haya diez peticiones en vuelo:
   hace falta un **mutex**. Sin él, diez `401` simultáneos disparan diez refresh
   concurrentes; el primero rota y los otros nueve llegan con un token ya rotado,
   lo que el servidor interpreta —correctamente— como reuso y **cierra la
   sesión**. Es el error más fácil de cometer contra esta API.
3. Reintentar la petición original con el token nuevo.
4. Si el refresh falla con `INVALID_REFRESH_TOKEN` o `TOKEN_REUSE_DETECTED`:
   limpiar el storage seguro e ir a Welcome. **Nunca reintentar.**

Los tokens van en almacenamiento seguro (Keychain / Keystore /
`flutter_secure_storage`), nunca en preferencias en claro.

### 4.4 `deviceId`

Todos los endpoints de sesión aceptan `deviceId`, `deviceName` y `platform`. El
cliente **genera un UUID la primera vez y lo persiste**; no debe cambiar entre
arranques. Es lo que permite listar "Pixel 8" / "iPad" como sesiones separadas y
revocar la cadena de un dispositivo concreto si se roba.

### 4.5 `mustChangePassword` es una puerta, no un aviso

`GET /auth/me` devuelve `mustChangePassword`. Cuando es `true`, la contraseña la
puso otro —alta desde la web pública: usuario CI, contraseña CI— y la app
**tiene que** mandar al usuario a `POST /auth/change-password` antes de dejarle
usar nada.

`onboardingSeenAt` (`null` = no vio los slides) se persiste en el backend, así
que **sobrevive a una reinstalación**.

### 4.6 Perfil

| Método | Ruta | Qué hace |
|---|---|---|
| GET | `/users/me` | Perfil completo (sin salud ni preferencias) |
| PATCH | `/users/me` | Nombre, email, ciudad, país, nacimiento, género, peso, altura, dorsal habitual |
| POST | `/users/me/avatar` | `multipart/form-data`, campo `file`, máx **5 MB** |
| DELETE | `/users/me/avatar` | Idempotente |
| GET/PATCH | `/users/me/preferences` | Unidades, tema, idioma, notificaciones, privacidad, onboarding |
| GET/PATCH | `/users/me/health` | Lesiones, sueño, hidratación |
| GET | `/users/me/highlights` | Kilometraje de la semana y carrera más larga |
| GET/POST | `/users/me/shoes` | Zapatillas (`?includeRetired=true`) |
| PATCH/DELETE | `/users/me/shoes/:id` | Editar, retirar, marcar principal, borrar |
| DELETE | `/users/me/data` | **Borra la cuenta entera. Irreversible** |

Detalles que importan:

- `GET /users/me` **no** incluye salud ni preferencias: son pantallas distintas y
  meterlas encarecería la llamada que se hace en cada arranque.
- `preferences.notifications` y `preferences.privacy` son objetos libres de
  banderas y el PATCH hace **merge superficial**: una app vieja que mande
  `{ "push": false }` no borra los toggles que no conoce. `injuryFlags`, en
  cambio, **se reemplaza entero**.
- El avatar se decodifica para saber su tipo real (no se confía en
  `Content-Type` ni en la extensión), se rota por EXIF, se recorta a 512 px y se
  reencoda a WebP — lo que **elimina las coordenadas GPS del EXIF**. Se rechaza
  SVG. Errores: `FILE_TOO_LARGE` (413), `INVALID_IMAGE` (415).
- Solo hay **una zapatilla principal**; es a la que se le suman los kilómetros al
  cerrar un entrenamiento. `wearAlert` se enciende al alcanzar
  `alertThresholdMeters` (800 km por defecto).
- La semana de `highlights` es **lunes–domingo en `America/La_Paz`**, no en UTC, y
  `weekEndsAt` es un límite **exclusivo**.

### 4.7 Roles

| Rol | Qué puede |
|---|---|
| `runner` | Nada de `/admin/*`. Es el rol del registro público |
| `organizer` | Administrar **cuentas de corredor** y validar **comprobantes de pago QR** |
| `admin` | Todo |

`organizer` es un admin recortado, para quien atiende ventanilla el día de la
carrera. **No puede** crear/editar/publicar maratones, subir QR ni afiche, abrir
o cerrar inscripciones, dar la largada, tocar categorías, extras, recorridos,
cargo por servicio ni resultados, confirmar transferencias bancarias, ni
**administrar cuentas que no sean `runner`** (esa última línea es la que sostiene
todas las demás: sin ella se daría `admin` a sí mismo). Al intentarlo:
`INSUFFICIENT_ROLE` (403).

Un administrador solo se crea desde `POST /admin/users`: el registro público
crea `runner` y punto.

### 4.8 Errores de auth

| Código | HTTP | Qué hacer |
|---|---|---|
| `INVALID_CREDENTIALS` | 401 | Error en el formulario. **No** distingue si el email existe |
| `EMAIL_ALREADY_REGISTERED` | 409 | Ofrecer ir a login |
| `INVALID_REFRESH_TOKEN` | 401 | Limpiar storage → Welcome |
| `TOKEN_REUSE_DETECTED` | 401 | Limpiar storage → Welcome. **Nunca reintentar** |
| `INVALID_RESET_TOKEN` | 400 | Ofrecer pedir uno nuevo |
| `INSUFFICIENT_ROLE` | 403 | No reintentar |

---

## 5. Maratones

> Swagger: tags **marathons**, **routes**, **admin**.

### 5.1 El catálogo es público

No exige token. Una maratón publicada es información de difusión: se comparte por
WhatsApp, se abre desde un deep link antes de instalar la app y mañana la lee un
front web. **Inscribirse sí exige token.**

| Método | Ruta | Qué hace |
|---|---|---|
| GET | `/marathons?city=&from=&to=&status=&limit=&cursor=` | Catálogo paginado por cursor |
| GET | `/marathons/upcoming?limit=` | Próximas, para el carrusel del home |
| GET | `/marathons/:slug` | Detalle, con categorías y extras embebidos |
| GET | `/marathons/:id/categories` | Solo las categorías |
| GET | `/marathons/:id/extras` | Solo los extras |

`:slug` y `:id` son **intercambiables** en los tres últimos. El detalle trae
categorías y extras dentro porque son lo que pinta la pantalla; los endpoints
sueltos existen para el paso 2 de la inscripción.

Filtros: `city` (parcial, insensible a mayúsculas), `from`/`to` (fecha de
largada, ISO, inclusivos), `status`, `limit` (1–50, 20 por defecto), `cursor`.

### 5.2 Qué se ve y qué no

Solo se listan las maratones con `publishedAt` **no nulo y ya pasado**. Un
`publishedAt` futuro es un **embargo**: el organizador la deja cargada y la API
la muestra sola a la hora acordada. Lo no publicado da **404** también por slug
directo, así que adivinar la URL no adelanta nada.

### 5.3 `registrationStatus` se **deriva al leer**

La columna de la base guarda la **intención del admin** y solo manda cuando dice
`closed`. Lo que responde la API se calcula en cada lectura, en este orden:

| Orden | Condición | Estado |
|---|---|---|
| 1 | La columna dice `closed` | `closed` |
| 2 | `registrationClosesAt` (o `startsAt` si es null) ya pasó | `closed` |
| 3 | `slotsTaken >= capacity` | `full` |
| 4 | Queda **<10%** del cupo **o** faltan **<7 días** | `closing_soon` |
| 5 | Resto | `open` |

Se deriva en vez de guardarse porque un job que actualizara la columna dejaría al
dato mintiendo entre corrida y corrida — y ese dato decide si alguien puede pagar.
`slotsAvailable` (`capacity - slotsTaken`, nunca negativo) viene ya resuelto: la
UI no lo calcula.

### 5.4 Categorías y extras

- La **categoría** puede llevar recargo (`0` es válido y la línea aparece igual
  en la cotización, para que la UI muestre qué eligió el usuario).
- En los **extras**, `stock: null` significa **sin límite**, no agotado. Para no
  obligar a la UI a aprenderse esa distinción, cada extra trae además
  `available: boolean`, ya resuelto. Máximo **10 unidades** por extra.
- Errores: `INVALID_CATEGORY` (400), `INVALID_EXTRA` (400),
  `EXTRA_OUT_OF_STOCK` (409, el mensaje dice cuántas quedan).

### 5.5 Recorridos preestablecidos

Los trazados que reutilizan las carreras: una ciudad tiene cuatro o cinco
circuitos homologados y cada edición vuelve a usar uno. Públicos
(`GET /routes`, `GET /routes/:idOrSlug?full=`); cargarlos vive en `/admin/routes`.

- **La distancia se mide, no se declara**: `POST /admin/routes` no acepta
  `distanceMeters`, lo calcula sobre la geometría (haversine).
- `POST /admin/marathons` con `routeId` **copia** a la carrera el trazado, la
  distancia y el punto de largada. Editar después el recorrido **no** toca las
  maratones que ya salieron de él.
- La geometría es un `LineString` GeoJSON en orden **`[lng, lat]`**, simplificado
  con Douglas-Peucker y con tope de **2.000 vértices** (`?full=true` para el
  crudo). Una maratón a 1 Hz son ~15.000 puntos que ningún mapa dibuja.

### 5.6 QR de cobro por maratón (temporal)

| Campo | Qué es |
|---|---|
| `paymentQrPayload` | El QR **como texto**. **Sin esto la carrera no admite `qr_manual`** |
| `paymentQrUrl` | Imagen del QR. **Respaldo**: solo se pinta si no hay texto |
| `paymentQrInstructions` | Texto libre que se pinta junto al QR |

`GET /marathons/:slug` los devuelve, para que el cliente sepa si puede ofrecer el
método en vez de prometer un pago imposible. **El QR viaja como texto y lo dibuja
el cliente**: un string son unos bytes donde un PNG son cientos de KB, sale
nítido a cualquier tamaño y se pinta aunque no haya conexión — que es justo lo
que pasa cuando alguien saca el teléfono para pagar. Píntalo oscuro sobre blanco
en los dos temas: un QR es un contraste antes que un adorno.

---

## 6. Inscripciones: los tres pasos

> Swagger: tags **registrations** y **pricing**.

Tres pasos, todos con token, y **todo es del usuario del token**: ninguna ruta
recibe un `userId`. El campo `step` (1..3) de la respuesta dice dónde quedó el
flujo, para retomarlo después de cerrar la app.

| Método | Ruta | Paso | Qué hace |
|---|---|---|---|
| GET | `/registrations?status=&marathonId=` | — | Mis inscripciones |
| POST | `/registrations` | **1** | Crea el borrador con los datos personales |
| GET | `/registrations/:id` | — | Detalle |
| PATCH | `/registrations/:id/category-extras` | **2** | Categoría y adicionales |
| GET | `/registrations/:id/quote` | 2 | Total en vivo, en cada cambio |
| POST | `/registrations/:id/checkout` | **3** | Términos, **cobro**, cupo y dorsal |
| GET | `/registrations/:id/payments` | — | Intentos de cobro, del más nuevo al más viejo |
| DELETE | `/registrations/:id` | — | Cancela y libera el cupo |

### Paso 1 — el borrador

```jsonc
POST /registrations
{ "marathonId": "maraton-la-paz-3600",       // id o slug
  "personalData": {
    "fullName": "Ana Quispe",                 // obligatorio
    "docId": "1234567LP",                     // obligatorio: cruza inscripción con cuenta
    "phone": "70012345",                      // obligatorio: por ahí avisa el organizador
    "email": "ana@example.com",               // opcional a propósito
    "knowsCam": true,                         // obligatorio
    "acceptsDonorCall": false,                // obligatorio
    "emergencyContactName": "…", "emergencyContactPhone": "…",
    "bloodType": "O+", "shirtSize": "M" } }
```

**Es idempotente por maratón:** si ya hay un borrador para esa carrera lo
devuelve actualizado en vez de crear otro. Quien cierra la app en el paso 2 y
vuelve mañana entra por el mismo sitio. Si perdiste el id,
`GET /registrations?marathonId=<slug>` lo recupera. Si ya hay una inscripción
**confirmada**: `ALREADY_REGISTERED` (409).

### Paso 2 — la lista de extras **reemplaza**

```jsonc
PATCH /registrations/:id/category-extras
{ "categoryId": "cat_…",                      // null la quita
  "extras": [{ "extraId": "ext_…", "quantity": 2 }] }   // [] deja sin adicionales
```

`extras` es la selección completa de una pantalla de checkboxes, **no un
incremento**. Cada llamada recotiza y guarda los totales, así que
`GET /registrations/:id/quote` y el detalle siempre coinciden. Los extras se
guardan **resueltos**, con nombre y precio del día.

### Paso 3 — el checkout

Es un cobro: ver **§7**. Lo que hay que retener aquí es **el orden**, porque es
lo que evita que alguien quede cobrado y sin carrera:

1. Se revalida que las inscripciones sigan abiertas, que quede cupo y que estén
   la categoría y los datos personales. **Nadie paga por una carrera cerrada.**
2. **Se recalcula el precio.** No se confía en el total que vio el cliente.
3. Se cobra contra el proveedor.
4. Con el cobro aprobado, y dentro de una transacción con la fila de la maratón
   bloqueada (`SELECT … FOR UPDATE`), se descuenta el stock, se asigna el dorsal
   y se incrementa `slotsTaken`.
5. Si ese último paso falla —el último cupo se fue mientras se procesaba la
   tarjeta— **se reembolsa automáticamente** y se devuelve `MARATHON_FULL`.

### Dorsales

Formato `MLP-0042`: tres letras derivadas del nombre + correlativo de cuatro
dígitos, único por maratón. El correlativo cuenta los dorsales **ya emitidos,
incluidos los de inscripciones canceladas**, así que un número nunca se reutiliza.

### Precios: vivos mientras es borrador, congelados después

| Estado | `items`, `subtotalCents`, `serviceFee`, `totalCents` |
|---|---|
| `draft`, `pending_payment` | Se **recalculan** en cada lectura, con los precios de hoy |
| `confirmed`, `cancelled` | Vienen del **desglose congelado** al confirmar |

Mostrarle a alguien que ya pagó un total distinto del que pagó no es una opción.
`GET /registrations` **no** recotiza: devuelve los totales guardados.

### Cancelación

Solo si la carrera **todavía no ocurrió** (`CANCELLATION_NOT_ALLOWED` si no).
Libera el cupo y devuelve el stock dentro del mismo bloqueo, cierra los cobros
`pending` y **reembolsa** los `paid`. Es **idempotente**. Después se puede volver
a empezar el flujo.

### Errores de inscripción

| Código | HTTP | Qué hacer |
|---|---|---|
| `MARATHON_FULL` | 409 | Volver al detalle: el estado ya dice `full` |
| `REGISTRATION_CLOSED` | 409 | No reintentar |
| `ALREADY_REGISTERED` | 409 | Llevar a la inscripción existente |
| `REGISTRATION_NOT_EDITABLE` | 409 | Ya se confirmó o canceló: recargar |
| `CATEGORY_REQUIRED` | 400 | Volver al paso 2 |
| `CANCELLATION_NOT_ALLOWED` | 409 | No reintentar |

### Precios: `POST /pricing/quote`

Cotización de vista previa **antes** de que exista una inscripción. Público, como
el catálogo: se calcula sobre datos públicos y **no reserva nada**.

```jsonc
POST /pricing/quote
{ "marathonId": "maraton-la-paz-3600", "categoryId": "cat_…",
  "extras": [{ "extraId": "ext_…", "quantity": 2 }] }
```

```jsonc
{ "data": {
    "currency": "BOB",
    "items": [
      { "type": "base",     "label": "Inscripcion",      "quantity": 1, "unitPriceCents": 25000, "amountCents": 25000 },
      { "type": "category", "label": "Elite masculino",  "quantity": 1, "unitPriceCents": 0,     "amountCents": 0 },
      { "type": "extra",    "label": "Remera tecnica",   "quantity": 2, "unitPriceCents": 12000, "amountCents": 24000 }
    ],
    "subtotalCents": 49000, "serviceFee": null, "totalCents": 49000 } }
```

**El precio nunca se calcula en el cliente.** El cliente pinta lo que responde
`/quote`; al confirmar, el backend vuelve a cotizar. Durante el flujo de 3 pasos
usa `GET /registrations/:id/quote`, que cotiza lo guardado.

**`serviceFee: null` no es `0`.** Cuando no hay cargo, el campo viaja como `null`
y la UI **no debe pintar la línea**: un "Cargo por servicio — Bs 0,00" anuncia un
cargo que hoy no se cobra. Hoy está desactivado por defecto.

---

## 7. Pagos

> Swagger: tag **payments**. Documento dedicado: `docs/pago-qr-manual.md`.

El proveedor real está **simulado** detrás de una interfaz (`PaymentProvider`).
El día que entre un PSP de verdad cambia el driver y nada más: ni los endpoints,
ni los estados, ni la tabla.

| Método | Ruta | Qué hace |
|---|---|---|
| POST | `/registrations/:id/checkout` | Paso 3: cobra y confirma. **Requiere `Idempotency-Key`** |
| GET | `/registrations/:id/payments` | Intentos de cobro de esa inscripción |
| GET | `/payments/:id` | Detalle de un pago propio. Es el **polling** del QR |
| GET | `/payments/:id/receipt` | Comprobante en PDF (URL estable) |
| POST | `/payments/:id/proof` | **Temporal** — sube el comprobante de un `qr_manual` |
| GET | `/payments/:id/proof` | **Temporal** — el último comprobante, o `null` |
| POST | `/payments/:id/mock-confirm` | Fuerza el cierre. **Solo desarrollo: 404 en producción** |
| POST | `/payments/webhook` | Eventos del proveedor. **Público**, firmado con HMAC |

### 7.1 Los cuatro métodos

```jsonc
POST /registrations/:id/checkout
Idempotency-Key: <uuid v4 persistido>
{ "termsAccepted": true,                    // tiene que ser exactamente true
  "method": "card",                          // card | qr | bank_transfer | qr_manual
  "card": { "number": "4242424242424242", "holder": "ANA QUISPE",
            "expMonth": 12, "expYear": 2030, "cvv": "123" } }   // solo si method=card
```

La respuesta trae el cobro y la inscripción **juntos** — después de pagar hay que
pintar el dorsal y el estado nuevo, y una segunda llamada dejaría una ventana en
la que el usuario ve "pagado" y "sin dorsal" a la vez:

```jsonc
{ "data": {
    "payment": { "id": "…", "status": "paid", "amountCents": 20000, "currency": "BOB",
                 "methodDetails": { "brand": "visa", "last4": "4242" } },
    "registration": { "status": "confirmed", "bibNumber": "MLP-0001" } } }
```

| `method` | Qué devuelve el checkout | Cómo se cierra |
|---|---|---|
| `card` | `payment.status: "paid"`, inscripción ya `confirmed` | En el mismo request |
| `qr` | `pending` + PNG en `methodDetails.qr` y `expiresAt` | Sondeando `GET /payments/:id` |
| `bank_transfer` | `pending` + datos bancarios en `methodDetails.bank` | Confirmación manual desde el panel |
| `qr_manual` | `pending` + QR del organizador en `methodDetails.manualQr` | El corredor sube comprobante y **un organizador aprueba** |

En los métodos asíncronos la inscripción queda en `pending_payment`, **sin dorsal
y sin cupo tomado**. El cupo se toma en el instante en que el cobro pasa a `paid`.

### 7.2 `qr_manual` — el método que se usa hoy

No hay pasarela contratada. El organizador cobra con el QR de su cuenta bancaria
y **alguien mira los comprobantes**. La API no puede *saber* si un pago entró: no
habla con el banco, así que no lo finge. Lleva la cuenta de **tres hechos
distintos** que la mayoría de los sistemas caseros confunden en uno:

| Hecho | Dónde vive |
|---|---|
| El corredor **vio** el QR | `payments.status = pending`, `method = qr_manual` |
| El corredor **dice** que pagó | `payment_proofs.status = in_review` |
| Un organizador **verificó** que el dinero llegó | `payments.status = paid` |

**Un comprobante subido no confirma la inscripción.** No hay dorsal, no se
descuenta cupo y no se descuenta stock hasta que una persona aprueba.

Flujo desde el cliente:

1. `POST /registrations/:id/checkout` con `method: "qr_manual"`. La respuesta trae
   `payment.methodDetails.manualQr` con `payload` (el QR como texto, que el
   cliente dibuja), `imageUrl` (respaldo, o `null`) y la **glosa**.
2. El corredor paga desde su banca móvil poniendo esa glosa (`PU-A1B2C3`, los
   últimos seis del id de inscripción) — es lo que el organizador cuadra contra
   el extracto. **Muéstrala destacada y con botón de copiar.**
3. `POST /payments/:id/proof` — `multipart/form-data`, campo `file`, `reference`
   opcional. Máx **8 MB**; se reescala a 1600 px y se reencoda a WebP (lo que tira
   el EXIF: un comprobante se saca en casa).
4. El cliente **relee** `GET /payments/:id`, que ahora incluye `proof`. **No
   sondees**: al otro lado no hay un banco que responda en segundos, hay una
   persona que mirará una imagen cuando pueda.

Reglas que sorprenden y no deberían:

- **Rechazar no cierra el cobro.** Lo normal es que la captura fuera la
  equivocada; dejarlo `failed` obligaría a rehacer la inscripción entera.
- **No se puede subir un segundo comprobante mientras hay uno `in_review`.** Para
  corregir, primero hay que rechazar.
- **El cobro caduca a las 48 h** (`PAYMENT_PROOF_TTL_HOURS`), resuelto por la
  siguiente lectura de `GET /payments/:id`, no por un cron. Es un vencimiento
  **blando**: el plazo es para el corredor, no para quien revisa.
- `QR_NOT_CONFIGURED` si la maratón no tiene `paymentQrPayload`.

### 7.3 QR automático (`qr`) — polling

```jsonc
{ "payment": { "status": "pending", "method": "qr",
    "expiresAt": "2026-08-19T15:40:00.000Z",
    "methodDetails": { "qr": { "imageUrl": "…/uploads/payments/qr/….png",
                               "payload": "PACEUP-QR|…|20000|BOB|reg_xyz" } } },
  "registration": { "status": "pending_payment", "bibNumber": null } }
```

Sondea `GET /payments/:id` **cada 2–3 s** y mira `status`. Deja de sondear en
cuanto salga de `pending` — cada lectura resuelve el cobro si ya toca.

| `status` | Qué mostrar |
|---|---|
| `pending` | El QR, con la cuenta atrás hasta `expiresAt` |
| `paid` | Éxito: la inscripción ya tiene dorsal |
| `failed` con `qr_expired` | Ofrecer generar uno nuevo (otro checkout, **clave nueva**) |
| `refunded` | El cobro pasó pero el último cupo se fue: se devolvió el dinero |

### 7.4 Transferencia bancaria

```jsonc
{ "methodDetails": { "bank": {
    "bankName": "Banco Nacional de Bolivia", "accountNumber": "1000-0000-0000",
    "accountType": "Caja de ahorro", "holder": "PaceUp SRL",
    "nit": "0000000000", "reference": "PACEUP-A1B2C3D4" } } }
```

**No caduca y no se paga sola.** Una transferencia entre bancos puede tardar un
día hábil; caducarla dejaría al usuario con el dinero enviado y la inscripción
muerta. Queda `pending` hasta que alguien la confirme desde el panel. **Sondear
no la resuelve.**

### 7.5 Tarjeta

Del número **no se guarda nada** salvo `brand` y `last4`, ni siquiera en
desarrollo. Tarjetas de prueba del mock:

| Número | Resultado |
|---|---|
| `4242 4242 4242 4242` | Aprueba |
| `4000 0000 0000 0002` | Rechaza (`card_declined`) |
| `4000 0000 0000 0069` | Vencida (`expired_card`) |

Cualquier otra estructuralmente válida (Luhn, CVV 3–4 dígitos, fecha futura) se
aprueba. Lo que no pasa esa validación: `invalid_card`.

**Un rechazo no consume nada:** la inscripción queda en `pending_payment`, sin
dorsal y sin cupo, y se reintenta con **clave de idempotencia nueva**. Los
rechazos quedan en el historial de `GET /registrations/:id/payments`.

### 7.6 Comprobante PDF

`GET /payments/:id/receipt` → `{ "url": "…/uploads/payments/receipts/<id>.pdf" }`.
Se genera la primera vez y se cachea; sale de los datos **congelados**, así que la
URL es estable y compartible. **No es una factura**: el propio documento dice que
no está dosificado ante Impuestos Nacionales. Si el cobro no llegó a `paid`:
`RECEIPT_NOT_AVAILABLE` (409).

### 7.7 Webhook (solo backend a backend)

`POST /payments/webhook` es **público** —quien llama es un servidor— y se
autentica con firma HMAC sobre el **cuerpo crudo**:

```
X-Paceup-Signature: t=1755600000,v1=<hmac-sha256 hex de "t.cuerpo">
```

Tipos: `payment.paid`, `payment.failed`, `payment.refunded`. Con firma válida
**siempre responde 200**, aunque el evento no se pueda aplicar
(`{ "received": true, "handled": false, "reason": "unknown_payment" }`): un
proveedor que recibe un error reintenta, y reintentar un evento inaplicable es un
bucle infinito. Solo la firma inválida corta, con
`401 INVALID_WEBHOOK_SIGNATURE`. Las tres operaciones son idempotentes por
estado. **No aplica a un cliente móvil.**

### 7.8 `cancelled` vs `refunded`

| Estado de la inscripción | Cuándo |
|---|---|
| `cancelled` | **El usuario** canceló. Se le devuelve el dinero |
| `refunded` | El **proveedor** devolvió el cobro: devolución, contracargo |

En los dos casos el cupo y el stock vuelven al pozo, y el dorsal se conserva como
registro histórico.

### 7.9 Errores de pago

| Código | HTTP | Qué hacer |
|---|---|---|
| `IDEMPOTENCY_KEY_REQUIRED` | 400 | Bug del cliente: generarla y reintentar |
| `IDEMPOTENCY_KEY_CONFLICT` | 409 | Generar una clave nueva |
| `PAYMENT_DECLINED` | 402 | `details[0].reason` dice por qué. Otro medio + **clave nueva** |
| `PAYMENT_METHOD_NOT_SUPPORTED` | 400 | Ofrecer solo los métodos que habilite `/config/app` |
| `PAYMENT_ALREADY_SETTLED` | 409 | Recargar el detalle |
| `RECEIPT_NOT_AVAILABLE` | 409 | Ocultar el botón hasta que esté `paid` |
| `INVALID_WEBHOOK_SIGNATURE` | 401 | No aplica al cliente |

Motivos de rechazo estables: `card_declined`, `expired_card`, `invalid_card`,
`qr_expired`, `cancelled_by_user`.

---

## 8. Inscripción web pública (sin sesión)

> Swagger: tag **public**. Se apaga entero con `PUBLIC_REGISTRATION_ENABLED=false`.

| Método | Ruta | Qué hace |
|---|---|---|
| POST | `/public/registrations` | Inscribe, crea o vincula la cuenta **por CI**, abre el cobro y devuelve el `publicToken` |
| POST | `/public/registrations/:id/proof` | Sube el comprobante. Token en `X-Public-Token` o `?token=` |
| GET | `/public/registrations/:id` | Estado de la inscripción y del comprobante |

Cuando la persona no tiene cuenta, se le crea con **usuario = su CI normalizada**
y **contraseña = la misma CI**, con `mustChangePassword = true`. La contraseña
inicial es pública a sabiendas: la sabe cualquiera que vea su documento. Por eso
`mustChangePassword` es una **puerta**, no un aviso.

Si ya existe por CI, la inscripción se cuelga de esa cuenta y la ve en la app sin
hacer nada. Si el email teclado pertenece a otra cuenta **con otra CI**:
`EMAIL_ALREADY_REGISTERED`, en vez de decidir cuál de las dos personas es.

El `publicToken` (256 bits) se devuelve **una sola vez** y es lo que autoriza a
subir el comprobante y consultar el estado sin sesión. Reenviar el formulario
emite uno nuevo e invalida el anterior. Límite: **5 req/min por IP**.

---

## 9. Carreras y resultados

> Swagger: tag **races**.

Todo se direcciona por **`registrationId`**, no por el id del resultado: la
inscripción existe desde que el corredor paga y el resultado no nace hasta que
cruza la meta.

```
GET  /races/me/summary
GET  /races/me?status=upcoming|completed
GET  /races/:registrationId
GET  /races/:registrationId/splits
GET  /races/:registrationId/receipt          ← atajo sobre /payments/:id/receipt
POST /races/:registrationId/share-card       ← genera el PNG para compartir
```

Solo aparecen las inscripciones **confirmadas**. El corte entre próximas y
pasadas lo pone `marathon.startsAt`, **no** la existencia del resultado: una
carrera de ayer sin tiempos cargados sigue siendo pasada.

`result` es `null` mientras no haya resultado, y el resto del objeto viene igual
(dorsal, categoría, `kitPickup`, hora de largada). **No es un error**:
`RESULT_NOT_AVAILABLE` (409) donde aplique; oculta splits y tarjeta hasta que
`result` deje de ser `null`.

| Campo | Qué es |
|---|---|
| `finishTimeSeconds` | Tiempo oficial, desde `marathon.startsAt` |
| `chipTimeSeconds` | Reloj del corredor: de su salida a su llegada |
| `overallRank` / `categoryRank` | Puesto general y de categoría. **Los empates comparten puesto** |
| `bestKmIndex` | Índice **base 0** del kilómetro más rápido |
| `shareCardUrl` | PNG para compartir, si ya se generó |

`checkpoints` son los pasos por 5, 10, 15… km con `splitSeconds` desde la largada,
interpolados dentro del tramo que cruza la marca.

---

## 10. Entrenamientos y tracking GPS

> Swagger: tags **workouts** y **tracking**. Documento dedicado: `docs/tracking.md`.

Un entrenamiento tiene dos filas: el **`Workout`** (lo que el usuario ve) y la
**`TrackingSession`** (el canal por el que entran las posiciones). Se crean y se
cierran juntas.

### 10.1 Sesión

| Método | Ruta | Qué hace |
|---|---|---|
| POST | `/workouts/sessions` | Arranca. Devuelve el **`ingestToken`** |
| PATCH | `/workouts/sessions/:id/pause` \| `/resume` | Pausa / reanuda |
| POST | `/workouts/sessions/:id/finish` | Cierra y **consolida** las métricas |
| DELETE | `/workouts/sessions/:id` | Descarta |

```jsonc
POST /workouts/sessions
{ "clientUuid": "<uuid v4 generado ANTES de tener red>",   // obligatorio
  "type": "free_run",         // free_run | plan_session | goal_distance | goal_time | race
  "planSessionId": "…",       // sesión del plan que este entrenamiento cumple
  "registrationId": "…",      // convierte la sesión en CARRERA
  "deviceId": "…", "startedAt": "…" }
```

- **Idempotente por `clientUuid`**: repetir la llamada con el mismo valor devuelve
  la sesión existente. En ese reintento el **`ingestToken` se rota**.
- **Una sola sesión abierta por usuario**: otra con uuid distinto responde
  `SESSION_ALREADY_ACTIVE` con el `sessionId` vivo en `details[0]`.
- Con `registrationId`, la inscripción tiene que estar **`confirmed`**
  (`REGISTRATION_NOT_CONFIRMED`, 409): sin esa comprobación se podría correr —y
  clasificar— sin haber pagado.
- Estados: `active` → `paused` → `active` → `finished` / `discarded`. Cualquier
  otra transición: `SESSION_NOT_ACTIVE`.

### 10.2 El `ingestToken`

`POST /workouts/sessions` lo devuelve **en claro una sola vez**; en la base solo
queda su sha256. **Autentica los lotes de posiciones en lugar del JWT**, porque
es un credencial que sale del teléfono cada 20 segundos: si se filtra, lo único
que permite es mandar puntos a *esa* sesión, y muere al cerrarla. **Guárdalo en
disco junto a la sesión, no en memoria.**

### 10.3 Ingesta de posiciones

```jsonc
POST /api/v1/tracking/sessions/:id/positions
Authorization: Bearer <ingestToken>          // NO el JWT del usuario
{ "points": [
  { "clientPointId": "3f1c…-0", "recordedAt": "2026-08-19T11:02:00.000Z",
    "lat": -16.4957, "lng": -68.1335,
    "altitude": 3625, "speed": 3.4, "accuracy": 8, "heading": 187, "battery": 74 } ] }
```

Respuesta `202`:
`{ "accepted": 28, "duplicated": 2, "rejected": 0, "reasons": { "future": 0, "before_session": 0, "invalid_coordinates": 0 } }`

- **Lotes cada 15–30 s, nunca punto por punto.** Una petición por segundo destroza
  la batería y no aporta nada: el mapa lo pinta el cliente con sus puntos locales.
- **Escribe siempre en la base local primero, red después.** Es lo que hace que
  perder la conexión a mitad de carrera no cueste nada.
- Máx **1000 puntos por lote**. Comprime con gzip.
- **Reenviar un lote es seguro:** dedupe por `(clientPointId, recordedAt)`. Es
  responsabilidad del cliente que `clientPointId` sea **estable entre reintentos**.
- Solo se rechaza lo imposible (`future`, `before_session`,
  `invalid_coordinates`) y **nunca tumba el lote entero**. La precisión mala **no**
  se filtra aquí: se descarta al consolidar.
- Se acepta en `active` **y en `paused`**. Con la sesión cerrada: `409
  SESSION_NOT_ACTIVE`. Token malo: `401 INVALID_INGEST_TOKEN`.

También existen `GET|POST /tracking/osmand` (protocolo de Traccar Client y
relojes baratos, un punto por petición) y `POST /tracking/simulate` (**404 en
producción**), documentados en `docs/tracking.md`.

### 10.4 Consolidación: los números los pone el servidor

`POST /workouts/sessions/:id/finish` recalcula **todo** desde las posiciones:
distancia (haversine), `durationSeconds`, `movingSeconds` (tramos ≥ 0,5 m/s),
`avgPaceSecPerKm`, `elevationGainMeters` (umbral de 3 m), `calories` (**`null` sin
peso en el perfil**), `splits` por km y `bestKmIndex`.

Se descarta antes de medir: puntos con `accuracyMeters > 30`, tramos a más de
12,5 m/s (eso no es un corredor, es el GPS reenganchando) y huecos de más de
120 s. `discardedPoints` dice cuántos se fueron: un número alto es un síntoma, no
un error.

El body acepta `clientReported` con los números del cliente: **se guardan y no se
publican**, solo para detectar deriva. El puesto en una carrera no puede depender
del modelo de teléfono. También acepta `feeling` (1..5) y `notes`.

Al cerrar: la distancia se suma a la **zapatilla principal** (viene en `shoe` con
su `wearAlert` — píntalo en la pantalla de fin) y, si venía de un plan, esa sesión
se marca completada.

**Descartar** (`DELETE /workouts/sessions/:id`) borra las posiciones **de
verdad**: son datos de ubicación y el usuario pidió tirarlos.

### 10.5 Historial y sincronización offline

| Método | Ruta | Qué hace |
|---|---|---|
| POST | `/workouts/sync` | Sube en bloque lo grabado sin red. **Exige `Idempotency-Key`** |
| GET | `/workouts?type=&from=&to=&limit=&cursor=` | Historial, del más reciente al más viejo |
| GET | `/workouts/grouped?by=week\|month&limit=` | Totales por semana o mes |
| GET | `/workouts/stats/weekly?weeks=` | Resumen semanal con la barra de cada día |
| GET | `/workouts/:id` | Detalle con splits |
| DELETE | `/workouts/:id` | Borrado lógico |

En `/workouts/sync`, **un fallo no tumba el lote**: cada entrenamiento se resuelve
por separado y la respuesta dice, uno a uno, qué pasó —`created` (bórralo de la
cola), `duplicated` (**no es un error**: bórralo igual), `rejected` (`reason` dice
por qué; **no lo reintentes**). Topes: 50 entrenamientos por lote, 20.000 puntos
por entrenamiento.

Con `points` manda el servidor (recalcula todo); **sin `points`** el
entrenamiento se guarda como `source: manual` con lo que declaró el usuario — la
única excepción a "la fuente de verdad es el servidor", y no es una concesión:
sin puntos no hay nada que recalcular.

`grouped` y `stats/weekly` cortan las semanas en **hora local**
(`America/La_Paz`), no en UTC, y devuelven **siempre las siete casillas**,
incluidas las vacías. `weekday` va de 1 (lunes) a 7 (domingo); `weekEndsAt` es
**exclusivo**.

### 10.6 Seguimiento en vivo (WebSocket)

```js
const socket = io('https://cam-run.tumype.com/live', {
  auth: { token: accessToken },       // el mismo JWT de la API, en auth y NO en la query
  transports: ['websocket'],
});
await socket.emitWithAck('spectate', { marathonId });   // → { ok: true, room: 'marathon:<id>' }
socket.on('runner:position', ({ bib, lat, lng, distanceMeters, t }) => { /* pintar */ });
await socket.emitWithAck('leave', { marathonId });
```

| Pieza | Valor |
|---|---|
| Namespace | `/live` · Sala `marathon:{id}` |
| Eventos del servidor | `runner:position`, `runner:finish`, `marathon:state` |
| Eventos del cliente | `spectate`, `leave` (los dos con ack) |
| `state` | `not_started` \| `preparing` \| `in_progress` \| `finished` |

**Solo se publican las sesiones con `marathonId`**: la posición de alguien
corriendo por su barrio no tiene espectadores ni debe tenerlos. El payload lleva
**el dorsal y nada más** — ni nombre, ni `userId`, ni id de sesión. Throttle:
máximo una posición por corredor cada 5 s.

**La llegada la decide el servidor**, proyectando el GPS sobre el trazado oficial
(no por distancia recorrida ni por cercanía a la meta: en una ida y vuelta las
dos mienten). El móvil puede estar sin batería justo en el arco; la carrera de
esa persona no puede depender de eso.

---

## 11. Planes de entrenamiento

> Swagger: tag **training-plans**.

Un plan es una **proyección** de una plantilla sobre el calendario del corredor.
La plantilla dice "semana 3, martes, rodaje suave, `paceFactor` 1.15"; el plan
dice "martes 22 de septiembre, 8 km entre 4:56 y 5:21". Toda esa conversión pasa
en el backend.

| Método | Ruta | Token | Qué hace |
|---|---|---|---|
| GET | `/training-plans/templates?goalDistance=&level=&weeks=` | no | Catálogo (no pagina) |
| GET | `/training-plans/templates/:slug` | no | Detalle con todas las sesiones |
| GET | `/training-plans/suggestions?marathonId=` | no | Plantillas que sirven para esa maratón |
| GET | `/training-plans/me` | sí | Plan activo + historial (`active: null` si no hay) |
| GET | `/training-plans/me/current?week=` | sí | Una semana del plan activo (404 sin plan) |
| POST | `/training-plans` | sí | Instanciar |
| PATCH | `/training-plans/sessions/:id/complete` | sí | Marcar hecha (o `skipped: true`) |
| PATCH | `/training-plans/sessions/:id/reschedule` | sí | Mover de día, dentro del plan |
| PATCH | `/training-plans/:id/abandon` | sí | Abandonar |
| POST | `/training-plans/:id/restart` | sí | Volver a empezar |
| DELETE | `/training-plans/:id` | sí | Borrar |

Dos caminos para empezar: **A)** del catálogo (`{ templateId, startDate? }`; sin
fecha arranca el lunes siguiente y cualquier fecha se **redondea hacia adelante**
al lunes). **B)** con maratón objetivo (`{ templateId, marathonId }`; `startDate`
se ignora, la fecha sale de la carrera).

- **`fits: false` no es "descartada"**: entra recortada. Solo desaparecen de la
  lista las que no entran ni recortando. Píntalas con advertencia, no las
  escondas.
- Con maratón objetivo el plan se **ancla por el final** (la última semana es la
  de la carrera). Al recortar se conservan la primera semana y **las dos últimas**
  (el tapering) y se van las de base; las semanas conservadas se **renumeran desde
  1**. Por debajo de 3 semanas: `PLAN_DOES_NOT_FIT`.
- Los ritmos salen de `paceFactor` × `plan.paceBasisSecPerKm`, ±4%.
  `paceMinSecPerKm` es el extremo **más rápido**. Las sesiones `rest` traen los dos
  en `null`. `paceBasisSource` dice si vino de `recent_efforts` o de
  `declared_level` (avisa en pantalla que se afinará solo).
- **Un solo plan activo.** Crear otro responde `PLAN_ALREADY_ACTIVE` con
  `activePlanId` y `activePlanName` en `details[0]`, para que el diálogo diga
  **cuál** se va a abandonar; confirmado, se repite con `replaceActive: true`.

Errores: `PLAN_ALREADY_ACTIVE`, `PLAN_DOES_NOT_FIT`, `PLAN_NOT_ACTIVE`,
`SESSION_NOT_PENDING` (todos 409).

---

## 12. Home

`GET /home/summary` — **un solo endpoint** para toda la pantalla de inicio. Cinco
cosas de cuatro módulos: con un endpoint por cosa, arrancar la app son cinco
peticiones en serie sobre red móvil y cinco oportunidades de que una falle.

```jsonc
{ "featuredMarathon": { "…": "…", "registrationId": null, "bibNumber": null, "isRegistered": false },
  "prediction": { "finishTimeSeconds": 7020, "paceSecPerKm": 333, "confidence": "medium", "basedOn": {}, "reason": null },
  "plan": { "id": "…", "currentWeek": 6, "totalWeeks": 12, "completedSessions": 14 },
  "planWeek": { "week": 6, "sessions": [] },
  "todaySession": { "…": "sesión del plan, o null" },
  "week": { "weekStartsAt": "…", "timezone": "America/La_Paz", "days": [] } }
```

**El pull-to-refresh es volver a llamar aquí.** Nada se cachea en el servidor.

- `featuredMarathon` es **la que el usuario ya pagó** (la cuenta regresiva que le
  importa); sin inscripción por delante cae a la próxima del catálogo.
  `isRegistered` distingue los dos casos.
- `week.days` trae **siempre las siete casillas**, ceros incluidos, cruzando lo
  corrido de verdad con lo que el plan pedía. El cruce es **por fecha**, no por
  día de la semana.
- `prediction` usa la fórmula de **Riegel** sobre el mejor esfuerzo de las últimas
  12 semanas. **`null` no es un error**: con menos de 3 entrenamientos de 2 km,
  responde `200` con `reason: "insufficient_data"` — eso no es un fallo, es un
  corredor que acaba de empezar, y la pantalla tiene que pintarlo **sin un catch**.

---

## 13. Administración

> Swagger: tag **admin**. Todo bajo `/api/v1/admin/*`, rol `admin` salvo lo
> marcado. Límite propio de 60 req/min.

**Aquí vive la lógica del panel**, no en el panel: la página de `/admin` es un
cliente más de estos endpoints, así que un front web nuevo no reimplementa nada.

```
GET    /admin/service-fee                          PUT /admin/service-fee
GET    /admin/service-fee/preview?subtotalCents=&marathonId=
PUT    /admin/marathons/:id/service-fee            DELETE /admin/marathons/:id/service-fee

GET    /admin/marathons                            ← admin | organizer
POST   /admin/marathons                            ← nace como BORRADOR
GET    /admin/marathons/:id                        ← admin | organizer
PUT    /admin/marathons/:id                        ← parcial: null vacía, ausente no toca
DELETE /admin/marathons/:id                        ← se niega con inscritos (CONFLICT)
POST   /admin/marathons/:id/publish | /unpublish
POST   /admin/marathons/:id/close-registrations | /reopen-registrations
POST   /admin/marathons/:id/start | /finish        ← largada y corte de la carrera
GET    /admin/marathons/:id/live                   ← admin | organizer · mapa en vivo
POST   /admin/marathons/:id/cover                  ← afiche (multipart, campo file)
POST   /admin/marathons/:id/qr                     ← QR de cobro, imagen de respaldo
GET    /admin/marathons/:id/registrants.csv        ← admin | organizer · CSV, fuera del sobre

POST   /admin/marathons/:id/categories             PUT|DELETE /admin/categories/:categoryId
POST   /admin/marathons/:id/extras                 PUT|DELETE /admin/extras/:extraId

GET    /admin/registrations?marathonId=&status=
GET    /admin/payments?marathonId=&status=&page=&pageSize=   ← admin | organizer (†)
GET    /admin/payments/pending-transfers
POST   /admin/payments/:id/confirm-transfer
POST   /admin/payments/:id/refund                            ← admin | organizer (†)

POST   /admin/marathons/:id/results                ← cargar tiempos POR DORSAL
POST   /admin/marathons/:id/recalculate-ranks

GET    /admin/users?q=&role=&page=&pageSize=       ← admin | organizer · meta.total
POST   /admin/users                                ← admin | organizer · única forma de crear un admin
PUT    /admin/users/:id                            ← admin | organizer
POST   /admin/users/:id/password                   ← admin | organizer · CIERRA TODAS sus sesiones
DELETE /admin/users/:id                            ← admin | organizer

GET    /admin/payment-proofs                       ← admin | organizer · cola de revisión
POST   /admin/payment-proofs/:id/approve           ← admin | organizer
POST   /admin/payment-proofs/:id/reject            ← admin | organizer

GET    /admin/routes    POST /admin/routes    GET|PUT|DELETE /admin/routes/:id
```

† Estos dos existen en el código pero **todavía no están desplegados**: no
aparecen en `/api/docs` de producción. Verifica antes de usarlos.

Reglas del panel que un cliente nuevo debe respetar:

- Una maratón **nace como borrador** salvo que se mande `published: true`.
  Publicarla sola la metería en el catálogo antes de que nadie la revise.
- Obligatorios en el alta: `name`, `startsAt`, `city`, `distanceMeters`,
  `capacity`, `priceCents`. Sin `slug` se deriva del nombre y se desambigua con
  `-2`, `-3`… en vez de fallar.
- `capacity` **puede bajarse por debajo de lo vendido** y no cancela nada: la
  carrera queda sobrevendida y a la vista en `slotsTaken / capacity`.
- Los **resultados llegan por dorsal**. Un dorsal desconocido no tumba la carga:
  `{ "imported": 128, "skipped": 2, "unknownBibs": ["MLP-9999"] }`. Es idempotente
  y los puestos se recalculan **una sola vez al final**.
- `POST /admin/payments/:id/refund` **anula la inscripción**, no solo mueve dinero:
  el cupo y el stock vuelven al pozo. Solo sobre un cobro `paid`, idempotente,
  `reason` obligatorio.
- `POST /admin/users/:id/password` **cierra todas sus sesiones** (devuelve
  `sessionsRevoked`): un reset que deja vivos los refresh tokens no sirve para lo
  único que se usa de verdad.
- Un admin **no puede quitarse el rol ni borrarse a sí mismo** (`CONFLICT`).
- El CSV lleva BOM UTF-8 (si no, Excel rompe los acentos) y neutraliza las celdas
  que empiezan por `=`, `+`, `-` o `@`: un CSV no debe ejecutar nada al abrirse.

---

## 14. Deep links y enlaces compartidos

```
GET /api/v1/links/marathon/:slug
GET /api/v1/links/workout/:id
GET /api/v1/links/race/:registrationId
```

Devuelven **HTML, no JSON** (no llevan el sobre y no aparecen en Swagger). Hacen
dos trabajos: metadatos **Open Graph** para el bot que rasca el enlace (WhatsApp,
Telegram, Facebook) y **salto a la app** con el esquema propio
(`paceup://marathon/la-paz-21k`, que sale de `/config/app`).

El salto va en un `<script>`, **nunca en un 302**: un redirect dejaría al bot sin
metadatos y la previsualización saldría en blanco.

De una maratón sale todo (es difusión); de un entrenamiento o un resultado sale
lo mínimo y **nunca el nombre del corredor, su recorrido ni sus coordenadas** —
la previsualización de WhatsApp la ve el grupo entero.

---

## 15. Inventario completo (129 operaciones)

Cuenta viva de `/api/docs-json`. **Para el request/response exacto de cualquiera
de estas, ve a https://cam-run.tumype.com/api/docs y búscala por su tag.**

Leyenda de acceso: `—` público · `T` token de usuario · `I` ingestToken ·
`P` publicToken · `A` admin · `A/O` admin u organizer.

<details>
<summary><b>auth</b> (10)</summary>

| | Ruta | Acceso |
|---|---|---|
| POST | `/auth/register` | — |
| POST | `/auth/login` | — |
| POST | `/auth/refresh` | — |
| POST | `/auth/logout` | — |
| POST | `/auth/forgot-password` | — |
| POST | `/auth/reset-password` | — |
| POST | `/auth/change-password` | T |
| GET | `/auth/me` | T |
| GET | `/auth/sessions` | T |
| DELETE | `/auth/sessions/{id}` | T |
</details>

<details>
<summary><b>users</b> (14)</summary>

| | Ruta | Acceso |
|---|---|---|
| GET / PATCH | `/users/me` | T |
| POST / DELETE | `/users/me/avatar` | T |
| GET / PATCH | `/users/me/preferences` | T |
| GET / PATCH | `/users/me/health` | T |
| GET | `/users/me/highlights` | T |
| GET / POST | `/users/me/shoes` | T |
| PATCH / DELETE | `/users/me/shoes/{id}` | T |
| DELETE | `/users/me/data` | T |
</details>

<details>
<summary><b>marathons · routes · pricing · config</b> (10)</summary>

| | Ruta | Acceso |
|---|---|---|
| GET | `/marathons` | — |
| GET | `/marathons/upcoming` | — |
| GET | `/marathons/{slug}` | — |
| GET | `/marathons/{id}/categories` | — |
| GET | `/marathons/{id}/extras` | — |
| GET | `/routes` | — |
| GET | `/routes/{id}` | — |
| POST | `/pricing/quote` | — |
| GET | `/config/app` | — |
| GET | `/home/summary` | T |
</details>

<details>
<summary><b>registrations · payments</b> (14)</summary>

| | Ruta | Acceso |
|---|---|---|
| GET / POST | `/registrations` | T |
| GET / DELETE | `/registrations/{id}` | T |
| PATCH | `/registrations/{id}/category-extras` | T |
| GET | `/registrations/{id}/quote` | T |
| POST | `/registrations/{id}/checkout` | T + `Idempotency-Key` |
| GET | `/registrations/{id}/payments` | T |
| GET | `/payments/{id}` | T |
| GET | `/payments/{id}/receipt` | T |
| POST / GET | `/payments/{id}/proof` | T |
| POST | `/payments/{id}/mock-confirm` | T · **404 en prod** |
| POST | `/payments/webhook` | — (firma HMAC) |
</details>

<details>
<summary><b>public</b> (3)</summary>

| | Ruta | Acceso |
|---|---|---|
| POST | `/public/registrations` | — |
| POST | `/public/registrations/{id}/proof` | P |
| GET | `/public/registrations/{id}` | P |
</details>

<details>
<summary><b>races</b> (6)</summary>

| | Ruta | Acceso |
|---|---|---|
| GET | `/races/me/summary` | T |
| GET | `/races/me` | T |
| GET | `/races/{registrationId}` | T |
| GET | `/races/{registrationId}/splits` | T |
| GET | `/races/{registrationId}/receipt` | T |
| POST | `/races/{registrationId}/share-card` | T |
</details>

<details>
<summary><b>workouts · tracking</b> (15)</summary>

| | Ruta | Acceso |
|---|---|---|
| POST | `/workouts/sessions` | T |
| PATCH | `/workouts/sessions/{id}/pause` | T |
| PATCH | `/workouts/sessions/{id}/resume` | T |
| POST | `/workouts/sessions/{id}/finish` | T |
| DELETE | `/workouts/sessions/{id}` | T |
| POST | `/workouts/sync` | T + `Idempotency-Key` |
| GET | `/workouts` | T |
| GET | `/workouts/grouped` | T |
| GET | `/workouts/stats/weekly` | T |
| GET / DELETE | `/workouts/{id}` | T |
| POST | `/tracking/sessions/{id}/positions` | **I** |
| GET / POST | `/tracking/osmand` | `?id=` del dispositivo |
| POST | `/tracking/simulate` | I · **404 en prod** |
</details>

<details>
<summary><b>training-plans</b> (11)</summary>

| | Ruta | Acceso |
|---|---|---|
| GET | `/training-plans/templates` | — |
| GET | `/training-plans/templates/{slug}` | — |
| GET | `/training-plans/suggestions` | — |
| GET | `/training-plans/me` | T |
| GET | `/training-plans/me/current` | T |
| POST | `/training-plans` | T |
| PATCH | `/training-plans/sessions/{id}/complete` | T |
| PATCH | `/training-plans/sessions/{id}/reschedule` | T |
| PATCH | `/training-plans/{id}/abandon` | T |
| POST | `/training-plans/{id}/restart` | T |
| DELETE | `/training-plans/{id}` | T |
</details>

<details>
<summary><b>admin</b> (44)</summary>

Ver la lista agrupada en **§13**. Todos exigen `A` salvo los marcados `A/O`.
</details>

<details>
<summary><b>Fuera del prefijo</b></summary>

| | Ruta |
|---|---|
| GET | `/health`, `/ready` |
| GET | `/api/docs`, `/api/docs-json` |
| GET | `/admin` (panel HTML) |
| GET | `/api/v1/links/{marathon\|workout\|race}/…` (HTML, no en Swagger) |
| WS | `/live` (socket.io) |
| GET | `/uploads/**` (binarios públicos, caché de 30 días, `immutable`) |
</details>

---

## 16. Orden de implementación recomendado

1. **Infraestructura de red.** Cliente HTTP con `baseUrl` inyectada, sobre
   `{ data, meta }` desenvuelto en un interceptor, errores mapeados **por
   `error.code`** a un tipo propio, y el **mutex del refresh** (§4.3). Esto
   primero: todo lo demás se apoya aquí y rehacerlo después duele.
2. **Arranque:** `GET /config/app` + gate de `minAppVersion` + refresh
   silencioso (§3).
3. **Auth:** registro, login por `identifier`, la puerta de `mustChangePassword`,
   almacenamiento seguro de tokens, `deviceId` persistido (§4).
4. **Catálogo:** `/marathons` con paginación por cursor y `/marathons/:slug`.
   Aquí ya tienes algo que enseñar (§5).
5. **Inscripción de 3 pasos + cotización** (§6). El paso 3 todavía no.
6. **Pagos:** empieza por `qr_manual`, que es lo que se usa hoy (§7.2). `card`
   y `qr` después, si llega una pasarela.
7. **Home** (`/home/summary`) y **Races** (§9, §12).
8. **Perfil, preferencias, zapatillas** (§4.6).
9. **Tracking GPS**: base local primero, lotes después, `ingestToken` en disco
   (§10). Es la parte más delicada del cliente.
10. **Planes de entrenamiento** (§11) y **live tracking** (§10.6).

---

## 17. Cuentas de prueba

Solo existen si la base se sembró (`npm run db:seed`). **Confirma antes de usar
que no siguen activas en producción.**

| Cuenta | CI | Rol | Contenido |
|---|---|---|---|
| `runner@test.com` | `6789012LP` | runner | **La única con actividad**: 4 meses de entrenamientos con GPS, un plan de 21K a mitad, 4 inscripciones (pagada, esperando QR, corrida con resultado, reembolsada), 3 pares de zapatillas |
| `runner2@test.com` | `5544332CB` | runner | Vacía a propósito: con ella se comprueba que los datos de uno no se ven desde la sesión de otro |
| `admin@test.com` | `1000001LP` | admin | |
| `organizer@test.com` y `organizer2@`, `organizer3@` | `2000001LP`, `2000002CB`, `2000003SC` | organizer | |

Contraseña de todas: `Test1234!`. Sirven también por CI en el campo `identifier`.

---

## 18. Diez trampas, en una lista

1. **Refresh sin mutex** → el servidor detecta reuso y cierra la sesión. Es el
   error nº 1 contra esta API.
2. **Serializar todos los campos en un PATCH** → borras lo que el usuario no tocó.
3. **Mandar un campo de más** → `400 VALIDATION_ERROR`, no se ignora.
4. **Calcular el precio en el cliente** → el backend recotiza y no coincidirá.
5. **Pintar "Cargo por servicio Bs 0,00"** cuando `serviceFee` es `null`.
6. **Guardar la `Idempotency-Key` en memoria** → un corte de red = segundo cobro.
7. **Reintentar un pago rechazado con la misma clave** → devuelve el mismo rechazo.
8. **Sondear una transferencia bancaria o un `qr_manual`** → no se resuelven solos.
9. **Cuentas regresivas contra el reloj del teléfono** → usa `meta.timestamp`.
10. **Paginar hasta que una página venga vacía** → pagina hasta `nextCursor: null`.
11. *(bonus)* **Mandar el JWT en la ingesta de posiciones** → va el `ingestToken`.
12. *(bonus)* **Tratar `prediction: null` o `result: null` como error** → no lo son.
