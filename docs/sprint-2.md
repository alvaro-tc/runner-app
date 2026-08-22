# Sprint 2 — Producción: carrera fiable, notificaciones y publicación

**Fechas:** lunes 07-sep-2026 → viernes 18-sep-2026 (10 días hábiles)
**Equipo:** los mismos 3 desarrolladores + 1 QA
**Objetivo de sprint:** dejar el producto publicable — que una carrera con la
pantalla apagada no pierda un punto de GPS, que la app avise por notificación,
que los resultados oficiales sean reales y que haya builds firmadas en
TestFlight y Play Console.

> Continúa `docs/sprint-1.md`. Se asume que lo del Sprint 1 está entregado y
> verificado: perfil y foto sincronizados, historial paginado, plan editable,
> i18n en español e inglés, CI/CD y producción sembrada.

---

## Resumen para todos

Este sprint deja el producto **listo para publicar en las tiendas**. Son cuatro
bloques.

El primero y más importante: que una carrera **no se pierda**. Hoy, si el usuario
bloquea el teléfono y lo guarda en el bolsillo, el sistema operativo puede dormir
la app y desaparecen trozos de la ruta. Se arregla al principio del sprint y se
prueba corriendo de verdad, en la calle, con dos teléfonos distintos.

El segundo: **la app empieza a hablarle al usuario**. Notificaciones reales —
recordatorio de la sesión del día, avisos del evento y resultados publicados —
que al tocarlas abren la pantalla que corresponde. Los interruptores que ya
existen en Ajustes hoy no hacen nada; a partir de aquí sí.

El tercero: **los resultados dejan de ser inventados**. Un organizador sube el
archivo real de resultados de la carrera desde el panel, y cada atleta ve su
tiempo y su puesto oficiales, y puede compartir una tarjeta con ellos. También se
añaden búsqueda y filtros al catálogo, que con más de veinte eventos ya no se
puede recorrer a mano.

El cuarto es lo que exige cualquier tienda antes de aceptar una app: que
funcione con lector de pantalla para personas ciegas, que los errores se detecten
solos en producción, y que haya builds firmadas subidas a TestFlight y a Play
Console.

En una frase: **al cerrar el Sprint 2, la app se puede instalar desde la tienda,
grabar una carrera entera con el teléfono en el bolsillo y avisar al atleta
cuando salgan sus resultados oficiales.**

---

## 0. Supuestos y exclusiones

Las mismas del Sprint 1. **La facturación sigue fuera**: no hay pasarela real,
ni recibos PDF, ni reembolso de dinero, ni módulo de costos e ingresos. La
cancelación de inscripción (PU-020) entra **solo en su parte funcional**: liberar
el cupo y dejar la inscripción en `cancelled` mostrando la política; el
movimiento de dinero queda anotado como pendiente de facturación.

**Capacidad:** 36 pts.

---

## 1. Reparto por carriles

| Persona | Carril | Archivos que toca | Pts |
|---|---|---|---|
| **Dev A** | Flutter · plataforma nativa y observabilidad | `android/**`, `ios/**`, `lib/features/tracking/**`, `lib/core/services/location_service.dart` | 13 |
| **Dev B** | Flutter · catálogo, resultados y accesibilidad | `lib/features/home/presentation/**`, `lib/features/races/presentation/**`, `lib/shared/**` | 13 |
| **Dev C** | Backend, admin y push | `running-api/**`, panel `/admin`, FCM/APNs | 10 |
| **QA** | Certificación, dispositivos reales, tienda | `test/**`, pruebas de campo, fichas de tienda | — |

Los carriles siguen sin solaparse: Dev A vive en las capas nativas y de tracking,
Dev B en pantallas de catálogo y carreras, Dev C fuera del repo de la app.

---

## 2. Historias del sprint

### Dev A — que la carrera no se pierda

#### PU-033 · Tracking en segundo plano — 5 pts

> **En corto:** Hoy, si el usuario bloquea el teléfono o lo guarda en el bolsillo durante la carrera, el sistema operativo puede dormir la app y se pierden trozos de la ruta. Esta tarea hace que la grabación siga viva con la pantalla apagada. Es lo más importante del sprint: una app de running que pierde la ruta no sirve.

