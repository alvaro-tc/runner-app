#!/usr/bin/env bash
# Guardia de i18n (PU-203).
#
# Falla si queda algun literal de UI en la capa de presentacion. Se ejecuta a
# mano por ahora; CI/CD (PU-004) lo engancha despues del lanzamiento.
#
#   ./tool/i18n_guard.sh            # solo el recuento y los hallazgos
#   ./tool/i18n_guard.sh --verbose  # ademas, que se ignoro y por que
#
# Salida 0 = limpio, 1 = quedan literales.

set -uo pipefail
cd "$(dirname "$0")/.."

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

# Ficheros que se auditan: todo lo que dibuja pantalla.
# `showcase_page.dart` queda fuera a proposito: es el catalogo de atomos y
# moleculas que vive en `/dev/showcase`, detras del guard de rutas de debug.
# No sale en ninguna build de tienda, y traducir los rotulos de un catalogo de
# componentes solo anade ruido al ARB.
TARGETS=$(find lib/features -path '*/presentation/*' -name '*.dart' \
          ! -name '*.g.dart' ! -name '*.freezed.dart' 2>/dev/null
          find lib/shared/widgets -name '*.dart' \
          ! -name 'showcase_page.dart' 2>/dev/null
          # De lib/app solo app.dart: el router y el contenedor de DI son
          # paths y claves, no copy.
          echo lib/app/app.dart)

python3 - "$VERBOSE" $TARGETS <<'PY'
import re, sys

verbose = sys.argv[1] == '1'
files = sys.argv[2:]

# Un literal es "de UI" si le queda alguna palabra propia despues de quitar la
# interpolacion: `'${Fmt.clock(x)} · '` no es copy, `'Guardar'` si.
WORDY = re.compile(r"[A-Za-zÁÉÍÓÚÑáéíóúñ]{2,}")

# `$identificador`. Los `${...}` los quita `blank_interpolations`, que si sabe
# de llaves anidadas.
INTERPOLATION = re.compile(r"\$[A-Za-z_]\w*")


def blank_interpolations(line):
    """Vacia el interior de cada `${...}`, respetando llaves anidadas.

    Sin esto, un `'${x ?? ''}'` parte el literal por la mitad y lo que sobra
    parece copy suelto.
    """
    out, i, n = [], 0, len(line)
    while i < n:
        if line[i] == '$' and i + 1 < n and line[i + 1] == '{':
            depth, j = 0, i + 1
            while j < n:
                if line[j] == '{':
                    depth += 1
                elif line[j] == '}':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            if j < n:
                # Mismo ancho, para que las columnas sigan cuadrando.
                out.append('_' * (j - i + 1))
                i = j + 1
                continue
        out.append(line[i])
        i += 1
    return ''.join(out)

# Contextos que NO son texto de usuario y por tanto no se traducen.
ALLOW_LINE = re.compile(
    r"""(^\s*(import|export|part|library)\b)          # directivas
      | (^\s*//)                                       # comentario de linea
      | (^\s*///)                                      # doc comment
      | (^\s*\*)                                       # cuerpo de /* */
      | (\bassets/)                                    # rutas de assets
      | (\bpackage:)                                   # uris de paquete
      | (fontFamily\s*:)                               # tokens de tema
      | (\bKey\s*\()                                   # ValueKey / GlobalKey
      | (\bkDebugMode\b)
      | (\.name\s*==)                                  # comparacion de enums
      | (SharedPreferences)                            # claves de prefs
      | (^\s*static\s+const\s+\w*[Kk]ey)               # claves declaradas
      | (context\.l10n)                                # ya traducido
      | (\bRoutes\.)                                   # constantes de ruta
      | (^\s*tag:)                                     # tags de Hero
      | (^\s*id:)                                      # ids generados
      | (\bDateFormat\s*\()                            # patrones de intl
      | (\bIcons\.)                                    
    """,
    re.X,
)

# Literales concretos que son identificadores, no copy.
ALLOW_VALUE = re.compile(
    r"""^(
        [\s\W\d]*                     # solo simbolos/numeros: '', ' ', '--:--'
      | (km|mi|mph|km/h|m|s|h|d|K|%|/|·|—|–|,|\.)
      | [a-z0-9_.\-]+                 # identificadores snake/dotted en minuscula
      | \#[0-9A-Fa-f]{3,8}            # colores
      | https?://.*
      | [\w.+-]+@[\w-]+\.[\w.-]+       # direcciones de correo
      | [A-Z]{1,3}                    # codigos de talla y unidad: XS, KM, QR
      # Marcas: no se traducen en ningun idioma.
      | (Google|LinkedIn|Facebook|PaceUp|Apple)
    )$""",
    re.X,
)

STRING = re.compile(r"""(?<![\w'"])(?:r?)('([^'\\\n]|\\.)*'|"([^"\\\n]|\\.)*")""")

hits, ignored = [], []
in_block_comment = False

for path in files:
    try:
        lines = open(path, encoding='utf-8').read().splitlines()
    except OSError:
        continue
    for n, line in enumerate(lines, 1):
        stripped = line.strip()
        if in_block_comment:
            if '*/' in line:
                in_block_comment = False
            continue
        if stripped.startswith('/*'):
            if '*/' not in stripped:
                in_block_comment = True
            continue
        scannable = blank_interpolations(line)
        for m in STRING.finditer(scannable):
            raw = m.group(1)
            val = raw[1:-1]
            # Lo que queda al quitar la interpolacion es lo unico que puede
            # necesitar traduccion.
            literal = INTERPOLATION.sub('', val).replace('_', '')
            if not WORDY.search(literal):
                ignored.append((path, n, val, 'solo interpolacion'))
                continue
            if ALLOW_VALUE.match(val) or ALLOW_VALUE.match(literal):
                ignored.append((path, n, val, 'identificador'))
                continue
            if ALLOW_LINE.search(line):
                ignored.append((path, n, val, 'contexto permitido'))
                continue
            hits.append((path, n, val))

for path, n, val in hits:
    print(f"{path}:{n}: {val!r}")

if verbose and ignored:
    print("\n--- ignorados ---")
    for path, n, val, why in ignored:
        print(f"{path}:{n}: {val!r}  ({why})")

print()
if hits:
    print(f"FALLO: {len(hits)} literal(es) sin traducir en la capa de presentacion.")
    sys.exit(1)
print("OK: cero literales en la capa de presentacion.")
PY
