.PHONY: run run-web run-local apk goldens fmt analyze test

# Contra el backend de produccion (runner-app.tumype.com).
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

goldens:
	flutter test --update-goldens

fmt:
	dart format .

analyze:
	flutter analyze

test:
	flutter test