Es el punto más frágil de cualquier app de running y por eso va el primer día del sprint.

- Foreground service en Android con notificación persistente mientras dura la carrera.
- Background location en iOS (`UIBackgroundModes` ya está declarado en `Info.plist`).
- Bloquear el teléfono y correr 10 minutos no pierde ni un punto de la ruta.
- El consumo de batería se mide y se documenta en `ARCHITECTURE.md`.
- La cola de ingesta existente (`/tracking/sessions/{id}/positions`) sigue siendo la única vía de subida.

#### PU-031 · Observabilidad — 5 pts

> **En corto:** Hoy, si a un usuario le falla la app, nadie se entera. Esta tarea añade el aviso automático de errores y unas pocas métricas de uso (con permiso previo del usuario), más alertas cuando algo se degrada.

- Sentry en la app y en el backend, con release y símbolos subidos desde CI.
- Métricas de producto con consentimiento previo: registro completado, inscripción completada, carrera finalizada.
- Alerta si la tasa de sesiones sin crash baja del 99,5 %.
- Panel con latencia y tasa de error de los endpoints críticos.

#### PU-032 · Deuda técnica acumulada — 3 pts

> **En corto:** Arreglos internos pendientes que no ve el usuario pero que hacen que las pruebas automáticas sean fiables — hoy algunas dependen del día en que se ejecutan y fallan solas.

- `FakeDataSeed` acepta una fecha base inyectable, para que los goldens de Home
  dejen de depender del día natural (limitación anotada en `ARCHITECTURE.md` §401).
- Golden de la sesión en vivo con la capa de tiles simulada.
- Tests de widget de la sesión en vivo: cuenta atrás, pausa, auto-pausa y finalización.

### Dev B — catálogo, resultados y accesibilidad

#### PU-040 · Búsqueda y filtros del catálogo — 5 pts

> **En corto:** Con pocos eventos basta con una lista. Cuando hay más de veinte, el usuario necesita buscar por nombre y filtrar por distancia, fecha, ciudad y precio. Eso es lo que se añade aquí.

Con más de 20 eventos publicados, el listado actual deja de servir.

- Filtros por distancia, fecha, ciudad y precio, aplicados como query params.
- Búsqueda por texto con debounce y estado vacío propio («ningún evento coincide»).
- Los filtros activos se ven y se quitan de uno en uno.
- El scroll infinito y el `ErrorStateView` con «reintentar» se conservan.

#### PU-029 · Tarjeta de resultado compartible — 3 pts

> **En corto:** Al terminar una carrera, poder compartir una imagen con el tiempo, el ritmo, el dorsal y el dibujo de la ruta, por WhatsApp o redes. Hoy el botón existe pero solo muestra un aviso de «próximamente».

Sustituye el snackbar de `race_detail_page.dart:204` («A shareable finisher card is on the way»).

- Widget renderizado a imagen con `RepaintBoundary`: evento, tiempo, ritmo, dorsal y traza de la ruta.
- Compartir por la hoja nativa del sistema.
- Legible en claro y oscuro, a 1080×1080 y a 1080×1920.

#### PU-020a · Cancelación de inscripción (parte funcional) — 2 pts

> **En corto:** El usuario puede cancelar su inscripción: se le muestra la política de reembolso y el importe que le correspondería, y al confirmar se libera su cupo para otro corredor. El movimiento real del dinero queda fuera de alcance y así se le explica.

- La política de reembolso configurada en el evento se muestra antes de confirmar,
  con el importe exacto que correspondería.
- Confirmar libera el cupo y deja la inscripción en `cancelled`.
- La devolución del dinero queda fuera de alcance y así se le dice al usuario.

#### PU-034 · Accesibilidad certificada — 3 pts

> **En corto:** Verificar que la app se puede usar con lector de pantalla (personas ciegas), que los colores contrastan lo suficiente y que nada se rompe con la letra agrandada. Es requisito para publicar en las tiendas.

