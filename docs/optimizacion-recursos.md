# Optimización de recursos — septiembre de 2026

Se conservan las funciones de entrenamiento, inscripciones, avisos, mapas,
grabación en segundo plano y sincronización sin cobertura. Los cambios están
en el código local; no se desplegaron ni se publicaron binarios.

## Fuentes de consumo corregidas

| Área | Antes | Ahora |
|---|---|---|
| Mapas | Abrir un mapa iniciaba también la descarga de toda La Paz, incluso en vistas sin teselas | Solo se precarga el circuito abierto; se consultan archivos existentes, se comparten descargas y se detiene la precarga al cerrar la vista o pasar al fondo |
| Carrera | Copia completa del recorrido y recálculo de todos los parciales en cada punto | Instantáneas inmutables comparten bloques de 64 puntos; los parciales procesan solo el segmento nuevo |
| Dibujo | La reconstrucción del reloj llegaba al widget del mapa | El mapa conserva su instancia y limita el repintado; la geometría del circuito se guarda entre actualizaciones |
| Ubicación | Los ajustes nativos heredaban precisión máxima; cada ping reconfiguraba Traccar | Precisión `high`, conservando el intervalo y filtro de calidad; una configuración compartida y un ping simultáneo como máximo |
| Segundo plano | Sondeos de carreras/notificaciones y relojes de interfaz seguían activos | Los sondeos y el reloj visual se suspenden; el GPS, la subida nativa y la cola de carrera siguen funcionando |
| Home | Carrusel oculto y cuenta atrás con reconstrucciones por segundo aunque muestra minutos | El carrusel se detiene cuando no está visible; la cuenta se actualiza en el cambio de minuto y al regresar |
| Memoria | Afiches y avatares decodificados a resolución original; proveedores de búsquedas/detalles retenidos | Imágenes dimensionadas según pantalla y liberación de proveedores al perder consumidores |
| Sincronización | Vaciar una cola sin cambios invalidaba el estado del historial | Solo los cambios de entrenamientos y escrituras notifican al historial; las escrituras GPS y el cierre esperan las tareas pendientes |
| Socket | La conexión personal podía quedar abierta después de validar el pago | Se cuentan los consumidores y se cierra cuando no quedan interesados; los temporizadores de reconexión se liberan |

No se redujo el muestreo de los entrenamientos ni se eliminaron puntos del
recorrido. Traccar mantiene el seguimiento nativo de la maratón; Geolocator
sigue proporcionando las métricas locales porque la versión instalada del SDK
de Traccar no expone un stream de posiciones a Flutter.

## Cambio necesario en runner-api

El móvil del corredor recibía las posiciones de todos los participantes y
descartaba las ajenas en Dart. Ese coste de red crecía con cada inscrito.

`spectate` acepta ahora `positions: false`. El servidor verifica la inscripción
del usuario autenticado y lo suscribe al estado de la maratón y a su propio
dorsal. Las posiciones y llegadas se envían al canal completo y al dorsal
correspondiente. Preparación, largada y corte siguen llegando al corredor.

Los organizadores y los clientes anteriores conservan el canal completo. Hay
que desplegar **runner-api antes de distribuir la app nueva** para obtener esta
reducción de tráfico. Con el servidor anterior la app sigue recibiendo el canal
completo. No se cambió el esquema de la base ni la API de ingesta GPS.

## Comprobaciones

- El análisis estático de `lib` y el comprobador de rendimiento pasó sin
  incidencias. TypeScript y ESLint del cambio del backend también pasaron.
- Pasaron **22 pruebas** del backend. Las del gateway cubren la suscripción
  propia, autenticación pendiente,
  rechazo de usuarios sin inscripción, compatibilidad, posiciones, llegada,
  estado y liberación de salas. También se ejecutan las pruebas existentes de
  estado en vivo y preparación.
- `tool/check_run_performance.dart` comprueba instantáneas en los límites de
  bloques y compara los parciales con el cálculo anterior, incluyendo 42 km,
  puntos repetidos y segmentos que atraviesan varios kilómetros.
- En una ejecución local, 12.000 inserciones tardaron aproximadamente **78 ms**
  con copias completas y **0,6 ms** con bloques compartidos. Es una comprobación
  de esa operación en Dart, no una medida del consumo total del teléfono.

```bash
dart run tool/check_run_performance.dart
flutter analyze
flutter test --no-pub test/core/sync test/features/train/run_session_test.dart \
  test/features/races test/features/home test/shared
```

Las pruebas de Flutter se intentaron pero el entorno de trabajo bloqueó el
puerto local que necesita `flutter_tester`. La compilación del bundle también
quedó bloqueada al necesitar una biblioteca SQLite de GitHub sin acceso de red.
Esas comprobaciones no se consideran aprobadas.

## Medición pendiente en dispositivos

Comparar el mismo dispositivo y las mismas condiciones antes y después: cinco
minutos en Home, navegación por las cuatro pestañas, entrenamiento de 30 minutos
con pantalla encendida/apagada, pausa/reanudación, carrera oficial y pérdida de
conectividad. Usar `flutter run --profile --dart-define-from-file=.env` para CPU,
memoria, reconstrucciones y tiempos de cuadro; para batería, comparar builds
release con Android Studio y Xcode Instruments. Confirmar que las rutas y los
avisos de largada/llegada siguen completos.

Este trabajo sigue el criterio de limitar reconstrucciones y conservar partes
estables del árbol descrito en las [recomendaciones de rendimiento de Flutter](https://docs.flutter.dev/perf/best-practices).
