"""V90 : l'Île Pixelithique (tout en petits cubes). Cet outil fabrique, pour le jeu :
  www/assets/models/pixel90/relief.bin     le relief en blocs de 50 cm (les carrés du maillage, par
                                           morceaux de 32 m ; les hauteurs aux coins pour la collision ;
                                           la matière de chaque bloc) ;
  www/assets/models/pixel90/modeles.bin    les modèles en petits cubes (plantes, rochers, os, nids,
                                           les hommes des cavernes, les dinosaures) et où poser les plantes.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_pixel_v90.py [relief] [modeles]
"""
from __future__ import annotations

from pathlib import Path
import sys
import time

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "pixel_v90"))
sys.path.insert(0, str(HERE / "habitants_v64"))
import gdvar  # noqa: E402
import terrain as T  # noqa: E402
import maillage  # noqa: E402

ROOT = HERE.parents[1]
OUT = ROOT / "www" / "assets" / "models" / "pixel90"
CHUNK = 64          # blocs par morceau (32 m)


def relief() -> dict:
    t0 = time.time()
    levels, mats, hs, info = T.build()
    n = T.N
    chunks = []
    nt = ns = 0
    for cz in range(0, n, CHUNK):
        for cx in range(0, n, CHUNK):
            tops, sides = maillage.relief_quads(levels, mats, cx, cz, min(cx + CHUNK, n), min(cz + CHUNK, n))
            nt += len(tops)
            ns += len(sides)
            chunks.append({"x": cx, "z": cz, "tops": gdvar.i32(np.array(tops, np.int32).ravel()),
                           "sides": gdvar.i32(np.array(sides, np.int32).ravel())})
    # les hauteurs aux coins des blocs (la moyenne des quatre blocs autour) : collision et height()
    top = levels.astype(np.float32) * T.LEVEL
    p = np.pad(top, 1, mode="edge")
    coins = (p[:-1, :-1] + p[1:, :-1] + p[:-1, 1:] + p[1:, 1:]) * 0.25 / T.BLOC      # en blocs (la collision est mise à l'échelle)
    d = {"n": n, "bloc": T.BLOC, "half": T.HALF, "coins": gdvar.f32(coins), "mats": gdvar.u8(mats), "chunks": chunks}
    raw, comp = gdvar.save(OUT / "relief.bin", d)
    print(f"relief : {nt} dessus, {ns} côtés, {len(chunks)} morceaux ; {comp // 1024} Ko ({time.time() - t0:.1f} s)")
    return {"levels": levels, "mats": mats, "info": info}


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    what = sys.argv[1:] or ["relief", "modeles", "peintures"]
    rel = None
    if "relief" in what or "modeles" in what:
        rel = relief() if "relief" in what else None
    if "modeles" in what:
        import modeles
        if rel is None:
            levels, mats, _, info = T.build()
            rel = {"levels": levels, "mats": mats, "info": info}
        modeles.build(OUT, rel)
    if "peintures" in what or "modeles" in what:
        import peintures
        peintures.build(ROOT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
