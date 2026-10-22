#!/usr/bin/env python3
"""Fusionne out/*.json en pcvr/data/histoires_v65/<groupe>.json (une fiche par habitant)."""
import json, glob, os, sys, collections

ICI = os.path.dirname(os.path.abspath(__file__))
ROSTER = json.load(open(os.path.join(ICI, "roster.json")))
DEST = os.path.join(ICI, "..", "..", "data", "histoires_v65")
os.makedirs(DEST, exist_ok=True)

all_ = {}
for fn in sorted(glob.glob(os.path.join(ICI, "out", "*.json"))):
    d = json.load(open(fn))
    for k, v in d.items():
        if k in all_:
            print("DOUBLON", k, fn)
        all_[k] = v

par = collections.defaultdict(dict)
for k, v in all_.items():
    par[ROSTER[k]["groupe"]][k] = v
manque = [k for k in ROSTER if k not in all_]
print("fiches :", len(all_), "/", len(ROSTER), "manquantes :", manque)
for g, d in par.items():
    ordered = {k: d[k] for k in ROSTER if k in d}
    with open(os.path.join(DEST, g + ".json"), "w") as f:
        json.dump(ordered, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(g, len(ordered), os.path.getsize(os.path.join(DEST, g + ".json")))
# réciprocité entre groupes
for a, f in all_.items():
    for b in f.get("liens", {}):
        if b in all_ and a not in all_[b].get("liens", {}):
            print("SENS UNIQUE", ROSTER[a]["groupe"], a, "->", ROSTER[b]["groupe"], b)
