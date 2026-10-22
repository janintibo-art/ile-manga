"""Chemins du générateur des habitants V64 (modifiables par variables d'environnement).

MAKEHUMAN_DATA : dossier « data » de MakeHuman 1.x (maillage de base, cibles) — licence CC0
MPFB_DATA      : dossier « src/mpfb/data » de MPFB2 (rig mixamo, poids, yeux, textures) — licence CC0
V64_CACHE      : fiches des habitants (pnj.json), squelette du héros (hero_skel.json) et caches de calcul
"""
import os

ICI = os.path.dirname(os.path.abspath(__file__))
DEPOT = os.path.abspath(os.path.join(ICI, '..', '..', '..'))
MH = os.environ.get('MAKEHUMAN_DATA', '/root/mh/makehuman/makehuman/data')
MPFB = os.environ.get('MPFB_DATA', '/root/mh/mpfb2/src/mpfb/data')
CACHE_DIR = os.environ.get('V64_CACHE', os.path.expanduser('~/.cache/ile_manga_v64'))
OUT = os.path.join(DEPOT, 'www', 'assets', 'models', 'pnj64')
OUTT = os.path.join(DEPOT, 'www', 'assets', 'textures', 'pnj64')


def cache(name):
    os.makedirs(CACHE_DIR, exist_ok=True)
    return os.path.join(CACHE_DIR, name)
