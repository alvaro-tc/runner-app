# Publicar CamRun en Google Play — datos a rellenar

Documento de checklist. Lo que ya esta resuelto en el codigo se marca **[hecho]**;
lo que hay que decidir o escribir a mano queda como campo en blanco.

## 1. El artefacto

```
make aab      # flutter build appbundle --release --dart-define-from-file=.env
```

Sale en `build/app/outputs/bundle/release/app-release.aab` (~70 MB).

| Dato | Valor actual | Donde se cambia |
|---|---|---|
| Nombre del paquete (`applicationId`) | `com.tumype.camrun` | `android/app/build.gradle.kts`. **No se puede cambiar despues del primer envio.** |
| Nombre visible | `CamRun` | `android/app/src/main/AndroidManifest.xml` (`android:label`) |
| `versionName` / `versionCode` | `1.0.0` / `1` | `pubspec.yaml` → `version: 1.0.0+1`. Cada subida a Play necesita un `versionCode` **mayor**; el nombre puede repetirse. |
| `minSdk` / `targetSdk` | 24 / 36 | `android/app/build.gradle.kts` |
| Firma | clave de release de `android/key.properties` + `android/upload-keystore.jks` | Ninguno de los dos esta en git: si se pierden, **no se puede volver a actualizar la app**. Guardar copia fuera de la maquina. |
| `API_BASE_URL` incrustada | la de `.env` (produccion) | `.env`. Compilar con `.env.local` deja `10.0.2.2` dentro y la app no conecta desde un telefono real. |

Antes de subir: `make analyze`, `make test`, e instalar el APK de release en un
telefono fisico y hacer login + grabar una salida. El bundle de Play no se puede
probar directamente; si se quiere, con `bundletool build-apks --local-testing`.

## 2. Play Console — cuenta y app

| Campo | Valor |
|---|---|
| Cuenta de desarrollador (25 USD, pago unico) | ______ |
| Tipo de cuenta | Personal / Organizacion: ______ (si es organizacion hace falta D-U-N-S) |
| Nombre del desarrollador que se muestra en la ficha | ______ |
| Correo y telefono de contacto publicos | ______ |
| Nombre de la app (30 caracteres) | `CamRun` |
| Idioma por defecto | Espanol (Latinoamerica) — la app tambien tiene ingles |
| Tipo | App (no juego) |
| Gratis o de pago | Gratis (una vez publicada como gratis **no se puede pasar a de pago**) |
| Paises de distribucion | Bolivia + ______ |

## 3. Ficha de Play Store (Store listing)

| Campo | Limite | Estado |
|---|---|---|
| Descripcion breve | 80 caracteres | ______ |
| Descripcion completa | 4000 caracteres | ______ |
| Icono | 512x512 PNG, 32 bits | derivar del de la app (`android/app/src/main/res/mipmap-*`) |
| Grafico destacado (feature graphic) | 1024x500 PNG/JPG | ______ |
| Capturas de telefono | minimo 2, maximo 8, 16:9 o 9:16, lado corto ≥ 320 px | sugeridas: inicio, salida en vivo, historial, detalle de carrera, plan de entrenamiento |
| Capturas de tablet 7" y 10" | opcionales | ______ |
| Video de YouTube | opcional | ______ |
| Categoria | — | Salud y bienestar (alternativa: Deportes) |
| Etiquetas | hasta 5 | running, entrenamiento, GPS, carreras, maraton |

## 4. URLs publicas obligatorias

Las dos tienen que abrir **sin login**. Ver `docs/play-store-privacidad.md`.

| Que | URL | Estado |
|---|---|---|
| Politica de privacidad | `https://cam-run.tumype.com/privacidad` | **[bloqueante]** confirmar que ya esta publicada |
| Eliminacion de cuenta | `https://cam-run.tumype.com/eliminar-cuenta` | **[bloqueante]** idem |

## 5. Contenido de la app (seccion "Content" del panel)

| Formulario | Respuesta |
|---|---|
| Data safety | Ya redactado en `docs/play-store-privacidad.md` §3. **Revisar antes de enviarlo**: ese documento declara background location y `ACTIVITY_RECOGNITION`, pero el manifest actual los elimina (`tools:node="remove"`). Con el manifest de hoy la respuesta correcta es **no** hay recogida en segundo plano y **no** se usa actividad fisica del sensor. |
| Clasificacion de contenido (cuestionario IARC) | Categoria "Referencia/Educacion o Estilo de vida", sin violencia, sin contenido sexual, sin apuestas, sin compras. Comparte ubicacion con otros usuarios durante la maraton → declararlo. |
| Publico objetivo | 18+ (o 13+; si se marca por debajo de 13 se activan las politicas de Families y hay que cambiar el consentimiento) |
| Anuncios | No contiene anuncios |
| Permisos sensibles: ubicacion precisa | Justificacion: grabar la ruta, ritmo y distancia de la salida, y el seguimiento en vivo durante una maraton. Se pide solo cuando el usuario inicia una grabacion. |
| Permiso de servicio en primer plano (`FOREGROUND_SERVICE_LOCATION`) | Declaracion obligatoria + **video de demostracion** (enlace de YouTube o Drive, no listado) mostrando el flujo: usuario pulsa iniciar → aparece la notificacion persistente → la ruta se sigue trazando con la pantalla apagada. **[bloqueante, grabarlo]** |
| App de noticias / finanzas / salud / gobierno | No |
| Seguridad de datos: cifrado en transito | Si, HTTPS |
| Cuentas de gobierno / COVID | No |

## 6. Acceso de los revisores

Google necesita entrar a la app. La cuenta de prueba **no puede ser una del seed
de desarrollo**: apuntan a la API local. Crear una en produccion y anotar:

| Campo | Valor |
|---|---|
| Correo | ______ |
| Contrasena | ______ |
| Instrucciones | "El campo de login acepta correo o CI. Para ver el seguimiento en vivo hace falta estar inscrito a una maraton en curso; la cuenta ya lo esta." |

Formato de las cuentas y roles: `docs/cuentas-de-prueba.md` (esas son de
desarrollo, **no** las que van a Play).

## 7. Lanzamiento

1. Subir el `.aab` a **Pruebas internas** primero (hasta 100 correos, revision
   en horas). Instalar desde el enlace y verificar login, GPS y mapa.
2. Prueba cerrada con ≥ 12 testers durante 14 dias seguidos: es **obligatorio**
   para cuentas de desarrollador personales creadas despues de nov-2023 antes de
   poder pasar a produccion. Verificar si aplica a esta cuenta. **[bloqueante si
   es cuenta personal nueva]**
3. Produccion: notas de la version (500 caracteres, por idioma), porcentaje de
   despliegue (empezar en 20 %).

## 8. Bloqueantes, en orden

- [ ] `/privacidad` y `/eliminar-cuenta` publicadas y accesibles sin login
- [ ] Video de justificacion del servicio de ubicacion en primer plano
- [ ] Cuenta de prueba creada **en produccion** para los revisores
- [ ] Data safety corregido segun el manifest real (sin background location)
- [ ] Copia de seguridad de `upload-keystore.jks` y `key.properties` fuera de esta maquina
- [ ] Capturas, icono 512 y feature graphic
