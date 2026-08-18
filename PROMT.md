# PROMPT — Backend Node.js para app de maratones (Flutter)

> Pásale este archivo completo a Claude Code como primer mensaje, o guárdalo en la raíz del backend como `PROMPT.md` y dile: "Lee PROMPT.md y empieza por la Fase 0".

---

## 0. REGLAS DE TRABAJO INNEGOCIABLES (léelas antes que nada)

### 0.1 Git: tú NO manejas el control de versiones

**Nunca** ejecutes ninguno de estos comandos, bajo ninguna circunstancia, ni aunque te parezca lo más práctico:

`git add`, `git commit`, `git push`, `git pull`, `git fetch`, `git merge`, `git rebase`, `git reset`, `git restore`, `git checkout`, `git switch`, `git branch`, `git tag`, `git stash`, `git revert`, `git cherry-pick`, `git clean`, `git init`, `gh pr create`, `npm version`, `changeset`, ni ningún script que envuelva a estos.

**Sí puedes** ejecutar comandos de solo lectura para orientarte: `git status`, `git diff`, `git log --oneline -n 20`.

Tampoco toques el versionado: no subas la versión en `package.json`, no crees ni edites `CHANGELOG.md` salvo que yo lo pida, no crees tags ni releases.

Sí puedes crear y editar `.gitignore` como cualquier archivo de código (solo el archivo, sin ejecutar git).

### 0.2 Protocolo de PAUSA PARA COMMIT

Al terminar **cada fase** (y cada checkpoint que yo marque), detente y entrega exactamente esto:

1. **Resumen** de lo implementado, 3–6 viñetas.
2. **Archivos tocados**, separados en creados / modificados / eliminados.
3. **Cómo lo verifico yo**: comandos concretos (`npm run test`, `curl ...`) y qué debería ver.
4. **Mensaje de commit sugerido** en formato Conventional Commits, en bloque de código, listo para copiar.
5. La línea literal:

   ```
   ⏸ PAUSA — haz el commit y escribe "continuar" cuando esté listo.
   ```

Después de esa línea **no escribas ni ejecutes nada más**. Espera mi respuesta.

### 0.3 Tamaño de las fases

Si una fase se está haciendo enorme (más de ~15 archivos nuevos o ~800 líneas), **párate antes de terminarla**, propón subdividirla en checkpoints y espera mi confirmación. Prefiero muchos commits pequeños y revisables.

### 0.4 Decisiones

Si una decisión técnica no está resuelta aquí y es difícil de revertir (esquema de BD, contrato de API, protocolo de tracking), **pregúntame antes**. Si es fácilmente reversible, decide tú y anótala en `docs/decisiones.md` con una línea de justificación.

No inventes librerías ni versiones: antes de usar un paquete que no conozcas con certeza, verifica que existe y su API actual (npm / pub.dev / docs oficiales).

---

## 1. CONTEXTO Y ESTRUCTURA DE REPOSITORIOS

Tengo una **app móvil en Flutter casi terminada** (solo UI + datos mock) para seguimiento de maratones y entrenamiento de running. Necesito el **backend en Node.js** que la alimente, más la **capa de integración del lado Flutter**.

**Repositorios separados**, en carpetas hermanas:

```
/running-app     ← proyecto Flutter existente (NO lo reestructures)
/running-api     ← backend nuevo, lo creas tú desde cero
```

Crea el backend en `running-api/`, hermana de `running-app/`. No metas el backend dentro del proyecto Flutter ni conviertas nada en monorepo.

**Datos del proyecto:**

| Parámetro | Valor |
|---|---|
| Despliegue | **VPS propio** (Linux, Docker Compose, proxy inverso con TLS) |
| Moneda | **BOB** (boliviano). Montos en centavos, formato `Bs 1.234,56` en el cliente |
| Zona horaria por defecto | `America/La_Paz` |
| Service fee | **Opcional y configurable**: el admin puede desactivarlo por completo |
| Panel de admin | Sí, **sencillo** |
| Stack | NestJS + Prisma + PostgreSQL (confirmado) |
| Tracking GPS | **Ingesta nativa en Node** (ver sección 7) |

Requisitos que me importan especialmente:

- **Sesión larga**: el usuario no vuelve a loguearse en al menos **2 meses**.
- **Offline-first**: los entrenamientos individuales se guardan primero en local y se sincronizan después.
- **Pagos simulados** por ahora, detrás de una interfaz que permita enchufar un proveedor real sin reescribir el módulo.
- Backend pensado para que **más adelante se le monte un front-end web**: API limpia, versionada y documentada.
- Preparado para, en el futuro, **seguir en vivo a todos los corredores de una maratón** en un mapa.

---

## 2. STACK Y DECISIONES TÉCNICAS

