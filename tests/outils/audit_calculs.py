#!/usr/bin/env python3
"""V218 : qui coûte au processeur ? (voir audit_calculs.gd). À chaque endroit : le temps d'une image au
rythme du casque (un pas de calculs + un pas de physique), le relevé des fonctions du jeu, ce que coûtent
les objets du moteur qui travaillent tout seuls (particules, animations, sons), et le plancher.

    python3 tests/outils/audit_calculs.py
    python3 tests/outils/audit_calculs.py --lieux "depart:238,2,1484;village:0,2,0" --sans-neo
    python3 tests/outils/audit_calculs.py --journal tests/sorties/audit_calculs.log     relire un journal

Le journal : tests/sorties/audit_calculs.log ; le relevé : tests/sorties/audit_calculs.txt.
Les temps sont ceux de la machine d'essai (sans image) : c'est le classement qui compte.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import lancer  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--lieux", default="depart:238,2,1484;village:0,2,0;foraine:1750,6,300")
ap.add_argument("--sans-neo", action="store_true")
ap.add_argument("--attente", type=float, default=12.0)
ap.add_argument("--images", type=int, default=90, help="images par mesure")
ap.add_argument("--bloc", type=int, default=8, help="images de suite éveillé, puis endormi")
ap.add_argument("--cycles", type=int, default=30, help="allers-retours éveillé/endormi par famille")
ap.add_argument("--chaque-script", action="store_true", help="essayer aussi chaque famille de scripts nombreuse, une par une")
ap.add_argument("--profil", type=int, default=300, help="images du relevé des fonctions")
ap.add_argument("--pas", type=int, default=72, help="pas de physique par seconde (le casque : 72)")
ap.add_argument("--top", type=int, default=40)
ap.add_argument("--delai", type=int, default=3000)
ap.add_argument("--sortie", default="audit_calculs")
ap.add_argument("--journal", default="")
args = ap.parse_args()


def godot_debogueur(main_text, log_path, timeout_s):
    """Comme lancer.godot, avec le débogueur local (-d) : c'est lui qui donne le relevé des fonctions."""
    with open(lancer.MAIN_DST, "w", encoding="utf-8") as f:
        f.write(main_text)
    cmd = (f"ulimit -f 800000; flock {lancer.VERROU} timeout {timeout_s} {lancer.GODOT} --headless -d "
           f"--path pcvr > {log_path} 2>&1 < /dev/null")
    try:
        rc = subprocess.call(["bash", "-c", cmd], cwd=lancer.COPIE)
    finally:
        shutil.copy(lancer.MAIN_SRC, lancer.MAIN_DST)
    return rc


lieux = []
for bout in [b for b in args.lieux.split(";") if b]:
    nom, xyz = bout.split(":")
    lieux.append([nom] + [float(v) for v in xyz.split(",")])
params = {"lieux": lieux, "neo": not args.sans_neo, "attente": args.attente, "images": args.images,
          "bloc": args.bloc, "cycles": args.cycles, "chaque_script": args.chaque_script, "profil": args.profil, "pas": args.pas}
if args.journal:
    journal, rc = args.journal, 0
else:
    main = open(lancer.MAIN_SRC, encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(ICI, "audit_calculs.gd"), encoding="utf-8").read()
    lancer.synchroniser()
    with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump(params, f)
    journal = os.path.join(lancer.SORTIES, args.sortie + ".log")
    rc = godot_debogueur(main, journal, args.delai)
    os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))

# ------------------------------------------------------------------ lecture du journal
ordre, lieu, fam, sol, profil, releve, rec, veille = [], {}, {}, {}, {}, {}, {}, {}
en_cours, accumule, fonction = None, False, None
RE_TEMPS = re.compile(r"total:\s*([0-9.eE+-]+)/.*self:\s*([0-9.eE+-]+)/.*tcalls:\s*(\d+)")
for ligne in open(journal, encoding="utf-8", errors="replace"):
    ligne = ligne.rstrip("\n")
    c = ligne.split("\t")
    if c[0] == "CAL_LIEU":
        ordre.append(c[1])
        lieu[c[1]] = [float(v) for v in c[2:7]] + [int(c[7]), int(c[8]), float(c[9]) if len(c) > 9 else 0.0, float(c[10]) if len(c) > 10 else 0.0]
        fam[c[1]] = []
    elif c[0] == "CAL_PROFIL_DEBUT":
        en_cours, accumule = c[1], False
        profil[en_cours] = []
    elif c[0] == "CAL_PROFIL_RELEVE":
        releve[c[1]] = (int(c[2]), float(c[3]))
    elif c[0] == "CAL_PROFIL_FIN":
        en_cours, accumule = None, False
    elif c[0] == "CAL_FAM":
        fam[c[1]].append((float(c[4]), float(c[5]), c[2], int(c[3]), float(c[6]) if len(c) > 6 else 0.0))
    elif c[0] == "CAL_REC":
        rec.setdefault(c[1], []).append((c[2], c[3], c[4], int(c[5]), int(c[6]), int(c[7]), float(c[8]), int(c[9])))
    elif c[0] == "CAL_VEILLE":
        veille[c[1]] = [float(v) for v in c[2:6]] + [int(v) for v in c[6:10]]
    elif c[0] == "CAL_SOL":
        sol[c[1]] = [float(v) for v in c[2:]]
    elif en_cours is not None:
        if ligne.startswith("ACCUMULATED"):
            accumule = True
        elif ligne.startswith("FRAME:"):
            accumule = False
        elif accumule:
            m = RE_TEMPS.search(ligne)
            if m and fonction is not None:
                # les fonctions de l'outil lui-même faussent le relevé (elles étaient en route quand il a commencé)
                if "::_ca8_" not in fonction and not fonction.endswith(("::_serie", "::_lancer")):
                    profil[en_cours].append((float(m.group(2)), float(m.group(1)), int(m.group(3)), fonction))
                fonction = None
            elif re.match(r"^\d+:", ligne):
                fonction = ligne.split(":", 1)[1]

