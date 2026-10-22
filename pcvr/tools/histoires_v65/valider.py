#!/usr/bin/env python3
"""V65 : vérifie un fichier d'histoires (fiches finales) ou une bible (plan).

  python3 valider.py fichier.json            -> fiches finales
  python3 valider.py --bible fichier.json    -> bible (plan)
  python3 valider.py --ids a,b,c fichier.json -> vérifie aussi que ces fiches sont toutes là

Sortie : ERREUR (à corriger obligatoirement) et ATTENTION (à regarder).
"""
import json, re, sys, os

ICI = os.path.dirname(os.path.abspath(__file__))
ROSTER = json.load(open(os.path.join(ICI, "roster.json")))
PASSANT = re.compile(r"^(elfe|nain|atlante)_\d$")
PLACEHOLDER = re.compile(r"\{[^}]*\}")
ID = re.compile(r"^[a-z0-9_]+$")

errs, warns = [], []


def E(m):
    errs.append(m)


def W(m):
    warns.append(m)


def txt(where, s, lo, hi, allow_nl=False):
    if not isinstance(s, str):
        E(f"{where} : doit être un texte")
        return
    n = len(s)
    if n < lo or n > hi:
        E(f"{where} : {n} caractères (attendu {lo} à {hi}) : {s[:70]!r}")
    for ph in PLACEHOLDER.findall(s):
        if ph != "{surnom}":
            E(f"{where} : variable interdite {ph} (seule {{surnom}} est permise)")
    if "\n" in s and not allow_nl:
        E(f"{where} : pas de retour à la ligne")
    if '"' in s:
        W(f"{where} : guillemets droits \" — utiliser « » ")
    if "  " in s:
        W(f"{where} : double espace")
    if s.strip() != s:
        E(f"{where} : espace au début ou à la fin")


