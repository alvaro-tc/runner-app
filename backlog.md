# CamRun — Product Backlog

Plan de trabajo para llevar CamRun de **prototipo front-end funcional** a
**producto en producción con backend, pagos reales y panel de administración**.

Organizado en 4 sprints de 2 semanas. El Sprint 1 cierra con una demo
instalable y conectada a un backend real.

---

## 1. Punto de partida

### Lo que ya está hecho

| Área | Estado |
|---|---|
| Design system (claro/oscuro, tokens, tipografía) | ✅ Completo |
| Librería de componentes (9 átomos, 8 moléculas, 8 organismos) | ✅ Completo |
| Navegación (4 tabs, shell con estado por pestaña, guards) | ✅ Completo |
| Onboarding, welcome, sign in / sign up / forgot | ✅ UI + validación cliente |
| Home (cuenta atrás, plan semanal, sesión del día) | ✅ Completo |
| Detalle de maratón + inscripción en 3 pasos | ✅ UI, pago simulado |
| Train (resumen semanal, historial agrupado y filtrable) | ✅ Completo |
| Sesión de running con GPS y persistencia en Hive | ✅ Completo (GPS simulado en debug) |
| Races (totales derivados, detalle con resultados) | ✅ Completo |
| Profile (estadísticas, edición, ajustes, apariencia) | ✅ Completo |
| Tests (50: unitarios, widget, golden, integración) | ✅ Verde |

### Lo que NO existe todavía

- **Backend.** Cero. Toda la data sale de `FakeDataSeed` en memoria.
- **Autenticación real.** `FakeAuthRepository` acepta cualquier email con 8+
  caracteres y guarda un booleano en `SharedPreferences`.
- **Pagos.** El paso de pago es una selección mock (`Card •••• 4242` / `Wallet`).
- **Administración.** No hay roles, ni panel, ni forma de crear un maratón.
- **Notificaciones.** Ninguna.
- **Internacionalización.** Los textos están escritos en inglés en el código.
- **Sincronización.** Los entrenamientos viven solo en el dispositivo.

---

## 2. Convenciones

### Estimación (story points, Fibonacci)

| Puntos | Significado |
|---|---|
| 1 | Cambio trivial, sin incógnitas (< 2 h) |
| 2 | Tarea clara, un solo archivo o endpoint |
| 3 | Historia pequeña completa con tests |
| 5 | Historia estándar, toca varias capas |
| 8 | Historia grande, con incógnitas técnicas |
| 13 | Demasiado grande: hay que dividirla antes de entrar a sprint |

### Equipo y capacidad asumidos

4 personas: 1 tech lead / PO técnico, 1 backend, 2 Flutter.
Velocidad objetivo: **~36 puntos por sprint**.

### Definition of Ready

- Criterios de aceptación escritos y verificables.
- Diseño o wireframe disponible si toca UI nueva.
- Contrato de API acordado si cruza cliente/servidor.
- Dependencias identificadas y desbloqueadas.
- Estimada por el equipo.

### Definition of Done

- `flutter analyze` sin issues y `dart format` aplicado.
- Tests: unitarios de la lógica nueva y widget test si hay UI nueva.
- Revisada en **claro y oscuro** y a `textScaleFactor` 1.3.
- Estados **loading / empty / error** implementados si carga datos.
- Sin colores, tamaños ni radios hardcodeados en pantallas.
- Documentación actualizada (`ARCHITECTURE.md` si cambia una convención).
- Code review aprobada y CI verde.
- Desplegada en el entorno de staging.

### Etiquetas

`[BE]` backend · `[APP]` Flutter · `[ADMIN]` panel de administración ·
`[INFRA]` infraestructura y CI · `[UX]` diseño · `[DEUDA]` deuda técnica

---

## 3. Épicas

