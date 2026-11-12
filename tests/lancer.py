#!/usr/bin/env python3
"""Lance les séries de tests du jeu, plusieurs séries par lancement du jeu.

    python3 tests/lancer.py                    toutes les séries
    python3 tests/lancer.py 10_voyages 50_faune_iles      seulement celles-là
    python3 tests/lancer.py --seul ...         une série par lancement (à l'ancienne)
    python3 tests/lancer.py --taille 6 ...     6 séries par lancement (12 par défaut)

Pourquoi des groupes : un lancement du jeu sans écran coûte ~1 min 50 (moteur 16 s, construction
du monde 78 s, premières images 12 s). On fait donc tourner plusieurs séries dans le même monde.
Chaque série garde son propre code (ses noms sont préfixés _b3_… pour ne pas se marcher dessus) ;
son get_tree().quit() passe la main à la suivante, après avoir relâché les touches et remis le
temps à 1. Une série qui échoue dans un groupe est relancée seule : seul ce résultat compte.

Les séries : tests/series/NN_nom.gd, précédées de tests/series/_commun.gd (outils communs).
Le jeu tourne dans une copie de travail (TESTS_COPIE, /root/t38 par défaut) où l'on recopie les
fichiers changés du dépôt ; Godot : TESTS_GODOT (~/gd/godot par défaut).

Sorties : tests/sorties/<série>.log (hors dépôt, voir .gitignore), et un bilan court à l'écran.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time

TESTS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TESTS)
SERIES = os.path.join(TESTS, "series")
SORTIES = os.path.join(TESTS, "sorties")
COPIE = os.environ.get("TESTS_COPIE", "/root/t38")
GODOT = os.path.expanduser(os.environ.get("TESTS_GODOT", "~/gd/godot"))
VERROU = "/tmp/godot77.lock"
MAIN_SRC = os.path.join(REPO, "pcvr/scripts/main.gd")
MAIN_DST = os.path.join(COPIE, "pcvr/scripts/main.gd")
GARDE_S = 1300          # une série bloquée plus longtemps : on arrête le groupe
ISOLEES = os.path.join(TESTS, "isolees.txt")
DUREES = os.path.join(SORTIES, "durees.txt")
KEYS = ["KEY_1", "KEY_2", "KEY_3", "KEY_4", "KEY_5", "KEY_6", "KEY_7", "KEY_8", "KEY_9", "KEY_0",
        "KEY_A", "KEY_B", "KEY_CTRL", "KEY_D", "KEY_E", "KEY_ESCAPE", "KEY_F", "KEY_F1", "KEY_F8",
        "KEY_G", "KEY_H", "KEY_I", "KEY_J", "KEY_K", "KEY_M", "KEY_P", "KEY_Q", "KEY_R", "KEY_S",
        "KEY_SHIFT", "KEY_SPACE", "KEY_T", "KEY_V", "KEY_W", "KEY_X", "KEY_Z", "KEY_TAB", "KEY_ENTER",
        "KEY_ALT", "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT"]


def toutes():
    return sorted(f[:-3] for f in os.listdir(SERIES) if f.endswith(".gd") and not f.startswith("_"))


def texte(sid):
    commun = open(os.path.join(SERIES, "_commun.gd"), encoding="utf-8").read()
    return commun + "\n\n" + open(os.path.join(SERIES, sid + ".gd"), encoding="utf-8").read()


def isolees():
    if not os.path.exists(ISOLEES):
        return set()
    out = set()
    for line in open(ISOLEES, encoding="utf-8"):
        line = line.split("#")[0].strip()
        if line:
            out.add(line)
    return out


# ------------------------------------------------------------------ copie de travail
def synchroniser():
    """Recopie dans la copie de travail les fichiers du dépôt qui ont changé."""
    def git(args):
        r = subprocess.run(["git"] + args, cwd=REPO, capture_output=True, text=True)
        return [x for x in r.stdout.split("\n") if x]
    files = set(git(["ls-files", "-m", "-o", "--exclude-standard", "pcvr", "www"]))
    files |= set(git(["diff", "--name-only", "origin/main", "--", "pcvr", "www"]))
    n = 0
    for f in sorted(files):
        src = os.path.join(REPO, f)
        if not os.path.isfile(src):
            continue
        dst = os.path.join(COPIE, f)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if not os.path.exists(dst) or open(src, "rb").read() != open(dst, "rb").read():
            shutil.copy(src, dst)
            n += 1
    shutil.copy(MAIN_SRC, MAIN_DST)
    subprocess.run("python3 pcvr/stage_assets.py > /dev/null", shell=True, cwd=COPIE)
    return n


# ------------------------------------------------------------------ transformation d'une série
DECL = re.compile(r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(?:func|var|const|signal|enum|class)\s+([A-Za-z_]\w*)", re.M)


def segments(src):
    """Découpe le code en (est_du_code, texte) : chaînes et commentaires à part."""
    out = []
    i = 0
    n = len(src)
    start = 0
    while i < n:
        c = src[i]
        if c == "#":
            if i > start:
                out.append((True, src[start:i]))
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append((False, src[i:j]))
            i = start = j
            continue
        if c in "\"'":
            if i > start:
                out.append((True, src[start:i]))
            q = src[i:i + 3] if src[i:i + 3] in ('"""', "'''") else c
            j = i + len(q)
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src.startswith(q, j):
                    j += len(q)
                    break
                if len(q) == 1 and src[j] == "\n":
                    break
                j += 1
            out.append((False, src[i:j]))
            i = start = j
            continue
        i += 1
    if start < n:
        out.append((True, src[start:]))
    return out


