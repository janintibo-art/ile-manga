"""V90 : les modèles en petits cubes de l'Île Pixelithique, et où poser les plantes.

  plantes et décor   fougère arborescente, cycas, araucaria, prêles, fougères basses, touffes
                     d'herbe, rochers, grand squelette, nid d'œufs, feu de camp, totem, séchoir,
                     peaux, tambour, os ;
  dinosaures         le raptor, le tricératops, le ptéranodon, l'ankylosaure, Grosse-Dent (le
                     tyrannosaure) et le brachiosaure ; chacun en pièces articulées (corps, tête,
                     mâchoire, queue, pattes…), avec la place de chaque articulation ;
  hommes des cavernes  huit habitants du Clan (tronc, tête, bras, jambes), chacun son visage.
Le jeu lit modeles.bin : {"modeles": {nom: {v, n, c, i}}, "rigs": {bête: {pièce: [x, y, z]}},
"plantes": {nom: [x, y, z, angle, taille, …]}}.
"""
from __future__ import annotations

import math
import zlib
import time

import numpy as np

import gdvar
import terrain as T
from vox import Piece

# =========================================================================== la palette

PAL = {
    "tronc": (0.36, 0.24, 0.15), "tronc2": (0.28, 0.18, 0.11), "ecorce": (0.45, 0.32, 0.2),
    "feuille": (0.22, 0.52, 0.18), "feuille2": (0.30, 0.62, 0.22), "feuille3": (0.16, 0.40, 0.14), "jeune": (0.48, 0.70, 0.26),
    "prele": (0.42, 0.58, 0.26), "prele2": (0.26, 0.40, 0.16),
    "roche": (0.48, 0.47, 0.45), "roche2": (0.40, 0.40, 0.39), "roche3": (0.56, 0.54, 0.51), "mousse": (0.30, 0.46, 0.20),
    "os": (0.88, 0.84, 0.72), "os2": (0.76, 0.71, 0.58), "brindille": (0.48, 0.36, 0.22),
    "oeuf": (0.93, 0.89, 0.78), "tache": (0.55, 0.42, 0.3), "braise": (1.0, 0.45, 0.08), "flamme": (1.0, 0.8, 0.25),
    "cuir": (0.60, 0.44, 0.28), "fourrure": (0.52, 0.38, 0.24), "fourrure2": (0.36, 0.26, 0.17), "fourrure3": (0.75, 0.68, 0.55),
    "ocre": (0.78, 0.42, 0.18), "rouge": (0.70, 0.18, 0.12), "plume": (0.20, 0.55, 0.75), "plume2": (0.95, 0.75, 0.2),
    # les dinosaures
    "raptor": (0.42, 0.50, 0.24), "raptor2": (0.30, 0.36, 0.17), "ventre": (0.86, 0.80, 0.62), "crete": (0.90, 0.35, 0.15),
    "trice": (0.50, 0.47, 0.35), "trice2": (0.39, 0.36, 0.27), "collerette": (0.86, 0.52, 0.22), "collerette2": (0.62, 0.30, 0.16),
    "corne": (0.92, 0.88, 0.76), "bec": (0.25, 0.23, 0.22),
    "ptero": (0.70, 0.52, 0.40), "ptero2": (0.56, 0.38, 0.30), "membrane": (0.80, 0.56, 0.44), "crane": (0.86, 0.36, 0.20),
    "anky": (0.52, 0.44, 0.30), "anky2": (0.40, 0.33, 0.22), "plaque": (0.70, 0.62, 0.44),
    "trex": (0.47, 0.41, 0.30), "trex2": (0.34, 0.29, 0.21), "trex3": (0.72, 0.56, 0.36), "dent": (0.97, 0.95, 0.88),
    "gueule": (0.62, 0.22, 0.22), "oeil": (0.98, 0.82, 0.18), "pupille": (0.05, 0.04, 0.03), "noir": (0.06, 0.05, 0.05),
    "brachio": (0.44, 0.52, 0.38), "brachio2": (0.34, 0.41, 0.29), "brachio3": (0.70, 0.72, 0.56),
    "griffe": (0.20, 0.18, 0.16), "blanc": (0.97, 0.97, 0.95),
    # les hommes des cavernes
    "peau1": (0.86, 0.66, 0.50), "peau2": (0.72, 0.52, 0.36), "peau3": (0.52, 0.36, 0.24), "peau4": (0.93, 0.76, 0.62),
    "cheveux1": (0.18, 0.12, 0.08), "cheveux2": (0.45, 0.28, 0.14), "cheveux3": (0.85, 0.84, 0.80), "cheveux4": (0.70, 0.36, 0.16),
    "levre": (0.62, 0.30, 0.26),
    "sol": (0.44, 0.35, 0.25), "sol2": (0.38, 0.30, 0.21), "paroi": (0.36, 0.33, 0.31), "paroi2": (0.30, 0.28, 0.27),
}
NOMS = list(PAL)
C = {k: i + 1 for i, k in enumerate(NOMS)}
PALETTE = [PAL[k] for k in NOMS]
import vox as _vox  # noqa: E402
_vox.COULEURS = C


def rayures(axe, pas, a, b, ph=0.0):
    """Des rayures (le long d'un axe) : a, b ; le ventre reste a."""
    def f(P):
        return np.where(np.sin(P[..., axe] * (math.pi / pas) + ph) > 0.35, C[b], C[a])
    return f


def ventre(dos, clair, y0=0.0, axe=1):
    def f(P):
        return np.where(P[..., axe] < y0, C[clair], C[dos])
    return f


def taches(a, b, freq=3.0, seuil=0.55, seed=0.0):
    def f(P):
        v = np.sin(P[..., 0] * freq * 1.7 + seed) * np.sin(P[..., 1] * freq * 2.3 + seed * 2) * np.sin(P[..., 2] * freq * 1.9 + seed * 3)
        return np.where(v > seuil - 0.5, C[b], C[a])
    return f


def melange(a, b, p=0.4, seed=0):
    def f(P):
        h = np.sin(P[..., 0] * 91.3 + P[..., 1] * 57.1 + P[..., 2] * 33.7 + seed) * 43758.5453
        return np.where(h - np.floor(h) < p, C[b], C[a])
    return f


# =========================================================================== plantes et décor

