"""V183 : le paquet pour fabriquer les vrais corps des habitants sur le PC de l'auteur (le serveur des tests n'a
pas les données de MakeHuman). Le générateur (pcvr/tools/habitants_v64), les lanceurs (tests/outils/pc/corps),
les fiches et le squelette du héros (V64_CACHE, écrits par extraire_fiches.gd et extraire_squelette.gd), les
noms à fabriquer et la liste des cibles (targets) de MakeHuman dont ils ont besoin.

    python3 tests/outils/corps_pc.py NOMS [SORTIE]     NOMS : « a,b,c » ou un fichier de noms (virgules)

Sur le PC (dossier Mondes_de_Travers_controle du Bureau) : corps_paquet.zip et 4_corps_preparer.bat (qui le
déballe, puis prépare un Python à part et les données), puis 5_corps.bat (journaux/corps_resultat.zip).
Au retour : tests/outils/comparer_corps.py compare les deux témoins à ceux du jeu.
"""
import os, sys, json, types, zipfile

ICI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(ICI))
GEN = os.path.join(REPO, "pcvr", "tools", "habitants_v64")
PC = os.path.join(ICI, "pc")
CACHE = os.environ.get("V64_CACHE", os.path.expanduser("~/.cache/ile_manga_v64"))
sys.path.insert(0, GEN)


def cibles(noms, fiches):
    """les cibles que le générateur chargera pour ces habitants (et le corps neutre, et les expressions)"""
    # mh.py lit le squelette de MPFB2 dès l'import : on n'en garde que le nommage des cibles
    src = open(os.path.join(GEN, "mh.py"), encoding="utf-8").read().split("\nRIG = json.load")[0]
    mh = types.ModuleType("mh_noms")
    exec(src.replace("from chemins import MH, MPFB", "MH = MPFB = ''"), mh.__dict__)
    from appearance import decide
    P0 = dict(gender=0.5, age=0.5, muscle=0.5, weight=0.5, height=0.5, african=1, asian=1, caucasian=1)
    out = {n for n, _ in mh.macro_targets(P0)}
    out |= {"expression/units/caucasian/" + e for e in ["eye-left-closure", "eye-right-closure", "mouth-open", "mouth-corner-puller"]}
    for pid in noms:
        D = decide(pid, fiches[pid])
        out |= {n for n, _ in mh.macro_targets(D["morph"]) + mh.modifier_targets(D["mods"])}
    return sorted(out)


def main():
    arg = sys.argv[1]
    noms = [n for n in (open(arg).read() if os.path.exists(arg) else arg).strip().split(",") if n]
    sortie = sys.argv[2] if len(sys.argv) > 2 else "/mnt/user-data/outputs/mdt/corps_paquet.zip"
    fiches = json.load(open(os.path.join(CACHE, "pnj.json"), encoding="utf-8"))
    temoins = []
    for l in open(os.path.join(PC, "corps", "lancer_corps.py"), encoding="utf-8"):
        if l.startswith("TEMOINS = "):
            temoins = json.loads(l.split("=", 1)[1].strip())
    sans = [n for n in noms + temoins if n not in fiches]
    if sans:
        sys.exit("pas de fiche pour : " + ",".join(sans))
    c = cibles(noms + temoins, fiches)
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    with zipfile.ZipFile(sortie, "w", zipfile.ZIP_DEFLATED) as z:
        for f in ["5_corps.bat", "LISEZMOI.txt"]:
            z.write(os.path.join(PC, f), f)
        for f in ["lancer_corps.py", "preparer_corps.py"]:
            z.write(os.path.join(PC, "corps", f), "corps/" + f)
        for f in sorted(os.listdir(GEN)):
            if f.endswith(".py"):
                z.write(os.path.join(GEN, f), "corps/pcvr/tools/habitants_v64/" + f)
        for f in ["pnj.json", "hero_skel.json"]:
            z.write(os.path.join(CACHE, f), "corps/cache/" + f)
        z.writestr("corps/cache/ids.txt", ",".join(noms) + "\n")
        z.writestr("corps/cache/cibles_requises.txt", "\n".join(c) + "\n")
    print("%s : %d habitants (+ %d témoins), %d cibles, %d Ko" % (sortie, len(noms), len(temoins), len(c), os.path.getsize(sortie) // 1024))


if __name__ == "__main__":
    main()
