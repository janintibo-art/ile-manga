"""V50 : les bruitages d'action d'Île Manga (pas, épée, coups, monstres, coffres, portes,
outils, pêche, bateau, ramassage, interface).

Tous viennent du recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (packs Kenney,
« 80 CC0 RPG SFX », « 80 CC0 creature SFX », « Organic Wooshes », « 100 CC0 SFX »…) : on les
découpe (silence de tête retiré, longueur bornée, fondu de sortie), on les met en mono, on
les normalise et on les convertit en OGG Vorbis dans www/assets/sons/sfx/.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_bruitages_v50.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons" / "sfx"

K_IMP = "kenney_impactsounds/Audio/"
K_RPG = "kenney_rpgaudio/Audio/"
K_UI = "kenney_interfacesounds/Audio/"
RPG = "80-CC0-RPG-SFX/"
CRE = "80-CC0-creature-SFX/"
CRE2 = "80-CC0-creature-sfx-2/"
WOOSH = "Micro Pack - Organic Wooshes/"
S100 = "100-CC0-SFX/"
WM = "100-CC0-wood-metal-SFX/"
BFH = "75-cc0-breaking-falling-hit-sfx/"
SPL = "40-cc0-water-splash-slime-sfx/"
MUD = "25-CC0-mud-sfx/"


def rng(prefix, a, b, fmt="{:03d}", ext=".ogg"):
    return [prefix + fmt.format(i) + ext for i in range(a, b + 1)]


## nom -> (fichiers sources, longueur max en s, transposition en demi-tons, passe-haut Hz)
CATALOGUE = {
    # Pas selon le sol
    "pas_herbe": (rng(K_IMP + "footstep_grass_", 0, 4), 0.35, 0, 60),
    "pas_sable": (rng(K_IMP + "footstep_snow_", 0, 4), 0.35, -2, 80),
    "pas_pierre": (rng(K_IMP + "footstep_concrete_", 0, 4), 0.35, 0, 60),
    "pas_bois": (rng(K_IMP + "footstep_wood_", 0, 4), 0.35, 0, 60),
    "pas_cendre": (rng(K_IMP + "footstep_carpet_", 0, 4), 0.35, -3, 60),
    "pas_eau": ([SPL + "splash_01.ogg", SPL + "splash_02.ogg", SPL + "splash_03.ogg", SPL + "splash_04.ogg"], 0.4, 5, 200),
    "atterrissage": ([K_IMP + "impactSoft_heavy_000.ogg", K_IMP + "impactSoft_heavy_001.ogg", K_IMP + "impactSoft_heavy_002.ogg"], 0.5, -2, 40),
    # Épée et combat
    "fendre_air": ([WOOSH + "Swish 1.wav", WOOSH + "Swish 2.wav", WOOSH + "Swish 3.wav", WOOSH + "Classic Swish 1.wav", WOOSH + "Classic Swish 2.wav"], 0.5, 0, 150),
    "fendre_lourd": ([WOOSH + "Slash.wav", WOOSH + "Combo 1.wav", WOOSH + "Thunk 1.wav"], 0.7, -2, 100),
    "touche_chair": (rng(K_IMP + "impactPunch_medium_", 0, 4), 0.4, 0, 60),
    "touche_lourd": (rng(K_IMP + "impactPunch_heavy_", 0, 4), 0.5, 0, 40),
    "touche_pierre": (rng(K_IMP + "impactMining_", 0, 4), 0.5, -2, 60),
    "touche_carapace": (rng(K_IMP + "impactPlate_light_", 0, 4), 0.4, 0, 80),
    "touche_bois": (rng(K_IMP + "impactWood_medium_", 0, 4), 0.4, 0, 60),
    "parade": (rng(K_IMP + "impactMetal_heavy_", 0, 4), 0.6, 0, 80),
    "jarre_casse": ([BFH + "bfh1_breaking_01.ogg", BFH + "bfh1_breaking_02.ogg", BFH + "bfh1_breaking_03.ogg"], 1.2, 2, 80),
    "joueur_blesse": ([CRE2 + "human_01.ogg", CRE2 + "human_02.ogg", CRE2 + "human_03.ogg", CRE2 + "human_04.ogg"], 0.6, 0, 100),
    # Monstres : menace (avant l'attaque), blessure, mort
    "crabe_menace": ([RPG + "creature_misc_01.ogg", RPG + "creature_misc_02.ogg"], 0.6, 6, 150),
    "crabe_mort": ([RPG + "creature_die_01.ogg"], 1.0, 5, 120),
    "insecte_menace": ([CRE + "bug_01.ogg", CRE + "bug_02.ogg", CRE + "bug_03.ogg", CRE + "bug_04.ogg"], 0.8, 0, 150),
    "insecte_mort": ([CRE2 + "bug_05.ogg", CRE2 + "bug_06.ogg"], 1.0, -2, 120),
    "monstre_menace": ([CRE + "monster_01.ogg", CRE + "monster_02.ogg", CRE + "monster_03.ogg", CRE + "monster_04.ogg"], 1.0, 0, 80),
    "monstre_blesse": ([CRE + "hurt_01.ogg", CRE + "hurt_02.ogg", CRE + "hurt_03.ogg", CRE + "hurt_04.ogg"], 0.8, 0, 80),
    "monstre_mort": ([CRE2 + "die_01.ogg", CRE2 + "die_02.ogg", CRE2 + "die_03.ogg"], 1.5, 0, 60),
    "golem_menace": ([CRE2 + "stomp_01.ogg", RPG + "stones_01.ogg", RPG + "stones_02.ogg"], 1.2, -5, 40),
    "golem_mort": ([BFH + "bfh1_rock_breaking_01.ogg", BFH + "bfh1_rock_breaking_02.ogg"], 2.0, -3, 40),
    "magma_menace": ([RPG + "spell_fire_01.ogg", RPG + "spell_fire_02.ogg", RPG + "spell_fire_03.ogg"], 1.2, -3, 60),
    "magma_mort": ([RPG + "creature_slime_01.ogg", RPG + "creature_slime_02.ogg"], 1.2, -5, 60),
    "follet_menace": ([RPG + "spell_01.ogg", RPG + "spell_02.ogg"], 1.2, 2, 150),
    "follet_mort": ([RPG + "item_gem_01.ogg", RPG + "item_gem_02.ogg"], 1.0, -3, 150),
    "serpent_menace": ([CRE + "breath.ogg", CRE2 + "breath_02.ogg"], 1.0, 2, 300),
    "boss_cri": ([RPG + "creature_roar_01.ogg", RPG + "creature_roar_02.ogg", RPG + "creature_roar_03.ogg"], 2.5, 0, 40),
    # Objets
    "ramasse": ([RPG + "item_misc_01.ogg", RPG + "item_misc_02.ogg", RPG + "item_misc_03.ogg", RPG + "item_misc_04.ogg"], 0.5, 0, 100),
    "ramasse_pieces": ([RPG + "item_coins_01.ogg", RPG + "item_coins_02.ogg", RPG + "item_coins_03.ogg", K_RPG + "handleCoins.ogg"], 0.8, 0, 120),
    "ramasse_gemme": ([RPG + "item_gem_01.ogg", RPG + "item_gem_02.ogg", RPG + "item_gem_03.ogg", RPG + "item_gem_04.ogg"], 0.8, 0, 120),
    "ramasse_pierre": ([RPG + "item_stone_01.ogg", RPG + "item_stone_02.ogg", RPG + "item_stone_03.ogg"], 0.6, 0, 80),
    "ramasse_bois": ([RPG + "item_wood_01.ogg", RPG + "item_wood_02.ogg", RPG + "item_wood_03.ogg"], 0.6, 0, 80),
    "manger": ([CRE + "eat_01.ogg", CRE + "eat_02.ogg", CRE + "eat_03.ogg", CRE + "eat_04.ogg"], 0.9, 2, 100),
    "jeter": ([K_RPG + "dropLeather.ogg"], 0.6, 0, 80),
    "equiper": ([K_RPG + "drawKnife1.ogg", K_RPG + "drawKnife2.ogg", K_RPG + "drawKnife3.ogg"], 0.6, 0, 120),
    # Coffres, portes, grilles
    "coffre": ([S100 + "wooded_box_open.ogg", K_RPG + "creak1.ogg", K_RPG + "creak2.ogg"], 1.6, 0, 80),
    "porte_ouvre": ([K_RPG + "doorOpen_1.ogg", K_RPG + "doorOpen_2.ogg"], 1.5, 0, 60),
    "porte_ferme": ([K_RPG + "doorClose_1.ogg", K_RPG + "doorClose_2.ogg", K_RPG + "doorClose_3.ogg"], 1.0, 0, 60),
    "grille": ([RPG + "chain_01.ogg", RPG + "chain_02.ogg", RPG + "chain_03.ogg"], 2.5, -4, 40),
    "pierre_glisse": ([BFH + "bfh1_rock_falling_01.ogg", BFH + "bfh1_rock_falling_02.ogg"], 2.5, -6, 30),
    "serrure": ([RPG + "lock_01.ogg", RPG + "lock_02.ogg", RPG + "lock_03.ogg"], 1.0, 0, 100),
    # Outils
    "hache": ([K_RPG + "chop.ogg", WM + "wood_hit_01.ogg", WM + "wood_hit_02.ogg", WM + "wood_hit_03.ogg"], 0.6, 0, 60),
    "arbre_tombe": ([WM + "wood_cracking_01.ogg", WM + "wood_falling_01.ogg", WM + "wood_falling_02.ogg"], 2.5, -3, 40),
    "pelle": ([MUD + "mud_01.ogg", MUD + "mud_02.ogg", MUD + "mud_03.ogg", MUD + "mud_04.ogg"], 0.7, -2, 60),
    # Pêche, bateau, eau
    "lancer": ([WOOSH + "Whistle 1.wav", WOOSH + "Whistle 2.wav", WOOSH + "Whistle 3.wav"], 0.8, 0, 200),
    "plouf": ([SPL + "splash_05.ogg", SPL + "splash_06.ogg", SPL + "splash_07.ogg"], 1.0, 3, 120),
    "gros_plouf": ([SPL + "splash_10.ogg", SPL + "splash_11.ogg", SPL + "splash_12.ogg"], 1.5, 0, 60),
    "moulinet": ([WM + "metal_spring_01.ogg", WM + "metal_spring_02.ogg"], 0.6, 4, 200),
    "ferrage": ([K_RPG + "metalClick.ogg", K_RPG + "metalLatch.ogg"], 0.5, 0, 150),
    "rame": ([SPL + "splash_08.ogg", SPL + "splash_09.ogg", SPL + "splash_13.ogg"], 0.9, -4, 80),
    # Interface
    "ui_ouvrir": (rng(K_UI + "open_", 1, 4), 0.6, 0, 100),
    "ui_fermer": (rng(K_UI + "close_", 1, 4), 0.6, 0, 100),
    "ui_choix": (rng(K_UI + "select_", 1, 4), 0.4, 0, 100),
    "ui_clic": (rng(K_UI + "click_", 1, 4), 0.3, 0, 100),
    "ui_dialogue": (rng(K_UI + "pluck_", 1, 2), 0.5, 0, 100),
    "ui_erreur": (rng(K_UI + "error_", 1, 3), 0.6, 0, 100),
    "ui_quete": (rng(K_UI + "confirmation_", 1, 4), 1.2, 0, 100),
}


def read_mono(path: Path) -> np.ndarray:
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(SR), tmp.name], check=True)
        _, d = wavfile.read(tmp.name)
    return d.astype(np.float64) / 32768.0


def process(x: np.ndarray, max_s: float, semitones: int, hp_hz: float) -> np.ndarray:
    # Silence de tête retiré (seuil relatif)
    peak = np.max(np.abs(x)) + 1e-9
    idx = np.argmax(np.abs(x) > peak * 0.03)
    x = x[max(idx - int(0.004 * SR), 0):]
    if semitones != 0:
        ratio = 2.0 ** (semitones / 12.0)
        x = signal.resample(x, max(int(len(x) / ratio), 16))
    x = x[: int(max_s * SR)]
    fade = min(int(0.06 * SR), len(x) // 3)
    x[-fade:] *= np.linspace(1.0, 0.0, fade)
    sos = signal.butter(2, hp_hz, btype="highpass", fs=SR, output="sos")
    x = signal.sosfilt(sos, x)
    return x / (np.max(np.abs(x)) + 1e-9) * 0.89


def save(name: str, x: np.ndarray) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.ogg"
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wavfile.write(tmp.name, SR, (x * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "4", str(path)], check=True)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is None or not lib.is_dir():
        print("Donner le chemin du dépôt CC0-Public-Domain-Sounds", file=sys.stderr)
        return 1
    total = 0
    for name, (files, max_s, semi, hp_hz) in CATALOGUE.items():
        k = 0
        for f in files:
            src = lib / f
            if not src.is_file():
                print(f"  ! absent : {f}")
                continue
            k += 1
            save(f"{name}_{k}", process(read_mono(src), max_s, semi, hp_hz))
        total += k
        print(f"{name}: {k}")
    print(f"{total} bruitages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