def fougere_arbo(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.09)
    h = rng.uniform(3.2, 4.4)
    pts = [(0, 0, 0), (0.08, h * 0.5, 0.03), (0.0, h, -0.05)]
    p.chaine(pts, [0.2, 0.15, 0.13], melange("tronc", "tronc2", 0.35, seed))
    for k in range(9):
        a = k / 9 * 2 * math.pi + rng.uniform(-0.2, 0.2)
        d = np.array([math.cos(a), 0, math.sin(a)])
        L = rng.uniform(1.6, 2.2)
        q = [np.array(pts[-1]) + np.array([0, 0.05, 0])]
        for t in (0.35, 0.7, 1.0):
            q.append(np.array(pts[-1]) + d * L * t + np.array([0, 0.45 * math.sin(t * 2.4) - 0.6 * t * t, 0]))
        p.chaine(q, [0.07, 0.06, 0.05, 0.03], "feuille3")
        # les folioles : de petits disques de part et d'autre
        side = np.cross(d, [0, 1, 0])
        for t in np.linspace(0.15, 0.95, 7):
            c = np.array(pts[-1]) + d * L * t + np.array([0, 0.45 * math.sin(t * 2.4) - 0.6 * t * t, 0])
            w = 0.38 * (1 - t * 0.6)
            for sg in (-1, 1):
                p.ellipsoide(c + side * sg * w * 0.6 + np.array([0, -0.04, 0]), (w * 0.55, 0.04, w * 0.25) if abs(side[0]) > 0.5 else (w * 0.25, 0.04, w * 0.55),
                             "feuille" if (k + int(t * 10)) % 3 else "feuille2")
    p.ellipsoide(pts[-1], (0.22, 0.14, 0.22), "jeune")
    return p


def cycas(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.07)
    h = rng.uniform(0.7, 1.2)
    p.capsule((0, 0, 0), (0, h, 0), 0.32, 0.26, melange("ecorce", "tronc", 0.45, seed))
    for k in range(11):
        a = k / 11 * 2 * math.pi
        d = np.array([math.cos(a), 0, math.sin(a)])
        top = np.array([0, h + 0.1, 0])
        q = [top, top + d * 0.7 + np.array([0, 0.55, 0]), top + d * 1.4 + np.array([0, 0.5, 0])]
        p.chaine(q, [0.06, 0.05, 0.03], "feuille3")
        side = np.cross(d, [0, 1, 0])
        for t in np.linspace(0.2, 0.95, 6):
            c = top + d * 1.4 * t + np.array([0, 0.6 * math.sin(t * 2.0), 0])
            for sg in (-1, 1):
                p.capsule(c, c + side * sg * 0.28 * (1 - t * 0.5) + np.array([0, -0.05, 0]), 0.035, 0.02, "feuille")
    return p


def araucaria(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.2)
    h = rng.uniform(8.0, 10.5)
    p.capsule((0, 0, 0), (0, h, 0), 0.32, 0.12, melange("tronc", "tronc2", 0.3, seed))
    for lv in range(7):
        y = h * (0.38 + lv * 0.09)
        L = 2.6 * (1.0 - lv * 0.11)
        for k in range(5):
            a = k / 5 * 2 * math.pi + lv * 0.6
            d = np.array([math.cos(a), 0, math.sin(a)])
            end = np.array([0, y, 0]) + d * L + np.array([0, 0.5, 0])
            p.capsule((0, y, 0), end, 0.08, 0.06, "tronc")
            p.ellipsoide(end + np.array([0, 0.1, 0]), (0.75, 0.42, 0.75), "feuille3" if lv % 2 else "feuille")
    p.ellipsoide((0, h + 0.2, 0), (0.6, 0.8, 0.6), "feuille")
    return p


def preles(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.05)
    for k in range(7):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0.0, 0.45)
        b = np.array([math.cos(a) * r, 0, math.sin(a) * r])
        h = rng.uniform(1.4, 2.6)
        top = b + np.array([rng.uniform(-0.2, 0.2), h, rng.uniform(-0.2, 0.2)])
        p.capsule(b, top, 0.05, 0.04, rayures(1, 0.18, "prele", "prele2"))
        for t in np.linspace(0.25, 0.9, 5):
            c = b + (top - b) * t
            for j in range(6):
                aa = j / 6 * 2 * math.pi
                p.capsule(c, c + np.array([math.cos(aa) * 0.22, -0.1, math.sin(aa) * 0.22]), 0.015, 0.012, "prele2")
        p.ellipsoide(top, (0.05, 0.1, 0.05), "brindille")
    return p


def fougere_basse(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.05)
    for k in range(8):
        a = k / 8 * 2 * math.pi + rng.uniform(-0.3, 0.3)
        d = np.array([math.cos(a), 0, math.sin(a)])
        L = rng.uniform(0.6, 0.95)
        q = [np.zeros(3), d * L * 0.5 + np.array([0, 0.5, 0]), d * L + np.array([0, 0.28, 0])]
        p.chaine(q, [0.03, 0.025, 0.015], "feuille3")
        side = np.cross(d, [0, 1, 0])
        for t in np.linspace(0.25, 0.95, 5):
            c = d * L * t + np.array([0, 0.55 * math.sin(t * 2.6), 0])
            for sg in (-1, 1):
                p.capsule(c, c + side * sg * 0.16 * (1.1 - t) - np.array([0, 0.04, 0]), 0.025, 0.015, "feuille2" if k % 2 else "feuille")
    return p


def touffe(seed):
    rng = np.random.default_rng(seed)
    p = Piece(0.04)
    for k in range(9):
        a = rng.uniform(0, 2 * math.pi)
        b = np.array([math.cos(a) * 0.06, 0, math.sin(a) * 0.06])
        top = b + np.array([math.cos(a) * 0.12, rng.uniform(0.18, 0.36), math.sin(a) * 0.12])
        p.capsule(b, top, 0.02, 0.012, "jeune" if k % 3 == 0 else "feuille2")
    return p


def rocher(seed, s=0.18):
    rng = np.random.default_rng(seed)
    p = Piece(s)
    r = rng.uniform(0.9, 1.6)
    p.ellipsoide((0, r * 0.45, 0), (r * rng.uniform(1.0, 1.4), r * 0.75, r * rng.uniform(0.9, 1.2)), melange("roche", "roche2", 0.4, seed))
    for k in range(3):
        c = rng.uniform(-0.6, 0.6, 3) * r
        c[1] = abs(c[1]) * 0.6 + 0.2 * r
        p.ellipsoide(c, rng.uniform(0.4, 0.7, 3) * r, melange("roche3", "roche", 0.5, seed + k))
    p.ellipsoide((0, r * 1.05, 0), (r * 0.7, r * 0.18, r * 0.6), "mousse")
    return p


