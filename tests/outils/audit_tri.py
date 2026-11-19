#!/usr/bin/env python3
"""V178 : trie les cas relevés par audit_pnj.py (le journal tests/sorties/audit_pnj.log) : ne garde que ce
qui se voit (seuils ci-dessous), les regroupe par maison et par personnage, et prépare la liste des photos.

    python3 tests/outils/audit_tri.py [--sortie audit_pnj] [--photos liste.json] [--max 40]

Ce qui se voit (libre : la distance entre le cœur du morceau et le décor le plus proche, en mètres ; à
l'échelle du personnage) :
  tête < 0,06 (le crâne fait ~0,10 : le décor entre de 4 cm dans la tête)
  cou < 0,03 ; buste, ventre < 0,055 ; bassin < 0,012 (assis, l'os est bas : le siège le touche presque)
  genoux < 0,02 ; mains < 0,004 (le poignet dans le meuble)
  pieds : plus de 0,08 au-dessus du sol (debout), ou plus de 0,07 dedans
  deux personnages : leurs cœurs se touchent
"""
import argparse
import collections
import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIES = os.path.join(os.path.dirname(ICI), "sorties")
SEUILS = {"tête": 0.06, "cou": 0.03, "buste": 0.055, "ventre": 0.055, "bassin": 0.012,
          "genou_g": 0.02, "genou_d": 0.02, "main_g": 0.004, "main_d": 0.004}


def lire(sortie):
    cas = []
    for x in open(os.path.join(SORTIES, sortie + ".log"), encoding="utf-8", errors="replace"):
        if not x.startswith("AUDIT\t"):
            continue
        c = x.rstrip("\n").split("\t")
        d = dict(zip(["i", "id", "style", "histoire", "metier", "heure", "nom", "pose", "morceau", "quoi",
                      "libre", "r0", "qui", "pos"], c[1:]))
        d["i"] = int(d["i"])
        d["heure"] = float(d["heure"])
        d["libre"] = float(d["libre"])
        d["r0"] = float(d["r0"])
        d["pos"] = [float(v) for v in d["pos"].split(",")]
        cas.append(d)
    return cas


ASSIS = ["assis", "rire_assis", "tricot", "lire", "manger", "guitare", "dormir_assis"]


def visible(d):
    q = d["quoi"]
    m = d["morceau"]
    pose = d["pose"]
    meuble = d["qui"].startswith("Ville_") or d["qui"].startswith("Collisions")
    # ce que les photos ont montré (V178) : assis, le bassin touche toujours un peu le siège, le dos le
    # dossier, les genoux le dessous de la table (les vêtements le cachent) ; couché, la tête est sur
    # l'oreiller ; en faisant des pompes, les genoux frôlent le sol ; les mains : à voir plus tard
    if m in ("main_g", "main_d"):
        return False
    if pose in ASSIS and meuble and q == "vu" and m in ("bassin", "genou_g", "genou_d"):
        return False
    if pose in ASSIS and meuble and q == "vu" and m in ("buste", "ventre") and d["libre"] > 0.02:
        return False
    if pose in ("dormir", "allonge") and m in ("tête", "cou", "buste") and d["libre"] > 0.02:
        return False
    if pose == "pompes" and m in ("genou_g", "genou_d"):
        return False
    if q == "solide" and m in ("tête", "cou"):
        # une boîte de collision (grossière) : seulement si le décor qu'on voit est touché aussi
        return False
    if q == "en_l_air":
        return d["libre"] > 0.08
    if q == "dans_le_sol":
        return d["libre"] < -0.07
    if q.startswith("personne:"):
        return True
    if "transparent" in d["qui"]:
        return False
    s = SEUILS.get(d["morceau"], 0.0)
    # à l'échelle du personnage (r0 / rayon d'origine)
    base = {"tête": 0.075, "cou": 0.045, "buste": 0.09, "ventre": 0.085, "bassin": 0.075, "genou_g": 0.05,
            "genou_d": 0.05, "main_g": 0.03, "main_d": 0.03}.get(d["morceau"], 1.0)
    return d["libre"] < s * d["r0"] / base


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sortie", default="audit_pnj")
    ap.add_argument("--photos", default="")
    ap.add_argument("--max", type=int, default=40)
    ap.add_argument("--quoi", default="")
    a = ap.parse_args()
    cas = [d for d in lire(a.sortie) if visible(d)]
    if a.quoi:
        cas = [d for d in cas if any(q in (d["morceau"] + " " + d["quoi"] + " " + d["histoire"] + " " + d["metier"] + " " + d["style"]) for q in a.quoi.split(","))]
    # un cas par personnage (le pire morceau), par maison et par heure
    pire = {}
    for d in cas:
        k = (d["i"], d["heure"], d["nom"])
        pire.setdefault(k, []).append(d)
    groupes = collections.defaultdict(list)
    for k, ds in pire.items():
        d0 = ds[0]
        groupes[(d0["style"], d0["histoire"], d0["metier"])].append(ds)
    print("%d cas visibles, %d personnages, %d sortes de maisons" % (len(cas), len(pire), len(groupes)))
    photos = []
    for g, lst in sorted(groupes.items(), key=lambda x: -len(x[1])):
        morceaux = collections.Counter(d["morceau"] + ("/" + d["quoi"].split(":")[0] if d["quoi"] not in ("vu",) else "") for ds in lst for d in ds)
        print("\n%3d  %s  %s" % (len(lst), " / ".join(g), ", ".join("%s %d" % kv for kv in morceaux.most_common(6))))
        for ds in lst[:4]:
            d = ds[0]
            print("      %4d %s %4.1fh %-22s %-12s %s" % (d["i"], d["id"], d["heure"], d["nom"][:22], d["pose"],
                  "; ".join("%s %s %.3f %s" % (x["morceau"], x["quoi"][:18], x["libre"], x["qui"][:40]) for x in ds[:4])))
        d = lst[0][0]
        tete = [x for x in lst[0] if x["morceau"] in ("tête", "buste", "ventre", "cou")]
        c = (tete or lst[0])[0]["pos"]
        photos.append([d["i"], d["heure"], c, ("%s_%s_%s" % (g[1], g[2] or g[0], d["nom"])).replace(" ", "_").replace("'", "")[:48]])
    if a.photos:
        json.dump(photos[:a.max], open(a.photos, "w", encoding="utf-8"), ensure_ascii=False)
        print("\n%d photos -> %s" % (min(len(photos), a.max), a.photos))


main()
