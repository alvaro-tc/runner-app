# Iniciar sesión con Apple

App Review rechazó la versión 1.0.8 (9) por la **guía 4.8 (Login Services)**: la
app ofrece Google y tiene que ofrecer además un acceso que limite los datos a
nombre y correo, permita ocultar el correo y no rastree para publicidad. Sign in
with Apple cumple las tres cosas.

## Qué hace la app

- **Botón del sistema.** En iPhone y iPad, las pantallas de inicio de sesión y
  de registro muestran el `ASAuthorizationAppleIDButton` nativo ("Continuar con
  Apple"), como recomienda la guía de interfaz de Apple: apariencia aprobada,
  título traducido al idioma del dispositivo y etiqueta de VoiceOver. Va encima
  del de Google, con su mismo alto y sus mismas esquinas (la guía pide que no
  sea más pequeño que ningún otro botón de acceso), negro sobre fondo claro y
  blanco sobre oscuro. Lo pinta `AppDelegate.swift` y lo usa
  `AppleAuthButton`. En Android no aparece.
- **Datos mínimos.** Se piden solo nombre y correo. El nombre llega **una sola
  vez**: se guarda en el llavero en cuanto llega, por si falla la red, y se manda
  al servidor. No se vuelve a preguntar nada ni se pide contraseña.
- **Nonce.** Cada intento genera uno aleatorio; a Apple va su SHA-256 y al
  servidor el original, que lo compara con el que vuelve dentro del token.
- **Bienvenida y transparencia.** Al entrar se saluda por el nombre compartido, y
  en Ajustes > Cuenta aparece "Usando Iniciar sesión con Apple" con el correo
  compartido (con "Ocultar mi correo", la dirección de relay).
- **Estado de la credencial.** Al abrir la app y cada vez que vuelve al frente se
  consulta `getCredentialState`: si el usuario dejó de usar Sign in with Apple
  con CamRun, borró su Apple Account o el dispositivo tiene otra, se cierra la
  sesión.
- **Borrado de cuenta.** El servidor revoca el token de Apple al borrar la
  cuenta, como exige Apple (ver `runner-api/src/modules/auth/social/README.md`).

## Configuración pendiente (una sola vez)

1. **Apple Developer > Identifiers > `com.tumype.camrun`**: activar la
   capability **Sign In with Apple** (*Enable as a primary App ID*). En *Edit*,
   como *Server-to-Server Notification Endpoint*:
   `https://<dominio de la API>/api/v1/auth/apple/notifications`.
2. **Xcode**: el proyecto ya declara el entitlement
   (`ios/Runner/Runner.entitlements`). Con firma automática, Xcode actualiza el
   perfil al compilar; con firma manual, regenerar el perfil de distribución
   después del paso 1.
3. **Keys**: crear una clave con *Sign in with Apple* para ese App ID, descargar
   el `.p8` y configurar en la API `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
   `APPLE_PRIVATE_KEY` y `APPLE_CLIENT_IDS=com.tumype.camrun`.
4. **Correo de relay**: en *Sign in with Apple for Email Communication*,
   registrar el dominio desde el que la API manda los correos de recuperar
   contraseña. Sin eso, los correos a `@privaterelay.appleid.com` rebotan.
5. Subir el `versionCode` y el `versionName` en `pubspec.yaml` antes del build.

## Respuesta a App Review

Al reenviar, se puede contestar en App Store Connect:

> We added Sign in with Apple as an equivalent login option to Google Sign-In.
> It appears with the same size and prominence on the sign-in and sign-up
> screens of iPhone and iPad, requests only the user's name and email address,
> supports Hide My Email, and we revoke the user's Sign in with Apple token when
> they delete their account from within the app.