def transformer(src, idx):
    names = sorted(set(DECL.findall(src)), key=len, reverse=True)
    if "_process" not in names:
        raise ValueError("pas de _process")
    pat = re.compile(r"(?<![\w.$%])(" + "|".join(re.escape(x) for x in names) + r")\b")
    pre = f"_b{idx}_"
    out = []
    for code, txt in segments(src):
        if code:
            txt = txt.replace("get_tree().quit()", f"_bt_fin({idx})")
            txt = pat.sub(lambda m: pre + m.group(1), txt)
        out.append(txt)
    return "".join(out)


def aiguillage(ids):
    cases = "".join(f"\t\t{i}:\n\t\t\t_b{i}__process(d)\n" for i in range(len(ids)))
    keys = ", ".join(KEYS)
    return f'''

# ======================= GROUPE DE SÉRIES (écrit par tests/lancer.py)
var _bt_ids: Array = {json.dumps(ids)}
var _bt_cur := -1
var _bt_next := 0
var _bt_t0 := 0
func _process(d: float) -> void:
	if _bt_cur < 0:
		if _bt_next == 0:
			_bt_begin(0)
		else:
			return
	if Time.get_ticks_msec() - _bt_t0 > {GARDE_S} * 1000:
		print("@@BATCH_TIMEOUT ", _bt_ids[_bt_cur])
		_bt_cur = -1
		_bt_next = 99999
		get_tree().quit()
		return
	match _bt_cur:
{cases}

func _bt_begin(n: int) -> void:
	_bt_cur = n
	_bt_next = n + 1
	_bt_t0 = Time.get_ticks_msec()
	print("@@BATCH_DEBUT ", _bt_ids[n], " ", Time.get_ticks_msec())


func _bt_fin(idx: int) -> void:
	if idx != _bt_cur:
		return
	print("@@BATCH_FIN ", _bt_ids[idx], " ", Time.get_ticks_msec())
	_bt_cur = -1
	if idx + 1 >= _bt_ids.size():
		get_tree().quit()
		return
	_bt_reset.call_deferred(idx + 1)


func _bt_reset(n: int) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	for k in [{keys}]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = false
		Input.parse_input_event(ev)
	for b in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var mb := InputEventMouseButton.new()
		mb.button_index = b
		mb.pressed = false
		Input.parse_input_event(mb)
	for a in InputMap.get_actions():
		Input.action_release(a)
	await get_tree().create_timer(0.5).timeout
	_bt_begin(n)
'''


# ------------------------------------------------------------------ lancements
def godot(main_text, log_path, timeout_s):
    with open(MAIN_DST, "w", encoding="utf-8") as f:
        f.write(main_text)
    cmd = (f"ulimit -f 800000; flock {VERROU} timeout {timeout_s} {GODOT} --headless "
           f"--path pcvr > {log_path} 2>&1")
    try:
        rc = subprocess.call(["bash", "-c", cmd], cwd=COPIE)
    finally:
        shutil.copy(MAIN_SRC, MAIN_DST)
    return rc


def verdict(text):
    bad = []
    for line in text.splitlines():
        if ("erreurs" in line and "[]" not in line) or line.startswith("FAIL ") or "SCRIPT ERROR" in line:
            bad.append(line.strip()[:200])
    if "SERIE_FINIE" not in text:
        bad.append("la série ne s'est pas terminée")
    return bad


