#!/usr/bin/env python3
"""V181 : le grand contrôle des bugs visuels, les personnages dehors (voir audit_dehors.gd).

    python3 tests/outils/audit_dehors.py                   tous les habitants, à 14 h
    python3 tests/outils/audit_dehors.py --de 0 --a 100    seulement les habitants 0 à 99 (dans l'ordre alphabétique)
    python3 tests/outils/audit_dehors.py --heures 9,19     à 9 h puis à 19 h
    python3 tests/outils/audit_dehors.py --ids "Clovis Meunier,Isidore"   seulement ceux-là
    python3 tests/outils/audit_dehors.py --lieux            chaque lieu où l'on s'assied (assis, lire, la guitare) de
        l'emploi du temps des habitants : on y envoie l'habitant, puis on regarde
    python3 tests/outils/audit_dehors.py --assises          les lieux tels qu'ils sont écrits (sans les corrections),
        puis la table des corrections : pcvr/scripts/pnj/assises_table_v181.gd

Le journal complet : tests/sorties/audit_dehors.log ; le relevé (un bilan, puis une ligne par cas) :
tests/sorties/audit_dehors.txt.
"""
import argparse
import collections
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import lancer  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--de", type=int, default=0)
ap.add_argument("--a", type=int, default=99999)
ap.add_argument("--heures", default="14")
ap.add_argument("--ids", default="")
ap.add_argument("--delai", type=int, default=7000)
ap.add_argument("--sortie", default="audit_dehors")
ap.add_argument("--lieux", action="store_true")
ap.add_argument("--assises", action="store_true")
ap.add_argument("--debug", action="store_true")
ap.add_argument("--affiner", action="store_true")
ap.add_argument("--radar", default="")
ap.add_argument("--dossier", default="")
args = ap.parse_args()

