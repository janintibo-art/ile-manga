#!/usr/bin/env python3
"""Rejoue ici les contrôles de la compilation GitHub (.github/workflows/build-pcvr-native.yml),
sans l'export Windows ni la publication : les vérifications Python, et le jeu lancé 5 images
en VR puis en mode PC (aucune erreur de script tolérée).

    python3 tests/outils/verifier_workflow.py

Travaille dans une copie jetable de la copie de test (TESTS_COPIE, /root/t38 par défaut), déjà importée.
Affiche chaque étape (OK / FAIL / SKIP) puis « FAILS n ».
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

import yaml

TESTS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(TESTS)
COPIE = os.environ.get("TESTS_COPIE", "/root/t38")
GODOT = os.path.expanduser(os.environ.get("TESTS_GODOT", "~/gd/godot"))
WF = os.path.join(REPO, ".github/workflows/build-pcvr-native.yml")
SAUTER = ("Installer Godot", "Exporter exe", "Verifier exactement deux EXE", "Archiver", "Publier",
          "Recuperer", "Installer Inno", "Construire les deux installateurs", "Ajouter les installateurs",
          "Importer scene GLB")


def main():
    sys.path.insert(0, TESTS)
    import lancer  # noqa: E402
    lancer.synchroniser()
    wf = yaml.safe_load(open(WF, encoding="utf-8"))
    tmp = tempfile.mkdtemp(prefix="wf_")
    work = os.path.join(tmp, "depot")
    # une copie jetable (sans les gros modèles : on les relie)
    shutil.copytree(COPIE, work, symlinks=True, ignore=shutil.ignore_patterns("www"))
    os.symlink(os.path.join(COPIE, "www"), os.path.join(work, "www"))
    env = dict(os.environ)
    bindir = os.path.join(tmp, "bin")
    os.makedirs(bindir)
    with open(os.path.join(bindir, "godot"), "w") as f:
        f.write(f'#!/bin/bash\nexec flock /tmp/godot77.lock timeout 900 {GODOT} "$@"\n')
    os.chmod(os.path.join(bindir, "godot"), 0o755)
    env["PATH"] = bindir + ":" + env["PATH"]
    env["GITHUB_ENV"] = os.path.join(tmp, "github_env")
    env["GITHUB_OUTPUT"] = os.path.join(tmp, "github_output")
    env["NOM"] = "Les_Mondes_de_Travers"
    fails = 0
    for job in wf.get("jobs", {}).values():
        for st in job.get("steps", []):
            name = str(st.get("name", ""))
            run = st.get("run")
            if not run:
                continue
            if any(name.startswith(s) for s in SAUTER):
                print("SKIP", name)
                continue
            if "${{" in run:
                run = re.sub(r"\$\{\{\s*env\.(\w+)\s*\}\}", r"$\1", run)
            if os.path.exists(env["GITHUB_ENV"]):
                for line in open(env["GITHUB_ENV"]):
                    if "=" in line:
                        k, v = line.strip().split("=", 1)
                        env[k] = v
            cwd = os.path.join(work, st.get("working-directory", "."))
            r = subprocess.run(["bash", "-e", "-o", "pipefail", "-c", run], cwd=cwd, env=env,
                               capture_output=True, text=True)
            if r.returncode == 0:
                print("OK  ", name)
            else:
                fails += 1
                print("FAIL", name)
                print("     " + (r.stdout + r.stderr).strip().replace("\n", "\n     ")[-1500:])
    shutil.rmtree(tmp, ignore_errors=True)
    print("FAILS", fails)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
