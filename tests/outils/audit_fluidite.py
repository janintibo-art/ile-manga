#!/usr/bin/env python3
"""V207 : le grand contrôle de la fluidité (voir audit_fluidite.gd) : à chaque île et grande place du jeu,
qui pèse dans ce que la carte graphique doit dessiner (triangles, appels), famille par famille.

    python3 tests/outils/audit_fluidite.py                      toutes les îles et grandes places
    python3 tests/outils/audit_fluidite.py --lieux "village:0,2,0;large:0,2,-240" --sans-iles
    python3 tests/outils/audit_fluidite.py --top 20 --attente 8

Le journal complet : tests/sorties/audit_fluidite.log ; le relevé : tests/sorties/audit_fluidite.txt (les
endroits du plus lourd au plus léger, puis pour chacun ses familles les plus lourdes).
"""
import argparse
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))
import lancer  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--lieux", default="")
ap.add_argument("--sans-iles", action="store_true")
ap.add_argument("--top", type=int, default=14)
ap.add_argument("--attente", type=float, default=7.0)
ap.add_argument("--detail", default="")
ap.add_argument("--dedans", action="store_true")
ap.add_argument("--paliers", action="store_true", help="V211 : mesure chaque vue avec et sans le détail allégé de loin")
ap.add_argument("--murs", action="store_true", help="V215 : essai des murs-écrans à Néopolis (chaque vue avec et sans)")
ap.add_argument("--photos", default="", help="V211 : endroits (séparés par des virgules) à photographier avec et sans")
ap.add_argument("--pc", default="", help="prépare le paquet du PC dans ce dossier au lieu de lancer ici")
ap.add_argument("--heure", type=float, default=14.0)
ap.add_argument("--delai", type=int, default=3000)
ap.add_argument("--sortie", default="audit_fluidite")
ap.add_argument("--journal", default="", help="lire ce journal (venu du PC) au lieu de lancer le jeu")
args = ap.parse_args()

lieux = []
for bout in [b for b in args.lieux.split(";") if b]:
    nom, xyz = bout.split(":")
    lieux.append([nom] + [float(v) for v in xyz.split(",")])
params = {"lieux": lieux, "iles": not args.sans_iles, "top": args.top, "attente": args.attente,
          "heure": args.heure, "detail": [d for d in args.detail.split(",") if d], "dedans": args.dedans,
          "paliers": args.paliers, "murs": args.murs, "photos": [d for d in args.photos.split(",") if d]}
main = open(lancer.MAIN_SRC, encoding="utf-8").read()
main += "\n\n" + open(os.path.join(lancer.SERIES, "_commun.gd"), encoding="utf-8").read()
main += "\n\n" + open(os.path.join(ICI, "audit_fluidite.gd"), encoding="utf-8").read()
if args.journal:
    args.pc = ""