def check_fiche(id_, f, bible):
    if id_ not in ROSTER:
        E(f"{id_} : identifiant inconnu")
        return
    passant = bool(PASSANT.match(id_))
    for k in f:
        allowed = {"genre", "prenom", "liens", "reve", "question"} | ({"plan"} if bible else {"histoire"})
        if k not in allowed:
            E(f"{id_} : clé inconnue « {k} »")
    if f.get("genre") not in ("f", "m"):
        E(f"{id_}.genre : « f » ou « m »")
    txt(f"{id_}.prenom", f.get("prenom"), 2, 28)
    nch = 3 if passant else 5
    if bible:
        plan = f.get("plan")
        if not isinstance(plan, list) or len(plan) != nch:
            E(f"{id_}.plan : {nch} chapitres attendus")
        else:
            for i, c in enumerate(plan):
                txt(f"{id_}.plan[{i}]", c, 40, 500)
        txt(f"{id_}.reve", f.get("reve"), 20, 300)
        if not passant:
            txt(f"{id_}.question", f.get("question"), 15, 300)
    else:
        h = f.get("histoire")
        if not isinstance(h, list) or len(h) != nch:
            E(f"{id_}.histoire : {nch} chapitres attendus")
        else:
            for i, c in enumerate(h):
                if not isinstance(c, dict) or set(c.keys()) - {"titre", "t"}:
                    E(f"{id_}.histoire[{i}] : {{\"titre\", \"t\"}} attendu")
                    continue
                txt(f"{id_}.histoire[{i}].titre", c.get("titre"), 3, 48)
                txt(f"{id_}.histoire[{i}].t", c.get("t"), 140, 460)
        rv = f.get("reve")
        if not isinstance(rv, list) or not (1 <= len(rv) <= 2):
            E(f"{id_}.reve : liste de 1 ou 2 répliques")
        else:
            for i, s in enumerate(rv):
                txt(f"{id_}.reve[{i}]", s, 40, 300)
        q = f.get("question")
        if passant:
            if q is not None:
                E(f"{id_} : pas de question pour un passant")
        else:
            if not isinstance(q, dict):
                E(f"{id_}.question : objet attendu")
            else:
                if set(q.keys()) - {"texte", "reponses"}:
                    E(f"{id_}.question : clés « texte » et « reponses » seulement")
                txt(f"{id_}.question.texte", q.get("texte"), 20, 220)
                rs = q.get("reponses")
                if not isinstance(rs, list) or len(rs) != 3:
                    E(f"{id_}.question.reponses : 3 réponses")
                else:
                    vals = set()
                    for i, r in enumerate(rs):
                        if not isinstance(r, dict) or set(r.keys()) != {"label", "valeur", "t", "rappel"}:
                            E(f"{id_}.question.reponses[{i}] : clés label, valeur, t, rappel")
                            continue
                        txt(f"{id_}.question.reponses[{i}].label", r["label"], 2, 48)
                        if not isinstance(r["valeur"], str) or not ID.match(r["valeur"]):
                            E(f"{id_}.question.reponses[{i}].valeur : identifiant court (a-z, 0-9, _)")
                        vals.add(r["valeur"])
                        txt(f"{id_}.question.reponses[{i}].t", r["t"], 20, 280)
                        txt(f"{id_}.question.reponses[{i}].rappel", r["rappel"], 15, 170)
                    if len(vals) != 3:
                        E(f"{id_}.question : les 3 valeurs doivent être différentes")
    liens = f.get("liens")
    lo, hi = (2, 4) if passant else (4, 7)
    if not isinstance(liens, dict) or not (lo <= len(liens) <= hi):
        E(f"{id_}.liens : {lo} à {hi} personnes")
        return
    for o, l in liens.items():
        w = f"{id_}.liens.{o}"
        if o == id_:
            E(f"{w} : se connaître soi-même ?")
        if o not in ROSTER:
            E(f"{w} : identifiant inconnu")
        keys = {"qui", "nom", "sentiment"} | ({"fond"} if bible else {"avis", "anecdotes", "bavardage"})
        if not isinstance(l, dict) or set(l.keys()) != keys:
            E(f"{w} : clés attendues {sorted(keys)}")
            continue
        txt(f"{w}.qui", l["qui"], 2, 34)
        if isinstance(l["qui"], str) and l["qui"][:1].isupper():
            W(f"{w}.qui : commence par une majuscule (« {l['qui']} ») — c'est un groupe nominal placé avant le nom, en minuscules")
        txt(f"{w}.nom", l["nom"], 2, 30)
        s = l["sentiment"]
        if not isinstance(s, (int, float)) or not (-1.0 <= s <= 1.0):
            E(f"{w}.sentiment : nombre entre -1 et 1")
        if bible:
            txt(f"{w}.fond", l["fond"], 40, 700)
            continue
        txt(f"{w}.avis", l["avis"], 30, 230)
        an = l["anecdotes"]
        na = (1, 2) if passant else (2, 3)
        if not isinstance(an, list) or not (na[0] <= len(an) <= na[1]):
            E(f"{w}.anecdotes : {na[0]} à {na[1]} anecdotes")
        else:
            for i, a in enumerate(an):
                txt(f"{w}.anecdotes[{i}]", a, 100, 400)
        bv = l["bavardage"]
        if not isinstance(bv, list) or not (2 <= len(bv) <= 4):
            E(f"{w}.bavardage : 2 à 4 répliques")
        else:
            for i, b in enumerate(bv):
                if not isinstance(b, list) or len(b) != 2 or b[0] not in ("a", "b"):
                    E(f"{w}.bavardage[{i}] : [\"a\" ou \"b\", texte]")
                    continue
                txt(f"{w}.bavardage[{i}]", b[1], 6, 95)
                if i == 0 and b[0] != "a":
                    E(f"{w}.bavardage : la première réplique est dite par « a » (le personnage de la fiche)")
                if i > 0 and b[0] == bv[i - 1][0]:
                    W(f"{w}.bavardage[{i}] : deux répliques de suite du même personnage")


def main():
    args = sys.argv[1:]
    bible = "--bible" in args
    ids = None
    if "--ids" in args:
        ids = args[args.index("--ids") + 1].split(",")
    files = [a for a in args if a.endswith(".json")]
    data = {}
    for fn in files:
        try:
            dd = json.load(open(fn))
        except Exception as e:
            print(f"ERREUR {fn} : JSON invalide : {e}")
            sys.exit(1)
        for k, v in dd.items():
            if k in data:
                E(f"{k} : en double")
            data[k] = v
    for k, v in data.items():
        if not isinstance(v, dict):
            E(f"{k} : objet attendu")
            continue
        check_fiche(k, v, bible)
    if ids:
        for i in ids:
            if i not in data:
                E(f"{i} : fiche manquante")
    # réciprocité : si A connaît B (même lot), B devrait connaître A
    for a, f in data.items():
        for b in (f.get("liens") or {}):
            if b in data and a not in (data[b].get("liens") or {}):
                W(f"{a} connaît {b}, mais {b} ne connaît pas {a}")
            elif b in data:
                sa = f["liens"][b].get("sentiment", 0)
                sb = data[b]["liens"][a].get("sentiment", 0)
                if isinstance(sa, (int, float)) and isinstance(sb, (int, float)) and abs(sa - sb) > 1.2:
                    W(f"{a}→{b} ({sa}) et {b}→{a} ({sb}) : sentiments très différents, est-ce voulu ?")
    for w in warns:
        print("ATTENTION", w)
    for e in errs:
        print("ERREUR", e)
    print(f"{len(data)} fiches, {len(errs)} erreurs, {len(warns)} avertissements")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