def squelette():
    p = Piece(0.1)
    # la colonne et la grande cage de côtes d'un très gros dinosaure
    sp = [(0, 1.4, -4.0), (0, 2.0, -2.0), (0, 2.3, 0.0), (0, 2.1, 2.0), (0, 1.5, 3.6), (0, 0.6, 5.0)]
    p.chaine(sp, [0.16, 0.2, 0.22, 0.2, 0.15, 0.1], melange("os", "os2", 0.3, 3))
    for k in range(9):
        z = -2.6 + k * 0.62
        rr = 1.7 * math.sin((k + 1) / 10 * math.pi) + 0.4
        for sg in (-1, 1):
            q = [(0, 2.25, z), (sg * rr * 0.8, 2.0, z + 0.05), (sg * rr, 1.0, z + 0.1), (sg * rr * 0.75, 0.1, z + 0.15)]
            p.chaine(q, [0.09, 0.08, 0.07, 0.05], "os")
    p.ellipsoide((0, 0.6, -5.0), (0.7, 0.55, 1.1), "os2")
    p.capsule((0.3, 0.3, -5.6), (0.4, 0.0, -6.3), 0.08, 0.03, "dent")
    return p


def nid():
    p = Piece(0.05)
    p.ellipsoide((0, 0.12, 0), (0.9, 0.22, 0.9), melange("brindille", "tronc", 0.4, 5))
    p.ellipsoide((0, 0.22, 0), (0.7, 0.14, 0.7), "fourrure2")
    for k, (x, z) in enumerate(((0.2, 0.15), (-0.25, 0.1), (0.05, -0.25), (-0.1, 0.32))):
        p.ellipsoide((x, 0.42, z), (0.17, 0.24, 0.17), taches("oeuf", "tache", 9.0, 0.95, k))
    return p


def feu():
    p = Piece(0.05)
    for k in range(10):
        a = k / 10 * 2 * math.pi
        p.ellipsoide((math.cos(a) * 0.75, 0.1, math.sin(a) * 0.75), (0.17, 0.13, 0.15), "roche2" if k % 2 else "roche")
    for k in range(4):
        a = k / 4 * 2 * math.pi + 0.4
        p.capsule((math.cos(a) * 0.5, 0.08, math.sin(a) * 0.5), (math.cos(a) * 0.05, 0.4, math.sin(a) * 0.05), 0.07, 0.06, "tronc")
    p.ellipsoide((0, 0.12, 0), (0.35, 0.1, 0.35), "braise")
    return p


def totem():
    p = Piece(0.07)
    p.capsule((0, 0, 0), (0, 4.0, 0), 0.32, 0.28, "tronc")
    # trois visages sculptés, peints d'ocre (le dernier : un dinosaure qui rit)
    for k, y in enumerate((1.0, 2.2, 3.4)):
        p.ellipsoide((0, y, 0.22), (0.3, 0.42, 0.14), "ecorce")
        p.boite((-0.12, y + 0.12, 0.33), (0.06, 0.05, 0.03), "noir")
        p.boite((0.12, y + 0.12, 0.33), (0.06, 0.05, 0.03), "noir")
        p.boite((0, y - 0.15, 0.33), (0.14, 0.04, 0.03), "ocre" if k != 2 else "dent")
        p.boite((0, y + 0.32, 0.3), (0.26, 0.04, 0.05), "rouge")
    p.ellipsoide((0, 4.15, 0), (0.45, 0.25, 0.45), "plume2")
    for k in range(5):
        a = k / 5 * math.pi - math.pi / 2
        p.capsule((0, 4.2, 0), (math.sin(a) * 0.5, 4.9, -0.1), 0.04, 0.06, "plume" if k % 2 else "crete")
    return p


def sechoir():
    p = Piece(0.05)
    for x in (-1.2, 1.2):
        p.capsule((x, 0, 0), (x, 1.9, 0), 0.06, 0.05, "tronc")
    p.capsule((-1.3, 1.85, 0), (1.3, 1.85, 0), 0.05, 0.05, "tronc2")
    p.boite((-0.55, 1.25, 0), (0.45, 0.55, 0.03), melange("fourrure", "fourrure2", 0.3, 2))
    p.boite((0.6, 1.3, 0), (0.42, 0.5, 0.03), melange("cuir", "fourrure", 0.3, 3))
    return p


def peau():
    p = Piece(0.05)
    p.boite((0, 0.03, 0), (0.9, 0.04, 0.6), melange("fourrure", "fourrure2", 0.35, 4))
    p.boite((0, 0.06, -0.55), (0.6, 0.06, 0.12), "fourrure3")
    return p


def tambour():
    p = Piece(0.04)
    p.capsule((0, 0, 0), (0, 0.55, 0), 0.32, 0.3, rayures(1, 0.12, "tronc", "ocre"))
    p.ellipsoide((0, 0.57, 0), (0.31, 0.03, 0.31), "cuir")
    return p


def os_seul():
    p = Piece(0.04)
    p.capsule((-0.3, 0.05, 0), (0.3, 0.05, 0.05), 0.05, 0.05, "os")
    for x in (-0.33, 0.33):
        p.ellipsoide((x, 0.06, 0.03), (0.08, 0.07, 0.1), "os2")
    return p


def entree_grotte():
    """Le cadre d'une entrée de grotte (posé contre la falaise) : un arc de gros blocs, du noir dedans."""
    p = Piece(0.25)
    for k in range(13):
        a = k / 12 * math.pi
        p.ellipsoide((math.cos(a) * 2.2, math.sin(a) * 3.0, 0.3), (0.85, 0.8, 0.7), melange("roche", "roche2", 0.4, k))
    p.boite((0, 1.4, -0.3), (2.0, 1.6, 0.3), "noir")
    return p


def massue():
    p = Piece(0.04)
    p.capsule((0, 0, 0), (0, 0.75, 0), 0.04, 0.06, "tronc")
    p.ellipsoide((0, 0.82, 0), (0.12, 0.16, 0.12), "ecorce")
    return p


def lance():
    p = Piece(0.03)
    p.capsule((0, -0.4, 0), (0, 1.3, 0), 0.025, 0.025, "tronc")
    p.capsule((0, 1.3, 0), (0, 1.55, 0), 0.05, 0.01, "roche3")
    return p


