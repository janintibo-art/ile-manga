"""V140 : les petites bêtes en petits cubes de l'Île Pixelithique (la faune sauvage de l'île).

  www/assets/models/pixel90/faune_v140.bin   {"modeles": {"bête.pièce": {v, n, c, i}},
                                              "rigs": {bête: {pièce: [x, y, z]}}}
  compsognathe   un petit dinosaure vert olive rayé de sombre (65 cm, queue comprise) : corps, cou
                 et tête, queue, cuisses, jambes, bras ;
  archeopteryx   l'oiseau-dinosaure : plumes noires aux reflets bleus, ailes griffues, longue queue
                 empennée, bec à petites dents ;
  meganeura      la libellule géante (65 cm d'envergure) : thorax, long abdomen, gros yeux, quatre
                 ailes veinées.
Mêmes outils et même palette que les modèles de l'île (tools/pixel_v90) : seules les couleurs
nouvelles s'ajoutent à la fin de la palette. Les modèles de l'île (modeles.bin) ne changent pas.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_faune_pixel_v140.py
"""
from __future__ import annotations

from pathlib import Path
import sys
import zlib

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "pixel_v90"))
sys.path.insert(0, str(HERE / "habitants_v64"))
import gdvar  # noqa: E402
import modeles as M  # noqa: E402
from vox import Piece  # noqa: E402

ROOT = HERE.parents[1]
OUT = ROOT / "www" / "assets" / "models" / "pixel90" / "faune_v140.bin"

NOUVELLES = {
    "compso": (0.46, 0.52, 0.27), "compso2": (0.29, 0.33, 0.17), "compso3": (0.82, 0.62, 0.30),
    "archeo": (0.10, 0.10, 0.12), "archeo2": (0.16, 0.24, 0.36), "archeo3": (0.30, 0.42, 0.60),
    "lib": (0.12, 0.42, 0.34), "lib2": (0.06, 0.20, 0.17), "lib3": (0.85, 0.62, 0.20),
    "aile_lib": (0.62, 0.74, 0.76), "veine": (0.20, 0.25, 0.27), "oeil_lib": (0.62, 0.20, 0.16),
}
for _k, _v in NOUVELLES.items():
    if _k not in M.C:
        M.PAL[_k] = _v
        M.NOMS.append(_k)
        M.C[_k] = len(M.NOMS)
        M.PALETTE.append(_v)

ventre, rayures, melange = M.ventre, M.rayures, M.melange


def compsognathe():
    s = 0.02
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (0.07, 0.08, 0.17), ventre("compso", "ventre", -0.035)) \
        .ellipsoide((0, 0.025, -0.01), (0.06, 0.06, 0.15), rayures(2, 0.045, "compso", "compso2"))
    P["cou"] = Piece(s).chaine([(0, 0, 0), (0, 0.07, 0.05), (0, 0.13, 0.07)], [0.04, 0.032, 0.028], ventre("compso", "ventre", 0.06, 2)) \
        .ellipsoide((0, 0.155, 0.11), (0.04, 0.042, 0.07), "compso") \
        .ellipsoide((0, 0.145, 0.17), (0.026, 0.027, 0.05), "compso") \
        .boite((0.032, 0.17, 0.12), (0.012, 0.012, 0.012), "oeil").boite((-0.032, 0.17, 0.12), (0.012, 0.012, 0.012), "oeil") \
        .boite((0.042, 0.17, 0.12), (0.004, 0.008, 0.006), "pupille").boite((-0.042, 0.17, 0.12), (0.004, 0.008, 0.006), "pupille") \
        .chaine([(0, 0.19, 0.06), (0, 0.205, 0.12)], [0.012, 0.01], "compso3")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, 0.01, -0.18), (0, 0.03, -0.38)], [0.05, 0.03, 0.014], rayures(2, 0.05, "compso", "compso2"))
    for sg, nm in ((1, "G"), (-1, "D")):
        P["cuisse" + nm] = Piece(s).capsule((0, 0, 0), (0, -0.1, 0.03), 0.036, 0.024, "compso")
        P["jambe" + nm] = Piece(s).chaine([(0, 0, 0), (0, -0.07, -0.035), (0, -0.115, 0.0)], [0.018, 0.015, 0.014], "compso2") \
            .boite((0, -0.12, 0.025), (0.016, 0.01, 0.035), "compso2")
        P["bras" + nm] = Piece(s).chaine([(0, 0, 0), (0, -0.035, 0.025), (0, -0.045, 0.05)], [0.014, 0.012, 0.011], "compso")
    rig = {"corps": [0, 0.25, 0], "cou": [0, 0.28, 0.13], "queue": [0, 0.26, -0.14],
           "cuisseG": [0.05, 0.24, -0.02], "cuisseD": [-0.05, 0.24, -0.02], "jambeG": [0.05, 0.135, 0.01], "jambeD": [-0.05, 0.135, 0.01],
           "brasG": [0.045, 0.22, 0.1], "brasD": [-0.045, 0.22, 0.1]}
    return P, rig


