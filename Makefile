.PHONY: run run-local goldens fmt analyze test

# Contra el backend de produccion (runner-app.tumype.com).
run:
	flutter run --dart-define-from-file=.env

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