def pinceau():
    p = Piece(0.03)
    p.capsule((0, 0, 0), (0, 0.35, 0), 0.02, 0.02, "tronc")
    p.ellipsoide((0, 0.4, 0), (0.035, 0.07, 0.035), "ocre")
    return p


# =========================================================================== les grottes du Clan

def grotte(kind):
    """L'intérieur d'une grotte (repère : sol à y = 0, la sortie vers +z)."""
    p = Piece(0.25)
    if kind == "clan":
        p.boite((0, 3.0, 0), (12.5, 5.5, 10.5), melange("paroi", "paroi2", 0.35, 31))
        p.creuser_ellipsoide((0, 1.0, -0.5), (10.0, 5.6, 8.0))
        p.creuser_ellipsoide((-8.2, 1.0, -4.0), (3.2, 3.0, 3.0))
        p.creuser_ellipsoide((7.8, 1.0, 3.5), (3.0, 2.8, 3.0))
        p.creuser_capsule((0, 1.4, 6.0), (0, 1.4, 9.4), 1.7)
        p.boite((0, -1.0, 0), (12.5, 1.0, 10.5), melange("sol", "sol2", 0.4, 33))
    else:
        p.boite((0, 3.0, -2.0), (9.5, 5.0, 13.5), melange("paroi", "paroi2", 0.35, 32))
        p.creuser_ellipsoide((0, 1.0, -4.0), (6.5, 4.4, 9.0))
        p.creuser_ellipsoide((0, 1.0, 4.0), (4.0, 3.2, 4.0))
        p.creuser_capsule((0, 1.4, 6.0), (0, 1.4, 9.8), 1.6)
        p.boite((0, -1.0, -2.0), (9.5, 1.0, 13.5), melange("sol", "sol2", 0.4, 33))
    return p


# =========================================================================== les dinosaures

def raptor():
    s = 0.055
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0.0, 0.0), (0.24, 0.27, 0.55), ventre("raptor", "ventre", -0.12)) \
        .ellipsoide((0, 0.12, 0.0), (0.2, 0.18, 0.5), rayures(2, 0.16, "raptor", "raptor2"))
    P["cou"] = Piece(s).chaine([(0, 0, 0), (0, 0.22, 0.18), (0, 0.38, 0.3)], [0.13, 0.1, 0.09], ventre("raptor", "ventre", 0.15, 2)) \
        .ellipsoide((0, 0.45, 0.42), (0.13, 0.13, 0.22), "raptor") \
        .ellipsoide((0, 0.5, 0.6), (0.08, 0.08, 0.14), "raptor") \
        .boite((0.1, 0.52, 0.48), (0.03, 0.03, 0.03), "oeil").boite((-0.1, 0.52, 0.48), (0.03, 0.03, 0.03), "oeil") \
        .chaine([(0, 0.56, 0.3), (0, 0.66, 0.2), (0, 0.6, 0.08)], [0.03, 0.05, 0.03], "crete")
    P["machoire"] = Piece(s).ellipsoide((0, -0.03, 0.17), (0.07, 0.04, 0.16), "ventre") \
        .boite((0.05, 0.02, 0.2), (0.015, 0.025, 0.1), "dent").boite((-0.05, 0.02, 0.2), (0.015, 0.025, 0.1), "dent")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, 0.04, -0.5), (0, 0.06, -1.0)], [0.15, 0.1, 0.06], rayures(2, 0.14, "raptor", "raptor2"))
    P["queue2"] = Piece(s).chaine([(0, 0, 0), (0, 0.02, -0.45), (0, 0.04, -0.8)], [0.06, 0.04, 0.03], rayures(2, 0.14, "raptor", "raptor2")) \
        .ellipsoide((0, 0.04, -0.7), (0.03, 0.08, 0.15), "crete")
    for sg, nm in ((1, "G"), (-1, "D")):
        P["cuisse" + nm] = Piece(s).capsule((0, 0, 0), (0, -0.32, 0.08), 0.12, 0.08, "raptor")
        P["jambe" + nm] = Piece(s).chaine([(0, 0, 0), (0, -0.28, -0.1), (0, -0.42, 0.0)], [0.06, 0.045, 0.04], "raptor2") \
            .boite((0, -0.45, 0.1), (0.05, 0.03, 0.1), "raptor2").capsule((0, -0.4, 0.04), (0, -0.3, 0.12), 0.025, 0.012, "griffe")
        P["bras" + nm] = Piece(s).chaine([(0, 0, 0), (0, -0.12, 0.1), (0, -0.14, 0.22)], [0.04, 0.03, 0.02], "raptor") \
            .capsule((0, -0.14, 0.22), (0, -0.2, 0.26), 0.015, 0.01, "griffe")
    rig = {"corps": [0, 0.82, 0], "cou": [0, 0.92, 0.42], "machoire": [0, 1.38, 0.82], "queue": [0, 0.85, -0.5], "queue2": [0, 0.91, -1.5],
           "cuisseG": [0.17, 0.75, -0.05], "cuisseD": [-0.17, 0.75, -0.05], "jambeG": [0.17, 0.43, 0.03], "jambeD": [-0.17, 0.43, 0.03],
           "brasG": [0.14, 0.72, 0.38], "brasD": [-0.14, 0.72, 0.38]}
    return P, rig


