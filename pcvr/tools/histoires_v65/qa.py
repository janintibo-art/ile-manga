#!/usr/bin/env python3
"""Contrôles de cohérence sur les fiches V65 fusionnées."""
import json, glob, os, re, unicodedata, collections

ICI = os.path.dirname(os.path.abspath(__file__))
ROSTER = json.load(open(os.path.join(ICI, "roster.json")))
D = {}
for fn in glob.glob(os.path.join(ICI, "..", "..", "data", "histoires_v65", "*.json")):
    D.update(json.load(open(fn)))


def norm(s):
    s = unicodedata.normalize("NFD", s.lower())
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


# 1. le nom donné à B ressemble au prénom de B
for a, f in D.items():
    for b, l in f.get("liens", {}).items():
        if b not in D:
            continue
        toks = set(re.findall(r"[a-z]+", norm(D[b]["prenom"] + " " + ROSTER[b]["nom"])))
        mine = set(re.findall(r"[a-z]+", norm(l["nom"])))
        if not (toks & mine):
            print(f"NOM {a}->{b} : « {l['nom']} » (prénom « {D[b]['prenom']} », {ROSTER[b]['nom']})")
# 2. prénom cohérent avec le nom du roster
for k, f in D.items():
    if not set(re.findall(r"[a-z]+", norm(f["prenom"]))) & set(re.findall(r"[a-z]+", norm(ROSTER[k]["nom"]))):
        print(f"PRENOM {k} : « {f['prenom']} » / {ROSTER[k]['nom']}")
# 3. textes en double
seen = collections.defaultdict(list)
for k, f in D.items():
    for c in f["histoire"]:
        seen[c["t"]].append(k)
    for b, l in f["liens"].items():
        for a in l["anecdotes"]:
            seen[a].append(k + "->" + b)
for t, w in seen.items():
    if len(w) > 1:
        print("DOUBLE", w, t[:60])
# 4. statistiques
nl = sum(len(f["liens"]) for f in D.values())
na = sum(len(l["anecdotes"]) for f in D.values() for l in f["liens"].values())
nb = sum(len(l["bavardage"]) for f in D.values() for l in f["liens"].values())
mots = sum(len(re.findall(r"\w+", json.dumps(f, ensure_ascii=False))) for f in D.values())
neg = sum(1 for f in D.values() for l in f["liens"].values() if l["sentiment"] < -0.2)
print(f"{len(D)} fiches, {nl} liens ({neg} négatifs), {na} anecdotes, {nb} répliques de bavardage, ~{mots} mots")
# 5. personnes que personne ne connaît
known = collections.Counter(b for f in D.values() for b in f["liens"])
print("inconnus de tous :", [k for k in D if known[k] == 0])