| ID | Épica | Descripción |
|---|---|---|
| **E1** | Plataforma y backend | API, base de datos, entornos, CI/CD, observabilidad |
| **E2** | Identidad y cuentas | Registro, login, OAuth, recuperación, sesión segura |
| **E3** | Catálogo de eventos | Maratones reales, búsqueda, filtros, imágenes, cupos |
| **E4** | Inscripciones y pagos | Pasarela real, recibos, cancelaciones, reembolsos |
| **E5** | Datos del atleta | Plan, entrenamientos, perfil sincronizados y offline-first |
| **E6** | Administración | Roles, CRUD de eventos, costos, usuarios, resultados |
| **E7** | Engagement | Notificaciones, compartir, social, logros |
| **E8** | Integraciones | Strava, Health/Fit, wearables, exportación GPX |
| **E9** | Calidad y operación | i18n, accesibilidad, rendimiento, deuda técnica, release |

---

## 4. Sprint 1 — Demo conectada de punta a punta

> **Objetivo de sprint:** que cualquiera pueda instalar la app desde un enlace,
> crear una cuenta real, iniciar sesión contra un backend desplegado y ver el
> catálogo de maratones servido por la API — sin datos falsos en ese camino.

**Total: 34 puntos**

### E1 · Plataforma

#### PU-001 · Definir el contrato de la API — 3 pts `[BE]`
Especificación OpenAPI 3.1 con los recursos de las próximas 4 semanas: `auth`,
`users`, `events`, `registrations`, `trainings`, `plans`.

- **Criterios de aceptación**
  - Fichero `api/openapi.yaml` versionado en el repo.
  - Cubre autenticación, paginación, formato de errores y códigos HTTP.
  - Formato de error único: `{ code, message, details? }`, mapeable 1:1 a la
    jerarquía `Failure` que ya existe en `lib/core/error/failure.dart`.
  - Revisado y aprobado por backend y por los dos Flutter.

#### PU-002 · Esqueleto del servicio backend — 5 pts `[BE]`
Servicio con framework y ORM elegidos, salud (`/health`), configuración por
entorno y logging estructurado.

- **Criterios de aceptación**
  - `GET /health` responde 200 con versión y commit.
  - Configuración por variables de entorno, nada de secretos en el repo.
  - Docker Compose levanta servicio + base de datos en local con un comando.
  - README de backend con instrucciones de arranque.

#### PU-003 · Base de datos y migraciones — 3 pts `[BE]`
Esquema inicial: `users`, `events`, `event_categories`, `event_extras`,
`registrations`, `training_plans`, `planned_sessions`, `training_runs`.

- **Criterios de aceptación**
  - Migraciones versionadas y reversibles.
  - Seed de desarrollo que replica `FakeDataSeed` (6 eventos, 1 plan de 12
    semanas, 25 entrenamientos, 4 inscripciones).
  - Índices en las columnas de consulta habituales (`user_id`, `event_date`).

#### PU-004 · Entornos y CI/CD — 5 pts `[INFRA]`
Pipeline que valida cada PR y despliega automáticamente a staging.

- **Criterios de aceptación**
  - CI ejecuta `flutter analyze`, `flutter test` y los tests de backend en cada
    PR; bloquea el merge si falla.
  - Backend de staging desplegado y accesible por HTTPS.
  - Build de Android firmada y publicada en Firebase App Distribution al hacer
    merge en `main`.
  - Los goldens se ejecutan en CI con la fecha congelada (ver PU-032).

### E2 · Identidad

#### PU-005 · Registro y login con email — 5 pts `[BE]`
Endpoints `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`,
`POST /auth/logout`.

- **Criterios de aceptación**
  - Contraseñas con Argon2id, nunca en texto plano ni en logs.
  - Access token JWT de 15 min + refresh token rotatorio de 30 días.
  - Email duplicado devuelve 409 con `code: EMAIL_TAKEN`.
  - Rate limit de 10 intentos de login por IP y minuto.
  - Tests de integración de los cuatro endpoints.

