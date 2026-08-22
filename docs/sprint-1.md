# Sprint 1 — Cerrar el atleta: perfil, historial e idioma

**Fechas:** lunes 24-ago-2026 → viernes 04-sep-2026 (10 días hábiles)
**Equipo:** 3 desarrolladores + 1 QA
**Objetivo de sprint:** que no quede ni un dato del atleta viviendo solo en el
teléfono, que la app hable español, y que el historial y el plan se editen de
verdad contra el servidor.

> Este documento continúa el `backlog.md`. Los sprints 1 y 2 de aquel plan
> (backend, identidad, catálogo, tracking real, sincronización offline) **ya
> están entregados**: la app corre contra `https://runner-app.tumype.com/api/v1`
> con `RemoteAuthRepository`, `RemoteHomeRepository`, `RemoteRaceRepository`,
> `TrackingService` y `SyncService` con outbox y backoff exponencial. Lo que
> queda planificado aquí es lo que falta para tener producto completo.

---

## Resumen para todos

Este sprint cierra todo lo que rodea al **atleta como persona**: su perfil, su
foto, su historial de entrenamientos y su plan. Hoy buena parte de esos datos
solo existen dentro del teléfono en el que se crearon — si el usuario cambia de
móvil o reinstala la app, los pierde. Al terminar el sprint, todo eso vive en el
servidor y le sigue a cualquier dispositivo.

Además pasan dos cosas visibles para cualquiera que abra la app: **estará en
español** (hoy está entera en inglés) y **el plan de entrenamiento se podrá
editar** — mover una sesión de día, o corregir una que se marcó como hecha por
error.

Por debajo, sin que el usuario lo note, se deja el servidor de producción usable
(hoy está vacío y no se puede ni entrar) y se automatiza la publicación: cada
cambio se prueba solo antes de entrar, y la app se genera sola al fusionarlo.

En una frase: **al cerrar el Sprint 1, un atleta puede entrar desde cualquier
teléfono, en español, y encontrar sus datos, su historial y su plan tal como los
dejó.**

---

## 0. Supuestos y exclusiones

| Punto | Decisión |
|---|---|
| **Facturación excluida** | Fuera de estos dos sprints: pasarela de pago real, recibos PDF (PU-019), reembolso con devolución de dinero (PU-020) y gestión de costos e ingresos (PU-024). El flujo de inscripción se queda con el checkout actual. |
| Backend | Repositorio aparte `running-api`, desplegado con systemd en el VPS. Lo toca solo Dev C. |
| Panel admin | Ya existe en `/admin` del backend. En estos dos sprints solo se le añade lo imprescindible (resultados oficiales, Sprint 2). |
| Idiomas | Español por defecto, inglés completo como segundo idioma. |
| Capacidad | ~36 pts por sprint. Sprint 1: **37 pts**. |

**Regla de independencia:** cada dev tiene su carril y sus archivos. El único
punto de contacto son los contratos de API, que Dev C publica en
`api/openapi.yaml` el **día 1**, antes de que nadie los consuma. Así ningún dev
espera a otro más de un día, y los dos de Flutter no tocan los mismos archivos.

---

## 1. Reparto por carriles

| Persona | Carril | Archivos que toca | Pts |
|---|---|---|---|
| **Dev A** | Flutter · datos y sincronización | `lib/features/profile/**`, `lib/features/train/**`, `lib/core/sync/**`, `lib/core/db/**` | 13 |
| **Dev B** | Flutter · producto, UX e i18n | `lib/l10n/**`, `lib/features/home/presentation/**`, `lib/features/races/presentation/**`, `lib/shared/**` | 13 |
| **Dev C** | Backend, infraestructura y CI | `running-api/**`, `.github/workflows/**`, VPS | 11 |
| **QA** | Verificación, dispositivos, regresión | `test/**`, plan de pruebas, matriz de dispositivos | — |

---

## 2. Historias del sprint

### Dev A — datos del atleta

#### PU-010 · Perfil sincronizado — 3 pts

> **En corto:** El perfil del atleta (nombre, edad, peso, ritmo objetivo) hoy vive solo dentro del teléfono. A partir de esta tarea vive en el servidor: si el usuario cambia de móvil o reinstala la app, sus datos siguen ahí.

Sustituir `LocalProfileRepository` por `RemoteProfileRepository` contra
`GET /me` y `PATCH /me`.