def seule(sid):
    log = os.path.join(SORTIES, sid + ".log")
    t0 = time.time()
    rc = godot(open(MAIN_SRC, encoding="utf-8").read() + "\n\n" + texte(sid), log, 1500)
    text = open(log, encoding="utf-8", errors="replace").read()
    bad = verdict(text)
    if rc == 124:
        bad.append("délai dépassé")
    elif rc != 0:
        bad.append(f"le jeu s'est arrêté (code {rc})")
    return bad, time.time() - t0


def groupe(ids, n):
    main = open(MAIN_SRC, encoding="utf-8").read()
    for i, sid in enumerate(ids):
        main += f"\n\n# ======================= SÉRIE {sid} (groupe)\n" + transformer(texte(sid), i)
    main += aiguillage(ids)
    glog = os.path.join(SORTIES, f"_groupe_{n}.log")
    rc = godot(main, glog, 300 + GARDE_S * len(ids))
    lines = open(glog, encoding="utf-8", errors="replace").read().splitlines(keepends=True)
    buf = {sid: [] for sid in ids}
    begun, ended, times = [], set(), {}
    cur = ids[0]
    for line in lines:
        if line.startswith("@@BATCH_DEBUT "):
            p = line.split()
            cur = p[1]
            begun.append(cur)
            times[cur] = [int(p[2]), None]
        elif line.startswith("@@BATCH_FIN "):
            p = line.split()
            ended.add(p[1])
            if p[1] in times:
                times[p[1]][1] = int(p[2])
        buf.setdefault(cur, []).append(line)
    res = {}
    for sid in begun:
        text = "".join(buf[sid])
        with open(os.path.join(SORTIES, sid + ".log"), "w", encoding="utf-8") as f:
            f.write(text)
        bad = verdict(text)
        if sid not in ended:
            bad.append("inachevée dans le groupe (code %d)" % rc)
        t = times.get(sid, [0, None])
        res[sid] = (bad, (t[1] - t[0]) / 1000.0 if t[1] else None)
    reste = [sid for sid in ids if sid not in begun]
    return res, reste, rc


def main():
    args = sys.argv[1:]
    taille = 12
    tout_seul = "--seul" in args
    if "--taille" in args:
        taille = int(args[args.index("--taille") + 1])
    ids = [a for i, a in enumerate(args) if not a.startswith("--") and (i == 0 or args[i - 1] != "--taille")]
    ids = ids or toutes()
    inconnues = [s for s in ids if not os.path.exists(os.path.join(SERIES, s + ".gd"))]
    if inconnues:
        print("séries inconnues :", " ".join(inconnues))
        return 1
    os.makedirs(SORTIES, exist_ok=True)
    print(f"{synchroniser()} fichier(s) recopié(s) dans {COPIE}")
    t_start = time.time()
    iso = isolees()
    en_groupe = [s for s in ids if s not in iso and not tout_seul]
    a_part = [s for s in ids if s in iso or tout_seul]
    final = {}
    a_relancer = []
    file = [en_groupe[i:i + taille] for i in range(0, len(en_groupe), taille)]
    n = 0
    while file:
        g = file.pop(0)
        n += 1
        res, reste, rc = groupe(g, n)
        if not res:
            print(f"groupe {n} : rien n'a démarré (code {rc}), voir {SORTIES}/_groupe_{n}.log ; séries lancées seules")
            a_part.extend(g)
            continue
        for sid, (bad, dur) in res.items():
            final[sid] = (bad, dur, "groupe")
            if bad:
                a_relancer.append(sid)
        if reste:
            file.insert(0, reste)
    for sid in a_part:
        bad, dur = seule(sid)
        final[sid] = (bad, dur, "seule")
    sauvees = []
    for sid in a_relancer:
        avant = final[sid][0]
        bad, dur = seule(sid)
        final[sid] = (bad, dur, "relancée seule")
        if not bad:
            sauvees.append((sid, avant[0] if avant else ""))
    with open(DUREES, "a") as f:
        for sid, (bad, dur, how) in final.items():
            if dur:
                f.write(f"{sid} {dur:.0f} {how}\n")
    echecs = {sid: v for sid, v in final.items() if v[0]}
    for sid in ids:
        if sid in echecs:
            bad, dur, how = echecs[sid]
            print(f"ÉCHEC {sid} ({how}) : " + " | ".join(bad[:4]))
    for sid, why in sauvees:
        print(f"seule ok, en groupe non : {sid} ({why[:120]})")
    mins = (time.time() - t_start) / 60
    print(f"BILAN {len(final)} série(s), {len(final) - len(echecs)} ok, {len(echecs)} échec(s), "
          f"{len(sauvees)} sauvée(s) seule(s), {n} groupe(s), {mins:.0f} min")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