#### PU-006 · Cliente HTTP con refresh automático — 5 pts `[APP]`
Capa de red compartida por todos los repositorios remotos.

- **Criterios de aceptación**
  - Cliente Dio con interceptores: `Authorization`, reintento con backoff en
    5xx y refresh transparente ante 401.
  - Un solo refresh concurrente aunque fallen varias peticiones a la vez.
  - Los errores HTTP se traducen a `Failure` y llegan a la UI como hoy.
  - Timeouts configurados (10 s conexión, 20 s recepción).
  - Tests con `mocktail` de los tres caminos: éxito, 401 + refresh, 401 + refresh
    caducado → logout.

#### PU-007 · Sustituir `FakeAuthRepository` por el real — 3 pts `[APP]`
`RemoteAuthRepository` implementando la interfaz `AuthRepository` existente.

- **Criterios de aceptación**
  - Solo cambia la línea de `app/dependencies.dart`; ninguna pantalla se toca.
  - Tokens en `flutter_secure_storage` (Keychain / Keystore), nunca en
    `SharedPreferences`.
  - Al cerrar sesión se borran tokens, caja Hive y providers.
  - Los mensajes de error del servidor se muestran bajo el campo, igual que hoy.
  - `FakeAuthRepository` se conserva para tests.

#### PU-008 · Catálogo de eventos desde la API — 5 pts `[BE]` `[APP]`
`GET /events` con paginación y `GET /events/{id}`.

- **Criterios de aceptación**
  - Respuesta paginada por cursor, 20 por página.
  - `RemoteMarathonRepository` sustituye al fake en una línea.
  - Home y el detalle de maratón muestran datos del servidor.
  - Scroll infinito en el listado con skeleton al final.
  - El estado de error mantiene el `ErrorStateView` con «Try again».

#### PU-009 · Imágenes reales de evento — 3 pts `[BE]` `[APP]`
Almacenamiento de las imágenes de cabecera y servido por CDN.

- **Criterios de aceptación**
  - El backend devuelve `heroImageUrl` absoluto con variantes de tamaño.
  - `EventImage` ya soporta URL: solo hay que verificar el fallback pintado
    cuando la descarga falla o el campo viene vacío.
  - Las imágenes se cachean en disco (`cached_network_image`).

### Demo del Sprint 1

Recorrido a enseñar: instalar desde el enlace → onboarding → **registrar una
cuenta nueva de verdad** → cerrar y reabrir la app (sesión persiste) → Home con
maratones servidos por la API → abrir el detalle de un evento → cerrar sesión →
volver a entrar. El resto de la app sigue con datos locales y se enseña como
«ya construido, pendiente de conectar».

---

## 5. Sprint 2 — El atleta y sus datos, sincronizados

> **Objetivo de sprint:** que el plan de entrenamiento, el historial de carreras
> y el perfil vivan en el servidor y sobrevivan a un cambio de teléfono, sin
> perder el funcionamiento sin cobertura.

**Total: 37 puntos**

### E5 · Datos del atleta

#### PU-010 · Perfil sincronizado — 3 pts `[BE]` `[APP]`
`GET /me`, `PATCH /me`.

- **Criterios de aceptación**
  - `RemoteProfileRepository` sustituye a `LocalProfileRepository`.
  - El guardado optimista que ya existe hace rollback si el servidor rechaza.
  - Cambiar el nombre actualiza el título de Home reactivamente (ya funciona).
  - Validación de servidor replicada en cliente.

#### PU-011 · Subida de foto de perfil — 3 pts `[BE]` `[APP]`
Sustituye el «Change photo» que hoy muestra un snackbar.

- **Criterios de aceptación**
  - Selección desde galería o cámara con permisos explicados antes de pedirlos.
  - Recorte cuadrado antes de subir; máximo 5 MB tras compresión.
  - Barra de progreso durante la subida y reversión si falla.
  - `AppAvatar` muestra la imagen y cae a las iniciales si no carga.