- Solo cambia la línea de `lib/app/dependencies.dart`; ninguna pantalla se toca.
- El guardado optimista que ya existe hace rollback si el servidor rechaza.
- La validación del servidor replicada en cliente (`core/utils/validators.dart`).
- Lectura desde Drift primero y refresco desde red, la regla offline-first ya vigente.

#### PU-011 · Foto de perfil — 3 pts

> **En corto:** Hoy, al intentar poner una foto de perfil, la app responde con un aviso de «próximamente». Aquí se implementa de verdad: elegir la foto, recortarla, subirla y verla en toda la app.

Sustituye el snackbar de `profile_edit_page.dart:187` («Photo upload arrives
with the media service»).

- Galería o cámara, con el permiso explicado **antes** de pedirlo.
- Recorte cuadrado y compresión a 5 MB máximo antes de subir.
- Barra de progreso durante la subida y reversión visual si falla.
- `AppAvatar` cae a las iniciales si la imagen no carga.

#### PU-014 · Historial paginado desde el servidor — 5 pts

> **En corto:** El historial de entrenamientos solo muestra lo que hay guardado en el teléfono. Pasa a pedirse al servidor de veinte en veinte a medida que el usuario baja por la lista, y a filtrarse también en el servidor. Así el historial completo está disponible aunque se cambie de dispositivo, sin que la app se ponga lenta.

Hoy `HiveTrainingRepository` lee solo la caja local y los filtros operan en memoria.

- `RemoteTrainingRepository` sobre `GET /workouts`, cursor de 20 por página.
- Los filtros de tipo y rango de fechas pasan a query params.
- La ruta GPS completa se pide solo al abrir el detalle, nunca en el listado.
- El listado sigue con `RouteThumbnail` (pintada, sin red) y la agrupación por semana intacta.
- Hive se conserva como caché de lectura y como cola de subida.

#### PU-100 · Estado de sincronización visible — 2 pts

> **En corto:** Cuando se corre sin cobertura, el entrenamiento se guarda y se sube después. Hoy el usuario no ve nada de eso. Esta tarea lo hace visible: cada entrenamiento indica si ya está guardado en el servidor, si está esperando, o si fue rechazado (y en ese caso, qué puede hacer).

`SyncReport` ya devuelve los contadores; falta pintarlos.

- Chip por entrenamiento en el historial: sincronizado / pendiente / rechazado.
- Un rechazo permanente es accionable: reintentar o descartar.
- Sin badge global permanente: nada de puntos rojos decorativos.

### Dev B — producto e idioma

#### PU-016 · Internacionalización — 5 pts

> **En corto:** Toda la app está escrita en inglés y con los textos incrustados en el código. Esta tarea los saca a archivos de traducción y añade el español completo, con un selector de idioma en Ajustes que cambia la app al momento. Es la tarea que más archivos toca del sprint.

Extraer del código todos los textos, que hoy están escritos en inglés dentro de los widgets.

- `flutter_localizations` + ARB con español e inglés completos.
- Ningún literal de UI queda en un widget; un `grep` en CI hace de red de seguridad.
- Fechas, números y moneda con el locale activo (`core/formatters/formatters.dart` ya usa `intl`).
- Selector de idioma en Ajustes, persistido junto al tema y con cambio en caliente.

#### PU-015 · Reprogramar y desmarcar sesión — 5 pts

> **En corto:** El plan de entrenamiento se puede consultar pero no editar: si el usuario no puede correr el jueves, no hay forma de mover esa sesión, ni de corregir una que marcó como hecha por error. Esta tarea añade ambas cosas.

Sustituye el snackbar de `home_page.dart:128` («Rescheduling arrives with the plan editor»).

- Selector de fecha limitado a la semana del plan; no deja mover a un día pasado.
- Aviso si el día destino ya tiene sesión, con opción de intercambiar.
- **Desmarcar** una sesión completada — hoy la API solo deja marcar, limitación
  anotada en `ARCHITECTURE.md` §358; el endpoint llega en PU-102.
- La tira semanal se actualiza sin recargar la pantalla.

#### PU-101 · Sesión expirada y estados de red — 3 pts

> **En corto:** Cubre los momentos en que algo va mal: la sesión caduca, no hay internet, el servidor tarda. Hoy la app se queda cargando sin explicar nada. Pasa a decir siempre qué está pasando y qué puede hacer el usuario.

