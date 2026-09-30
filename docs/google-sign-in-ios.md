# Inicio de sesión con Google en iOS

La app utiliza el SDK nativo de Google para obtener un ID token y enviarlo a
`POST /auth/google` en runner-api. El backend valida la firma, el destinatario y
el correo verificado, y devuelve los tokens de sesión propios de CamRun.

## Completar el cliente de iOS

En el mismo proyecto de Google Cloud que el cliente Web utilizado por la app,
crea un cliente OAuth de **tipo iOS** con bundle ID **`com.tumype.camrun`**.
Copia su ID en la clave que ya está preparada en `.env`:

```dotenv
GOOGLE_IOS_CLIENT_ID=123456789012-tuclienteios.apps.googleusercontent.com
```

El ejemplo anterior es ilustrativo: usa el ID real que entregue Google.
`GOOGLE_SERVER_CLIENT_ID` conserva el cliente OAuth de **tipo Web** existente.
Los dos IDs son distintos. No hace falta introducir un client secret ni añadir
Firebase Auth o `GoogleService-Info.plist` para este flujo.

## Ejecutar y generar el IPA

Desde la raíz de runner-app:

```bash
make run-ios
# Si hay varios dispositivos:
make run-ios IOS_DEVICE="ID del iPhone o simulador"

# Compilación release para distribuir, con la firma de Apple configurada:
make ipa
```

Estos comandos leen `.env`, validan ambos IDs y generan
`ios/Flutter/GoogleSignIn.generated.xcconfig`. El ID invertido que necesita el
retorno de Google se calcula automáticamente; no hay que mantenerlo a mano.
El archivo generado queda excluido de Git y debe regenerarse en un clon nuevo.
Las configuraciones Debug, Profile y Release incluyen esos ajustes.

Para ejecutar Flutter directamente, primero prepara los ajustes nativos:

```bash
make google-ios
flutter run -d "ID del iPhone" --dart-define-from-file=.env
```

Si cambias un ID, detén y recompila la app. Hot reload no actualiza el plist
ni las constantes de compilación.

## Backend local

Completa también `GOOGLE_IOS_CLIENT_ID` en `.env.local` y ejecuta:

```bash
make run-ios IOS_ENV=.env.local
```

Con `.env.local`, los comandos de iOS utilizan automáticamente
`http://127.0.0.1:3000/api/v1` para llegar al backend desde el simulador. En un
iPhone físico indica la IP de la Mac en la red local:

```bash
make run-ios IOS_ENV=.env.local IOS_DEVICE="ID del iPhone" \
  IOS_API_BASE_URL=http://192.168.1.50:3000/api/v1
```

Esto conserva `10.0.2.2` en `.env.local` para el emulador Android.

En runner-api, `GOOGLE_CLIENT_IDS` debe incluir el valor de
`GOOGLE_SERVER_CLIENT_ID` del archivo de entorno de la app. El `.env` local del
backend quedó configurado con los clientes Web existentes de la app. Reinicia
el backend para que lea el cambio.

En producción, comprueba el mismo ajuste en el entorno del servidor y reinicia
su proceso si lo modificas. No se desplegó el backend desde esta configuración.
El cliente Web es el destinatario solicitado para los tokens, por lo que no
es necesario sustituirlo por el nuevo ID de iOS.

## Compilar desde Xcode

```bash
make google-ios
flutter build ios --config-only --dart-define-from-file=.env
open ios/Runner.xcworkspace
```

Selecciona Runner y configura tu equipo y firma de Apple. Usa el mismo archivo
de entorno para preparar la configuración nativa y la de Flutter.

## Retorno y comprobación pendiente

`Info.plist` registra `GIDClientID`, `GIDServerClientID` y el esquema invertido
en `CFBundleURLTypes`. La versión instalada de `google_sign_in_ios` registra
sus callbacks con Flutter tanto para AppDelegate como para SceneDelegate; el
SceneDelegate de Runner hereda de `FlutterSceneDelegate`.

La autenticación real queda pendiente de crear el cliente OAuth: comprobar en
un iPhone el inicio de sesión, la cancelación, cerrar sesión y volver a entrar,
y la restauración de la sesión al reiniciar la app. Si el consentimiento de
Google está en modo de pruebas, la cuenta utilizada debe estar autorizada como
usuario de prueba del proyecto.

Referencias: [integración oficial del plugin](https://pub.dev/packages/google_sign_in_ios#ios-integration)
y [configuración oficial de Google](https://developers.google.com/identity/sign-in/ios/start-integrating).
