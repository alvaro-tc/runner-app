.PHONY: run run-web run-local apk aab goldens fmt analyze test l10n i18n-guard

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
