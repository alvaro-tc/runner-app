# PaceUp

App móvil de running en Flutter: plan de entrenamiento, seguimiento de carreras
en vivo con GPS, historial persistente e inscripción a maratones.

Los datos salen de [`running-api`](../running-api). Auth, Home y el catálogo de
maratones ya hablan con el backend real; Train, Races y Profile siguen con
repositorios en memoria hasta sus fases (ver
[ARCHITECTURE.md](ARCHITECTURE.md#9-sustituir-los-fakes-por-una-api-real)).

## Requisitos

- Flutter 3.44 o superior (Dart 3.12)
- Android SDK y/o Xcode. Para la web, solo Chrome
- Un backend al que apuntar: el de producción o
  [`running-api`](../running-api) corriendo en local

## Puesta en marcha

```bash
flutter pub get
make run          # movil, contra el backend de produccion
make run-web      # Chrome, contra el backend de produccion
make run-local    # movil, contra el backend de esta maquina
```

Al arrancar por primera vez verás el onboarding. La sesión ya es real: entra
con `runner@test.com` / `Test1234!` (las demás cuentas, en
[docs/cuentas-de-prueba.md](docs/cuentas-de-prueba.md)).

### A qué backend apunta cada comando

La URL base **no se escribe en el código**: entra como constante de
compilación desde un archivo de la raíz del repo. `--dart-define-from-file` es
de Flutter, no hace falta ningún paquete.

| Comando | Archivo | URL base |
|---|---|---|
| `make run` / `make run-web` | `.env` | `https://cam-run.tumype.com/api/v1` |
| `make run-local` | `.env.local` | `http://10.0.2.2:3000/api/v1` |

Lo que hay en esos archivos se **incrusta en el binario**: ahí no va nunca un
secreto. Desde un teléfono físico contra un backend local, `10.0.2.2` no sirve
—solo existe dentro del emulador de Android—, hay que usar la IP del equipo:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api/v1
```

### En Chrome contra el backend real

```bash
make run-web
```

**El puerto va fijo (5000) a propósito.** El navegador exige que el origen esté
autorizado por el servidor, y `flutter run -d chrome` elegiría uno distinto cada
vez: un puerto aleatorio no se puede meter en una lista blanca. En el backend,
`/etc/running-api/.env.production`:

```
CORS_ORIGINS=https://cam-run.tumype.com,http://localhost:5000
```

```bash
sudo systemctl restart running-api
```

Sin eso Chrome bloquea cada petición y la app se queda en el esqueleto de
carga: el servidor responde `200` y el navegador tira la respuesta. Se
comprueba con

```bash
curl -sI -H "Origin: http://localhost:5000"   https://cam-run.tumype.com/api/v1/config/app | grep -i access-control-allow-origin
```

En web no todo se comporta igual: el GPS del navegador se para al cambiar de
pestaña —no hay grabación en segundo plano— y los tokens van a `localStorage`,
no al Keychain. Sirve para ver pantallas rápido; el tracking se prueba en un
teléfono.

### Backend en local

```bash
cd ../running-api
npm install && npx prisma migrate deploy && npm run db:seed
npm run dev            # escucha en :3000
```

y en otra terminal, `make run-local`. Sin `db:seed` no hay maratones ni cuentas
de prueba: la app arranca, pero no hay con qué entrar.

## Comandos

```bash
make run              # movil contra produccion
make run-web          # Chrome contra produccion, puerto 5000
make run-local        # movil contra localhost:3000
make fmt              # dart format .
make analyze          # flutter analyze
make test             # flutter test
flutter test --update-goldens   # regenerar capturas de referencia
```

## Qué incluye

**Cuatro pestañas** con pila de navegación independiente:

| Tab | Contenido |
|---|---|
| **Home** | Cuenta atrás del próximo maratón, tarjeta del evento, plan semanal con anillos de progreso y sesión del día |
| **Train** | Inicio rápido, resumen semanal con gráfico de barras, historial agrupado y filtrable |
| **Races** | Totales calculados, inscripciones próximas y completadas con resultados |
| **Profile** | Estadísticas, calzado, sueño, hidratación y ajustes |

**Flujos completos**

- Onboarding de 3 slides → welcome → sign in / sign up / recuperar contraseña.
- Detalle de maratón e inscripción en 3 pasos (datos, categoría y extras, pago
  simulado) que genera un dorsal y aparece de inmediato en Races.
- Sesión de running a pantalla completa: cuenta atrás 3-2-1, mapa que sigue tu
  posición, ritmo y splits en vivo, pausa, auto-pausa y finalización con
  pulsación mantenida.
- Resumen post-entrenamiento con mapa, métricas, gráfico de splits, sensación y
  notas; se guarda en Hive y sobrevive al reinicio.
- Perfil editable con validación, estado *dirty* y diálogo de descarte.

**Tema claro y oscuro** completos, conmutables desde *Profile → Appearance* y
persistidos entre sesiones.

## Probar la carrera sin salir a correr

En modo debug `LocationService` usa `SimulatedLocationService`, que reproduce
una ruta pregrabada 20 veces más rápido que la vida real. Puedes iniciar una
sesión desde el emulador y ver la polilínea, las métricas y los splits
avanzar. Para probar el GPS real en un dispositivo, sobrescribe
`useSimulatedLocationProvider` con `false`.

## Capturas

Las capturas de referencia en claro y oscuro se generan como goldens y viven en
`test/golden/goldens/`:

| | Claro | Oscuro |
|---|---|---|
| Home | `home_light.png` | `home_dark.png` |
| Races | `races_light.png` | `races_dark.png` |
| Profile | `profile_light.png` | `profile_dark.png` |

Regenéralas con `flutter test --update-goldens`.

## Catálogo de componentes

En modo debug, navega a `/dev/showcase` para ver todos los átomos y moléculas
del design system con un interruptor de tema.

## Documentación

- [docs/cuentas-de-prueba.md](docs/cuentas-de-prueba.md) — cuentas sembradas,
  cómo apuntar la app a cada backend y estado de producción.
- [ARCHITECTURE.md](ARCHITECTURE.md) — capas, convenciones, cómo añadir una
  feature, cómo sustituir los fakes y las desviaciones respecto al brief.
