# Versionado de CamRun

Una sola fuente: la linea `version:` de `pubspec.yaml`. Flutter la parte en dos
y la inyecta en Android (`versionName` / `versionCode`) y en iOS
(`CFBundleShortVersionString` / `CFBundleVersion`). **No editar a mano el
`build.gradle.kts` ni el Info.plist**, ya leen de ahi.

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        |     versionCode — entero, interno, solo lo ve Play
#        versionName — lo que ve el usuario en la ficha y en Ajustes
```

## Las dos reglas

1. **`versionCode` siempre sube, nunca se repite.** Play rechaza un `.aab` con
   un `versionCode` igual o menor a uno ya subido — aunque el anterior se haya
   descartado. Si te equivocas, la unica salida es subir otra vez con el
   siguiente numero.
2. **`versionName` es texto libre**, puede repetirse. Sirve para hablar con el
   usuario, no para que Play ordene nada.

## versionName: semver

`MAYOR.MENOR.PARCHE`

| Parte | Cuando sube | Ejemplo en esta app |
|---|---|---|
| **PARCHE** | Correcciones de bugs, textos, ajustes visuales. Nada nuevo que el usuario tenga que aprender | `1.0.1` — se arregla que el ritmo se congela al pausar |
| **MENOR** | Funcionalidad nueva compatible con lo que habia | `1.1.0` — se anaden los planes de entrenamiento personalizados |
| **MAYOR** | Rediseno grande, cambio de flujo que obliga al usuario a reaprender, o ruptura con la API que exige actualizar si o si | `2.0.0` — nueva navegacion y nuevo modelo de carreras |

Mientras la app no este publicada se puede usar `0.x.y`; desde la primera
subida a produccion, `1.0.0` en adelante.

## versionCode: contador

Un entero que solo hace `+1` en cada **subida a Play**, sea al canal que sea
(interna, cerrada, produccion). No se reinicia con los cambios de `versionName`.

## Ejemplo de como avanzan juntos

| Subida | `pubspec.yaml` | Que fue |
|---|---|---|
| 1 | `1.0.0+1` | Primera subida, prueba interna |
| 2 | `1.0.0+2` | Mismo contenido, se corrige el Data Safety y hay que re-subir el bundle |
| 3 | `1.0.1+3` | Se arregla el crash al perder el GPS |
| 4 | `1.1.0+4` | Entra el seguimiento en vivo de maratones |
| 5 | `1.1.1+5` | Textos en ingles que faltaban |
| 6 | `2.0.0+6` | Rediseno de inicio e historial |

Ojo con la 2: **la subida cuenta, aunque el codigo no haya cambiado**. Cualquier
`.aab` nuevo necesita su propio `versionCode`.

## Al publicar

1. Subir la linea en `pubspec.yaml`.
2. Commit con ese numero en el mensaje y `git tag v1.0.1`.
3. `make aab`.
4. Notas de la version en Play (500 caracteres, en espanol y en ingles).

El resto del proceso, en `docs/play-store-publicacion.md`.

## iOS, si algun dia se publica

Misma linea de `pubspec.yaml`. La App Store es mas estricta: el `versionName`
tiene que subir en cada envio a revision (no solo el build), y no acepta volver
atras. Con la tabla de arriba se cumple sin hacer nada extra.