#### PU-012 · Plan de entrenamiento desde el servidor — 5 pts `[BE]` `[APP]`
`GET /plans/active`, `PATCH /plans/sessions/{id}`.

- **Criterios de aceptación**
  - El selector de semana carga cualquiera de las 12 desde la API.
  - Marcar una sesión como completada persiste en servidor y es idempotente.
  - La tira semanal y la tarjeta del día reflejan el estado del servidor.

#### PU-013 · Sincronización offline-first de entrenamientos — 8 pts `[APP]` `[BE]`
El caso crítico: se corre sin cobertura y la carrera no se puede perder.

- **Criterios de aceptación**
  - Al finalizar, el `TrainingRun` se guarda **siempre** en Hive primero.
  - Cola de subida con reintentos y backoff exponencial; se vacía al recuperar
    conectividad y al arrancar la app.
  - Cada run lleva un `clientId` (UUID) para que el servidor deduplique.
  - Estado visible por entrenamiento en el historial: sincronizado / pendiente.
  - Matar la app con la cola llena y reabrirla reanuda la subida.
  - Tests de la cola: éxito, fallo transitorio, fallo permanente, duplicado.

#### PU-014 · Historial paginado desde el servidor — 5 pts `[BE]` `[APP]`
`GET /trainings` con filtros por tipo y rango de fechas.

- **Criterios de aceptación**
  - Los filtros que hoy operan en memoria pasan a query params.
  - Scroll infinito con agrupación por semana intacta.
  - La ruta GPS completa se pide solo al abrir el detalle, no en el listado.
  - El listado sigue usando `RouteThumbnail` (pintada, sin red).

#### PU-015 · Reprogramar una sesión — 5 pts `[BE]` `[APP]`
Sustituye el snackbar «Rescheduling arrives with the plan editor».

- **Criterios de aceptación**
  - Selector de fecha dentro de la semana del plan.
  - No permite mover una sesión a una fecha ya pasada.
  - Aviso si el día destino ya tiene una sesión, con opción de intercambiar.
  - La tira semanal se actualiza sin recargar la pantalla.

### E9 · Calidad

#### PU-016 · Internacionalización — 5 pts `[APP]` `[DEUDA]`
Extraer todos los textos del código.

- **Criterios de aceptación**
  - `flutter_localizations` + ARB con inglés y español completos.
  - Ningún literal de UI queda en un widget.
  - Fechas, números y monedas formateados con el locale activo
    (`core/formatters/formatters.dart` ya usa `intl`).
  - Selector de idioma en Ajustes, persistido junto al tema.

#### PU-017 · Sesión expirada y estados de red — 3 pts `[APP]`

- **Criterios de aceptación**
  - Un refresh caducado cierra sesión y lleva a `/welcome` con un mensaje que
    explica qué pasó.
  - Banner global no bloqueante cuando no hay conectividad.
  - Ninguna pantalla se queda en skeleton indefinido: hay timeout y error.

### Demo del Sprint 2

Iniciar sesión en un teléfono, correr con GPS simulado en **modo avión**,
finalizar, ver el entrenamiento marcado como pendiente, recuperar red y verlo
sincronizar; entrar con la misma cuenta en otro dispositivo y encontrar ahí el
entrenamiento, el plan y el perfil. Cambiar el idioma a español en caliente.

---

## 6. Sprint 3 — Inscripciones de verdad y panel de administración

> **Objetivo de sprint:** cobrar una inscripción real en entorno sandbox y dar a
> un administrador las herramientas para publicar eventos, fijar precios y
> gestionar usuarios.

**Total: 39 puntos**

### E4 · Inscripciones y pagos

#### PU-018 · Pasarela de pago real (sandbox) — 8 pts `[BE]` `[APP]`
Sustituye el selector mock del paso 3 de la inscripción.