def triceratops():
    s = 0.09
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (0.95, 0.85, 1.6), ventre("trice", "ventre", -0.5)) \
        .ellipsoide((0, 0.25, -0.1), (0.85, 0.65, 1.45), taches("trice", "trice2", 2.0, 0.6, 1))
    P["tete"] = Piece(s).ellipsoide((0, 0, 0.45), (0.45, 0.42, 0.6), "trice") \
        .ellipsoide((0, 0.45, -0.05), (1.0, 0.85, 0.16), rayures(0, 0.22, "collerette", "collerette2")) \
        .capsule((0.25, 0.3, 0.55), (0.32, 0.75, 1.35), 0.09, 0.02, "corne").capsule((-0.25, 0.3, 0.55), (-0.32, 0.75, 1.35), 0.09, 0.02, "corne") \
        .capsule((0, 0.05, 0.95), (0, 0.32, 1.2), 0.08, 0.02, "corne") \
        .ellipsoide((0, -0.15, 1.05), (0.18, 0.16, 0.18), "bec") \
        .boite((0.32, 0.18, 0.62), (0.05, 0.05, 0.05), "noir").boite((-0.32, 0.18, 0.62), (0.05, 0.05, 0.05), "noir")
    for sp in range(5):
        a = (sp / 4 - 0.5) * 2.4
        P["tete"].cone((math.sin(a) * 0.95, 0.45 + math.cos(a) * 0.8, -0.08), (math.sin(a) * 1.15, 0.45 + math.cos(a) * 1.0, -0.12), 0.08, "corne")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, -0.1, -1.0), (0, -0.4, -2.0)], [0.45, 0.28, 0.1], ventre("trice", "ventre", -0.25))
    for nm, x, z in (("avG", 0.55, 1.0), ("avD", -0.55, 1.0), ("arG", 0.6, -0.9), ("arD", -0.6, -0.9)):
        P["patte" + nm] = Piece(s).capsule((0, 0, 0), (0, -1.0, 0.05), 0.3 if "ar" in nm else 0.24, 0.2, "trice2") \
            .ellipsoide((0, -1.08, 0.12), (0.26, 0.12, 0.3), "trice2")
    rig = {"corps": [0, 1.65, 0], "tete": [0, 1.6, 1.6], "queue": [0, 1.75, -1.5],
           "patteavG": [0.55, 1.15, 1.0], "patteavD": [-0.55, 1.15, 1.0], "pattearG": [0.6, 1.15, -0.9], "pattearD": [-0.6, 1.15, -0.9]}
    return P, rig


def pteranodon():
    s = 0.045
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (0.18, 0.18, 0.42), ventre("ptero", "ventre", -0.06))
    P["tete"] = Piece(s).chaine([(0, 0, 0), (0, 0.1, 0.2)], [0.08, 0.07], "ptero") \
        .ellipsoide((0, 0.14, 0.3), (0.08, 0.09, 0.16), "ptero") \
        .capsule((0, 0.14, 0.38), (0, 0.08, 0.95), 0.055, 0.01, "bec") \
        .capsule((0, 0.2, 0.25), (0, 0.38, -0.35), 0.05, 0.015, "crane") \
        .boite((0.06, 0.18, 0.36), (0.02, 0.02, 0.02), "noir").boite((-0.06, 0.18, 0.36), (0.02, 0.02, 0.02), "noir")
    for sg, nm in ((1, "G"), (-1, "D")):
        P["aile" + nm] = Piece(s).boite((sg * 0.55, 0, 0.0), (0.55, 0.025, 0.28), melange("membrane", "ptero2", 0.2, 3)) \
            .capsule((0, 0.02, 0.22), (sg * 1.1, 0.02, 0.18), 0.04, 0.03, "ptero2")
        P["bout" + nm] = Piece(s).chaine([(0, 0, 0.18), (sg * 0.5, 0.0, 0.1), (sg * 0.95, 0, -0.25)], [0.03, 0.025, 0.01], "ptero2") \
            .boite((sg * 0.45, 0, -0.02), (0.45, 0.02, 0.2), "membrane")
    P["pattes"] = Piece(s).capsule((0.06, 0, 0), (0.08, -0.05, -0.3), 0.03, 0.02, "ptero2").capsule((-0.06, 0, 0), (-0.08, -0.05, -0.3), 0.03, 0.02, "ptero2")
    rig = {"corps": [0, 0, 0], "tete": [0, 0.08, 0.4], "aileG": [0.15, 0.08, 0.05], "aileD": [-0.15, 0.08, 0.05],
           "boutG": [1.25, 0.08, 0.05], "boutD": [-1.25, 0.08, 0.05], "pattes": [0, -0.08, -0.3]}
    return P, rig


def ankylosaure():
    s = 0.07
    P = {}
    body = Piece(s).ellipsoide((0, 0, 0), (0.8, 0.5, 1.3), ventre("anky", "ventre", -0.3)) \
        .ellipsoide((0, 0.12, 0), (0.85, 0.45, 1.3), melange("plaque", "anky2", 0.35, 7))
    for k in range(7):
        z = -1.0 + k * 0.33
        for sg in (-1, 1):
            body.cone((sg * 0.8, 0.0, z), (sg * 1.1, 0.12, z), 0.09, "corne")
        body.cone((0.35, 0.5, z), (0.4, 0.68, z), 0.06, "anky2").cone((-0.35, 0.5, z), (-0.4, 0.68, z), 0.06, "anky2")
    P["corps"] = body
    P["tete"] = Piece(s).ellipsoide((0, 0, 0.25), (0.34, 0.24, 0.38), melange("anky", "plaque", 0.3, 2)) \
        .cone((0.28, 0.12, 0.05), (0.42, 0.22, -0.1), 0.06, "corne").cone((-0.28, 0.12, 0.05), (-0.42, 0.22, -0.1), 0.06, "corne") \
        .boite((0.22, 0.06, 0.4), (0.03, 0.03, 0.03), "noir").boite((-0.22, 0.06, 0.4), (0.03, 0.03, 0.03), "noir")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, 0, -0.8), (0, -0.05, -1.6)], [0.3, 0.16, 0.1], "anky") \
        .ellipsoide((0, -0.05, -1.75), (0.3, 0.2, 0.25), melange("plaque", "anky2", 0.3, 5))
    for nm, x, z in (("avG", 0.5, 0.8), ("avD", -0.5, 0.8), ("arG", 0.55, -0.7), ("arD", -0.55, -0.7)):
        P["patte" + nm] = Piece(s).capsule((0, 0, 0), (0, -0.55, 0.03), 0.2, 0.15, "anky2").ellipsoide((0, -0.6, 0.08), (0.17, 0.08, 0.2), "anky2")
    rig = {"corps": [0, 0.95, 0], "tete": [0, 0.8, 1.35], "queue": [0, 0.95, -1.2],
           "patteavG": [0.5, 0.65, 0.8], "patteavD": [-0.5, 0.65, 0.8], "pattearG": [0.55, 0.65, -0.7], "pattearD": [-0.55, 0.65, -0.7]}
    return P, rig