def archeopteryx():
    s = 0.016
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (0.055, 0.06, 0.12), ventre("archeo", "archeo2", -0.02))
    P["tete"] = Piece(s).chaine([(0, 0, 0), (0, 0.035, 0.04)], [0.035, 0.03], "archeo") \
        .ellipsoide((0, 0.055, 0.07), (0.035, 0.036, 0.045), "archeo") \
        .capsule((0, 0.05, 0.1), (0, 0.04, 0.15), 0.018, 0.009, "bec") \
        .boite((0.026, 0.065, 0.085), (0.008, 0.008, 0.008), "oeil").boite((-0.026, 0.065, 0.085), (0.008, 0.008, 0.008), "oeil") \
        .boite((0.008, 0.035, 0.13), (0.004, 0.006, 0.004), "dent").boite((-0.008, 0.035, 0.13), (0.004, 0.006, 0.004), "dent")
    for sg, nm in ((1, "G"), (-1, "D")):
        P["aile" + nm] = Piece(s).boite((sg * 0.14, 0, -0.035), (0.14, 0.012, 0.06), melange("archeo", "archeo3", 0.3, 5 + sg)) \
            .boite((sg * 0.2, 0, -0.07), (0.09, 0.012, 0.03), "archeo2") \
            .capsule((0, 0.01, 0.02), (sg * 0.27, 0.01, 0.02), 0.016, 0.012, "archeo") \
            .capsule((sg * 0.12, 0.01, 0.03), (sg * 0.13, 0.0, 0.06), 0.008, 0.005, "griffe") \
            .capsule((sg * 0.2, 0.01, 0.03), (sg * 0.215, 0.0, 0.06), 0.008, 0.005, "griffe")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, 0.0, -0.14), (0, 0.0, -0.26)], [0.016, 0.012, 0.009], "archeo") \
        .boite((0, 0, -0.16), (0.05, 0.012, 0.11), melange("archeo", "archeo3", 0.25, 9)) \
        .boite((0, 0, -0.27), (0.035, 0.012, 0.03), "archeo2")
    P["pattes"] = Piece(s).capsule((0.025, 0, 0), (0.03, -0.07, 0.02), 0.012, 0.009, "griffe") \
        .capsule((-0.025, 0, 0), (-0.03, -0.07, 0.02), 0.012, 0.009, "griffe") \
        .boite((0.03, -0.075, 0.035), (0.01, 0.006, 0.02), "griffe").boite((-0.03, -0.075, 0.035), (0.01, 0.006, 0.02), "griffe")
    rig = {"corps": [0, 0, 0], "tete": [0, 0.035, 0.11], "aileG": [0.045, 0.03, 0.02], "aileD": [-0.045, 0.03, 0.02],
           "queue": [0, 0.005, -0.11], "pattes": [0, -0.045, -0.01]}
    return P, rig


def meganeura():
    s = 0.012
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (0.025, 0.028, 0.04), rayures(2, 0.02, "lib", "lib3")) \
        .chaine([(0, 0, -0.03), (0, -0.004, -0.17), (0, -0.01, -0.3)], [0.017, 0.014, 0.011], rayures(2, 0.03, "lib", "lib2"))
    P["tete"] = Piece(s).ellipsoide((0, 0, 0.01), (0.022, 0.018, 0.014), "lib2") \
        .ellipsoide((0.017, 0.006, 0.012), (0.016, 0.018, 0.016), "oeil_lib") \
        .ellipsoide((-0.017, 0.006, 0.012), (0.016, 0.018, 0.016), "oeil_lib")
    for sg, nm in ((1, "G"), (-1, "D")):
        P["avant" + nm] = Piece(s).ellipsoide((sg * 0.165, 0, 0), (0.165, 0.009, 0.03), rayures(0, 0.03, "aile_lib", "veine")) \
            .capsule((0, 0, 0.012), (sg * 0.32, 0, 0.012), 0.006, 0.005, "veine")
        P["arriere" + nm] = Piece(s).ellipsoide((sg * 0.15, 0, -0.004), (0.15, 0.009, 0.036), rayures(0, 0.03, "aile_lib", "veine")) \
            .capsule((0, 0, 0.014), (sg * 0.29, 0, 0.014), 0.006, 0.005, "veine")
    rig = {"corps": [0, 0, 0], "tete": [0, 0.004, 0.045], "avantG": [0.02, 0.022, 0.02], "avantD": [-0.02, 0.022, 0.02],
           "arriereG": [0.02, 0.022, -0.02], "arriereD": [-0.02, 0.022, -0.02]}
    return P, rig


def main() -> int:
    modeles = {}
    rigs = {}
    for nom, f in (("compsognathe", compsognathe), ("archeopteryx", archeopteryx), ("meganeura", meganeura)):
        parts, rig = f()
        for pn, piece in parts.items():
            modeles[f"{nom}.{pn}"] = piece.export(M.PALETTE, seed=zlib.crc32((nom + pn).encode()) % 983, var=0.06)
        rigs[nom] = {k: [float(x) for x in v] for k, v in rig.items()}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    raw, comp = gdvar.save(OUT, {"modeles": modeles, "rigs": rigs})
    tri = sum(len(m["i"].data) // 12 for m in modeles.values())
    print(f"V140 : {len(modeles)} pièces, ~{tri} triangles ; {comp // 1024} Ko dans {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