- **Criterios de aceptación**
  - Stripe Payment Sheet integrada; la app **nunca** ve datos de tarjeta.
  - `POST /registrations` crea la inscripción en estado `pending` y devuelve el
    `clientSecret`.
  - Webhook de confirmación mueve la inscripción a `paid` y asigna dorsal.
  - Sin webhook confirmado no se asigna dorsal: nada de dorsales fantasma.
  - Cancelar el pago deja la inscripción en `pending` y es reanudable.
  - Cupos decrementados de forma transaccional; sin sobreventa bajo carga.
  - Prueba de concurrencia: 50 inscripciones simultáneas al último cupo dejan
    exactamente una ganadora.

#### PU-019 · Recibos reales — 3 pts `[BE]` `[APP]`
Sustituye el snackbar «Receipts download once the billing service is connected».

- **Criterios de aceptación**
  - `GET /registrations/{id}/receipt` devuelve un PDF con datos fiscales.
  - El botón descarga y abre el PDF con el visor del sistema.
  - Solo el dueño de la inscripción o un administrador puede pedirlo.

#### PU-020 · Cancelación y reembolso — 5 pts `[BE]` `[APP]`
Hoy `FakeRaceRepository.cancel` solo cambia un enum en memoria.

- **Criterios de aceptación**
  - Política de reembolso configurable por evento (100 % / 50 % / 0 % según
    días restantes), mostrada antes de confirmar.
  - El reembolso se emite en la pasarela y el cupo se libera.
  - El estado de pago pasa a `refunded` y la inscripción a `cancelled`.
  - El diálogo de confirmación ya existente muestra el importe exacto a devolver.

### E6 · Administración

#### PU-021 · Roles y permisos — 5 pts `[BE]` `[APP]`
Base de todo lo que sigue.

- **Criterios de aceptación**
  - Roles `athlete`, `organizer`, `admin` en el JWT.
  - Toda ruta administrativa verifica el rol en **servidor**; el cliente solo
    oculta la UI.
  - Un `athlete` que llama a un endpoint admin recibe 403.
  - Tests de autorización por cada endpoint administrativo.

#### PU-022 · Shell del panel de administración — 5 pts `[ADMIN]`
Aplicación Flutter Web reutilizando el design system existente.

- **Criterios de aceptación**
  - Proyecto en `admin/` que consume el paquete de design system compartido.
  - Login con las mismas credenciales; rechaza a quien no sea `admin` u
    `organizer`.
  - Layout responsive con navegación lateral: Eventos, Inscripciones, Usuarios.
  - Claro y oscuro funcionando, como en la app.

#### PU-023 · CRUD de maratones — 8 pts `[ADMIN]` `[BE]`
La pieza que el producto no tiene hoy: crear un evento.

- **Criterios de aceptación**
  - Formulario completo: nombre, fecha, ciudad, país, distancia, descripción,
    cronograma, qué incluye, ruta oficial e imagen de cabecera.
  - Gestión de **categorías** (distancias) con su suplemento de precio.
  - Gestión de **extras** opcionales con precio individual.
  - Cupo total y estado de inscripción (`open` / `closingSoon` / `full` /
    `closed`), con transición automática a `full` al agotarse.
  - Borrador → publicado, con vista previa de cómo se verá en la app.
  - Un evento con inscripciones pagadas no se puede borrar, solo despublicar.
  - Editar el precio no altera lo ya cobrado.

#### PU-024 · Gestión de costos e ingresos — 5 pts `[ADMIN]` `[BE]`

- **Criterios de aceptación**
  - Configuración de cuota de servicio por evento o global.
  - Registro de **costos del evento** (permisos, avituallamiento, medallas,
    personal) con categoría, importe y nota.
  - Vista de margen por evento: ingresos − costos − comisiones de pasarela.
  - Exportación a CSV del desglose.

#### PU-025 · Gestión de usuarios — 5 pts `[ADMIN]` `[BE]`

