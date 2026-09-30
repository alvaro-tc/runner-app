.PHONY: run run-web run-local google-ios run-ios ipa apk aab goldens fmt analyze test l10n i18n-guard

IOS_ENV ?= .env
IOS_DEVICE ?= iPhone
IOS_API_BASE_URL ?= $(if $(filter .env.local,$(IOS_ENV)),http://127.0.0.1:3000/api/v1)

# Un solo ID de iOS en IOS_ENV; el esquema de retorno se deriva automaticamente.
google-ios:
	dart tool/configure_google_ios.dart "$(IOS_ENV)"

# IOS_DEVICE permite elegir el iPhone o simulador que se utilizara.
run-ios: google-ios
	flutter run -d "$(IOS_DEVICE)" --dart-define-from-file="$(IOS_ENV)" $(if $(IOS_API_BASE_URL),--dart-define="API_BASE_URL=$(IOS_API_BASE_URL)")

ipa: google-ios
	flutter build ipa --release --dart-define-from-file="$(IOS_ENV)" $(if $(IOS_API_BASE_URL),--dart-define="API_BASE_URL=$(IOS_API_BASE_URL)")

# Contra el backend de produccion (cam-run.tumype.com).
run:
	flutter run --dart-define-from-file=.env

# En Chrome, contra produccion. El puerto va fijo porque el origen tiene que
# estar en CORS_ORIGINS del backend, y uno aleatorio no se puede autorizar.
run-web:
	flutter run -d chrome --web-port=5000 --dart-define-from-file=.env

# Contra el backend levantado en esta maquina.
run-local:
	flutter run --dart-define-from-file=.env.local

# El APK de release. El `--dart-define-from-file` NO es opcional: sin el, la
# URL que queda incrustada es `10.0.2.2`, que solo existe para el emulador, y
# en un telefono real no conecta con nada.
apk:
	flutter build apk --release --dart-define-from-file=.env

# El bundle firmado que se sube a Play Console. Mismo aviso que el APK sobre
# el --dart-define-from-file, y ademas necesita android/key.properties: sin el
# sale firmado con la clave de debug y Play lo rechaza.
aab:
	flutter build appbundle --release --dart-define-from-file=.env

# Regenera las clases de traduccion desde los ARB (PU-203). Lo que salga en
# lib/l10n/gen/ va al commit.
l10n:
	flutter gen-l10n

# Falla si queda algun literal sin traducir en la capa de presentacion. Por
# ahora se corre a mano; lo engancha CI/CD en PU-004.
i18n-guard:
	./tool/i18n_guard.sh

goldens:
	flutter test --update-goldens

fmt:
	dart format .

analyze: l10n
	flutter analyze

test: l10n
	flutter test
