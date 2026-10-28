# Genera las variantes del logo madre+hija desde una sola geometría.
import pathlib
import sys
# Coleta relativa al centro de la cabeza de la madre (r=17); la hija la reusa a escala.
PONY = sys.argv[1] if len(sys.argv) > 1 else "M-8 -16 C-22 -22 -36 -18 -44 -10 C-48 -6 -52 -8 -56 -14 C-56 -2 -46 8 -32 8 C-22 8 -14 4 -14 -2 Z"
BG, MOM, KID = "#4C1D95", "#FFFFFF", "#C4B5FD"

def figures(mom, kid):
    s = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
    return f'''<g transform="translate(-12 6)">
<g {s} stroke="{mom}" stroke-width="16"><path d="M124 76 L108 134"/><path d="M108 134 L140 162 L130 206"/><path d="M108 134 L90 174 L58 186"/><path d="M121 86 L96 106 L84 128"/><path d="M121 86 L140 116 L164 132"/></g>
<g {s} stroke="{kid}" stroke-width="11"><path d="M198 134 L190 170"/><path d="M190 170 L210 190 L204 214"/><path d="M190 170 L178 196 L158 204"/><path d="M196 142 L166 133"/><path d="M196 142 L212 158 L224 146"/></g>
<circle cx="130" cy="50" r="17" fill="{mom}"/><path fill="{mom}" transform="translate(130 50)" d="{PONY}"/>
<circle cx="202" cy="114" r="12" fill="{kid}"/><path fill="{kid}" transform="translate(202 114) scale(0.72)" d="{PONY}"/>
</g>'''

def svg(body, vb="0 0 256 256"):
    w, h = vb.split()[2:]  # tamaño real: si no, Chrome rasteriza a 256 y escala (bordes facetados)
    k = 1024 / int(w)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{int(int(w)*k)}" height="{int(int(h)*k)}" viewBox="{vb}">{body}</svg>'

def scaled(k, mom=MOM, kid=KID):  # figuras escaladas k alrededor del centro
    return f'<g transform="translate(128 128) scale({k}) translate(-128 -128)">{figures(mom, kid)}</g>'

out = {
  # Ícono de tienda / iOS: fondo a sangre (Play e iOS redondean solos).
  "icon-store.svg": svg(f'<rect width="256" height="256" fill="{BG}"/>' + scaled(0.78)),
  # Foreground adaptativo: transparente; el XML ya mete 16% de inset.
  "adaptive-foreground.svg": svg(scaled(0.80)),
  "symbol-black.svg": svg(figures("#000", "#000")),
  "symbol-color.svg": svg(figures("#4C1D95", "#8B5CF6")),
  "symbol-white.svg": svg(figures("#FFF", "#FFF")),
}
import base64
fontdata = lambda f: "data:font/ttf;base64," + base64.b64encode(pathlib.Path(r"C:/Users/alvar/Documents/GitHub/running-app/assets/fonts/" + f).read_bytes()).decode()
font = fontdata("Poppins-Bold.ttf")
fontm = fontdata("Poppins-Medium.ttf")
out["feature-graphic.svg"] = svg(f'''<style>@font-face{{font-family:P;src:url({font})}}@font-face{{font-family:PM;src:url({fontm})}}</style>
<rect width="1024" height="500" fill="{BG}"/>
<circle cx="820" cy="250" r="300" fill="#5B21B6"/>
<g transform="translate(600 30) scale(1.75)">{figures(MOM, KID)}</g>
<text x="80" y="245" font-family="P" font-size="104" fill="#FFF">CamRun</text>
<text x="84" y="305" font-family="PM" font-size="34" fill="{KID}">Corre en familia</text>''', "0 0 1024 500")
for n, c in out.items(): pathlib.Path(n).write_text(c, encoding="utf-8")
