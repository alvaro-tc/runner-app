# Cumplimiento Play Store / App Store — CamRun

## 1. URLs publicas (a crear en cam-run.tumype.com)

| Que | URL | Quien la pide |
|---|---|---|
| Politica de privacidad | `https://cam-run.tumype.com/privacidad` | Ficha de Play Console, Data Safety, App Store |
| Solicitud de borrado de cuenta | `https://cam-run.tumype.com/eliminar-cuenta` | Play Console > "URL de eliminacion de cuenta" |

Ambas deben abrir **sin iniciar sesion** y sin redirigir a un login.

## 2. Hecho en la app

- `lib/core/constants/legal_urls.dart` — las dos URLs, en un solo sitio.
- Ajustes > Ayuda > "Politica de privacidad" abre la politica en el navegador.
- Registro: enlace "Leer la politica de privacidad" bajo el check de terminos.
- Ajustes > Cuenta > "Eliminar cuenta": borrado dentro de la app
  (`DELETE /auth/me` con contrasena + dialogo de confirmacion) y, al pie,
  enlace a la pagina web de solicitud.

## 3. Data Safety form (Play Console) — respuestas

**¿Recoge o comparte datos de usuario?** Si, recoge. **No comparte con terceros.**
**¿Cifrado en transito?** Si (HTTPS/TLS a `cam-run.tumype.com`).
**¿El usuario puede pedir el borrado de sus datos?** Si — desde la app y desde la web.

| Categoria | Tipo de dato | Recogido | Compartido | Obligatorio | Proposito |
|---|---|---|---|---|---|
| Info personal | Direccion de correo | Si | No | Si | Gestion de la cuenta, inicio de sesion |
| Info personal | Nombre | Si | No | Si | Gestion de la cuenta, perfil |
| Info personal | Otra info (fecha nacimiento, sexo, peso/altura si el usuario los rellena) | Si | No | No | Funcionalidad de la app (calculo de ritmo/calorias) |
| Fotos | Foto de perfil y comprobante de pago | Si | No | No | Funcionalidad de la app, inscripciones |
| Ubicacion | **Ubicacion precisa** | Si | No | Si (para grabar salidas) | Funcionalidad de la app: trazar la ruta, ritmo y distancia; seguimiento en vivo durante la maraton |
| Ubicacion | Ubicacion aproximada | Si | No | No | Funcionalidad de la app |
| Actividad fisica | Actividad, distancia, ritmo, duracion | Si | No | Si | Funcionalidad de la app, historial y plan de entrenamiento |
| Info financiera | Comprobante de pago (imagen) subido por el usuario | Si | No | No | Inscripcion a carreras |
| Info de la app | Registros de fallos / diagnostico | No | No | — | — |

Notas para el formulario:
- La ubicacion se recoge **tambien en segundo plano** (`ACCESS_BACKGROUND_LOCATION`,
  servicio en primer plano con notificacion) mientras hay una salida grabando.
  Declararlo y grabar el video de justificacion de background location que pide Play.
- Se usa `ACTIVITY_RECOGNITION` para ahorrar bateria: entra en "Actividad fisica".
- Ningun SDK envia datos a terceros: el seguimiento en vivo (Traccar SDK) sube a
  `cam-run.tumype.com`, servidor propio.
- Los datos **no se venden** ni se usan para publicidad ni scoring crediticio.


