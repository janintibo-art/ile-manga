"""La copie du jeu pour le PC de l'auteur (V182) : le projet de la copie de travail des tests (avec ses
modèles et ses textures préparés par stage_assets.py, sans le cache d'import .godot), en archives zip de
moins de 330 Mo (le pont vers le PC en prend une par envoi), dans SORTIE.

    python3 tests/outils/paquets_pc.py [SORTIE]

Sur le PC (dossier Mondes_de_Travers_controle du Bureau) : paquets/jeu_N.zip, puis 1_deballer.bat,
2_preparer.bat (Godot importe tout, ~3 min), 3_photos.bat (tests/outils/pc). Ensuite, pour une mise à
jour : un maj.zip (les scripts changés, le main.gd et la liste des photos de photos_pc.py) que
3_photos.bat applique tout seul.
"""
import os, sys, zipfile
SRC = os.path.join(os.environ.get("TESTS_COPIE", "/root/t38"), "pcvr")
REPO = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "pcvr")
OUT = sys.argv[1] if len(sys.argv) > 1 else "/mnt/user-data/outputs/mdt"
os.makedirs(OUT, exist_ok=True)
LIM = 330 * 1024 * 1024
STORE = {".png", ".jpg", ".jpeg", ".ogg", ".webp", ".mp3", ".wav", ".zip"}
DEBRIS = ("dbg142.gd", "rendu_", "audit_args.json")
files = []
for d, dirs, fs in os.walk(SRC):
    rel_d = os.path.relpath(d, SRC)
    if rel_d == ".godot" or rel_d.startswith(".godot" + os.sep) or rel_d.startswith("build"):
        dirs[:] = []
        continue
    dirs.sort()
    for f in sorted(fs):
        rel = os.path.normpath(os.path.join(rel_d, f))
        if rel_d == "." and f.startswith(DEBRIS):
            continue
        files.append(rel)
parts = []
cur, size = [], 0
for rel in files:
    s = os.path.getsize(os.path.join(SRC, rel))
    if cur and size + s > LIM:
        parts.append(cur)
        cur, size = [], 0
    cur.append(rel)
    size += s
parts.append(cur)
for i, p in enumerate(parts):
    path = os.path.join(OUT, "jeu_%d.zip" % (i + 1))
    with zipfile.ZipFile(path, "w") as z:
        for rel in p:
            src = os.path.join(SRC, rel)
            if rel == os.path.join("scripts", "main.gd"):
                src = os.path.join(REPO, rel)
            ext = os.path.splitext(rel)[1].lower()
            if ext in STORE:
                z.write(src, rel.replace(os.sep, "/"), compress_type=zipfile.ZIP_STORED)
            else:
                z.write(src, rel.replace(os.sep, "/"), compress_type=zipfile.ZIP_DEFLATED, compresslevel=5)
    print(path, len(p), os.path.getsize(path) // (1024 * 1024), "Mo", flush=True)
print("FIN", len(files))