def trex():
    s = 0.11
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (1.15, 1.35, 2.3), ventre("trex", "trex3", -0.55)) \
        .ellipsoide((0, 0.4, -0.1), (1.0, 1.0, 2.1), rayures(2, 0.45, "trex", "trex2")) \
        .chaine([(0, 0.6, 1.6), (0, 1.3, 2.5)], [0.85, 0.72], ventre("trex", "trex3", 0.9))
    P["tete"] = Piece(s).ellipsoide((0, 0.2, 0.7), (0.62, 0.65, 1.05), "trex") \
        .ellipsoide((0, 0.15, 1.45), (0.5, 0.45, 0.6), "trex") \
        .ellipsoide((0, 0.55, 0.65), (0.5, 0.25, 0.7), rayures(2, 0.3, "trex", "trex2")) \
        .boite((0.48, 0.5, 0.95), (0.08, 0.1, 0.1), "oeil").boite((-0.48, 0.5, 0.95), (0.08, 0.1, 0.1), "oeil") \
        .boite((0.53, 0.5, 0.97), (0.04, 0.08, 0.04), "pupille").boite((-0.53, 0.5, 0.97), (0.04, 0.08, 0.04), "pupille") \
        .boite((0.42, 0.62, 0.95), (0.12, 0.05, 0.14), "trex2").boite((-0.42, 0.62, 0.95), (0.12, 0.05, 0.14), "trex2")
    for k in range(7):
        z = 0.75 + k * 0.17
        for sg in (-1, 1):
            P["tete"].boite((sg * 0.4, -0.18, z), (0.03, 0.08, 0.03), "dent")
    P["tete"].ellipsoide((0, -0.12, 0.95), (0.45, 0.12, 0.8), "gueule")
    P["machoire"] = Piece(s).ellipsoide((0, -0.1, 0.7), (0.5, 0.25, 1.0), ventre("trex", "trex3", -0.15)) \
        .ellipsoide((0, 0.05, 0.8), (0.38, 0.08, 0.75), "gueule")
    for k in range(6):
        for sg in (-1, 1):
            P["machoire"].boite((sg * 0.34, 0.14, 0.4 + k * 0.17), (0.03, 0.07, 0.03), "dent")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, 0.1, -1.6)], [0.95, 0.6], rayures(2, 0.45, "trex", "trex2"))
    P["queue2"] = Piece(s).chaine([(0, 0, 0), (0, 0.0, -1.6)], [0.6, 0.35], rayures(2, 0.45, "trex", "trex2"))
    P["queue3"] = Piece(s).chaine([(0, 0, 0), (0, -0.05, -1.8)], [0.35, 0.08], rayures(2, 0.45, "trex", "trex2"))
    for sg, nm in ((1, "G"), (-1, "D")):
        P["cuisse" + nm] = Piece(s).ellipsoide((0, -0.6, 0.15), (0.55, 1.0, 0.75), "trex").capsule((0, -0.5, 0.2), (0, -1.6, -0.2), 0.42, 0.3, "trex")
        P["jambe" + nm] = Piece(s).capsule((0, 0, 0), (0, -1.3, -0.15), 0.3, 0.2, "trex2") \
            .boite((0, -1.45, 0.25), (0.28, 0.12, 0.55), "trex2") \
            .capsule((0.15, -1.45, 0.75), (0.2, -1.55, 0.95), 0.07, 0.02, "griffe").capsule((-0.15, -1.45, 0.75), (-0.2, -1.55, 0.95), 0.07, 0.02, "griffe")
        P["bras" + nm] = Piece(s).chaine([(0, 0, 0), (0, -0.35, 0.3), (0, -0.4, 0.55)], [0.13, 0.1, 0.08], "trex") \
            .capsule((0, -0.4, 0.55), (0, -0.55, 0.65), 0.04, 0.02, "griffe")
    rig = {"corps": [0, 3.6, 0], "tete": [0, 4.9, 2.65], "machoire": [0, 4.75, 2.9], "queue": [0, 3.7, -2.1], "queue2": [0, 3.8, -3.7],
           "queue3": [0, 3.8, -5.3], "cuisseG": [0.95, 3.4, -0.3], "cuisseD": [-0.95, 3.4, -0.3], "jambeG": [0.95, 1.8, -0.5],
           "jambeD": [-0.95, 1.8, -0.5], "brasG": [0.7, 3.5, 1.9], "brasD": [-0.7, 3.5, 1.9]}
    return P, rig


def brachiosaure():
    s = 0.16
    P = {}
    P["corps"] = Piece(s).ellipsoide((0, 0, 0), (1.6, 1.7, 3.2), ventre("brachio", "brachio3", -0.6)) \
        .ellipsoide((0, 0.5, 0.5), (1.4, 1.4, 2.6), taches("brachio", "brachio2", 1.2, 0.6, 2))
    P["cou"] = Piece(s).chaine([(0, 0, 0), (0, 2.0, 1.5), (0, 3.8, 3.2)], [0.95, 0.72, 0.56], ventre("brachio", "brachio3", 0.0, 2))
    P["cou2"] = Piece(s).chaine([(0, 0, 0), (0, 1.8, 0.9), (0, 3.2, 1.6)], [0.56, 0.44, 0.36], ventre("brachio", "brachio3", 0.0, 2))
    P["tete"] = Piece(s).ellipsoide((0, 0.2, 0.5), (0.42, 0.45, 0.8), "brachio") \
        .ellipsoide((0, 0.55, 0.35), (0.3, 0.3, 0.35), "brachio2") \
        .boite((0.36, 0.35, 0.55), (0.06, 0.06, 0.06), "noir").boite((-0.36, 0.35, 0.55), (0.06, 0.06, 0.06), "noir")
    P["queue"] = Piece(s).chaine([(0, 0, 0), (0, -0.4, -2.4), (0, -1.0, -4.4)], [1.0, 0.6, 0.35], "brachio")
    P["queue2"] = Piece(s).chaine([(0, 0, 0), (0, -0.4, -2.6), (0, -0.6, -4.6)], [0.35, 0.2, 0.08], "brachio")
    for nm, x, z, L in (("avG", 1.1, 2.0, 4.4), ("avD", -1.1, 2.0, 4.4), ("arG", 1.2, -2.0, 3.6), ("arD", -1.2, -2.0, 3.6)):
        P["patte" + nm] = Piece(s).capsule((0, 0, 0), (0, -L, 0.05), 0.6, 0.48, "brachio2").ellipsoide((0, -L - 0.05, 0.15), (0.55, 0.22, 0.6), "brachio2")
    rig = {"corps": [0, 5.6, 0], "cou": [0, 6.6, 2.4], "cou2": [0, 10.4, 5.6], "tete": [0, 13.6, 7.2], "queue": [0, 5.8, -2.8],
           "queue2": [0, 4.8, -7.2], "patteavG": [1.1, 4.6, 2.0], "patteavD": [-1.1, 4.6, 2.0], "pattearG": [1.2, 3.8, -2.0], "pattearD": [-1.2, 3.8, -2.0]}
    return P, rig