| Área | Elección |
|---|---|
| Runtime | Node.js LTS (20+) |
| Lenguaje | TypeScript estricto (`strict: true`) |
| Framework | **NestJS** |
| ORM | **Prisma** |
| Base de datos | **PostgreSQL 16** |
| Geo | Columnas `lat`/`lng` (`double precision`) + índices. PostGIS solo si hace falta, como migración opcional documentada |
| Posiciones GPS | Tabla `positions` **particionada por mes** |
| Cache / colas | **Redis** (ioredis) + BullMQ |
| Tiempo real | **Socket.IO** con adapter de Redis |
| Validación | `class-validator` + `class-transformer` en DTOs; `zod` para env |
| Auth | JWT access + refresh opaco rotativo en BD (sección 5) |
| Hashing | `argon2` |
| Logs | `pino` + `nestjs-pino`, request-id por petición |
| Docs API | Swagger/OpenAPI en `/api/docs` |
| Panel admin | **AdminJS** con adaptador de Prisma (sección 9) |
| Imágenes | `sharp` (avatares, tarjetas de resultado). Nada de Puppeteer |
| PDF | `pdfkit` (comprobantes) |
| Tests | Jest (unit) + Supertest (e2e) contra Postgres en Docker |
| Contenedores | `docker-compose.yml`: `postgres`, `redis`, `api`, `caddy` |
| Proxy / TLS | **Caddy** (certificados automáticos, menos fricción que nginx + certbot en un VPS) |
| Lint/format | ESLint + Prettier. **Sin husky ni git hooks** (regla 0.1) |

---

## 3. ARQUITECTURA DEL PROYECTO

```
/running-api
  /src
    /modules
      /auth              ← login, registro, refresh, logout, recuperación
      /users             ← perfil, preferencias, zapatillas, salud
      /marathons         ← catálogo, detalle, categorías, extras
      /registrations     ← inscripción en 3 pasos, dorsal, cancelación
      /payments          ← proveedor mock detrás de una interfaz
      /pricing           ← quote, service fee configurable
      /training-plans    ← catálogo de planes, instanciación, sesiones
      /workouts          ← entrenamientos, splits, historial, estadísticas
      /tracking          ← ingesta de posiciones, sesiones activas
      /races             ← resultados, métricas, comprobantes
      /devices           ← registro de dispositivos
      /realtime          ← gateway Socket.IO
      /admin             ← endpoints de administración + montaje de AdminJS
      /notifications     ← stub preparado para push
    /common              ← guards, interceptors, filters, decorators, pipes
    /config              ← configuración tipada por entorno
    /database            ← Prisma service, seeds
  /prisma
    schema.prisma
    /migrations
  /test
  /docs
    api.md
    tracking.md
    despliegue.md
    decisiones.md
    flutter-integracion.md
  /docker
    docker-compose.yml
    docker-compose.prod.yml
    Caddyfile
```

Reglas transversales:

- Prefijo de API: **`/api/v1`**, versionado por URI.
- Sobre de respuesta consistente:
  ```json
  { "data": {}, "meta": { "requestId": "...", "timestamp": "..." } }
  ```
  y en error:
  ```json
  { "error": { "code": "MARATHON_FULL", "message": "...", "details": [] },
    "meta": { "requestId": "..." } }
  ```
  Códigos de error como enum de TypeScript, listados en `docs/api.md`, para que Flutter mapee por `code` y no por texto.
- **Unidades base**: distancias en **metros**, duraciones en **segundos**, dinero en **centavos** (entero) + `currency: "BOB"`, fechas **ISO-8601 UTC**. El formateo (km/mi, min/km, `Bs`) es del cliente. Cada maratón guarda su `timezone` IANA (por defecto `America/La_Paz`).
- Paginación por cursor en listados largos: `?limit=&cursor=`, respuesta con `meta.nextCursor`.
- Idempotencia: header `Idempotency-Key` en pagos y en sincronización masiva de entrenamientos.
- Rate limiting global, más estricto en `/auth/*` y en ingesta de posiciones.
- Soft delete donde borrar duele (entrenamientos, inscripciones): `deletedAt`.

---

## 4. MODELO DE DATOS

Mínimo esperado en `schema.prisma`. Ajusta nombres y agrega lo que falte, pero no quites nada.

**Identidad y perfil**
- `User`: email (único, citext), passwordHash, name, role (`runner` | `admin`), emailVerifiedAt, createdAt.
- `UserProfile`: userId, avatarUrl, city, country (default `BO`), birthDate, gender, weightGrams, heightCm, defaultBibNumber, injuryFlags (jsonb), avgSleepMinutes, hydrationHabit.
- `UserPreferences`: units (`metric` | `imperial`), theme (`light` | `dark` | `system`), notifications (jsonb), privacy (jsonb), onboardingSeenAt, locale (default `es-BO`).
- `Shoe`: userId, brand, model, distanceMeters, alertThresholdMeters, isPrimary, retiredAt.
- `AuthSession`: userId, refreshTokenHash, deviceId, deviceName, platform, ip, userAgent, expiresAt, revokedAt, rotatedFromId, lastUsedAt.
- `PasswordResetToken`: userId, tokenHash, expiresAt, usedAt.

