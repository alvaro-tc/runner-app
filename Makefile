.PHONY: run run-web run-local goldens fmt analyze test

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

goldens:
	flutter test --update-goldens

fmt:
	dart format .

analyze:
	flutter analyze

test:
	flutter test