- **Criterios de aceptación**
  - Búsqueda por nombre, email o dorsal, con paginación.
  - Ficha de usuario: datos, inscripciones, historial de pagos.
  - **Restablecer contraseña**: el admin dispara un email con enlace de un solo
    uso y caducidad de 1 h. El admin **nunca** ve ni fija la contraseña.
  - Forzar cierre de sesión (revocar todos los refresh tokens).
  - Bloquear y desbloquear cuenta, con motivo obligatorio.
  - Toda acción queda registrada en auditoría (PU-030).

### Demo del Sprint 3

Un administrador crea un maratón desde el panel, le pone precio, extras y cupo, y
lo publica. En el teléfono aparece en el catálogo; un atleta se inscribe pagando
con tarjeta sandbox, recibe dorsal y descarga el recibo. El admin lo ve en la
lista de inscripciones, le restablece la contraseña por email y el atleta la
cambia y vuelve a entrar.

---

## 7. Sprint 4 — Producción

> **Objetivo de sprint:** dejar el producto listo para publicarse: notificaciones,
> resultados oficiales, observabilidad, accesibilidad certificada y builds de
> tienda.

**Total: 36 puntos**

### E6 · Administración avanzada

#### PU-026 · Carga de resultados oficiales — 5 pts `[ADMIN]` `[BE]`
Hoy los `RaceResult` son sintéticos.

- **Criterios de aceptación**
  - Importación CSV: dorsal, tiempo oficial, tiempo de chip, puesto general,
    puesto por categoría.
  - Validación previa con informe de filas rechazadas antes de confirmar.
  - Publicar resultados notifica a los participantes (PU-028).
  - La inscripción pasa a `completed` y el detalle en la app muestra los datos
    reales en la rejilla de métricas que ya existe.

#### PU-027 · Dashboard del organizador — 5 pts `[ADMIN]`

- **Criterios de aceptación**
  - Ocupación por evento (inscritos / cupo) y evolución de inscripciones.
  - Ingresos del periodo y desglose por categoría y extras.
  - Reparto por sexo y grupo de edad de los participantes.
  - Todo alimentado por datos reales, nada hardcodeado.

### E7 · Engagement

#### PU-028 · Notificaciones push — 5 pts `[BE]` `[APP]`
La pantalla de ajustes ya tiene los interruptores, pero no hacen nada.

- **Criterios de aceptación**
  - FCM/APNs integrados con registro y baja de token.
  - Tres tipos: recordatorio de sesión, actualizaciones del evento (retirada de
    kit, hora de salida), resultados publicados.
  - Los interruptores de Ajustes controlan de verdad cada tipo, en servidor.
  - Tocar la notificación abre la pantalla correcta (deep link).
  - Se respeta el rechazo del permiso del sistema sin romper nada.

#### PU-029 · Tarjeta de resultado compartible — 3 pts `[APP]`
Sustituye el snackbar «A shareable finisher card is on the way».

- **Criterios de aceptación**
  - Widget renderizado a imagen con `RepaintBoundary`: evento, tiempo, ritmo,
    dorsal y traza de la ruta.
  - Compartir por la hoja nativa del sistema.
  - Legible en claro y oscuro y a 1080×1080 y 1080×1920.

### E9 · Operación y calidad

#### PU-030 · Auditoría de acciones administrativas — 3 pts `[BE]` `[ADMIN]`

- **Criterios de aceptación**
  - Registro inmutable de quién, qué, cuándo y sobre qué recurso.
  - Cubre como mínimo: cambios de precio, reembolsos, restablecimientos de
    contraseña, bloqueos y publicación de resultados.
  - Consultable y filtrable desde el panel.

#### PU-031 · Observabilidad — 5 pts `[INFRA]` `[APP]`

- **Criterios de aceptación**
  - Sentry en app y backend, con release y sourcemaps/símbolos subidos por CI.
  - Métricas de producto: registro completado, inscripción completada, carrera
    finalizada, con consentimiento previo del usuario.
  - Alerta si la tasa de sesiones sin crash baja del 99,5 %.
  - Panel con latencia y tasa de error de los endpoints críticos.