- Un refresh caducado cierra sesión y lleva a `/welcome` con un mensaje que explica qué pasó.
- Banner global no bloqueante cuando no hay conectividad.
- Ninguna pantalla se queda en skeleton indefinido: timeout y estado de error en todas.

### Dev C — backend e infraestructura

#### PU-102 · Endpoints del atleta — 5 pts

> **En corto:** Es el trabajo de servidor que hace posible casi todo lo anterior: las direcciones (endpoints) que la app llama para leer y guardar el perfil, subir la foto, pedir el historial y editar el plan. Se publica primero el contrato — el documento que describe cómo se llaman y qué devuelven — para que los dos desarrolladores de la app puedan avanzar sin esperar.

Publica primero el contrato en `api/openapi.yaml` (día 1) e implementa después.

- `GET /me`, `PATCH /me` con validación y errores en el formato `{ code, message, details? }`.
- `POST /me/avatar` (multipart, 5 MB máximo, variantes de tamaño servidas como estático o CDN).
- `GET /workouts` paginado por cursor con filtros `type`, `from`, `to`.
- `PATCH /training-plans/sessions/{id}/reschedule` y `DELETE /training-plans/sessions/{id}/complete`.
- Tests de integración de cada endpoint y de autorización: nadie lee datos de otro.

#### PU-103 · Sembrar producción y sanear el entorno — 2 pts

> **En corto:** La base de datos del servidor de producción está vacía: hoy no se puede ni iniciar sesión ahí. Esta tarea la deja usable, con datos de ejemplo, y añade copias de seguridad diarias con una restauración probada.

Hoy la base de producción está vacía y no se puede ni entrar
(`docs/cuentas-de-prueba.md`, sección «Estado de producción»).

- `npm run db:seed` ejecutado en el VPS y verificado con `curl` sobre login, `/marathons` y `/config/app`.
- `CORS_ORIGINS` con el puerto web fijo incluido.
- Copia de seguridad diaria de la base y una restauración probada de verdad.

#### PU-004 · CI/CD — 4 pts

> **En corto:** Automatizar lo que hoy se hace a mano: cada cambio propuesto se prueba solo y no se puede fusionar si algo falla, y al fusionarlo se genera la app y se publica el servidor automáticamente, sin nadie conectándose por SSH.

- CI ejecuta `flutter analyze`, `flutter test` y los tests del backend en cada PR, y bloquea el merge si falla.
- Build de Android firmada publicada automáticamente al hacer merge en `main`.
- Despliegue del backend desde CI, no a mano por SSH, con rollback documentado.

### QA — transversal

- Plan de pruebas del sprint escrito el día 1, antes de que haya nada que probar.
- Matriz de dispositivos: 2 Android reales (uno de gama baja), 1 iOS, 1 tablet y Chrome.
- Regresión completa de lo ya entregado (auth, catálogo, inscripción, tracking) al abrir y al cerrar el sprint.
- Verificación de i18n en los dos idiomas, en claro y oscuro y a `textScaleFactor` 1.3.
- Bugs reportados con pasos, dispositivo, número de build y captura.

---

## 3. Plan diario

Leyenda: **[C]** entrega un contrato del que otro depende · **[V]** queda listo para verificar por QA.

### Semana 1

| Día | Dev A | Dev B | Dev C | QA |
|---|---|---|---|---|
| **D1** lun 24 | Leer `RemoteHomeRepository` como patrón; crear `ProfileApi` y modelos contra el contrato | Montar `flutter_localizations`, `l10n.yaml` y los ARB vacíos; inventariar literales con un script `grep` | **[C]** Publicar `api/openapi.yaml` con `/me`, `/me/avatar`, `/workouts`, reschedule y uncomplete | Escribir el plan de pruebas del sprint y preparar la matriz de dispositivos |
| **D2** mar 25 | `RemoteProfileRepository` con rollback optimista; tests con `mocktail` | Extraer a ARB los literales de auth, onboarding y home (es/en) | Implementar `GET /me` y `PATCH /me` con tests de integración | Regresión de lo ya entregado sobre la build actual: auth, catálogo, inscripción, tracking |
| **D3** mié 26 | **[V]** Cambiar la línea de `dependencies.dart`; verificar que Home reacciona al cambio de nombre | Extraer los literales de train, races y profile | **[V]** `POST /me/avatar` con validación de tamaño y tipo | Verificar PU-010 en los dos idiomas y ambos temas; abrir bugs |
| **D4** jue 27 | Selección de foto, permisos explicados, recorte y compresión | Selector de idioma en Ajustes, persistencia y cambio en caliente | `GET /workouts` paginado con filtros y test de aislamiento por usuario | Probar el cambio de idioma en caliente en todas las pantallas; buscar overflows a escala 1.3 |
| **D5** vie 28 | **[V]** Subida con progreso y reversión; `AppAvatar` con fallback | **[V]** i18n cerrada: cero literales y el `grep` de guardia en CI | **[V]** PU-103: sembrar producción, CORS y backup verificado | Verificar PU-011 y PU-016; smoke contra producción ya sembrada |

