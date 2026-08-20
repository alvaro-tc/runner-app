# PaceUp

App móvil de running en Flutter: plan de entrenamiento, seguimiento de carreras
en vivo con GPS, historial persistente e inscripción a maratones.

Front-end completo. Toda la data viene de repositorios en memoria con latencia
simulada; la capa de datos está diseñada para que pasar a una API real sea un
cambio de una línea por repositorio (ver
[ARCHITECTURE.md](ARCHITECTURE.md#9-sustituir-los-fakes-por-una-api-real)).

## Requisitos

- Flutter 3.44 o superior (Dart 3.12)
- Android SDK y/o Xcode

## Puesta en marcha

```bash
flutter pub get
make run          # contra el backend de produccion (.env)
make run-local    # contra el backend en esta maquina (.env.local)
```

Al arrancar por primera vez verás el onboarding. La sesión ya es real: entra
con `runner@test.com` / `Test1234!` (las demás cuentas y el estado de cada
entorno, en [docs/cuentas-de-prueba.md](docs/cuentas-de-prueba.md)).

## Comandos

```bash
make run              # flutter run --dart-define-from-file=.env
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