# =========================================================================== les hommes des cavernes

HABITANTS = {
    # nom : peau, cheveux, barbe, tenue, taille, extras
    "ougha": ("peau2", "cheveux1", True, "fourrure2", 1.12, ["coiffe", "collier"]),
    "ocre": ("peau1", "cheveux4", False, "fourrure", 0.98, ["mains_ocre", "bandeau"]),
    "mamie_silex": ("peau4", "cheveux3", False, "fourrure3", 0.9, ["chignon", "collier"]),
    "grok": ("peau3", "cheveux1", True, "fourrure", 1.08, ["peinture"]),
    "ploc": ("peau1", "cheveux2", False, "fourrure2", 0.62, ["enfant"]),
    "pika": ("peau2", "cheveux4", False, "fourrure3", 0.6, ["enfant", "chignon"]),
    "vieux_flint": ("peau4", "cheveux3", True, "fourrure2", 0.95, ["longue_barbe"]),
    "boum": ("peau3", "cheveux2", True, "fourrure3", 1.02, ["bandeau"]),
}


def habitant(nom):
    peau, chev, barbe, tenue, k, ext = HABITANTS[nom]
    s = 0.045
    enfant = "enfant" in ext
    P = {}
    # le tronc : la tunique de fourrure en biais (une épaule nue), une ceinture de cuir
    tr = Piece(s).ellipsoide((0, 0.28, 0), (0.2, 0.3, 0.13), peau) \
        .boite((0, 0.16, 0), (0.21, 0.2, 0.14), melange(tenue, "fourrure2" if tenue != "fourrure2" else "fourrure", 0.3, 1)) \
        .capsule((0.18, 0.5, 0), (-0.05, 0.25, 0.0), 0.11, 0.12, tenue) \
        .boite((0, 0.0, 0), (0.21, 0.03, 0.145), "cuir")
    if "collier" in ext:
        for j in range(5):
            tr.boite(((j - 2) * 0.06, 0.48 - abs(j - 2) * 0.03, 0.12), (0.02, 0.03, 0.02), "dent")
    if "peinture" in ext:
        tr.boite((-0.1, 0.38, 0.13), (0.06, 0.015, 0.01), "ocre").boite((-0.1, 0.32, 0.13), (0.06, 0.015, 0.01), "ocre")
    P["tronc"] = tr
    # la tête : un gros cube arrondi, de gros sourcils, un grand nez, les yeux, la bouche
    hd = Piece(s).boite((0, 0.15, 0), (0.15, 0.16, 0.14), peau) \
        .boite((0, 0.3, -0.02), (0.165, 0.06, 0.16), chev).boite((0, 0.18, -0.12), (0.165, 0.16, 0.05), chev) \
        .boite((0, 0.2, 0.15), (0.13, 0.025, 0.02), chev) \
        .boite((0.065, 0.15, 0.145), (0.025, 0.025, 0.01), "blanc").boite((-0.065, 0.15, 0.145), (0.025, 0.025, 0.01), "blanc") \
        .boite((0.065, 0.145, 0.155), (0.012, 0.015, 0.005), "noir").boite((-0.065, 0.145, 0.155), (0.012, 0.015, 0.005), "noir") \
        .boite((0, 0.09, 0.165), (0.035, 0.045, 0.03), peau) \
        .boite((0, 0.03, 0.15), (0.05, 0.012, 0.01), "levre")
    if barbe:
        hd.boite((0, 0.0, 0.08), (0.15, 0.06 if "longue_barbe" not in ext else 0.12, 0.08), chev).boite((0, 0.04, 0.15), (0.05, 0.01, 0.01), "levre")
    if "chignon" in ext:
        hd.ellipsoide((0, 0.4, -0.05), (0.08, 0.08, 0.08), chev).capsule((-0.1, 0.42, -0.05), (0.1, 0.42, -0.05), 0.012, 0.012, "os")
    if "bandeau" in ext:
        hd.boite((0, 0.26, 0.0), (0.17, 0.02, 0.17), "rouge")
    if "coiffe" in ext:
        hd.boite((0, 0.34, 0.0), (0.17, 0.03, 0.17), "cuir")
        for j in range(5):
            hd.capsule(((j - 2) * 0.06, 0.36, -0.02), ((j - 2) * 0.1, 0.62, -0.08), 0.02, 0.03, ["plume", "crete", "plume2", "crete", "plume"][j])
    P["tete"] = hd
    for sg, nm in ((1, "G"), (-1, "D")):
        arm = Piece(s).capsule((0, 0, 0), (0, -0.48, 0.02), 0.065, 0.055, peau).ellipsoide((0, -0.52, 0.03), (0.06, 0.06, 0.05), peau)
        if "mains_ocre" in ext:
            arm.ellipsoide((0, -0.53, 0.03), (0.065, 0.05, 0.055), "ocre")
        if sg == 1:
            arm.boite((0, -0.06, 0), (0.08, 0.07, 0.08), tenue)
        P["bras" + nm] = arm
        P["jambe" + nm] = Piece(s).capsule((0, 0, 0), (0, -0.42, 0.0), 0.085, 0.07, peau) \
            .boite((0, -0.1, 0), (0.09, 0.1, 0.09), tenue) \
            .boite((0, -0.47, 0.04), (0.07, 0.04, 0.11), "cuir")
    hip = 0.5
    rig = {"tronc": [0, hip, 0], "tete": [0, hip + 0.58, 0], "brasG": [0.25, hip + 0.52, 0], "brasD": [-0.25, hip + 0.52, 0],
           "jambeG": [0.1, hip, 0], "jambeD": [-0.1, hip, 0], "taille": [k * (0.85 if enfant else 1.0)]}
    return P, rig


# =========================================================================== où poser les plantes

