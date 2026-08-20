# Cuentas de prueba y entornos

Las tres cuentas las crea `npm run db:seed` en `running-api`. La contraseña es
la misma para todas.

| Correo | Contraseña | Rol | Qué tiene |
|---|---|---|---|
| `runner@test.com` | `Test1234!` | `runner` | **La cuenta con datos.** Cuatro meses de entrenamientos con GPS, un plan de 21K a mitad de camino, cuatro inscripciones y tres pares de zapatillas |
| `runner2@test.com` | `Test1234!` | `runner` | **Vacía a propósito.** Es con la que se comprueba que los datos de uno no se ven desde la sesión de otro |
| `admin@test.com` | `Test1234!` | `admin` | Panel de administración en `/admin` |

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

## Estado de producción (20-08-2026)

`https://runner-app.tumype.com/api/v1` responde, pero **todo lo que toca la
base de datos devuelve `500 INTERNAL_ERROR`**:

| Petición | Respuesta |
|---|---|
| `GET /health` | `200` — el proceso está vivo |
| `GET /api/v1/config/app` | `500 INTERNAL_ERROR` |
| `GET /api/v1/marathons` | `500 INTERNAL_ERROR` |
| `POST /api/v1/auth/login` | `500 INTERNAL_ERROR` |

Que `/health` conteste y el resto no apunta a la conexión con Postgres o a las
migraciones, no a la app Flutter. Qué mirar en el VPS:

```bash
journalctl -u running-api -n 100 --no-pager   # la traza real, con su requestId
sudo -u postgres psql -c '\l'                 # la base existe?
cd /srv/running-api && npx prisma migrate deploy
npm run db:seed                               # sin esto no hay cuentas de prueba
```

Los `requestId` de las pruebas de arriba —`d6944417…`, `e2c82d55…`,
`73dba757…`— están en los logs del servidor y llevan a la excepción exacta.

Hasta que eso se arregle, la app contra producción no pasa de la pantalla de
login. Con `make run-local` y el backend en la máquina funciona igual.
