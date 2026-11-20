"""V183 : prépare la fabrication des corps des habitants sur le PC de l'auteur (lancé par 4_corps_preparer.bat,
avec le Python du PC ; rien que la bibliothèque standard). Tout reste dans ce dossier (corps) :

- venv : un Python à part, avec numpy, scipy et Pillow (pip, sans cache) ; le Python du PC n'est pas touché ;
- mh\\makehuman, mh\\mpfb2 : des copies partielles des dépôts GitHub de MakeHuman 1.x et de MPFB2 (licence
  CC0), seulement les dossiers utiles (le maillage de base, les cibles des formes, les yeux, le squelette
  « mixamo » et ses poids).

    python preparer_corps.py            tout (ce qui est déjà là n'est pas refait)
    python preparer_corps.py --yeux-zip les yeux par l'archive des « system assets » de MakeHuman (267 Mo),
                                        si les dépôts ne les donnent pas
"""
import os, sys, subprocess, shutil, time, zipfile, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
VENV = os.path.join(ICI, "venv")
VPY = os.path.join(VENV, "Scripts", "python.exe") if os.name == "nt" else os.path.join(VENV, "bin", "python")
MH_DEPOT = os.path.join(ICI, "mh", "makehuman")
MPFB_DEPOT = os.path.join(ICI, "mh", "mpfb2")
ASSETS_DEPOT = os.path.join(ICI, "mh", "makehuman-assets")
MH = os.path.join(MH_DEPOT, "makehuman", "data")
CIBLES = ["macrodetails", "breast", "nose", "head", "mouth", "chin", "eyes", "neck", "ears", "cheek", "forehead",
          "eyebrows", "torso", "armslegs", "stomach", "expression/units/caucasian"]
MH_DOSSIERS = ["makehuman/data/3dobjs", "makehuman/data/eyes"] + ["makehuman/data/targets/" + c for c in CIBLES]
MPFB_DOSSIERS = ["src/mpfb/data/rigs/standard"]
YEUX = {"high-poly.mhclo": "eyes/high-poly", "high-poly.obj": "eyes/high-poly", "brown_eye.png": "eyes/materials"}
ZIP_YEUX = ["https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip",
            "https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip"]
SANS_LFS = dict(os.environ, GIT_LFS_SKIP_SMUDGE="1", GIT_TERMINAL_PROMPT="0")


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def run(cmd, cwd=None, env=None):
    log(">", " ".join(cmd))
    try:
        r = subprocess.call(cmd, cwd=cwd, env=env)
    except OSError as e:
        log("  ERREUR", e)
        return -1
    log("  code", r)
    return r


def taille(d):
    return sum(os.path.getsize(os.path.join(a, f)) for a, _, fs in os.walk(d) for f in fs) // (1024 * 1024)


def lfs(p):
    try:
        with open(p, "rb") as f:
            return os.path.getsize(p) < 1024 and f.read(40).startswith(b"version https://git-lfs")
    except OSError:
        return False


def git_exe():
    for c in [shutil.which("git"),
              os.path.join(os.environ.get("ProgramFiles", r"C:\Program Files"), "Git", "cmd", "git.exe"),
              os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "Git", "cmd", "git.exe")]:
        if c and os.path.exists(c):
            return c
    return None


def python_a_part():
    log("PYTHON", sys.version.split()[0], sys.executable)
    if not os.path.exists(VPY):
        if run([sys.executable, "-m", "venv", VENV]) != 0:
            return False
    r = run([VPY, "-m", "pip", "install", "--no-cache-dir", "--disable-pip-version-check", "numpy", "scipy", "pillow"])
    log("VENV", "OK" if r == 0 else "ECHEC", taille(VENV), "Mo")
    return r == 0


def pointeurs(dest, dossiers):
    """le nombre de fichiers de ces dossiers du dépôt restés « pointeurs » de Git LFS"""
    n = 0
    for d in dossiers:
        for a, _, fs in os.walk(os.path.join(dest, *d.split("/"))):
            n += sum(1 for f in fs if lfs(os.path.join(a, f)))
    return n


