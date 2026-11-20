"""V183 : les vrais corps des habitants, fabriqués sur le PC de l'auteur (le serveur des tests n'a pas les
données de MakeHuman). Lancé par 5_corps.bat, avec le Python à part du dossier (corps\\venv).

    python lancer_corps.py verifier   les données et les modules sont-ils là ?
    python lancer_corps.py corps      fabrique les corps de cache\\ids.txt (et deux témoins déjà dans le jeu)

Données (licence CC0) : mh\\makehuman\\makehuman\\data (MakeHuman 1.x), mh\\mpfb2\\src\\mpfb\\data (MPFB2).
Fiches des habitants (pnj.json), squelette du héros (hero_skel.json), noms (ids.txt) et cibles utiles
(cibles_requises.txt) : cache. Sortie : www\\assets\\models\\pnj64, puis ..\\journaux\\corps_resultat.zip.
"""
import os, sys, subprocess, time, zipfile, json

ICI = os.path.dirname(os.path.abspath(__file__))
MH = os.path.join(ICI, "mh", "makehuman", "makehuman", "data")
MPFB = os.path.join(ICI, "mh", "mpfb2", "src", "mpfb", "data")
CACHE = os.path.join(ICI, "cache")
GEN = os.path.join(ICI, "pcvr", "tools", "habitants_v64", "generer.py")
OUT = os.path.join(ICI, "www", "assets", "models", "pnj64")
RESULTAT = os.path.join(os.path.dirname(ICI), "journaux", "corps_resultat.zip")
# deux habitants déjà dans le jeu (V101, le générateur d'aujourd'hui) : refaits ici, on compare
TEMOINS = ["aquarelle", "augustin"]
FICHIERS = [
    (MH, "3dobjs/base.obj"), (MH, "eyes/high-poly/high-poly.mhclo"), (MH, "eyes/high-poly/high-poly.obj"),
    (MH, "eyes/materials/brown_eye.png"), (MPFB, "rigs/standard/rig.mixamo.json"), (MPFB, "rigs/standard/weights.mixamo.json"),
]


def lfs(p):
    """un fichier resté « pointeur » de Git LFS (le vrai contenu pas téléchargé)"""
    try:
        with open(p, "rb") as f:
            return os.path.getsize(p) < 1024 and f.read(40).startswith(b"version https://git-lfs")
    except OSError:
        return False


def verifier():
    ok = True
    for base, rel in FICHIERS:
        p = os.path.join(base, rel)
        etat = "OK" if os.path.exists(p) and not lfs(p) else ("LFS" if os.path.exists(p) else "MANQUE")
        ok = ok and etat == "OK"
        print("%-7s %s (%s)" % (etat, rel, os.path.getsize(p) if os.path.exists(p) else "-"), flush=True)
    # les cibles (targets) : une cible des formes du corps qui manque est sautée sans rien dire par le
    # générateur (certaines n'existent pas dans MakeHuman) ; on les compte par dossier
    noms = [l.strip() for l in open(os.path.join(CACHE, "cibles_requises.txt"), encoding="utf-8") if l.strip()]
    manque, par = [], {}
    for n in noms:
        g = n.rsplit("/", 1)[0]
        par.setdefault(g, [0, 0])
        par[g][1] += 1
        p = os.path.join(MH, "targets", n + ".target")
        if os.path.exists(p) and not lfs(p):
            par[g][0] += 1
        else:
            manque.append(n)
    print("CIBLES", " ".join("%s=%d/%d" % (g, a, b) for g, (a, b) in sorted(par.items())), flush=True)
    # les formes générales (macrodetails, breast) : toutes les combinaisons n'existent pas, le générateur saute
    # celles qui manquent (comme avant) ; les autres (nez, menton… expressions) sont indispensables
    generales = [n for n in manque if n.startswith(("macrodetails/", "breast/"))]
    autres = [n for n in manque if n not in generales]
    for n in autres[:40] + generales[:12]:
        print("CIBLE_MANQUE", n, flush=True)
    ok = ok and not autres
    print("CIBLES_MANQUANTES %d sur %d (formes générales : %d ; autres : %d)" % (len(manque), len(noms), len(generales), len(autres)), flush=True)
    for mod in ["numpy", "scipy", "PIL"]:
        try:
            m = __import__(mod)
            print("OK      module %s %s" % (mod, getattr(m, "__version__", "")), flush=True)
        except Exception as e:
            ok = False
            print("MANQUE  module %s (%s)" % (mod, e), flush=True)
    ids = open(os.path.join(CACHE, "ids.txt"), encoding="utf-8").read().strip().split(",")
    fiches = json.load(open(os.path.join(CACHE, "pnj.json"), encoding="utf-8"))
    sans = [i for i in ids + TEMOINS if i not in fiches]
    if sans:
        ok = False
        print("SANS_FICHE", ",".join(sans), flush=True)
    print("PYTHON", sys.version.split()[0], sys.executable, flush=True)
    print("VERIFIER", "OK" if ok else "INCOMPLET", "(%d habitants + %d témoins)" % (len(ids), len(TEMOINS)), flush=True)
    return ok


def corps():
    if not verifier():
        print("CORPS_ARRET : il manque des données ou des modules", flush=True)
        return 1
    ids = open(os.path.join(CACHE, "ids.txt"), encoding="utf-8").read().strip().split(",")
    env = dict(os.environ, MAKEHUMAN_DATA=MH, MPFB_DATA=MPFB, V64_CACHE=CACHE, PYTHONUTF8="1")
    t = time.time()
    r = subprocess.call([sys.executable, "-X", "utf8", GEN, "corps", ",".join(ids + TEMOINS)], env=env, cwd=os.path.dirname(GEN))
    print("CORPS_FINI code %d en %.0f s" % (r, time.time() - t), flush=True)
    faits = sorted(f for f in os.listdir(OUT) if f.endswith(".bin")) if os.path.isdir(OUT) else []
    os.makedirs(os.path.dirname(RESULTAT), exist_ok=True)
    with zipfile.ZipFile(RESULTAT, "w", zipfile.ZIP_DEFLATED) as z:
        for f in faits:
            z.write(os.path.join(OUT, f), "pnj64/" + f)
    absents = [i for i in ids + TEMOINS if i + ".bin" not in faits]
    print("RESULTAT %d fichiers dans %s ; absents : %s" % (len(faits), RESULTAT, ",".join(absents) or "aucun"), flush=True)
    return r


if __name__ == "__main__":
    quoi = sys.argv[1] if len(sys.argv) > 1 else "verifier"
    if quoi == "verifier":
        sys.exit(0 if verifier() else 1)
    sys.exit(corps())
