# Cuentas de prueba y entornos

Las cuentas las crea `npm run db:seed` en `running-api`. La contraseña es la
misma para todas.

| Correo | CI | Contraseña | Rol | Qué tiene |
|---|---|---|---|---|
| `runner@test.com` | `6789012LP` | `Test1234!` | `runner` | **La cuenta con datos.** Cuatro meses de entrenamientos con GPS, un plan de 21K a mitad de camino, cuatro inscripciones y tres pares de zapatillas |
| `runner2@test.com` | `5544332CB` | `Test1234!` | `runner` | **Vacía a propósito.** Es con la que se comprueba que los datos de uno no se ven desde la sesión de otro |
| `admin@test.com` | `1000001LP` | `Test1234!` | `admin` | Panel de administración en `/admin` |
| `runner3@test.com` | `7788990SC` | `Test1234!` | `runner` | Vacía, en Santa Cruz |
| `runner4@test.com` | `3322110CB` | `Test1234!` | `runner` | Vacía, en Cochabamba |
| `runner5@test.com` | `9988776SU` | `Test1234!` | `runner` | Vacía, en Sucre |

El campo de la pantalla de login acepta **cualquiera de los dos**: con `@` se
trata como correo, sin `@` como CI. Es el mismo campo, así que se puede probar
`6789012LP` / `Test1234!` sin cambiar nada.

Qué hay exactamente en `runner@test.com`:

- ~40 entrenamientos repartidos en cuatro meses, con posiciones GPS, splits y
  sensaciones.
- Un plan activo instanciado, con la semana en curso a medio completar.
- Cuatro inscripciones: una futura pagada con tarjeta, una futura pendiente de
  QR, una pasada con resultado completo (marcas cada 5 km y puestos) y una
  cancelada con reembolso.
- Tres zapatillas, una cerca del umbral de desgaste.
- Cargo por servicio global **activo** (10 %, mínimo Bs 5), para poder probar
  activarlo y desactivarlo.

## Probar el cobro por QR con verificación manual

El seed carga un QR de cobro escaneable en **todas** las maratones, así que el
método "Bank QR" aparece en el paso 3 sin tocar nada. El recorrido completo:

1. Con `runner@test.com`, inscríbete en una maratón y elige **Bank QR**.
   El cobro queda pendiente y la app pinta el QR y la glosa (`PU-XXXXXX`).
2. Toca **Upload receipt** y elige cualquier imagen de la galería. El estado
   pasa a *Receipt under review*: **la inscripción sigue sin confirmar**, que es
   justo lo que hay que comprobar.
3. Entra en `/admin` con `admin@test.com`, pestaña **Comprobantes QR**, y
   aprueba. Ahí se emite el dorsal y se toma el cupo.
4. Rechaza en vez de aprobar para ver el otro camino: el cobro **sigue abierto**
   y la app deja subir otra imagen, con el motivo del rechazo a la vista.

Para el alta desde la web (cuenta creada con usuario CI y contraseña CI), llama
a `POST /public/registrations` con una CI que no exista y entra en la app con
esa CI en los dos campos: la app te manda directo a cambiar la contraseña y no
te deja salir de ahí hasta que lo hagas.

El flujo entero, y cómo se desmonta cuando entre una pasarela real, está en
`running-api/docs/pago-qr-manual.md`.

## Apuntar la app a un backend

La URL base **no se escribe en el código**: entra como constante de
compilación. Los dos entornos ya están en la raíz del repo.

| Entorno | Archivo | Comando |
|---|---|---|
| Producción | `.env` (`https://runner-app.tumype.com/api/v1`) | `make run` |
| Local | `.env.local` (`http://10.0.2.2:3000/api/v1`) | `make run-local` |

o, sin `make`:

```bash
flutter run --dart-define-from-file=.env
```

`--dart-define-from-file` es de Flutter, no hace falta ningún paquete. Y como
lo que hay dentro se **incrusta en el binario**, en esos archivos no va nunca
un secreto: cualquiera con el APK puede leerlos.

Sin ninguno de los dos, la app cae al backend local por defecto
(`api_config.dart`): `10.0.2.2:3000` en el emulador de Android —que es como ve
al equipo anfitrión— y `localhost:3000` en el resto.

### Dispositivo físico contra un backend local

`10.0.2.2` solo existe dentro del emulador. Desde un teléfono de verdad hay que
usar la IP del equipo en la red:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api/v1
```

## En Chrome contra el backend real

```bash
make run-web      # flutter run -d chrome --web-port=5000 --dart-define-from-file=.env
```

**El puerto va fijo a propósito.** El navegador exige que el origen esté
autorizado por el backend, y `flutter run -d chrome` elige un puerto distinto
cada vez: uno aleatorio no se puede meter en una lista blanca. Hay que añadirlo
en el VPS, en `/etc/running-api/.env.production`:

```
CORS_ORIGINS=https://runner-app.tumype.com,http://localhost:5000
```

```bash
sudo systemctl restart running-api
```

Sin eso, Chrome bloquea cada petición y la app se queda en el esqueleto de
carga —el backend responde `200`, pero el navegador tira la respuesta—. Se
comprueba así, que hoy **no** devuelve la cabecera:

```bash
curl -sI -H "Origin: http://localhost:5000"   https://runner-app.tumype.com/api/v1/config/app | grep -i access-control-allow-origin
```

Qué no funciona igual en web, para que no sorprenda:

| Pieza | En Chrome |
|---|---|
| Grabar un entrenamiento en segundo plano | No. El GPS del navegador se para al cambiar de pestaña |
| Tokens | Van a `localStorage`, no al Keychain: para mirar pantallas vale, para juzgar seguridad no |
| Mapas y el resto de la UI | Igual que en el teléfono |

Web es para ver pantallas rápido. Lo que se prueba de verdad —tracking,
permisos, segundo plano— se prueba en un teléfono.

## Estado de producción (20-08-2026, 22:16)

`https://runner-app.tumype.com/api/v1` **funciona**. Lo que falla es que la
base está vacía: falta sembrarla.

| Petición | Respuesta |
|---|---|
| `GET /health` | `200` |
| `GET /api/v1/config/app` | `200` — BOB, `America/La_Paz`, `serviceFee: null` |
| `GET /api/v1/marathons` | `200` con `data: []` — **catálogo vacío** |
| `POST /api/v1/auth/login` (`runner@test.com`) | `401 INVALID_CREDENTIALS` — **la cuenta no existe** |
| `GET /api/v1/home/summary` sin token | `401 UNAUTHORIZED` — el guard responde bien |

Un solo comando en el VPS lo arregla:

```bash
cd /srv/running-api && npm run db:seed
```

Mientras tanto la app abre y llega al login, pero no hay con qué entrar. Dos
salidas: sembrar, o crear una cuenta desde la pantalla de registro de la propia
app —el alta funciona igual, solo que esa cuenta nace sin entrenamientos ni
inscripciones—.

`serviceFee: null` significa que el cargo por servicio está **desactivado**: la
UI no debe pintar esa línea. Sembrando queda activo al 10 % con mínimo Bs 5, que
es lo que hace falta para probar activarlo y desactivarlo.