**Maratones e inscripciones**
- `Marathon`: slug, name, description, startsAt, timezone, city, country, lat, lng, distanceMeters, capacity, slotsTaken, priceCents, currency, registrationStatus (`open` | `closing_soon` | `full` | `closed`), routeGeoJson (jsonb), schedule (jsonb), includes (jsonb), coverUrl, kitPickup (jsonb), registrationClosesAt, publishedAt, **serviceFeeConfigId (nullable → override del global)**.
- `MarathonCategory`: marathonId, name, minAge, maxAge, gender, extraPriceCents.
- `MarathonExtra`: marathonId, name (remera, medalla, transporte…), priceCents, stock.
- `ServiceFeeConfig`: scope (`global` | `marathon`), **enabled (boolean)**, type (`percent` | `fixed` | `mixed`), percentBps (basis points), fixedCents, minCents, maxCents, label, updatedByUserId, updatedAt.
- `Registration`: userId, marathonId, categoryId, status (`draft` | `pending_payment` | `confirmed` | `cancelled` | `refunded`), step (1..3, para retomar el flujo), bibNumber (único por maratón), personalData (jsonb), extras (jsonb), subtotalCents, **serviceFeeCents + serviceFeeSnapshot (jsonb)**, totalCents, currency, termsAcceptedAt, registeredAt, cancelledAt.
- `Payment`: registrationId, provider (`mock`), method (`card` | `qr` | `bank_transfer`), status (`pending` | `paid` | `failed` | `refunded`), amountCents, currency, methodDetails (jsonb, **solo datos enmascarados**), idempotencyKey (único), receiptUrl, externalId, paidAt, refundedAt, failureReason.

**Entrenamiento**
- `TrainingPlanTemplate`: slug, name, description, goalDistanceMeters (5K / 10K / 21K / 42K), level (`beginner` | `intermediate` | `advanced`), totalWeeks, weeklySessions, avgWeeklyDistanceMeters, coverUrl, isActive.
- `TrainingPlanTemplateSession`: templateId, week (1..N), weekday (1..7), type (`easy` | `tempo` | `intervals` | `long` | `rest` | `recovery`), targetDistanceMeters, targetDurationSeconds, **paceFactor** (multiplicador sobre el ritmo base del usuario, ej. 1.15 = ritmo suave), description, isKeySession.
- `TrainingPlan` (instancia del usuario): userId, templateId, marathonId (nullable), name, totalWeeks, startDate, endDate, paceBasisSecPerKm, status (`active` | `completed` | `abandoned`), isActive.
- `TrainingPlanSession`: planId, templateSessionId, week, weekday, scheduledDate, type, targetDistanceMeters, targetDurationSeconds, paceMinSecPerKm, paceMaxSecPerKm, suggestedRoute (jsonb), status (`pending` | `completed` | `skipped` | `rescheduled`), rescheduledFromDate, workoutId.
- `Workout`: userId, **clientUuid (único)**, source (`app` | `manual` | `external`), type (`free_run` | `plan_session` | `goal_distance` | `goal_time` | `race`), planSessionId, registrationId (si es carrera), startedAt, endedAt, durationSeconds, movingSeconds, distanceMeters, avgPaceSecPerKm, avgSpeedMps, elevationGainMeters, calories, bestKmIndex, feeling (1..5), notes, isSynced, deletedAt.
- `WorkoutSplit`: workoutId, index, distanceMeters, durationSeconds, paceSecPerKm, elevationGainMeters.
- `WorkoutLap`: workoutId, index, targetPaceSecPerKm, actualPaceSecPerKm, durationSeconds (para el "Lap 6/10").
- `Position` (**particionada por mes**): trackingSessionId, workoutId (nullable), userId, deviceId, recordedAt, receivedAt, lat, lng, altitude, speedMps, accuracyMeters, heading, batteryLevel, source (`app_batch` | `osmand` | `traccar`), clientPointId (dedupe).
- `TrackingSession`: userId, workoutId, marathonId (nullable), deviceId, status (`active` | `paused` | `finished` | `discarded`), ingestToken (hash), startedAt, lastPositionAt, finishedAt.
- `Device`: userId, uniqueId (único, uuid), name, platform, appVersion, osVersion, lastSeenAt, pushToken.

**Carreras**
- `RaceResult`: registrationId, workoutId, finishTime, chipTime, avgPaceSecPerKm, avgSpeedMps, distanceMeters, elevationGainMeters, bestKmIndex, overallRank, categoryRank, finishedAt, shareCardUrl.
- `RaceCheckpoint`: raceResultId, kmMark, lat, lng, passedAt, splitSeconds (marcadores cada 5 km).

**Índices obligatorios:** `Position(trackingSessionId, recordedAt)`, `Position(userId, recordedAt)`, `Position(clientPointId)` único parcial, `Workout(userId, startedAt DESC)`, `Registration(userId, status)`, `Registration(marathonId, bibNumber)` único, `AuthSession(refreshTokenHash)`, `Marathon(startsAt)`, `TrainingPlan(userId, isActive)`.

---

## 5. AUTENTICACIÓN Y SESIÓN DE 2 MESES

Punto crítico: **el usuario no debe volver a loguearse durante al menos 60 días de uso normal.**

- **Access token**: JWT HS256, **TTL 15 minutos**, payload mínimo (`sub`, `role`, `sessionId`, `iat`, `exp`).
- **Refresh token**: string opaco de 256 bits (`crypto.randomBytes`), **TTL 60 días**, guardado en BD **solo como hash**.
- **Rotación deslizante**: cada `POST /auth/refresh` invalida el token usado y emite uno nuevo con `expiresAt` recalculado a 60 días desde ahora. Mientras el usuario abra la app cada tanto, la sesión nunca caduca.
- **Detección de reuso**: si llega un refresh token ya rotado, revoca **toda la cadena de sesiones de ese dispositivo** y responde `401 TOKEN_REUSE_DETECTED`.
- **Multi-dispositivo**: una `AuthSession` por dispositivo (`deviceId` persistido por la app). Endpoints para listar y cerrar sesiones.
- **Logout**: marca `revokedAt`, no borra la fila.
- **Rol admin**: guard `@Roles('admin')` sobre `/api/v1/admin/*` y sobre el panel.

