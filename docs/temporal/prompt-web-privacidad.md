# Prompt para generar las paginas legales en cam-run.tumype.com

Pegalo tal cual en el agente/dev que trabaje sobre la web.

---

Crea dos paginas publicas y estaticas en el sitio `cam-run.tumype.com`, accesibles
sin iniciar sesion, indexables, con el mismo layout/estilo del resto del sitio y
enlazadas desde el footer:

## Pagina 1 — `/privacidad` (titulo: "Politica de privacidad de CamRun")

Escribela en espanol, con lenguaje claro, fecha de "ultima actualizacion" visible,
y **debe mencionar explicitamente** la recoleccion de ubicacion precisa y de datos
de cuenta. Secciones:

1. **Quienes somos y como contactarnos** — CamRun, app de running (Android/iOS y web).
   Contacto de privacidad: `alvarocallet@gmail.com`.
2. **Que datos recogemos**
   - *Datos de cuenta*: correo electronico y contrasena (la contrasena se guarda
     siempre con hash, nunca en claro), nombre, foto de perfil opcional y datos
     deportivos opcionales (fecha de nacimiento, sexo, peso, altura).
   - *Ubicacion precisa (GPS)*: CamRun recoge la **ubicacion precisa del
     dispositivo**, incluida **en segundo plano y con la pantalla apagada**,
     unicamente mientras el usuario tiene una salida en grabacion o participa en
     una carrera con seguimiento en vivo. Sirve para trazar la ruta, calcular
     distancia, ritmo y desnivel, y mostrar la posicion en el mapa en vivo de la
     maraton. La grabacion se inicia siempre por accion explicita del usuario y
     se detiene cuando este la para; con la app sin salida activa no se recoge
     ninguna ubicacion.
   - *Actividad fisica*: distancia, ritmo, duracion, y el sensor de reconocimiento
     de actividad para ahorrar bateria cuando el usuario esta parado.
   - *Inscripciones y pagos*: datos de inscripcion a carreras y la imagen del
     comprobante de pago que el usuario sube.
   - *Datos tecnicos minimos*: registros de servidor necesarios para operar y
     proteger el servicio.
3. **Para que usamos los datos** — prestar el servicio (cuenta, historial de
   salidas, plan de entrenamiento, inscripciones), seguridad y soporte. Nada mas.
4. **Con quien los compartimos** — no vendemos ni compartimos datos personales con
   terceros con fines publicitarios ni de analitica. Los datos se alojan en la
   infraestructura propia de CamRun. Solo se comparten los datos minimos de la
   inscripcion con el organizador de la carrera en la que el usuario se inscribe,
   y cuando lo exija la ley.
5. **Seguridad** — todo el trafico entre la app y el servidor viaja **cifrado con
   HTTPS/TLS**; las contrasenas se almacenan con hash y las credenciales de sesion
   en el almacen seguro del dispositivo.
6. **Conservacion y borrado** — conservamos los datos mientras la cuenta exista.
   El usuario puede **eliminar su cuenta y todos sus datos** desde la app en
   *Perfil > Ajustes > Cuenta > Eliminar cuenta*, o desde
   `https://cam-run.tumype.com/eliminar-cuenta`. Enlaza esa pagina desde aqui.
7. **Derechos del usuario** — acceso, rectificacion, portabilidad y supresion,
   escribiendo a `alvarocallet@gmail.com`.
8. **Menores** — el servicio no esta dirigido a menores de 13 anos.
9. **Cambios en esta politica** — se avisara en la app y en esta pagina.

## Pagina 2 — `/eliminar-cuenta` (titulo: "Eliminar tu cuenta de CamRun")

Debe explicar y ofrecer:

1. **Como borrarla desde la app** (via preferente): abrir CamRun >
   *Perfil > Ajustes > Cuenta > Eliminar cuenta*, confirmar con la contrasena.
   El borrado es inmediato e irreversible.
2. **Formulario web** para quien ya no tiene la app instalada: campos
   *correo de la cuenta* y *motivo (opcional)*, boton "Solicitar eliminacion",
   con una casilla de confirmacion de que la accion es irreversible. Al enviarlo,
   se manda un correo de verificacion a esa direccion y solo se borra tras
   confirmar el enlace, para que nadie pueda pedir el borrado de una cuenta ajena.
   Plazo maximo de tramitacion: 30 dias.
3. **Que se borra**: perfil, salidas y rutas, plan de entrenamiento, inscripciones
   y foto de perfil. **Que se conserva y por que**: los registros contables de los
   pagos ya realizados, que el organizador debe guardar por obligacion legal,
   desvinculados de la cuenta.
4. Enlace a `/privacidad`.

Ambas paginas: responsive, sin cookies de terceros ni scripts de analitica, y
accesibles (contraste, jerarquia de encabezados, formulario con labels).