- Recorrido completo con TalkBack y VoiceOver sin callejones sin salida.
- Contraste AA verificado con herramienta, no a ojo, en los dos temas.
- Sin overflows a `textScaleFactor` 1.3 en 360×640, 390×844, 430×932 y tablet.

### Dev C — resultados, push y permisos

#### PU-026 · Carga de resultados oficiales — 5 pts

> **En corto:** Los resultados que hoy muestra la app son inventados. Esta tarea permite que un organizador suba el archivo real de resultados de la carrera desde el panel de administración, revisando antes qué filas están mal, y que el atleta vea su tiempo y su puesto reales.

Hoy los `RaceResult` que se muestran son sintéticos.

- Importación CSV en el panel: dorsal, tiempo oficial, tiempo de chip, puesto general y puesto por categoría.
- Validación previa con informe de filas rechazadas antes de confirmar nada.
- Publicar resultados deja la inscripción en `completed` y dispara la notificación de PU-028.
- El detalle de la carrera en la app pinta los datos reales en la rejilla de métricas que ya existe.

#### PU-028 · Notificaciones push — 5 pts

> **En corto:** Los interruptores de notificaciones en Ajustes hoy no hacen nada. Esta tarea las hace reales: recordatorio de la sesión del día, avisos del evento y resultados publicados. Al tocar la notificación, la app abre directamente la pantalla que corresponde.

Los interruptores de Ajustes ya existen y hoy no hacen nada.

- FCM y APNs integrados, con alta y baja de token.
- Tres tipos: recordatorio de sesión, actualizaciones del evento y resultados publicados.
- Los interruptores de Ajustes controlan cada tipo **en servidor**, no solo en el cliente.
- Tocar la notificación abre la pantalla correcta por deep link.
- El rechazo del permiso del sistema se respeta sin romper nada.

*(La parte cliente de PU-028 —registro de token, permiso y deep links— la
integra Dev A el D7–D8, con el contrato que Dev C publica el D1.)*

### QA — certificación y publicación

- Prueba de campo real: correr 10 km con el teléfono bloqueado, en dos dispositivos distintos.
- Comparar la ruta grabada contra un GPS de referencia (reloj o segunda app).
- Certificar accesibilidad con TalkBack y VoiceOver, recorrido completo.
- Verificar los tres tipos de notificación en Android e iOS, con la app abierta, en segundo plano y cerrada.
- Preparar y revisar la ficha de tienda: capturas en ambos idiomas, descripción y política de privacidad.
- Regresión completa antes de la subida a TestFlight y Play Console.

---

## 3. Plan diario

Leyenda: **[C]** entrega un contrato del que otro depende · **[V]** queda listo para verificar por QA.

### Semana 1

| Día | Dev A | Dev B | Dev C | QA |
|---|---|---|---|---|
| **D1** lun 7 | Foreground service en Android con notificación persistente | Query params de búsqueda y filtros en `MarathonRepository` | **[C]** Contrato de push (registro de token, tipos, payload de deep link) y de resultados CSV | Plan de certificación del sprint: rutas de campo, guion de a11y, matriz de push |
| **D2** mar 8 | Background location en iOS y permisos «siempre» explicados | UI de filtros: chips activos, quitar de uno en uno, estado vacío | Modelo y endpoint de importación CSV con validación previa | Regresión de cierre del Sprint 1 sobre la build nueva |
| **D3** mié 9 | **[V]** Pantalla bloqueada 10 min sin perder puntos; primera medición de batería | **[V]** Búsqueda con debounce; scroll infinito y error intactos | Informe de filas rechazadas y confirmación en dos pasos en el panel | Primera prueba de campo: 5 km con pantalla bloqueada en Android |
| **D4** jue 10 | Sentry en la app, con release y símbolos desde CI | Tarjeta compartible: layout, `RepaintBoundary` y render a imagen | Publicar resultados: inscripción a `completed` y disparo de notificación | Prueba de campo en iOS; comparar la traza con el GPS de referencia |
| **D5** vie 11 | **[V]** Métricas de producto con consentimiento; alerta de crash-free | **[V]** Compartir por la hoja nativa; verificar 1080×1080 y 1080×1920 | **[V]** Resultados oficiales visibles en la app con datos reales | Verificar PU-033, PU-040 y PU-029; abrir bugs de campo |

