extends RefCounted
## V147 : le Menteur (les dés menteurs), la règle et les adversaires. Chaque joueur a trois dés cachés
## sous son gobelet. À tour de rôle, on annonce combien il y a de dés d'une face sur TOUTE la table
## (« trois 5 ») ; chacun doit monter (plus de dés, ou autant d'une face plus haute), ou crier
## « Menteur ! ». On soulève les gobelets : si l'annonce était vraie, celui qui a crié perd un dé ; sinon,
## c'est le menteur. Qui n'a plus de dé quitte la partie ; le dernier qui en a gagne le pot.
## Les adversaires ont leur caractère : la prudence (crier tôt ou tard), le bluff (annoncer une face
## qu'ils n'ont pas), et un peu de hasard.

var joueurs: Array = []           # {id, nom, des: Array, humain, prudence, bluff, alea}
var tour: int = 0                 # l'indice du joueur qui doit parler
var enchere: Dictionary = {}      # {q, f, par} (vide en début de manche)
var manche: int = 0
var rng := RandomNumberGenerator.new()
var journal: Array = []           # ce qui s'est passé (pour l'écran)


func _init(specs: Array, n_des: int = 3, graine: int = -1) -> void:
	if graine >= 0:
		rng.seed = graine
	else:
		rng.randomize()
	for s in specs:
		var j: Dictionary = (s as Dictionary).duplicate(true)
		j["n"] = n_des
		j["des"] = []
		if not j.has("prudence"):
			j["prudence"] = 0.5
		if not j.has("bluff"):
			j["bluff"] = 0.3
		if not j.has("alea"):
			j["alea"] = 0.1
		joueurs.append(j)


func actifs() -> Array:
	var out: Array = []
	for i in range(joueurs.size()):
		if int(joueurs[i]["n"]) > 0:
			out.append(i)
	return out


func fini() -> bool:
	return actifs().size() <= 1


func gagnant() -> int:
	var a: Array = actifs()
	return int(a[0]) if a.size() == 1 else -1


func total_des() -> int:
	var t: int = 0
	for j in joueurs:
		t += int(j["n"])
	return t


## Une nouvelle manche : chacun secoue son gobelet ; « premier » commence.
func nouvelle_manche(premier: int = -1) -> void:
	manche += 1
	enchere = {}
	for j in joueurs:
		var d: Array = []
		for k in range(int(j["n"])):
			d.append(rng.randi_range(1, 6))
		d.sort()
		j["des"] = d
	if premier >= 0 and int(joueurs[premier]["n"]) > 0:
		tour = premier
	elif int(joueurs[tour]["n"]) <= 0:
		tour = _suivant(tour)


func _suivant(i: int) -> int:
	for k in range(1, joueurs.size() + 1):
		var j: int = (i + k) % joueurs.size()
		if int(joueurs[j]["n"]) > 0:
			return j
	return i


## L'annonce est-elle permise ?
func valide(q: int, f: int) -> bool:
	if f < 1 or f > 6 or q < 1 or q > total_des():
		return false
	if enchere.is_empty():
		return true
	var q0: int = int(enchere["q"])
	var f0: int = int(enchere["f"])
	return q > q0 or (q == q0 and f > f0)


## La plus petite annonce permise pour la face « f » (0 si aucune).
func min_q(f: int) -> int:
	if enchere.is_empty():
		return 1
	var q0: int = int(enchere["q"])
	var q: int = q0 if f > int(enchere["f"]) else q0 + 1
	return q if q <= total_des() else 0


func annoncer(q: int, f: int) -> bool:
	if not valide(q, f):
		return false
	enchere = {"q": q, "f": f, "par": tour}
	journal.append({"quoi": "annonce", "qui": tour, "q": q, "f": f})
	tour = _suivant(tour)
	return true


func compte(f: int) -> int:
	var c: int = 0
	for j in joueurs:
		for v in j["des"]:
			if int(v) == f:
				c += 1
	return c


## « Menteur ! » (le joueur dont c'est le tour, sur l'annonce d'avant) : on compte ; le perdant perd un
## dé et commence la manche suivante (ou son voisin, s'il est éliminé).
func menteur() -> Dictionary:
	if enchere.is_empty():
		return {}
	var crieur: int = tour
	var par: int = int(enchere["par"])
	var c: int = compte(int(enchere["f"]))
	var vraie: bool = c >= int(enchere["q"])
	var perdant: int = crieur if vraie else par
	joueurs[perdant]["n"] = int(joueurs[perdant]["n"]) - 1
	var res := {"crieur": crieur, "par": par, "q": int(enchere["q"]), "f": int(enchere["f"]), "compte": c, "vraie": vraie, "perdant": perdant,
		"elimine": int(joueurs[perdant]["n"]) <= 0}
	journal.append({"quoi": "menteur"}.merged(res))
	tour = perdant if int(joueurs[perdant]["n"]) > 0 else _suivant(perdant)
	return res


# =================================================================== les adversaires

## P(au moins k succès sur n tirages à 1/6)
static func p_au_moins(k: int, n: int) -> float:
	if k <= 0:
		return 1.0
	if k > n:
		return 0.0
	var p: float = 1.0 / 6.0
	var s: float = 0.0
	for x in range(k, n + 1):
		s += _comb(n, x) * pow(p, x) * pow(1.0 - p, n - x)
	return clampf(s, 0.0, 1.0)


static func _comb(n: int, k: int) -> float:
	var r: float = 1.0
	for i in range(1, k + 1):
		r = r * (n - k + i) / i
	return r


## La chance (vue du joueur « i ») que l'annonce (q, f) soit vraie.
func chance(i: int, q: int, f: int) -> float:
	var mine: int = 0
	for v in joueurs[i]["des"]:
		if int(v) == f:
			mine += 1
	return p_au_moins(q - mine, total_des() - int(joueurs[i]["n"]))


## Ce que décide l'adversaire « i » : {"menteur": true} ou {"q", "f", "bluff"}.
func decider(i: int) -> Dictionary:
	var j: Dictionary = joueurs[i]
	var prud: float = float(j["prudence"])
	var bluff: float = float(j["bluff"])
	var alea: float = float(j["alea"])
	if not enchere.is_empty():
		var p: float = chance(i, int(enchere["q"]), int(enchere["f"]))
		var seuil: float = lerpf(0.22, 0.5, prud) + rng.randf_range(-alea, alea)
		if p < seuil:
			return {"menteur": true}
	# monter : pour chaque face, la plus petite annonce ; on garde la plus sûre (ou, en bluffant, une
	# face qu'on n'a pas, pour égarer les autres)
	var best: Dictionary = {}
	var best_p: float = -1.0
	var bluffe: bool = rng.randf() < bluff
	for f in range(1, 7):
		var q: int = min_q(f)
		if q <= 0:
			continue
		var p2: float = chance(i, q, f)
		var mine: int = 0
		for v in j["des"]:
			if int(v) == f:
				mine += 1
		var score: float = p2 + rng.randf_range(-alea, alea)
		if bluffe and mine == 0:
			score += 0.25
		if score > best_p:
			best_p = score
			best = {"q": q, "f": f, "bluff": mine == 0, "p": p2}
	if best.is_empty():
		return {"menteur": true}
	if not enchere.is_empty() and float(best["p"]) < 0.18 and rng.randf() > bluff * 0.5:
		return {"menteur": true}
	return best