L = []
for nom in ordre:
    moy, med, p90, pire, pas, objets, familles, etalon, etalon_jeu = lieu[nom]
    L.append("")
    L.append("=== %s : une image = %.1f ms en moyenne (médiane %.1f, neuf sur dix sous %.1f, la pire %.1f) ; "
             "%.2f pas de physique par image ; %d objets au travail, %d familles ; étalon %.2f ms, étalon du jeu %.2f ms"
             % (nom, moy, med, p90, pire, pas, objets, familles, etalon, etalon_jeu))
    if nom in sol and len(sol[nom]) >= 9:
        v = sol[nom]
        L.append("    en alternance serrée (moyenne, médiane) : tout éveillé %.1f / %.1f ms ; tout endormi sauf le cœur du jeu %.1f / %.1f ; "
                 "les scripts endormis %.1f / %.1f ; le moteur endormi %.1f / %.1f ; étalon %.2f ms" % tuple(v[:9]))
    if nom in veille:
        v = veille[nom]
        L.append("    la veille coupée puis remise, dans la même partie (moyenne / médiane) : sans %.1f / %.1f ms ; avec %.1f / %.1f ms ; "
                 "%d habitants au ralenti, %d jeux de particules arrêtés, %d ralentis, %d décors endormis" % tuple(v))
    if nom in profil and nom in releve and profil[nom]:
        n, duree = releve[nom]
        total = sum(p[0] for p in profil[nom])
        L.append("    relevé des fonctions sur %d images (%.1f ms par image pendant le relevé) : %.1f ms par image dans les "
                 "fonctions du jeu" % (n, duree / n, total * 1000.0 / n))
        par_fichier = {}
        for soi, tout, appels, f in profil[nom]:
            fichier = f.split("::")[0].split("/")[-1]
            par_fichier[fichier] = par_fichier.get(fichier, 0.0) + soi
        L.append("    -- par fichier (ms par image)")
        for fichier, soi in sorted(par_fichier.items(), key=lambda kv: -kv[1])[:args.top]:
            L.append("       %7.3f   %s" % (soi * 1000.0 / n, fichier))
        L.append("    -- par fonction (ms par image en propre ; avec ce qu'elle appelle ; appels par image)")
        for soi, tout, appels, f in sorted(profil[nom], reverse=True)[:args.top]:
            morceaux = f.split("::")
            court = morceaux[0].split("/")[-1] + " " + "::".join(morceaux[1:])
            L.append("       %7.3f   %7.3f   %8.1f   %s" % (soi * 1000.0 / n, tout * 1000.0 / n, appels / n, court))
        L.append("    -- par fonction, avec ce qu'elle appelle (ms par image avec ; en propre ; appels par image)")
        for soi, tout, appels, f in sorted(profil[nom], key=lambda p: -p[1])[:args.top]:
            morceaux = f.split("::")
            court = morceaux[0].split("/")[-1] + " " + "::".join(morceaux[1:])
            L.append("       %7.3f   %7.3f   %8.1f   %s" % (tout * 1000.0 / n, soi * 1000.0 / n, appels / n, court))
    if fam.get(nom):
        L.append("    -- ce qu'on gagne en endormant une famille (ms par image : moyenne, ± incertitude, médiane) ; le témoin donne le bruit")
        for gain, gain_med, f, nb, ecart in sorted(fam[nom], reverse=True):
            L.append("       %7.2f ± %4.2f   %7.2f   %-40s %5d objet(s)" % (gain, ecart, gain_med, f, nb))
    if rec.get(nom):
        L.append("    -- les objets du moteur au travail : sorte, à qui, distance du joueur, combien (visibles ; particules ; portée d'affichage ; en émission)")
        ordre_tr = {"<60": 0, "<150": 1, "<400": 2, "<1000": 3, ">1000": 4, "?": 5}
        for f, maitre, tranche, nb, vis, part, portee, emet in sorted(rec[nom], key=lambda r: (r[0], -r[3])):
            if nb >= 2 or f.endswith("AnimationPlayer"):
                L.append("       %-28s %-34s %-6s %4d  (%4d visibles ; %6d particules ; portée %5.0f ; %4d en émission)"
                         % (f.replace("(moteur) ", ""), maitre[:34], tranche, nb, vis, part, portee, emet))
sortie = os.path.join(lancer.SORTIES, args.sortie + ".txt")
with open(sortie, "w", encoding="utf-8") as f:
    f.write("\n".join(L) + "\n")
print("\n".join(L))
print("code", rc, "->", sortie)