En Flutter:
- Tokens en **`flutter_secure_storage`** (Keychain / Keystore), nunca en `SharedPreferences`.
- Interceptor de **Dio** que adjunta el access token, ante `401` dispara **un solo** refresh (con mutex para peticiones paralelas), reintenta la original y, si el refresh falla, limpia storage y va a Welcome.
- Guard de navegación: sin refresh válido → Welcome; sin `onboardingSeenAt` → slides.
- `onboardingSeenAt` se persiste local **y** en el backend (sobrevive a reinstalaciones).

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/sessions
DELETE /api/v1/auth/sessions/:id
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
GET    /api/v1/auth/me
```

Los botones sociales (Google, LinkedIn, Facebook) son **solo UI** por ahora: deja el módulo preparado con una estrategia stub y documenta en `docs/decisiones.md` qué falta para activarlos. No implementes el flujo real.

---

## 6. MÓDULOS Y ENDPOINTS POR SECCIÓN DE LA APP

### 6.1 Onboarding
- `GET/PATCH /users/me/preferences` → `onboardingSeenAt`, tema, unidades, idioma.

### 6.2 Home
- `GET /marathons/upcoming?limit=` → carrusel.
- `GET /home/summary` → **endpoint agregado**, una sola llamada al arrancar: maratón destacada con `startsAt` (la cuenta regresiva la calcula el cliente contra `meta.timestamp`), tiempo de llegada estimado, semana actual del plan, tira Mon–Sun con progreso y distancia por día, sesión de hoy.
- `GET /training-plans/me/current?week=` → selector de semana.
- `PATCH /training-plans/sessions/:id/complete`
- `PATCH /training-plans/sessions/:id/reschedule`
- Pull-to-refresh = volver a llamar `/home/summary` con `Cache-Control: no-cache`.

**Tiempo estimado de llegada:** servicio `PredictionService` con la fórmula de **Riegel** (`T2 = T1 × (D2/D1)^1.06`) sobre el mejor esfuerzo reciente (últimas 8–12 semanas), ajustado por volumen semanal medio. Devuelve `null` con `reason: "insufficient_data"` si hay menos de 3 entrenamientos. Documenta la fórmula en `docs/decisiones.md`.

### 6.3 Maratones e inscripción
```
GET    /marathons?city=&from=&to=&status=&cursor=
GET    /marathons/:slug
GET    /marathons/:id/categories
GET    /marathons/:id/extras
POST   /registrations                        ← paso 1: draft con datos personales
PATCH  /registrations/:id/category-extras    ← paso 2
GET    /registrations/:id/quote              ← total en vivo
POST   /registrations/:id/checkout           ← paso 3: pago + términos → dorsal
DELETE /registrations/:id                    ← cancelar (solo si la carrera no ocurrió)
```

- **`QuoteService` (módulo `pricing`)** es la única fuente del total: cuota base + categoría + extras + **service fee resuelto**. La resolución del fee es: override de la maratón → config global → si `enabled = false`, `serviceFeeCents = 0` y el campo **no se muestra** en la respuesta (`serviceFee: null`), para que la UI no pinte una línea "Bs 0,00". El cliente llama a `/quote` en cada cambio. **El precio nunca se calcula en el móvil.**
- Al confirmar se guarda `serviceFeeSnapshot` con la configuración exacta aplicada, para que cambiar el fee después **no altere comprobantes históricos**.
- **Cupos**: al confirmar, incrementa `slotsTaken` en una **transacción con `SELECT ... FOR UPDATE`**; falla con `MARATHON_FULL` si no hay lugar. `registrationStatus` se recalcula a `closing_soon` cuando queda <10% de cupo o faltan <7 días.
- **Dorsal**: secuencial por maratón (`prefijo + correlativo`), asignado en la misma transacción del pago confirmado, con constraint único `(marathonId, bibNumber)`.
- **Cancelación**: solo si `marathon.startsAt > now()`. Libera cupo, marca el pago como `refunded` (mock), registra `cancelledAt`.

### 6.4 Planes de entrenamiento (simplificado, elegible por el usuario)

Dos caminos, ambos deben funcionar:

**A. El usuario elige un plan del catálogo**
```
GET  /training-plans/templates?goalDistance=&level=&weeks=
GET  /training-plans/templates/:slug
POST /training-plans          { templateId, startDate }
```

**B. El usuario elige una maratón objetivo y el backend le sugiere planes**
```
GET  /training-plans/suggestions?marathonId=
POST /training-plans          { templateId, marathonId }
```
La sugerencia filtra plantillas cuya `goalDistanceMeters` coincida con la distancia de la maratón y cuyo `totalWeeks` quepa en las semanas disponibles hasta `startsAt`. Devuelve cada opción con `weeksAvailable`, `fits: boolean` y `level`, ordenadas por ajuste.

**Instanciación** (`TrainingPlanInstantiationService`):
- Materializa `TrainingPlanSession` con fechas reales.
- Si hay maratón objetivo, **ancla el final del plan a la semana de la carrera** (la última semana es el tapering).
- Si quedan menos semanas que las de la plantilla, **recorta desde las semanas de base (el medio), nunca del tapering ni de la primera semana**.
- Personaliza los ritmos: `paceBasisSecPerKm` sale del mejor esfuerzo reciente vía Riegel; si no hay datos, del `level` autodeclarado. Cada sesión calcula su rango con `paceFactor ± 4%`.

**Gestión:**
```
GET    /training-plans/me            ← plan activo + historial de planes
PATCH  /training-plans/:id/abandon
POST   /training-plans/:id/restart   { startDate }
DELETE /training-plans/:id
```
Solo **un plan activo a la vez** (`isActive`); activar otro marca el anterior como `abandoned` previa confirmación del cliente.

Catálogo inicial en seeds: 8 plantillas (5K/10K/21K/42K × principiante/intermedio), de 8 a 16 semanas, 3–5 sesiones por semana.

### 6.5 Train (workouts)
```
POST   /workouts/sessions                    ← inicia tracking, devuelve ingestToken
PATCH  /workouts/sessions/:id/pause|resume
POST   /workouts/sessions/:id/finish         ← consolida métricas y splits
DELETE /workouts/sessions/:id                ← descartar
POST   /workouts/sync                        ← subida masiva offline (Idempotency-Key)
GET    /workouts?type=&from=&to=&cursor=     ← historial filtrado
GET    /workouts/grouped?by=week|month
GET    /workouts/:id
DELETE /workouts/:id
GET    /workouts/stats/weekly?weeks=         ← resumen semanal + barras por día
```

- **Consolidación en el backend**: al recibir `finish` o un `sync`, recalcula desde las posiciones: distancia (Haversine acumulado descartando puntos con `accuracy > 30 m` y saltos de velocidad imposibles), splits por km, ritmo medio y mejor km, ganancia de elevación (umbral de 3 m para filtrar ruido), velocidad media y calorías (MET según peso y ritmo). **No confíes en los números del cliente**: guárdalos como `clientReported*` para comparar, pero la fuente de verdad es el servidor.
- **Auto-pausa**: la detecta el cliente; el backend recibe los eventos y usa `movingSeconds` vs `durationSeconds`.
- **Modo simulación de GPS**: `POST /tracking/simulate` (solo si `NODE_ENV !== 'production'`, protegido por flag de config), reproduce un track GeoJSON a velocidad configurable. Sirve para probar sin salir a correr.
- Permisos de ubicación, cuenta regresiva 3-2-1, control de música, bloqueo del back físico y re-centrado del mapa son **puramente del cliente**.

### 6.6 Races
```
GET  /races/me/summary                  ← cuántas maratones corriste, distancia total, total gastado
GET  /races/me?status=upcoming|completed
GET  /races/:registrationId
GET  /races/:registrationId/splits
GET  /races/:registrationId/receipt     ← comprobante mock
POST /races/:registrationId/share-card  ← tarjeta de imagen del resultado
```
- El detalle devuelve el recorrido (GeoJSON **simplificado con Douglas-Peucker**, para no mandar 20.000 puntos al móvil) + checkpoints cada 5 km + métricas completas (tiempo de llegada, chip time, ritmo y velocidad medios, distancia, elevación, mejor km, puesto general y por categoría).
- Próximas: cuenta regresiva, dorsal, info logística (`kitPickup`, hora de largada).
- **Tarjeta de imagen**: PNG generado con `sharp`, guardado vía interfaz `StorageService` (driver local en `/uploads`, cambiable a S3 después).
- **Total gastado** = suma de `Payment.amountCents` con status `paid` menos reembolsos. No sumes precios de maratón.

### 6.7 Profile
```
GET    /users/me
PATCH  /users/me                    ← nombre, email, ciudad, nacimiento, género, peso, altura
POST   /users/me/avatar             ← multipart, máx 5 MB, valida tipo real y redimensiona
GET/PATCH /users/me/preferences
GET/POST/PATCH/DELETE /users/me/shoes
GET/PATCH /users/me/health          ← injury flags, sueño, hidratación
GET    /users/me/highlights         ← kilometraje semanal, carrera más larga
```
- **Km de zapatillas** se acumulan automáticamente: al consolidar un workout, suma la distancia a la zapatilla principal de ese momento. Emite `shoe.wear_alert` al superar `alertThresholdMeters` (default 800 km).

### 6.8 Transversales
- `GET /health`, `GET /ready`.
- `GET /config/app` → constantes que el cliente no debe hardcodear: si el service fee está activo, umbrales, moneda, versión mínima soportada de la app.
- **Deep links**: `GET /links/marathon/:slug`, `/links/workout/:id`, `/links/race/:id` con metadatos Open Graph + redirección al esquema de la app. Formato documentado en `docs/api.md`.
- Notificaciones: módulo stub con interfaz `NotificationService` y driver `console`, con el enganche a FCM documentado.
- `DELETE /users/me/data` → borrado de cuenta en cascada.

---

## 7. TRACKING GPS — INGESTA NATIVA EN NODE

> **Decisión tomada:** se descartó montar un servidor Traccar. Sus ~200 protocolos de hardware no aportan nada a una app de celulares, la parte difícil (mantener el GPS vivo en segundo plano) la resuelve el plugin de Flutter y no el servidor, y en un VPS propio la JVM costaría ~700 MB de RAM. Se implementa la ingesta directamente en Node, **dejando la puerta abierta** con los dos puntos de la sección 7.4. Documenta este razonamiento en `docs/decisiones.md`.

### 7.1 Flujo

```
App Flutter
  ├─▶ escribe cada punto en base local (drift)   ← siempre, primero
  └─▶ envía LOTES cada 15–30 s ──▶ POST /api/v1/tracking/sessions/:id/positions
                                          │
                              ┌───────────┴───────────┐
                              ▼                       ▼
                     Postgres (positions)     Socket.IO (live)