def placer(rel, rng):
    lv, mats, info = rel["levels"], rel["mats"], rel["info"]
    n = T.N
    out = {}
    dpath = info["dpath"]
    lake = info["lake"]

    def free(ix, iz, rad_paths=2.5):
        if ix < 1 or iz < 1 or ix >= n - 1 or iz >= n - 1:
            return False
        if lake[iz, ix] or dpath[iz, ix] < rad_paths:
            return False
        return True

    def pos(ix, iz):
        x = (ix + 0.5) * T.BLOC - T.HALF
        z = (iz + 0.5) * T.BLOC - T.HALF
        return x, lv[iz, ix] * T.LEVEL, z

    def far(x, z, zones):
        for (cx, cz, r) in zones:
            if (x - cx) ** 2 + (z - cz) ** 2 < r * r:
                return False
        return True

    interdits = [(T.CAMP[0], T.CAMP[1], T.CAMP[2] + 4), (T.CIRQUE[0], T.CIRQUE[1], T.CIRQUE[2] + 3), (T.DOCK_A[0], T.DOCK_A[1], 8.0)]
    regles = {
        # nom : (matières, essais, distance aux chemins, taille min-max, niveau mini)
        "fougere_arbo": ([T.JUNGLE, T.HERBE], 7000, 3.0, (0.85, 1.25), 2),
        "cycas": ([T.HERBE, T.SABLE, T.PRAIRIE, T.JUNGLE], 2600, 2.5, (0.8, 1.2), 1),
        "araucaria": ([T.HERBE, T.PRAIRIE, T.JUNGLE], 2400, 4.0, (0.85, 1.2), 3),
        "preles": ([T.BOUE, T.HERBE, T.JUNGLE], 5000, 2.0, (0.8, 1.3), 2),
        "fougere_basse": ([T.JUNGLE, T.HERBE, T.MOUSSE], 9000, 1.5, (0.7, 1.4), 1),
        "touffe": ([T.HERBE, T.PRAIRIE, T.JUNGLE], 26000, 1.0, (0.7, 1.5), 1),
        "rocher_0": ([T.PIERRE, T.PRAIRIE, T.HERBE, T.BASALTE, T.CENDRE], 1200, 2.0, (0.6, 1.4), 0),
        "rocher_1": ([T.PIERRE, T.PRAIRIE, T.HERBE, T.BASALTE], 1200, 2.0, (0.6, 1.4), 0),
    }
    poids = {"fougere_arbo": {T.JUNGLE: 1.0, T.HERBE: 0.25}, "araucaria": {T.PRAIRIE: 0.5, T.HERBE: 0.6, T.JUNGLE: 0.4},
             "preles": {T.BOUE: 1.0, T.HERBE: 0.12, T.JUNGLE: 0.3}}
    for nom, (ok_mats, essais, dp, (t0, t1), lmin) in regles.items():
        arr = []
        placed = []
        for _ in range(essais):
            ix, iz = rng.integers(2, n - 2, 2)
            m = mats[iz, ix]
            if m not in ok_mats or not free(ix, iz, dp) or lv[iz, ix] < lmin:
                continue
            w = poids.get(nom, {}).get(int(m), 1.0)
            if rng.random() > w:
                continue
            x, y, z = pos(ix, iz)
            if not far(x, z, interdits):
                continue
            # pas sur une marche : les quatre voisins à la même hauteur
            if nom != "touffe" and np.ptp(lv[iz - 1:iz + 2, ix - 1:ix + 2]) > 0:
                continue
            md = {"araucaria": 9.0, "fougere_arbo": 3.5, "cycas": 2.5}.get(nom, 0.0)
            if md > 0 and any((x - a) ** 2 + (z - b) ** 2 < md * md for a, b in placed):
                continue
            placed.append((x, z))
            arr += [x, y, z, float(rng.uniform(0, 2 * math.pi)), float(rng.uniform(t0, t1))]
        out[nom] = gdvar.f32(np.array(arr, np.float32))
    return out


def build(OUT, rel):
    t0 = time.time()
    rng = np.random.default_rng(9090)
    modeles = {}
    variantes = {"fougere_arbo": 3, "cycas": 2, "araucaria": 2, "preles": 2, "fougere_basse": 2, "touffe": 2}
    fabriques = {"fougere_arbo": fougere_arbo, "cycas": cycas, "araucaria": araucaria, "preles": preles,
                 "fougere_basse": fougere_basse, "touffe": touffe}
    for nom, nv in variantes.items():
        for k in range(nv):
            modeles[f"{nom}_{k}"] = fabriques[nom](9000 + k * 7 + len(nom)).export(PALETTE, seed=k + 1)
    for k in range(2):
        modeles[f"rocher_{k}"] = rocher(950 + k).export(PALETTE, seed=k + 3)
    for nom, f in (("squelette", squelette), ("nid", nid), ("feu", feu), ("totem", totem), ("sechoir", sechoir), ("peau", peau),
                   ("tambour", tambour), ("os", os_seul), ("entree_grotte", entree_grotte), ("massue", massue), ("lance", lance),
                   ("pinceau", pinceau)):
        modeles[nom] = f().export(PALETTE, seed=len(nom))
    for k in ("clan", "peintures"):
        g = grotte(k)
        modeles["grotte_" + k] = g.export(PALETTE, seed=40 + len(k), var=0.06, bord_plein=True)
    rigs = {}
    for nom, f in (("raptor", raptor), ("triceratops", triceratops), ("pteranodon", pteranodon), ("ankylosaure", ankylosaure),
                   ("trex", trex), ("brachiosaure", brachiosaure)):
        parts, rig = f()
        for pn, piece in parts.items():
            modeles[f"{nom}.{pn}"] = piece.export(PALETTE, seed=zlib.crc32(pn.encode()) % 997, var=0.06)
        rigs[nom] = {k: [float(x) for x in v] for k, v in rig.items()}
    for nom in HABITANTS:
        parts, rig = habitant(nom)
        for pn, piece in parts.items():
            modeles[f"{nom}.{pn}"] = piece.export(PALETTE, seed=zlib.crc32((nom + pn).encode()) % 991, var=0.05)
        rigs[nom] = {k: [float(x) for x in v] for k, v in rig.items()}
    plantes = placer(rel, rng)
    d = {"modeles": modeles, "rigs": rigs, "plantes": plantes}
    raw, comp = gdvar.save(OUT / "modeles.bin", d)
    tri = sum(len(m["i"].data) // 12 for m in modeles.values())
    print(f"modèles : {len(modeles)} pièces, ~{tri} triangles ; plantes : " +
          ", ".join(f"{k} {len(v.data) // 20}" for k, v in plantes.items()) + f" ; {comp // 1024} Ko ({time.time() - t0:.1f} s)")
