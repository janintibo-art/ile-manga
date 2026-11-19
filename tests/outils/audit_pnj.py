#!/usr/bin/env python3
"""V178 : le grand contrôle des bugs visuels, les personnages des maisons (voir audit_pnj.gd).

    python3 tests/outils/audit_pnj.py                     toutes les maisons, le jour et la nuit
    python3 tests/outils/audit_pnj.py --de 0 --a 200      seulement les portes 0 à 199
    python3 tests/outils/audit_pnj.py --heures 14         seulement le jour
    python3 tests/outils/audit_pnj.py --ids m81_1_2,m81_3_4      seulement ces maisons
    python3 tests/outils/audit_pnj.py --filtre b174       les maisons dont le style, l'histoire ou le métier contient « b174 »
    python3 tests/outils/audit_pnj.py --photos liste.json --dossier DOSSIER [--sortie audit_pnj]
        des photos des cas relevés : liste.json = [[n° de porte, heure, [x, y, z] dans la pièce, nom], …] ;
        la maison est refaite telle que l'audit l'a construite (journal --sortie), par rendu_maisons.sh
        (mode « audit ») ; deux vues de chaque endroit, et des planches (DOSSIER/planche_N.jpg)

Le journal complet : tests/sorties/audit_pnj.log ; le relevé (une ligne par cas, puis un bilan par
histoire) : tests/sorties/audit_pnj.txt.
"""
import argparse
import collections
import json
import os
import subprocess
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import lancer  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--de", type=int, default=0)
ap.add_argument("--a", type=int, default=99999)
ap.add_argument("--heures", default="14,22")
ap.add_argument("--ids", default="")
ap.add_argument("--filtre", default="")
ap.add_argument("--delai", type=int, default=7000)
ap.add_argument("--sortie", default="audit_pnj")
ap.add_argument("--photos", default="")
ap.add_argument("--dossier", default="")
args = ap.parse_args()

if args.photos:
    # les photos : la maison telle que l'audit l'a construite (sa ligne AUDIT_MAISON dans le journal
    # --sortie), refaite par tests/outils/rendu_maisons.sh (mode « audit », sans le reste du monde)
    journal = open(os.path.join(lancer.SORTIES, args.sortie + ".log"), encoding="utf-8", errors="replace").read()
    portes = {}
    for x in journal.splitlines():
        if x.startswith("AUDIT_MAISON\t"):
            c = x.split("\t")
            portes[(int(c[1]), float(c[3]))] = c[5]
    liste = []
    for ph in json.load(open(args.photos, encoding="utf-8")):
        cle = (int(ph[0]), float(ph[1]))
        if cle not in portes:
            print("pas dans le journal :", ph)
            continue
        liste.append([portes[cle], ph[1], ph[2], ph[3]])
    fl = os.path.join(lancer.SORTIES, "audit_photos.json")
    json.dump(liste, open(fl, "w", encoding="utf-8"))
    rc = subprocess.call(["bash", os.path.join(ICI, "rendu_maisons.sh"), os.path.abspath(args.dossier), "audit", fl])
    sys.exit(rc)

lancer.synchroniser()
params = {"de": args.de, "a": args.a, "heures": [float(h) for h in args.heures.split(",") if h],
          "ids": [x for x in args.ids.split(",") if x], "filtre": args.filtre}
with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
    json.dump(params, f)
os.makedirs(lancer.SORTIES, exist_ok=True)
log = os.path.join(lancer.SORTIES, args.sortie + ".log")
main = open(lancer.MAIN_SRC, encoding="utf-8").read()
main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
main += "\n\n" + open(os.path.join(ICI, "audit_pnj.gd"), encoding="utf-8").read()
rc = lancer.godot(main, log, args.delai)
os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))

lignes = open(log, encoding="utf-8", errors="replace").read().splitlines()
cas = [x.split("\t") for x in lignes if x.startswith("AUDIT\t")]
maisons = [x for x in lignes if x.startswith("AUDIT_MAISON\t")]
erreurs = [x for x in lignes if "SCRIPT ERROR" in x or "Parse Error" in x]
fin = [x for x in lignes if x.startswith("AUDIT_FIN") or x.startswith("SERIE_FINIE")]
out = os.path.join(lancer.SORTIES, args.sortie + ".txt")
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(fin) + "\n")
    for e in erreurs[:20]:
        f.write("ERREUR " + e + "\n")
    bilan = collections.Counter()
    for c in cas:
        # i id style histoire metier heure nom pose morceau quoi libre r0 qui pos
        bilan[(c[3], c[4] if len(c) > 4 else "", c[8], c[9].split(":")[0])] += 1
    f.write("\n== par histoire, métier, morceau, sorte\n")
    for k, n in bilan.most_common():
        f.write("%5d  %s\n" % (n, " / ".join(k)))
    f.write("\n== les cas\n")
    for c in cas:
        f.write("\t".join(c[1:]) + "\n")
print("%d maisons, %d cas, code %d -> %s" % (len(maisons), len(cas), rc, out))
for x in fin + erreurs[:5]:
    print(x)