```

**Lotes, no punto por punto.** Enviar una petición por segundo destroza la batería y no aporta nada: agrupa 15–30 s de puntos, comprime con gzip y manda un solo request. Si no hay señal, la cola local se acumula y se drena al reconectar; el entrenamiento se completa igual.

### 7.2 Endpoint de ingesta

```
POST /api/v1/tracking/sessions/:id/positions
Body: { points: [{ clientPointId, recordedAt, lat, lng, altitude, speed, accuracy, heading, battery }] }
```
- Autenticado con el **`ingestToken`** de la sesión (devuelto por `POST /workouts/sessions`), no con el JWT de usuario: así el token de ingesta es de vida corta y alcance mínimo.
- **Deduplica por `clientPointId`** (`ON CONFLICT DO NOTHING`) → reintentar un lote es seguro.
- Valida: `recordedAt` no puede estar en el futuro ni ser anterior al inicio de la sesión; descarta lat/lng fuera de rango.
- Inserta en bloque (`createMany`), responde `202` rápido con `{ accepted, duplicated, rejected }`.
- El post-procesado pesado (splits parciales, publicación a espectadores) va a una **cola BullMQ**, nunca en el request.
- Rate limit específico: máximo N lotes por sesión por minuto.

### 7.3 Del lado Flutter

1. **Verifica en pub.dev** las opciones de geolocalización en segundo plano antes de decidir, y **repórtame los hallazgos con sus licencias** antes de instalar nada. Candidatos a evaluar: `geolocator` + `flutter_foreground_task`, `background_locator_2`, `flutter_background_geolocation` (ojo: licencia comercial para release en Android). **No asumas ni inventes.**
2. Servicio `TrackingService` con API interna: `start(sessionId)`, `pause()`, `resume()`, `stop()`, `stream<Position>`.
3. **Doble escritura**: cada punto se guarda en drift *antes* de intentar enviarlo. La cola de envío es una tabla local (outbox) que se drena con reintentos y backoff exponencial.
4. Muestreo: 1 punto/segundo mientras corre, filtro `accuracy > 30 m`, `distanceFilter` para no gastar batería en pausa.
5. Permisos: `whileInUse` no alcanza para background; se necesita `always` en Android/iOS. Implementa el flujo educativo previo (explicación → solicitud → estado denegado con acceso a ajustes → detección de GPS apagado).

### 7.4 Puertas abiertas (impleméntalas, son baratas)

1. **Interfaz `PositionIngestionSource`** con la implementación `AppBatchSource`. Agregar Traccar o cualquier otra fuente después es escribir un adaptador, no reescribir el módulo.
2. **Endpoint compatible con protocolo OsmAnd**: `POST|GET /api/v1/tracking/osmand` aceptando los parámetros estándar (`id`, `lat`, `lon`, `timestamp`, `speed`, `bearing`, `altaltitude`, `accuracy`, `batt`), resolviendo `id → Device → sesión activa`. Son ~60 líneas y significa que la app oficial de Traccar Client, un reloj o un tracker físico pueden apuntar a tu backend sin cambios. Documéntalo en `docs/tracking.md`.

### 7.5 Preparado para live tracking masivo

No lo implementes completo ahora, pero deja la estructura:
- Namespace `/live`, rooms por `marathon:{id}`.
- Evento `runner:position` con payload mínimo (`bib`, `lat`, `lng`, `distanceMeters`, `t`).
- **Throttling server-side**: máximo 1 update por corredor cada 5 s hacia espectadores.
- Documenta en `docs/tracking.md` qué falta: autorización de espectadores, privacidad opt-in, clustering en el mapa, y estimación de carga (N corredores × frecuencia).

---

## 8. PAGOS SIMULADOS (BOB)

- Interfaz `PaymentProvider`: `createIntent(amountCents, currency, metadata)`, `confirm(intentId, method)`, `refund(paymentId)`, `getReceipt(paymentId)`.
- Implementa **`MockPaymentProvider`** con **tres métodos**, porque en Bolivia la tarjeta no es el medio dominante y la UI tiene que contemplarlo desde ahora:

  | Método | Simulación |
  |---|---|
  | `card` | Tarjetas deterministas: `4242…4242` → éxito, `4000…0002` → rechazo, `4000…0069` → expirada |
  | `qr` | Genera un **QR falso** (PNG con `sharp` o `qrcode`) + `expiresAt`; el cliente hace polling a `GET /payments/:id/status`; se confirma solo a los ~8 s, o se puede forzar con `POST /payments/:id/mock-confirm` en desarrollo |
  | `bank_transfer` | Devuelve datos bancarios mock y queda en `pending` hasta confirmación manual desde el panel admin |

- Latencia artificial configurable (300–1500 ms) para que la UI muestre loaders reales.
- **Nunca** almacena PAN completo: solo `brand` + últimos 4.
- **Idempotencia obligatoria**: `Idempotency-Key` en `POST /registrations/:id/checkout`; reintentar con la misma clave devuelve el mismo resultado sin cobrar dos veces.
- **Comprobante mock**: PDF con `pdfkit`, en español, montos en `Bs`, con NIT/razón social configurables desde el panel.
- **Webhook simulado**: `POST /payments/webhook` replicando el formato de un proveedor real (evento + firma HMAC), para que migrar a un PSP real sea cambiar el driver, no el flujo.
- Estados visibles en Races: `paid` / `pending` / `refunded` + fecha de inscripción.
- Documenta en `docs/decisiones.md` los candidatos reales para Bolivia (QR Simple del BCB vía banco adquirente, pasarelas locales) y qué haría falta para enchufarlos.

---

## 9. PANEL DE ADMINISTRACIÓN (sencillo)

Usa **AdminJS** con el adaptador de Prisma, montado en `/admin`, protegido por autenticación propia + rol `admin` + rate limiting. Es la opción de menor esfuerzo: genera el CRUD desde el esquema de Prisma casi sin código.

**Recursos CRUD automáticos:** maratones, categorías, extras, plantillas de planes y sus sesiones, usuarios (solo lectura de datos sensibles), inscripciones, pagos.

**Acciones personalizadas (las que AdminJS no da gratis):**
- **Activar/desactivar el service fee** (global y por maratón) con vista previa del efecto sobre un total de ejemplo.
- Publicar / despublicar una maratón.
- Confirmar manualmente un pago por transferencia bancaria.
- Cerrar inscripciones y recalcular `registrationStatus`.
- Cargar resultados de una carrera y **recalcular puestos** general y por categoría.
- Exportar inscritos de una maratón a CSV.

**Importante:** toda la lógica vive en servicios de Nest expuestos también como **endpoints REST bajo `/api/v1/admin/*`**, y AdminJS solo los invoca. Así, cuando construyas el panel web propio, la API ya está lista y no hay que reimplementar nada.

Personaliza AdminJS en español y limita las columnas visibles a lo útil; no me interesa un panel bonito, me interesa uno que funcione.

---

## 10. DESPLIEGUE EN VPS

Documenta todo en `docs/despliegue.md`.

- `docker-compose.yml` (desarrollo): `postgres`, `redis`, `api` con hot reload.
- `docker-compose.prod.yml`: `postgres`, `redis`, `api` (build multi-stage, imagen final slim, usuario no-root), `caddy`.
- **Caddy** como proxy inverso con TLS automático (Let's Encrypt), configuración en `Caddyfile`: dominio de API, headers de seguridad, compresión, y `/uploads` servido como estático.
- Variables de entorno en `.env.production` (fuera del repo), validadas con zod al arrancar: si falta algo, el proceso muere con mensaje claro.
- **Backups**: script `scripts/backup-db.sh` con `pg_dump` comprimido + rotación de 7 días, y su línea de cron documentada. Incluye el comando de restauración probado.
- Migraciones en el arranque del contenedor: `prisma migrate deploy` (nunca `migrate dev` en producción).
- Healthcheck en compose apuntando a `/health`; política `restart: unless-stopped`.
- **Dimensionamiento**: estima RAM/CPU y anótalo. Un VPS de 2 vCPU / 4 GB debería sobrar; indica en qué punto (usuarios concurrentes, corredores simultáneos) haría falta crecer.
- Logs rotados, sin secretos. Redacta `password`, `token`, `authorization`, `card` en pino.
- Sección de checklist de seguridad del VPS: firewall (solo 80/443/22), sin Postgres expuesto al exterior, SSH por clave, `fail2ban`.

---

## 11. SEEDS Y DATOS DE PRUEBA

`npm run db:seed` debe dejar un entorno usable de inmediato:

- 3 usuarios: `runner@test.com`, `runner2@test.com`, `admin@test.com` (password `Test1234!`).
- **10 maratones bolivianas realistas** (La Paz, Santa Cruz, Cochabamba, Sucre, Tarija…): 6 futuras (una a 3 días, una a 2 semanas, una a 4 meses), 4 pasadas, estados variados (`open`, `closing_soon`, `full`, `closed`), con categorías, extras, recorrido GeoJSON y cronograma. Precios en BOB realistas (Bs 80–350).
- **8 plantillas de plan** (5K/10K/21K/42K × principiante/intermedio), de 8 a 16 semanas.
- 1 plan activo instanciado para el usuario runner, con la semana actual parcialmente completada.
- ~40 entrenamientos históricos en 4 meses, con posiciones GPS reales (track GeoJSON de ejemplo desplazado y con ruido), splits y sensaciones.
- 4 inscripciones: 1 futura pagada con tarjeta, 1 futura pendiente por QR, 1 pasada con resultado completo (checkpoints cada 5 km y puestos), 1 cancelada/reembolsada.
- 3 zapatillas, una cerca del umbral de desgaste.
- Config de service fee global **activa** por defecto (10%, mínimo Bs 5) para poder probar activar y desactivar.

Sin seeds decentes no puedo probar la UI: trátalos como entregable, no como extra.

---

## 12. INTEGRACIÓN DEL LADO FLUTTER

Después del backend, en fases separadas, dentro de `running-app/`:

- Capa `data/` con **Dio** + interceptores (auth, retry con backoff, logging en debug, mapeo de errores por `code`).
- Modelos con `freezed` + `json_serializable`; nada de `Map<String, dynamic>` suelto.
- Repositorios **offline-first**: leer de local, refrescar desde red, escribir en una **outbox** local que se drena con conectividad.
- Base local con **drift**: workouts, posiciones, perfil, inscripciones, preferencias, outbox.
- `TrackingService` según 7.3.
- `flutter_secure_storage` para tokens.
- **No rediseñes la UI existente.** Conecta la que ya está. Si una pantalla necesita un campo que el backend no expone, avísame antes de tocar el widget.

---

## 13. CALIDAD Y SEGURIDAD

- `.env.example` completo y comentado.
- Helmet, CORS por entorno, límite de body size, `class-validator` con `whitelist: true` y `forbidNonWhitelisted: true`.
- **Autorización a nivel de recurso**: un usuario jamás debe leer el workout, la inscripción o las posiciones de otro. Escribe **tests e2e explícitos** que lo intenten y esperen `403/404`.
- Los datos de ubicación son sensibles: política de retención documentada en `docs/decisiones.md`.
- Tests mínimos: unitarios en `QuoteService` (con fee activo y desactivado), `PredictionService`, cálculo de métricas, instanciación de planes y rotación de refresh tokens. E2E en auth, inscripción completa con pago, sync de workouts e ingesta de posiciones.
- `README.md`: requisitos, `docker compose up`, migraciones, seeds, cómo apuntar Flutter al backend local (incluido `10.0.2.2` para el emulador Android), credenciales de prueba.
- Scripts npm: `dev`, `build`, `start`, `test`, `test:e2e`, `db:migrate`, `db:seed`, `db:reset`, `lint`, `format`.

---

## 14. PLAN DE FASES (pausa para commit en cada una)

Ejecuta **una fase por vez**. Al terminar, aplica el protocolo 0.2 y espera.

| # | Fase | Entregable |
|---|---|---|
| 0 | **Plan** | Lee todo, resuelve las preguntas de la sección 15 y presenta el plan detallado. **Sin código.** |
| 1 | Andamiaje | `running-api/` con NestJS + TS estricto, config tipada con zod, logger, filtros de error, sobre de respuesta, Swagger, docker-compose (postgres + redis), `/health` |
| 2 | Esquema de datos | `schema.prisma` completo, primera migración, particionado de `positions`, Prisma service |
| 3 | Auth | Registro, login, refresh rotativo 60 días, logout, sesiones, recuperación, guards, rol admin + tests |
| 4 | Usuarios y perfil | Perfil, preferencias, avatar, zapatillas, salud, highlights |
| 5 | Maratones | Catálogo, detalle, categorías, extras, estados de inscripción |
| 6 | Pricing | `ServiceFeeConfig`, `QuoteService`, fee opcional con override por maratón, snapshot |
| 7 | Inscripciones | Flujo de 3 pasos, cupos transaccionales, dorsal, cancelación |
| 8 | Pagos mock | `PaymentProvider`, driver mock con card/QR/transferencia, idempotencia, webhook, comprobante PDF en BOB |
| 9 | Planes de entrenamiento | Catálogo de plantillas, sugerencias por maratón, instanciación con anclaje y tapering, gestión de sesiones |
| 10 | Workouts | Sesiones, finish, consolidación de métricas y splits, historial, filtros, stats semanales |
| 11 | **Tracking** | Ingesta por lotes, `ingestToken`, dedupe, `PositionIngestionSource`, endpoint OsmAnd, modo simulación |
| 12 | Races | Resultados, checkpoints cada 5 km, ranking, comprobante, tarjeta de imagen |
| 13 | Home + predicción | `/home/summary`, `PredictionService` (Riegel) |
| 14 | Realtime | Socket.IO + Redis adapter, rooms por maratón, throttling (base para live tracking) |
| 15 | Panel admin | AdminJS + endpoints `/api/v1/admin/*`, acciones personalizadas |
| 16 | Transversales | Deep links, `/config/app`, notificaciones stub, rate limiting, borrado de cuenta |
| 17 | Seeds + docs + tests | Seeds completos, `docs/*`, README, suite e2e verde |
| 18 | Despliegue | compose de producción, Caddy, backups, checklist de seguridad, guía paso a paso del VPS |
| 19 | Flutter: capa de datos | Dio, interceptores, modelos, repositorios, secure storage |
| 20 | Flutter: local + offline | Drift, outbox, sincronización |
| 21 | Flutter: tracking | Servicio de GPS, permisos, background, doble escritura, envío por lotes |
| 22 | Flutter: conexión de pantallas | Reemplazar mocks por datos reales, pantalla por pantalla |

---

## 15. ANTES DE EMPEZAR, PREGÚNTAME

En la Fase 0 resuelve conmigo:

1. **Ruta absoluta** de `running-app/` para crear `running-api/` como hermana.
2. **Dominio** previsto para la API en el VPS (necesario para Caddy y deep links). Si aún no lo hay, usa un placeholder y déjalo en env.
3. **Datos fiscales** para el comprobante mock (razón social, NIT) o placeholders.
4. **Service fee por defecto**: ¿10% con mínimo de Bs 5 está bien, o prefieres monto fijo?
5. Del catálogo de planes: ¿te sirven las 8 plantillas propuestas, o tienes plantillas propias que quieras cargar?
6. Envío de correos (recuperación de contraseña): ¿SMTP propio, un servicio externo, o lo dejamos en un driver `console` por ahora?

Después de responder, presenta el plan de la Fase 1 y **pausa** — no escribas código hasta que yo diga "continuar".