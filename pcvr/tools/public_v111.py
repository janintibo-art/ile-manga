#!/usr/bin/env python3
# V111 : la table des deux versions du jeu (Tout public / Public averti).
# Lit tools/public_v111/table.json : [français, fr_famille, en_famille, es_famille, en_averti, es_averti]
# (cinq chaînes vides : le texte ne parle pas d'alcool) et data/langues/en.json / es.json, et écrit
# data/langues/public.json :
#   « tout »   : fr / en / es -> la version familiale (seulement ce qui change) ;
#   « averti » : en / es -> la vraie boisson (seulement là où la traduction l'avait adoucie) ;
#   « motifs_fr » : les motifs à trous, recopiés tels quels (en français Tout public, le texte d'un
#                   trou — le nom d'une boisson — est remplacé lui aussi).
import json, os
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(here)
rows = json.load(open(os.path.join(here, "public_v111", "table.json"), encoding="utf-8"))
en = json.load(open(os.path.join(root, "data", "langues", "en.json"), encoding="utf-8"))
es = json.load(open(os.path.join(root, "data", "langues", "es.json"), encoding="utf-8"))
out = {"tout": {"fr": {}, "en": {}, "es": {}}, "averti": {"en": {}, "es": {}}, "motifs_fr": {}}
for r in rows:
    fr, ff, ef, sf, ea, sa = r
    if ff == "" and ef == "":
        continue
    if ff != "" and ff != fr:
        out["tout"]["fr"][fr] = ff
    if ef != "" and ef != en["textes"].get(fr, ""):
        out["tout"]["en"][fr] = ef
    if sf != "" and sf != es["textes"].get(fr, ""):
        out["tout"]["es"][fr] = sf
    if ea != "" and ea != en["textes"].get(fr, ""):
        out["averti"]["en"][fr] = ea
    if sa != "" and sa != es["textes"].get(fr, ""):
        out["averti"]["es"][fr] = sa
for k in en["motifs"]:
    out["motifs_fr"][k] = k
with open(os.path.join(root, "data", "langues", "public.json"), "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1, sort_keys=True)
print("public :", {m: {l: len(v) for l, v in out[m].items()} for m in ("tout", "averti")}, "motifs", len(out["motifs_fr"]))