if args.pc:
    # le paquet du PC (dossier Mondes_de_Travers_controle) : jeu/scripts/main.gd, jeu/audit_args.json et
    # jeu/project.godot (sauvegardes à part) ; 3_photos.bat le lance, le relevé arrive dans journaux/photos.txt
    import re
    os.makedirs(os.path.join(args.pc, "jeu", "scripts"), exist_ok=True)
    with open(os.path.join(args.pc, "jeu", "scripts", "main.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write(main)
    with open(os.path.join(args.pc, "jeu", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump(params, f)
    projet = open(os.path.join(os.path.dirname(lancer.MAIN_SRC), "..", "project.godot"), encoding="utf-8").read()
    projet = re.sub(r'config/custom_user_dir_name="[^"]*"', 'config/custom_user_dir_name="IleManga_controle"', projet)
    if args.murs:
        projet = projet.replace("[rendering]\n", "[rendering]\n\nocclusion_culling/use_occlusion_culling=true\n", 1)
        assert "occlusion_culling/use_occlusion_culling=true" in projet
    projet = re.sub(r'config/name="([^"]*)"', r'config/name="\1 (controle)"', projet, count=1)
    with open(os.path.join(args.pc, "jeu", "project.godot"), "w", encoding="utf-8", newline="\n") as f:
        f.write(projet)
    print("paquet du PC prêt :", args.pc)
    sys.exit(0)
if args.journal:
    journal, rc = args.journal, 0
else:
    lancer.synchroniser()
    with open(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"), "w", encoding="utf-8") as f:
        json.dump(params, f)
    journal = os.path.join(lancer.SORTIES, args.sortie + ".log")
    rc = lancer.godot(main, journal, args.delai)
    os.remove(os.path.join(lancer.COPIE, "pcvr", "audit_args.json"))

ordre, tot, tri, app, regle, vues = [], {}, {}, {}, {}, {}
sous = {}
murs, nmurs = {}, 0
sans, paliers = {}, None
for x in open(journal, encoding="utf-8", errors="replace"):
    c = x.rstrip("\n").split("\t")
    if c[0] == "FLU_LIEU":
        ordre.append(c[1])
        tot[c[1]] = [int(v) for v in c[2:]]
    elif c[0] == "FLU_SOUS":
        sous.setdefault(c[1], []).append(c[2:])
    elif c[0] == "FLU_VUE_MURS":
        murs.setdefault(c[1], {})[c[2]] = c[3:]
    elif c[0] == "FLU_MURS":
        nmurs = int(c[1])
    elif c[0] == "FLU_VUE":
        vues.setdefault(c[1], []).append(c[2:])
    elif c[0] == "FLU_VUE_SANS":
        sans.setdefault(c[1], {})[c[2]] = c[3:]
    elif c[0] == "FLU_PALIERS":
        paliers = c[1:]
    elif c[0] == "FLU_REGLE":
        regle[c[1]] = [json.loads(v) for v in c[2:]]
    elif c[0] in ("FLU_TRI", "FLU_APP"):
        (tri if c[0] == "FLU_TRI" else app).setdefault(c[1], []).append(c[2:])
ordre.sort(key=lambda n: -tot[n][3])
with open(os.path.join(lancer.SORTIES, args.sortie + ".txt"), "w", encoding="utf-8") as f:
    f.write("LES ENDROITS, du plus lourd au plus léger (triangles en milliers, tout autour du joueur)\n")
    for n in ordre:
        x, y, z, t, a, o, omb, nf = tot[n]
        f.write("%-22s (%5d,%4d,%5d)  %7d k triangles  %6d appels  %6d objets  %7d k avec ombre  %4d familles\n"
                % (n, x, y, z, t // 1000, a, o, omb // 1000, nf))
    if vues:
        f.write("\nCE QUE LA CARTE GRAPHIQUE DESSINE VRAIMENT (avec un écran), en regardant dans quatre directions\n")
        for n in sorted(vues, key=lambda n: -max(float(v[4]) for v in vues[n])):
            f.write("%-22s %s\n" % (n, " | ".join("%s : %s appels, %d k tri, %s ms" % (v[0], v[1], int(v[2]) // 1000, v[4]) for v in vues[n])))
    if paliers:
        f.write("\nLE DÉTAIL ALLÉGÉ DE LOIN (V211) : %s gros maillages, %s ont leurs paliers, de %d k à %d k triangles au plus léger, en %.0f s\n"
                % (paliers[0], paliers[1], int(paliers[2]) // 1000, int(paliers[3]) // 1000, float(paliers[4]) / 1000.0))
    if sans:
        f.write("\nAVEC ET SANS LE DÉTAIL ALLÉGÉ DE LOIN (triangles en milliers ; temps de la carte graphique)\n")
        ta = ts = ga = gs = 0.0
        for n in sorted(sans, key=lambda n: -sum(float(v[1]) for v in sans[n].values())):
            bouts = []
            for v in vues.get(n, []):
                if v[0] in sans[n]:
                    w = sans[n][v[0]]
                    bouts.append("%s : %d k -> %d k, %.2f -> %s ms" % (v[0], int(w[1]) // 1000, int(v[2]) // 1000, float(w[3]), v[4]))
                    ts += float(w[1]); ta += float(v[2]); gs += float(w[3]); ga += float(v[4])
            f.write("%-22s %s\n" % (n, " | ".join(bouts)))
        if ts > 0 and gs > 0:
            f.write("EN TOUT : triangles %d k -> %d k (%.0f %%), temps de la carte graphique %.1f -> %.1f ms (%.0f %%)\n"
                    % (ts // 1000, ta // 1000, (ta / ts - 1) * 100, gs, ga, (ga / gs - 1) * 100))
    if murs:
        f.write("\nAVEC ET SANS LES MURS-ÉCRANS (%d murs dans les immeubles de Néopolis) : objets dessinés, appels, temps de la carte graphique, temps du processeur pour le rendu\n" % nmurs)
        oa = os_ = ga = gs = ca = cs = 0.0
        for n in sorted(murs, key=lambda n: -sum(float(v[3]) for v in murs[n].values())):
            bouts = []
            for v in vues.get(n, []):
                if v[0] in murs[n]:
                    w = murs[n][v[0]]
                    bouts.append("%s : %s -> %s objets, %s -> %s appels, carte %s -> %s ms, processeur %s -> %s ms" % (v[0], v[3], w[2], v[1], w[0], v[4], w[3], v[5], w[4]))
                    os_ += float(v[3]); oa += float(w[2]); gs += float(v[4]); ga += float(w[3]); cs += float(v[5]); ca += float(w[4])
            f.write("%-22s %s\n" % (n, "\n                       ".join(bouts)))
        if os_ > 0 and gs > 0 and cs > 0:
            f.write("EN TOUT : objets %d -> %d (%.0f %%), carte graphique %.1f -> %.1f ms (%.0f %%), processeur %.1f -> %.1f ms (%.0f %%)\n"
                    % (os_, oa, (oa / os_ - 1) * 100, gs, ga, (ga / gs - 1) * 100, cs, ca, (ca / cs - 1) * 100))
    if sous:
        f.write("\nCE QUI EST DESSINÉ SANS POUVOIR ÊTRE VU (le joueur est en surface) : tout entier sous la mer ou sous le sol\n")
        for n in sorted(sous, key=lambda n: -sum(int(v[2]) for v in sous[n])):
            parcat = {}
            for v in sous[n]:
                pc = parcat.setdefault(v[0], [0, 0, 0])
                pc[0] += int(v[2]); pc[1] += int(v[3]); pc[2] += int(v[4])
            f.write("%-22s %s\n" % (n, " | ".join("%s : %d k tri, %d appels, %d objets" % (k, w[0] // 1000, w[1], w[2]) for k, w in sorted(parcat.items()))))
            for v in sous[n][:8]:
                f.write("        %-16s %7d k  %5s appels  %5s objets  le plus proche à %5s m  haut %6s m  %s\n" % (v[0], int(v[2]) // 1000, v[3], v[4], v[5], v[6], v[1]))
    f.write("\nLES APPELS SELON LA DISTANCE, et ce qui resterait si un objet disparaissait au-delà de K fois sa taille\n")
    for n in ordre:
        if n in regle:
            rt, ra, la, inc = regle[n]
            f.write("%-22s appels à <100 m %5d, 100-300 m %5d, 300-800 m %5d, au-delà %5d, nappes à la place inconnue %5d (%6d k) | K=150 : %5d appels %6d k ; K=250 : %5d appels %6d k ; K=400 : %5d appels %6d k\n"
                    % (n, la[0], la[1], la[2], la[3], la[4], inc // 1000, ra[0], rt[0] // 1000, ra[1], rt[1] // 1000, ra[2], rt[2] // 1000))
    for n in ordre:
        f.write("\n== %s : %d k triangles, %d appels\n" % (n, tot[n][3] // 1000, tot[n][4]))
        for titre, table in (("par triangles", tri), ("par appels", app)):
            f.write("  -- %s\n" % titre)
            for li in table.get(n, []):
                fam, t, a, o, d, omb = li[:6]
                bandes = ("  [<100 m %s, 100-300 %s, 300-800 %s, au-delà %s, inconnue %s]" % tuple(li[6:11])) if len(li) >= 11 else ""
                f.write("    %8d k  %6s appels  %5s objets  %5s avec ombre  %s%s\n"
                        % (int(t) // 1000, a, o, omb, fam, bandes))
print("contrôle de la fluidité : code %d, %d endroits -> %s" % (rc, len(ordre), os.path.join(lancer.SORTIES, args.sortie + ".txt")))
sys.exit(0 if rc == 0 and ordre else 1)