#### PU-032 · Deuda técnica acumulada — 5 pts `[DEUDA]`
Recogida de lo anotado durante la construcción.

- **Criterios de aceptación**
  - `FakeDataSeed` acepta una fecha base inyectable, para que los goldens de
    Home dejen de depender del día natural (limitación anotada en
    `ARCHITECTURE.md` §11).
  - Golden de la sesión en vivo con la capa de tiles simulada, cubriendo el
    hueco declarado.
  - Revisar si `riverpod_generator` y `freezed` ya resuelven juntos; si es así,
    evaluar la migración a codegen. Si no, dejarlo documentado otro trimestre.
  - Tests de widget de la sesión en vivo: countdown, pausa, auto-pausa y
    finalización.

#### PU-033 · Tracking en segundo plano — 5 pts `[APP]`
Hoy la carrera se detiene si el sistema mata la app en segundo plano.

- **Criterios de aceptación**
  - Foreground service en Android con notificación persistente durante la
    carrera.
  - Background location en iOS (`UIBackgroundModes` ya está declarado).
  - Bloquear el teléfono y correr 10 minutos no pierde ni un punto de la ruta.
  - La batería consumida se mide y se documenta.

#### PU-034 · Accesibilidad certificada y publicación — 5 pts `[APP]` `[UX]`

- **Criterios de aceptación**
  - Recorrido completo con TalkBack y VoiceOver sin callejones sin salida.
  - Contraste AA verificado con herramienta, no a ojo, en ambos temas.
  - Sin overflows a `textScaleFactor` 1.3 en 360×640, 390×844, 430×932 y tablet.
  - Ficha de tienda: capturas, descripción, política de privacidad.
  - Builds de release firmadas subidas a TestFlight y Play Console (internal).

---

## 8. Backlog sin planificar

Funcionalidades que aportarían valor pero que no entran en los 4 sprints.
Ordenadas por relación valor/esfuerzo estimada.

### Alto valor

| ID | Función | Épica | Est. | Por qué |
|---|---|---|---|---|
| PU-040 | **Búsqueda y filtros del catálogo** (distancia, fecha, ciudad, precio, cercanía) | E3 | 5 | Con más de 20 eventos el listado actual deja de servir |
| PU-041 | **Lista de espera** para eventos llenos, con notificación al liberarse un cupo | E3/E7 | 5 | Hoy un evento `full` es un callejón sin salida |
| PU-042 | **Generador de plan adaptativo**: elegir objetivo y fecha y que el plan se calcule y se reajuste según lo cumplido | E5 | 13 | El diferenciador real del producto; hoy el plan es fijo |
| PU-043 | **Integración con Strava** (importar y exportar actividades) | E8 | 8 | Petición número uno en cualquier app de running |
| PU-044 | **Apple Health / Google Fit** (frecuencia cardíaca, sueño, peso) | E8 | 8 | Alimentaría con datos reales las tarjetas de Profile, hoy estáticas |
| PU-045 | **Cupones y códigos de descuento** en la inscripción | E4 | 5 | Herramienta comercial básica para organizadores |
| PU-046 | **Inscripción de equipos y relevos** | E4 | 8 | Categoría de evento completa que hoy no se puede vender |

### Valor medio