### Semana 2

| Día | Dev A | Dev B | Dev C | QA |
|---|---|---|---|---|
| **D6** lun 14 | Sentry en backend coordinado con Dev C; panel de latencia y errores | PU-020a: política visible y cancelación que libera cupo | FCM y APNs: alta y baja de token, envío de los tres tipos | Triaje de los bugs de campo; verificación de arreglos |
| **D7** mar 15 | Cliente de push: permiso, registro de token y baja al cerrar sesión | Recorrido con TalkBack: etiquetas, orden de foco y objetivos táctiles | Los interruptores de Ajustes se aplican en servidor, con test por tipo | Matriz de notificaciones: app abierta, en segundo plano y cerrada, en ambos SO |
| **D8** mié 16 | **[V]** Deep links de las tres notificaciones a la pantalla correcta | **[V]** Contraste AA verificado con herramienta y overflows a 1.3 corregidos | **[V]** Envío de los tres tipos verificado end-to-end | Certificación de accesibilidad completa con TalkBack y VoiceOver |
| **D9** jue 17 | **[V]** PU-032: `FakeDataSeed` con fecha inyectable, goldens y tests de la sesión en vivo | Capturas de tienda en español e inglés, claro y oscuro | Verificación del entorno de producción y del rollback | Regresión completa de todo el producto contra producción |
| **D10** vie 18 | Build de release firmada de Android y iOS desde CI | Ficha de tienda: descripción y política de privacidad | Cierre: documentación de operación y runbook de incidencias | **[V]** Subida a TestFlight y Play Console (internal) y verificación de la instalación |

---

## 4. Demo del sprint (viernes 18-sep)

Instalar desde TestFlight o Play interno; salir a correr 10 minutos con el
teléfono bloqueado en el bolsillo y volver con la ruta completa; un administrador
sube el CSV de resultados de una carrera pasada desde el panel, con dos filas
rechazadas que el informe explica, y publica; al atleta le llega la notificación,
la toca y aterriza en el detalle de la carrera con su tiempo oficial, su puesto y
su dorsal; comparte la tarjeta de finisher por WhatsApp; busca en el catálogo un
maratón de 21K en Santa Cruz con los filtros nuevos. Todo en español, todo
navegable con TalkBack.

---

## 5. Riesgos del sprint

| Riesgo | Mitigación |
|---|---|
| El tracking en segundo plano es lo más frágil del producto | Va el D1–D3, no al final; QA lo prueba en campo desde el D3 y hay margen para dos semanas de arreglos |
| La revisión de App Store cuestiona la ubicación en segundo plano | Justificación clara en la ficha y en el diálogo previo; el texto ya está redactado en `Info.plist` |
| Push en iOS depende de certificados y de la cuenta de Apple | Certificados gestionados el D1, antes de escribir código de cliente |
| RGPD de datos de salud y ubicación | Consentimiento granular, exportación y borrado de cuenta verificados antes de la subida a tienda |
| La subida a tienda se atasca el último día | La build firmada se genera el D9, no el D10; el D10 es solo subir y verificar |

---

## 6. Qué queda fuera al cerrar los dos sprints

Para que quede escrito y no se descubra en la demo:

- **Todo lo de facturación**: pasarela real, recibos PDF, reembolsos con
  devolución de dinero y el módulo de costos e ingresos del panel.
- Del backlog sin planificar: generador de plan adaptativo (PU-042), Strava
  (PU-043), Health/Fit (PU-044), cupones (PU-045), equipos y relevos (PU-046) y
  el resto de la sección 8 de `backlog.md`.

---

## 7. Definition of Done

El mismo del Sprint 1, más dos condiciones propias de este: recorrido verificado
con lector de pantalla, y build de release firmada instalable desde TestFlight y
Play Console interno.