### Semana 2

| Día | Dev A | Dev B | Dev C | QA |
|---|---|---|---|---|
| **D6** lun 31 | `RemoteTrainingRepository` sobre `GET /workouts` con scroll infinito | Selector de fecha de reprogramación dentro de la semana del plan | `PATCH .../reschedule` y `DELETE .../complete`, con tests e idempotencia | Triaje de los bugs de la semana 1 y verificación de los arreglos |
| **D7** mar 1 | Filtros a query params conservando la agrupación por semana | Aviso de colisión de día con opción de intercambiar sesiones | Pipeline de CI: analyze + test Flutter + test backend, bloqueante | Pruebas de paginación y filtros: listas largas, listas vacías, red lenta |
| **D8** mié 2 | **[V]** Ruta GPS solo en el detalle; comprobar que el listado no pide red de más | **[V]** Desmarcar sesión y tira semanal reactiva sin recargar | Publicación automática de la build Android firmada al hacer merge | Verificar PU-014 y PU-015 en dispositivo real; medir tiempos de carga |
| **D9** jue 3 | **[V]** PU-100: chips de estado de sync y acción sobre el rechazo permanente | **[V]** PU-101: sesión expirada, banner offline y ningún skeleton infinito | **[V]** Despliegue del backend desde CI y rollback documentado | Prueba dura: modo avión, cola llena, matar la app, reabrir y recuperar red |
| **D10** vie 4 | Corrección de bugs del sprint y `flutter analyze` limpio | Corrección de bugs y revisión de claro/oscuro y escala 1.3 | Corrección de bugs y verificación del entorno de producción | Regresión de cierre, firma del Definition of Done e informe del sprint |

---

## 4. Demo del sprint (viernes 4-sep)

Entrar con la cuenta sembrada en producción y **cambiar el idioma a español en
caliente**; editar el perfil y subir una foto desde la cámara, verla aparecer en
Home; abrir el historial y hacer scroll infinito con filtro por tipo;
reprogramar la sesión del jueves al sábado y desmarcar una ya completada; poner
el teléfono en modo avión, correr, ver el entrenamiento como «pendiente»,
recuperar red y verlo pasar a «sincronizado»; entrar con la misma cuenta en otro
teléfono y encontrarlo todo ahí.

---

## 5. Riesgos del sprint

| Riesgo | Mitigación |
|---|---|
| Dev A y Dev B dependen de endpoints de Dev C | El contrato OpenAPI se entrega el **D1**; ambos trabajan contra mocks de `mocktail` hasta que llega el endpoint real |
| La i18n toca todos los archivos y choca con todo lo demás | Dev B la hace entera en la semana 1, en PRs por feature y mergeando a diario; nadie más edita textos esa semana |
| La base de producción sigue vacía y bloquea las pruebas | PU-103 cae el D5, no al final del sprint |
| Subir foto en gama baja consume memoria | Compresión antes de subir, y QA lo prueba en el dispositivo de gama baja de la matriz |

---

## 6. Definition of Done (el vigente del backlog)

`flutter analyze` sin issues · `dart format` aplicado · tests unitarios de la
lógica nueva y widget test si hay UI nueva · revisado en claro y oscuro y a
`textScaleFactor` 1.3 · estados loading / empty / error si carga datos · sin
colores, tamaños ni radios hardcodeados · `ARCHITECTURE.md` actualizado si cambia
una convención · code review aprobada y CI verde · desplegado en staging.