| ID | Función | Épica | Est. | Por qué |
|---|---|---|---|---|
| PU-047 | **Exportar GPX / TCX** de cualquier entrenamiento | E8 | 3 | Barato, y desbloquea a los usuarios avanzados |
| PU-048 | **Zonas de frecuencia cardíaca** y conexión con banda BLE | E8 | 8 | `avgHeartRate` ya existe en el modelo pero nadie lo llena |
| PU-049 | **Logros y rachas** (primer 10K, 7 días seguidos, récord personal) | E7 | 5 | Retención barata sobre datos que ya tenemos |
| PU-050 | **Perfil público y seguir a otros atletas** | E7 | 8 | Base de cualquier función social posterior |
| PU-051 | **Retos entre amigos** (kilometraje mensual) | E7 | 8 | Depende de PU-050 |
| PU-052 | **Mapas offline** por descarga de región | E5 | 8 | Correr sin cobertura hoy deja el mapa en blanco |
| PU-053 | **Controles de música** integrados con el reproductor del sistema | E7 | 3 | El botón ya está en la sesión y hoy no hace nada |
| PU-054 | **Widget de pantalla de inicio** con la sesión del día | E7 | 5 | Punto de entrada diario sin abrir la app |
| PU-055 | **Live Activity / Dynamic Island** durante la carrera | E7 | 5 | Muy visible en iOS, valor de marca |
| PU-056 | **Modo cinta de correr** (sin GPS, con distancia manual o podómetro) | E5 | 5 | Bloquea a todo un segmento de usuarios en invierno |
| PU-057 | **Alertas de voz por kilómetro** | E5 | 3 | Estándar en la categoría, esperado por el usuario |

### Valor bajo o dependiente

| ID | Función | Épica | Est. | Por qué |
|---|---|---|---|---|
| PU-058 | **Comparador de calzado** y aviso de retiro | E5 | 3 | La barra de desgaste ya está en Profile, faltaría el resto |
| PU-059 | **Predicción de tiempo de meta** basada en el historial real | E5 | 8 | Hoy `predictedFinishTime` viene fijo del servidor |
| PU-060 | **Panel del organizador externo** (autoservicio para terceros) | E6 | 13 | Solo tiene sentido con varios organizadores en la plataforma |
| PU-061 | **Multi-divisa y precios por región** | E4 | 5 | Depende de expansión internacional |
| PU-062 | **Chat de soporte dentro de la app** | E7 | 5 | El email de Ajustes cubre el caso mientras el volumen sea bajo |
| PU-063 | **Modo espectador** (seguir a un corredor en directo) | E7 | 13 | Requiere subida de posición en vivo, coste alto |

---

## 9. Riesgos y dependencias

| Riesgo | Impacto | Mitigación |
|---|---|---|
| El tracking en segundo plano es el punto más frágil de cualquier app de running | Alto | PU-033 aislado y con pruebas en dispositivo real; presupuestar un sprint entero si se tuerce |
| La revisión de App Store cuestiona el uso de ubicación en segundo plano | Alto | Justificación clara en la ficha y en el diálogo previo; el texto ya está redactado en `Info.plist` |
| Sobreventa de cupos bajo concurrencia | Alto | Transacción con bloqueo a nivel de fila y prueba de carga explícita en PU-018 |
| El panel admin en Flutter Web obliga a duplicar componentes | Medio | Extraer el design system a un paquete compartido al empezar PU-022, no después |
| Cumplimiento RGPD de datos de salud y ubicación | Alto | Consentimiento granular, exportación y borrado de cuenta antes de publicar (parte de PU-034) |
| `riverpod_generator` y `freezed` siguen sin poder convivir | Bajo | Ya resuelto sin codegen; revisar en PU-032 sin bloquear nada |

---

## 10. Resumen

| Sprint | Objetivo | Puntos | Demo |
|---|---|---|---|
| **1** | Backend real de identidad y catálogo | 34 | App instalable, cuenta real, eventos del servidor |
| **2** | Datos del atleta sincronizados y offline-first | 37 | Correr sin cobertura, sincronizar, cambiar de teléfono |
| **3** | Pagos reales y panel de administración | 39 | Crear evento, cobrar, gestionar usuarios |
| **4** | Producción: notificaciones, resultados y release | 36 | Build en TestFlight y Play, resultados oficiales |

**Total planificado:** 146 puntos · **Backlog sin planificar:** ~180 puntos.