if args.radar:
    # les « radars » : sans écran (comme les séries), une image faite de rayons (voir audit_dehors.gd)
    import glob
    from PIL import Image, ImageDraw
    lancer.synchroniser()
    dossier = os.path.abspath(args.dossier)
    os.makedirs(dossier, exist_ok=True)
    for x in glob.glob(os.path.join(dossier, "*.png")):
        os.remove(x)
    with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump({"radar": json.load(open(args.radar, encoding="utf-8")), "dossier": dossier, "brut": args.assises}, f)
    main = open(lancer.MAIN_SRC, encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(ICI, "audit_dehors.gd"), encoding="utf-8").read()
    rc = lancer.godot(main, os.path.join(lancer.SORTIES, args.sortie + "_radar.log"), args.delai)
    os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))
    files = sorted(glob.glob(os.path.join(dossier, "*_0.png")))
    for page in range(0, len(files), 8):
        chunk = files[page:page + 8]
        w, h = Image.open(chunk[0]).size
        sheet = Image.new("RGB", (w * 3 * 2 + 8, (h + 4) * 4), (255, 255, 255))
        for j, f0 in enumerate(chunk):
            for v in range(3):
                fv = f0[:-6] + "_%d.png" % v
                if os.path.exists(fv):
                    sheet.paste(Image.open(fv).convert("RGB"), ((j % 2) * (w * 3 + 8) + v * w, (j // 2) * (h + 4)))
            ImageDraw.Draw(sheet).text(((j % 2) * (w * 3 + 8) + 4, (j // 2) * (h + 4) + 2), os.path.basename(f0)[:-6], fill=(0, 0, 0))
        sheet.save(os.path.join(dossier, "planche_%02d.png" % (page // 8)))
    print("radars : code %d, %d -> %s" % (rc, len(files), dossier))
    sys.exit(rc)

lancer.synchroniser()
params = {"de": args.de, "a": args.a, "heures": [float(h) for h in args.heures.split(",") if h],
          "ids": [x for x in args.ids.split(",") if x], "lieux": args.lieux or args.assises or args.affiner,
          "sans_assises": args.assises, "debug": args.debug, "affiner": args.affiner}
with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
    json.dump(params, f)
os.makedirs(lancer.SORTIES, exist_ok=True)
log = os.path.join(lancer.SORTIES, args.sortie + ".log")
main = open(lancer.MAIN_SRC, encoding="utf-8").read()
main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
main += "\n\n" + open(os.path.join(ICI, "audit_dehors.gd"), encoding="utf-8").read()
rc = lancer.godot(main, log, args.delai)
os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))

lignes = open(log, encoding="utf-8", errors="replace").read().splitlines()
cas = [x.split("\t") for x in lignes if x.startswith("AUDIT\t")]
pnj = [x for x in lignes if x.startswith("AUDIT_PNJ\t")]
erreurs = [x for x in lignes if "SCRIPT ERROR" in x or "Parse Error" in x]
fin = [x for x in lignes if x.startswith("AUDIT_FIN") or x.startswith("SERIE_FINIE")]
out = os.path.join(lancer.SORTIES, args.sortie + ".txt")
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(fin) + "\n")
    for e in erreurs[:20]:
        f.write("ERREUR " + e + "\n")
    bilan = collections.Counter()
    for c in cas:
        # i nom heure état anim morceau quoi libre r0 qui pos
        bilan[(c[6], c[7], c[10].split("|")[0].split("<")[0] if len(c) > 10 else "")] += 1
    f.write("\n== par morceau, sorte, ce qui est touché\n")
    for k, n in bilan.most_common():
        f.write("%5d  %s\n" % (n, " / ".join(k)))
    f.write("\n== les cas\n")
    for c in cas:
        f.write("\t".join(c[1:]) + "\n")
if args.assises or args.affiner:
    # la table des corrections (pcvr/scripts/pnj/assises_table_v181.gd), d'après les lignes AUDIT_ASSISE ;
    # --affiner : les lieux encore mal assis, les corrections en place (on ajoute le nouveau décalage)
    import re
    dst0 = os.path.join(lancer.REPO, "pcvr", "scripts", "pnj", "assises_table_v181.gd")
    avant = {}
    if args.affiner:
        for m in re.finditer(r'"([^"]+)": \["(\w+)", ([^\]]*)\]', open(dst0, encoding="utf-8").read()):
            avant[m.group(1)] = [m.group(2)] + [float(v) for v in m.group(3).split(",")]
    table = {}
    for x in lignes:
        if x.startswith("AUDIT_ASSISE\t"):
            c = x.split("\t")
            if c[1] in table:
                continue
            e = [c[2]] + [float(v) for v in c[3].split(",")]
            if c[2] == "tabouret":
                e += [float(v) for v in c[4].split(",")] + [float(c[5])]
            if c[1] in avant:
                v = avant[c[1]]
                e[1:4] = [e[1] + v[1], e[2] + v[2], e[3] + v[3]]
                if v[0] == "tabouret" and e[0] != "tabouret":
                    e = ["tabouret"] + e[1:4] + v[4:8]
            table[c[1]] = e
    if args.affiner:
        nouveaux = set(table)
        for k, v in avant.items():
            if k not in table:
                table[k] = v
        print("affiner : %d lieux repris %s" % (len(nouveaux), sorted(nouveaux)))
    dst = dst0
    with open(dst, "w", encoding="utf-8") as f:
        f.write("extends RefCounted\n")
        f.write("## V181 : écrit par tests/outils/audit_dehors.py --assises (ne pas modifier à la main : refaire l'audit des\n")
        f.write("## lieux). \"<script de la ville>:<lieu>\" : [sorte, dx, dy, dz (m, dans le monde)] ; pour un tabouret, en\n")
        f.write("## plus : x, y, z (le sol sous le bassin) et la hauteur du siège. Voir assises_v181.gd.\n")
        f.write("const TABLE := {\n")
        for k in sorted(table):
            e = table[k]
            f.write('\t"%s": ["%s", %s],\n' % (k, e[0], ", ".join("%.3f" % v for v in e[1:])))
        f.write("}\n")
    sortes = collections.Counter(e[0] for e in table.values())
    print("assises : %d lieux à corriger %s -> %s" % (len(table), dict(sortes), dst))
print("%d habitants, %d cas, code %d -> %s" % (len(pnj), len(cas), rc, out))
for x in fin + erreurs[:5]:
    print(x)
