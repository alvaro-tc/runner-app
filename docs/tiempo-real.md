# Tiempo real: como llega cada aviso

Las dos piezas del backend ya estan hechas (`../running-api`). Esto es lo que
hay y por que, no una lista de pendientes.

## 1. Sala personal del corredor → `user:{userId}`

El socket mete a cada cliente en `user:{userId}` en el handshake, donde ya se
valida el JWT (`live.gateway.ts`). Por ahi van dos cosas:

- **`registration:state`** cuando algo cambia en una inscripcion: pago validado,
  comprobante rechazado, dorsal emitido, inscripcion cancelada o reembolsada. El
  payload es solo el id: la app relee `GET /registrations/me`, que es la fuente.
  Se emite desde `RegistrationsService` (confirmar, devolver a pendiente,
  cancelar, liberar) y desde `PaymentProofService.rechazar` —ese no toca la
  inscripcion, asi que nadie mas lo avisaria—.
- **`marathon:state`** va ademas a la sala personal de cada inscrito
  confirmado, no solo a `marathon:{id}`. La preparacion, la largada y el corte
  llegan aunque la app no hubiera pedido esa sala. Socket.IO entrega una sola
  vez a quien esta en las dos.

Esto es lo que hace inmediato el pago validado: quien espera revision no esta
inscrito todavia, y no hay sala de maraton de la que colgarle el aviso.

## 2. Posicion en preparacion → el organizador ve la salida

`GET/POST /tracking/osmand` resuelve el dispositivo a su sesion abierta; si no
tiene, busca una **inscripcion confirmada en una maraton en fase `preparing`** y
publica `runner:position` en `marathon:{id}` con `distanceMeters: 0`
(`LiveService.publicarCalentamiento`). Esos puntos **no se guardan**: son de
antes de la largada y no pueden acabar en el entrenamiento; la respuesta dice
`accepted: 0`. Un dispositivo que no es ninguna de las dos cosas sigue dando
`SESSION_NOT_ACTIVE`.

La resolucion dispositivo → maraton se cachea un minuto, positivos y negativos:
OsmAnd manda un punto por peticion y sin cache seria una consulta por segundo y
por corredor. Cuando arranca la sesion de verdad, `publicar()` borra el estado
de calentamiento de ese dispositivo para que no queden dos marcadores con el
mismo dorsal.

La app arranca Traccar en cuanto entra en preparacion (`PreRaceBeacon`) y **no**
lo apaga en la largada: la sesion de carrera se hace cargo del mismo servicio,
asi que el corredor no desaparece del mapa ni un segundo.

## Por que Traccar y no el socket para la posicion

El corredor se guarda el telefono y el sistema suspende la app. Un socket de
Dart se muere ahi; el servicio nativo de Traccar —el que ya sube durante la
carrera, con wakelock y cola offline— no.

## Cuando el aviso no llega

Nada de esto es la unica via. La app sondea "mis carreras" cada 20 s con la
pantalla abierta (`RacesAutoRefresh`), y la lista trae las mismas fechas que el
socket: quien abrio la app con la carrera ya en marcha acaba en la misma
pantalla sin haber recibido ningun evento.

El socket solo esta abierto cuando hace falta: mientras un pago espera
validacion, y desde 12 h antes de una carrera propia (`MarathonGateNotifier`).
Fuera de esa ventana el aviso lo recoge el sondeo.