def depot(git, url, dest, dossiers, cone=True):
    """une copie partielle : l'arbre du dernier état, puis seulement les fichiers des dossiers voulus"""
    if not os.path.isdir(os.path.join(dest, ".git")):
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if run([git, "clone", "--depth", "1", "--filter=blob:none", "--sparse", url, dest], env=SANS_LFS) != 0:
            return False
    r = run([git, "-C", dest, "sparse-checkout", "set"] + ([] if cone else ["--no-cone"]) + dossiers, env=SANS_LFS)
    # des fichiers utiles gardés dans Git LFS (restés des pointeurs) : leur vrai contenu, ces dossiers seulement
    if r == 0 and cone:
        n = pointeurs(dest, dossiers)
        if n:
            log("LFS", n, "fichiers pointeurs dans", os.path.basename(dest))
            run([git, "-C", dest, "lfs", "pull", "--include", ",".join(d + "/**" for d in dossiers)])
            log("LFS", "il reste", pointeurs(dest, dossiers), "pointeurs")
    log("DEPOT", os.path.basename(dest), "OK" if r == 0 else "ECHEC", taille(dest), "Mo")
    return r == 0


def yeux_manquants():
    return [f for f, d in YEUX.items() if not os.path.exists(os.path.join(MH, d, f)) or lfs(os.path.join(MH, d, f))]


def copier_yeux(racine):
    """range dans MH les fichiers des yeux trouvés sous racine (quelle que soit la disposition du dépôt)"""
    for a, _, fs in os.walk(racine):
        for f in fs:
            if f in YEUX and a.replace("\\", "/").endswith(YEUX[f]) and not lfs(os.path.join(a, f)):
                os.makedirs(os.path.join(MH, YEUX[f]), exist_ok=True)
                shutil.copyfile(os.path.join(a, f), os.path.join(MH, YEUX[f], f))
                log("  yeux :", f, "depuis", a)


def les_yeux(git, par_zip):
    if not yeux_manquants():
        return True
    # 1. les fichiers des yeux du dépôt principal sont peut-être dans Git LFS
    run([git, "-C", MH_DEPOT, "lfs", "pull", "--include",
         "makehuman/data/eyes/high-poly/*,makehuman/data/eyes/materials/brown_eye.png"])
    # 2. le dépôt des « assets » de MakeHuman (Git LFS), seulement les yeux
    if yeux_manquants():
        if depot(git, "https://github.com/makehumancommunity/makehuman-assets.git", ASSETS_DEPOT,
                 ["**/eyes/high-poly/", "**/eyes/materials/"], cone=False):
            run([git, "-C", ASSETS_DEPOT, "lfs", "pull", "--include",
                 "base/eyes/high-poly/*,base/eyes/materials/brown_eye.png,eyes/high-poly/*,eyes/materials/brown_eye.png"])
            copier_yeux(ASSETS_DEPOT)
    # 3. l'archive des « system assets » (267 Mo), seulement si on l'a demandé
    if yeux_manquants() and par_zip:
        z = os.path.join(ICI, "mh", "makehuman_system_assets_cc0.zip")
        for url in ZIP_YEUX:
            if os.path.exists(z) and zipfile.is_zipfile(z):
                break
            log("> téléchargement", url)
            try:
                urllib.request.urlretrieve(url, z)
            except Exception as e:
                log("  ERREUR", e)
        if os.path.exists(z) and zipfile.is_zipfile(z):
            with zipfile.ZipFile(z) as zz:
                for n in zz.namelist():
                    f = n.rsplit("/", 1)[-1]
                    if f in YEUX and n.rsplit("/", 1)[0].endswith(YEUX[f]):
                        os.makedirs(os.path.join(MH, YEUX[f]), exist_ok=True)
                        with zz.open(n) as src, open(os.path.join(MH, YEUX[f], f), "wb") as dst:
                            shutil.copyfileobj(src, dst)
                        log("  yeux :", f, "depuis l'archive", n)
    m = yeux_manquants()
    log("YEUX", "OK" if not m else "MANQUE " + ",".join(m))
    return not m


def main():
    t = time.time()
    ok_py = python_a_part()
    git = git_exe()
    if git is None:
        log("PAS_DE_GIT")
        ok_mh = ok_mpfb = ok_yeux = False
    else:
        run([git, "--version"])
        run([git, "lfs", "version"])
        ok_mh = depot(git, "https://github.com/makehumancommunity/makehuman.git", MH_DEPOT, MH_DOSSIERS)
        ok_mpfb = depot(git, "https://github.com/makehumancommunity/mpfb2.git", MPFB_DEPOT, MPFB_DOSSIERS)
        ok_yeux = ok_mh and les_yeux(git, "--yeux-zip" in sys.argv)
    if os.path.exists(VPY):
        run([VPY, "-X", "utf8", os.path.join(ICI, "lancer_corps.py"), "verifier"])
    log("PREPARER_FINI python=%s makehuman=%s mpfb2=%s yeux=%s en %.0f s" % (ok_py, ok_mh, ok_mpfb, ok_yeux, time.time() - t))


if __name__ == "__main__":
    main()
