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
ap.add_argument("--chemins", action="store_true")
ap.add_argument("--villes", default="")
ap.add_argument("--detours", action="store_true")
ap.add_argument("--table", action="store_true")
ap.add_argument("--depuis", default="")
ap.add_argument("--aretes", default="")
ap.add_argument("--oublier", default="")
ap.add_argument("--apres", default="")
ap.add_argument("--radar_chemins", default="")
args = ap.parse_args()

def tracer_plans(items, dossier):
    # le chemin d'avant en rouge, le détour en vert, sur les plans faits par le jeu ; des planches de six
    from PIL import Image, ImageDraw
    faits = []
    for it in items:
        base = os.path.join(dossier, it["nom"].replace("/", "_").replace("|", "_").replace(" ", "_"))
        if not os.path.exists(base + ".png"):
            continue
        meta = json.load(open(base + ".json", encoding="utf-8"))
        im = Image.open(base + ".png").convert("RGB")
        d = ImageDraw.Draw(im)
        px = lambda q: ((q[0] - meta["lo"][0]) * meta["ech"], (q[2] - meta["lo"][1]) * meta["ech"])
        d.line([px(it["A"]), px(it["B"])], fill=(230, 40, 30), width=3)
        if it.get("detour"):
            d.line([px(it["A"])] + [px(w) for w in it["detour"]] + [px(it["B"])], fill=(40, 220, 60), width=3)
        for q, c in [(it["A"], (255, 255, 255)), (it["B"], (255, 255, 0))]:
            x, y = px(q)
            d.ellipse([x - 4, y - 4, x + 4, y + 4], outline=c, width=2)
        if not it.get("sans_nom"):
            d.text((4, 2), it["nom"][:60], fill=(255, 255, 255))
        im.save(base + "_trace.png")
        faits.append(base + "_trace.png")
    for page in range(0, len(faits), 6):
        chunk = [Image.open(f0) for f0 in faits[page:page + 6]]
        w = max(i.width for i in chunk)
        h = max(i.height for i in chunk)
        sheet = Image.new("RGB", (w * 2 + 6, (h + 6) * ((len(chunk) + 1) // 2)), (255, 255, 255))
        for j, i in enumerate(chunk):
            sheet.paste(i, ((j % 2) * (w + 6), (j // 2) * (h + 6)))
        sheet.save(os.path.join(dossier, "planche_%02d.png" % (page // 6)))
    return faits


def preparer_plans():
    import glob
    dossier = os.path.abspath(args.dossier)
    os.makedirs(dossier, exist_ok=True)
    for x in glob.glob(os.path.join(dossier, "*.png")) + glob.glob(os.path.join(dossier, "*.json")):
        os.remove(x)
    return dossier, json.load(open(args.radar_chemins, encoding="utf-8"))


if args.radar_chemins and not args.chemins:
    # V184 : les plans des chemins, vus de dessus (voir audit_dehors.gd, _ad_radars_chemins)
    lancer.synchroniser()
    dossier, items = preparer_plans()
    with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump({"radar_chemins": items, "dossier": dossier}, f)
    main = open(lancer.MAIN_SRC, encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
    main += "\n\n" + open(os.path.join(ICI, "audit_dehors.gd"), encoding="utf-8").read()
    rc = lancer.godot(main, os.path.join(lancer.SORTIES, args.sortie + "_radar_chemins.log"), args.delai)
    os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))
    faits = tracer_plans(items, dossier)
    print("plans des chemins : code %d, %d -> %s" % (rc, len(faits), dossier))
    sys.exit(rc)

if args.chemins:
    # V184 : les chemins des habitants (voir audit_dehors.gd, _ad_chemins) ; le relevé : un bilan par ville,
    # puis les bouts de chemin, du plus enfoncé dans le décor au moins enfoncé
    lancer.synchroniser()
    sortie = args.sortie if args.sortie != "audit_dehors" else "audit_chemins"
    params = {"chemins": True, "heures": [float(h) for h in args.heures.split(",") if h], "de": args.de, "a": args.a,
              "villes": [x for x in args.villes.split(",") if x], "detours": args.detours,
              "aretes": json.load(open(args.aretes, encoding="utf-8")) if args.aretes else [],
              "apres": json.loads(args.apres) if args.apres else []}
    plans_items = None
    if args.radar_chemins:
        plans_dossier, plans_items = preparer_plans()
        params["radar_chemins"] = plans_items
        params["dossier"] = plans_dossier
    with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump(params, f)
    # pour refaire la table (--table), les plans tels qu'ils sont écrits : la copie du jeu sans les détours
    TABLE = os.path.join("pcvr", "scripts", "pnj", "chemins_table_v184.gd")
    if args.table:
        with open(os.path.join(lancer.COPIE, TABLE), "w", encoding="utf-8") as f:
            f.write("extends RefCounted\nconst TABLE := {\n}\n")
    os.makedirs(lancer.SORTIES, exist_ok=True)
    log = os.path.join(lancer.SORTIES, sortie + ".log")
    if args.depuis:
        # (--depuis LOG1,LOG2… : sans relancer le jeu, d'après les journaux d'audits déjà faits, mis bout à
        # bout ; un bout de chemin revu dans un journal plus récent prend sa nouvelle ligne ; --oublier
        # v1,v2 : les détours de ces villes ne viennent que du dernier journal)
        oublier = [x for x in args.oublier.split(",") if x]
        journaux = [x for x in args.depuis.split(",") if x]
        tout = []
        for n_j, lj in enumerate(journaux):
            for x in open(lj, encoding="utf-8", errors="replace").read().splitlines():
                c = x.split("\t")
                if x.startswith("CHEMIN") and len(c) > 2 and n_j < len(journaux) - 1 and c[2].split(":")[0] in oublier:
                    continue
                tout.append(x)
        log = os.path.join(lancer.SORTIES, sortie + "_fusion.log")
        open(log, "w", encoding="utf-8").write("\n".join(tout) + "\n")
        rc = 0
    else:
        main = open(lancer.MAIN_SRC, encoding="utf-8").read()
        main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
        main += "\n\n" + open(os.path.join(ICI, "audit_dehors.gd"), encoding="utf-8").read()
        rc = lancer.godot(main, log, args.delai)
    os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))
    if args.table:
        import shutil
        shutil.copy(os.path.join(lancer.REPO, TABLE), os.path.join(lancer.COPIE, TABLE))
    lignes = open(log, encoding="utf-8", errors="replace").read().splitlines()
    cas = [x.split("\t") for x in lignes if x.startswith("CHEMIN\t")]
    detours = [x.split("\t") for x in lignes if x.startswith("CHEMIN_DETOUR")]
    plans = [x for x in lignes if x.startswith("CHEMIN_PLAN\t")]
    erreurs = [x for x in lignes if "SCRIPT ERROR" in x or "Parse Error" in x]
    fin = [x for x in lignes if x.startswith("CHEMINS_") or x.startswith("SERIE_FINIE")]
    out = os.path.join(lancer.SORTIES, sortie + ".txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(fin) + "\n")
        for e in erreurs[:20]:
            f.write("ERREUR " + e + "\n")
        f.write("\n== les plans\n" + "\n".join(plans) + "\n")
        par_ville = collections.Counter()
        par_quoi = collections.Counter()
        for c in cas:
            # i ville a b L touchés libre_min A B pas sauts
            if float(c[7]) < 0.1:
                par_ville[c[2]] += 1
                for p in c[10].split(";"):
                    if p and float(p.split("/")[1]) < 0.1:
                        par_quoi[p.split("/", 2)[2].split("<")[0].split("@")[0]] += 1
        f.write("\n== par ville (bouts de chemin où l'axe du corps passe à moins de 10 cm du décor)\n")
        for k, n in par_ville.most_common():
            f.write("%5d  %s\n" % (n, k))
        f.write("\n== ce qui est traversé (pas à moins de 10 cm)\n")
        for k, n in par_quoi.most_common(80):
            f.write("%5d  %s\n" % (n, k))
        if detours:
            f.write("\n== les détours (%d)\n" % len(detours))
            for d in detours:
                f.write("\t".join(d) + "\n")
        f.write("\n== les bouts de chemin\n")
        for c in sorted(cas, key=lambda c: float(c[7])):
            f.write("\t".join(c[1:]) + "\n")
    if plans_items is not None:
        print("plans des chemins : %d -> %s" % (len(tracer_plans(plans_items, plans_dossier)), plans_dossier))
    if args.table and rc == 0 and any(x.startswith("CHEMINS_FIN") for x in lignes):
        # la table des détours (pcvr/scripts/pnj/chemins_table_v184.gd), d'après les lignes CHEMIN_DETOUR
        table = collections.defaultdict(list)
        # (le dernier détour d'un bout de chemin l'emporte : les journaux plus récents viennent après)
        # (un bout de chemin refait plus tard sans trouver de détour perd celui d'avant : il était moins bon
        # que le chemin d'origine)
        derniers = {}
        for d in detours:
            if d[0] == "CHEMIN_DETOUR":
                derniers[(d[2], d[3], d[4])] = d
            elif d[0] == "CHEMIN_DETOUR_ECHEC":
                derniers.pop((d[2], d[3], d[4]), None)
        detours = list(derniers.values())
        for d in detours:
            # (pas les tours de course ni les jeux des enfants : ils ne passent pas par le plan)
            if d[0] != "CHEMIN_DETOUR" or d[2].endswith(":course") or d[2].endswith(":jeu"):
                continue
            # i ville a b ax,az bx,bz L L2 points
            a, b = d[3], d[4]
            ax, az = [float(v) for v in d[5].split(",")]
            pts = [[float(v) for v in p.split(",")] for p in d[9].split(";") if p]
            if a > b:
                a, b = b, a
                ax, az = [float(v) for v in d[6].split(",")]
                pts.reverse()
            table[a + "|" + b].append([ax, az, pts, 1 if len(d) > 10 and d[10] == "souple" else 0])
        dst = os.path.join(lancer.REPO, TABLE)
        with open(dst, "w", encoding="utf-8") as f:
            f.write("extends RefCounted\n")
            f.write("## V184 : écrit par tests/outils/audit_dehors.py --chemins --detours --table (ne pas modifier à la main :\n")
            f.write("## refaire l'audit des chemins). \"<a>|<b>\" : [[ax, az, [x, y, z, x, y, z, …]], …] : le bout de chemin entre\n")
            f.write("## les points a et b du plan d'une ville (ax, az : où est a, pour reconnaître la ville) passe par ces\n")
            f.write("## points, dans l'ordre de a vers b ; un 1 à la fin : un détour « souple » (trouvé au second essai, il\n")
            f.write("## frôle le décor à moins de 1,5 m des deux bouts). Voir chemins_v184.gd.\n")
            f.write("const TABLE := {\n")
            for k in sorted(table):
                f.write('\t"%s": [%s],\n' % (k, ", ".join("[%.2f, %.2f, [%s]%s]" % (e[0], e[1], ", ".join("%.2f" % v for p in e[2] for v in p), ", 1" if e[3] else "") for e in table[k])))
            f.write("}\n")
        print("table : %d bouts de chemin avec un détour -> %s" % (sum(len(v) for v in table.values()), dst))
    print("%d bouts de chemin touchent le décor, code %d -> %s" % (len(cas), rc, out))
    for x in fin + erreurs[:5]:
        print(x)
    sys.exit(rc)

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
