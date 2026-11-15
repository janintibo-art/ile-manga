extends RefCounted
## V149 : le poker de Pile-ou-Face, la règle (deux jeux, au choix du joueur) :
##  - le Texas Hold'em (au Saloon du Chien qui Mise) : deux cartes cachées chacun, cinq cartes communes
##    (le flop, trois ; le tournant, une ; la rivière, une) ; les petite et grosse blindes ;
##  - le poker à cinq cartes, avec échange (au Terrier, derrière le barbier) : une mise d'entrée (l'ante),
##    cinq cartes cachées, un tour d'enchères, on échange jusqu'à trois cartes (quatre, si l'on garde un as),
##    un second tour, et l'on abat.
## Les enchères sont « à limite fixe » : on suit, on relance d'un montant fixé (petit au début, gros à la
## fin), trois relances au plus par tour. La meilleure combinaison de cinq cartes gagne le pot (partagé en
## cas d'égalité).
## Les adversaires ont leur caractère (prudence, bluff, un peu de hasard) et jugent leur main en simulant
## des donnes au hasard (la méthode de Monte-Carlo, quelques dizaines de fois).

const COMBINAISONS := ["Hauteur", "Une paire", "Deux paires", "Brelan", "Quinte", "Couleur", "Full", "Carré", "Quinte flush"]
const MAX_RELANCES := 3

var mode: String = "holdem"       # « holdem » ou « cinq »
var joueurs: Array = []           # {id, nom, cartes, couche, mise_tour, total, humain, prudence, bluff, alea, a_parle}
var communes: Array = []
var pot: int = 0
var mise_courante: int = 0
var relances: int = 0
var etape: int = 0                # holdem : 0 préflop, 1 flop, 2 tournant, 3 rivière ; cinq : 0 avant, 1 après l'échange
var tour: int = 0
var donneur: int = 0
var paquet: Array = []
var petite: int = 1               # la mise d'un tour (petite : les premiers tours ; grosse : les derniers)
var grosse: int = 2
var journal: Array = []
var rng := RandomNumberGenerator.new()


func _init(specs: Array, mode_: String = "holdem", graine: int = -1) -> void:
	mode = mode_
	if graine >= 0:
		rng.seed = graine
	else:
		rng.randomize()
	for s in specs:
		var j: Dictionary = (s as Dictionary).duplicate(true)
		j["cartes"] = []
		j["couche"] = false
		j["mise_tour"] = 0
		j["total"] = 0
		j["a_parle"] = false
		for k in [["prudence", 0.5], ["bluff", 0.15], ["alea", 0.08]]:
			if not j.has(k[0]):
				j[k[0]] = k[1]
		joueurs.append(j)


# =================================================================== les cartes et les combinaisons

static func nouveau_paquet(r: RandomNumberGenerator) -> Array:
	var p: Array = []
	for c in range(4):
		for v in range(1, 14):
			p.append({"r": v, "c": c})
	for i in range(p.size() - 1, 0, -1):
		var k: int = r.randi_range(0, i)
		var t: Variant = p[i]
		p[i] = p[k]
		p[k] = t
	return p


static func _haut(r: int) -> int:
	return 14 if r == 1 else r


## La valeur d'une main de cinq cartes : [combinaison, départages…] (on compare dans l'ordre).
static func valeur5(m: Array) -> Array:
	var rs: Array = []
	var couleurs: Dictionary = {}
	var compte: Dictionary = {}
	for c in m:
		var h: int = _haut(int(c["r"]))
		rs.append(h)
		couleurs[int(c["c"])] = true
		compte[h] = int(compte.get(h, 0)) + 1
	rs.sort()
	rs.reverse()
	var flush: bool = couleurs.size() == 1 and m.size() >= 5
	var uniques: Array = compte.keys()
	uniques.sort()
	uniques.reverse()
	var quinte: int = 0
	if uniques.size() == 5:
		if int(uniques[0]) - int(uniques[4]) == 4:
			quinte = int(uniques[0])
		elif uniques == [14, 5, 4, 3, 2]:
			quinte = 5
	if quinte > 0 and flush:
		return [8, quinte]
	# les groupes, du plus gros au plus haut
	var groupes: Array = []
	for h in compte:
		groupes.append([int(compte[h]), int(h)])
	groupes.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	var ordre: Array = []
	for g in groupes:
		ordre.append(g[1])
	# V155 : moins de cinq cartes (deux cartes avant le flop, une paire en main) : un seul groupe
	groupes.append([0, 0])
	if int(groupes[0][0]) == 4:
		return [7] + ordre
	if int(groupes[0][0]) == 3 and int(groupes[1][0]) == 2:
		return [6] + ordre
	if flush:
		return [5] + rs
	if quinte > 0:
		return [4, quinte]
	if int(groupes[0][0]) == 3:
		return [3] + ordre
	if int(groupes[0][0]) == 2 and int(groupes[1][0]) == 2:
		return [2] + ordre
	if int(groupes[0][0]) == 2:
		return [1] + ordre
	return [0] + rs


static func compare(a: Array, b: Array) -> int:
	for i in range(mini(a.size(), b.size())):
		if int(a[i]) != int(b[i]):
			return 1 if int(a[i]) > int(b[i]) else -1
	return 0


## La meilleure main de cinq cartes parmi 5 à 7 cartes : [valeur, les cinq cartes].
static func meilleure(cartes: Array) -> Array:
	if cartes.size() <= 5:
		return [valeur5(cartes), cartes]
	var best: Array = []
	var best_m: Array = []
	var n: int = cartes.size()
	# on écarte (n - 5) cartes de toutes les façons
	for a in range(n):
		for b in range(a + 1, n) if n == 7 else [-1]:
			var m: Array = []
			for k in range(n):
				if k != a and k != b:
					m.append(cartes[k])
			if m.size() != 5:
				continue
			var v: Array = valeur5(m)
			if best.is_empty() or compare(v, best) > 0:
				best = v
				best_m = m
	return [best, best_m]


static func nom_combinaison(v: Array) -> String:
	return str(COMBINAISONS[int(v[0])])


# =================================================================== une main

func actifs() -> Array:
	var out: Array = []
	for i in range(joueurs.size()):
		if not bool(joueurs[i]["couche"]):
			out.append(i)
	return out


func _suivant(i: int) -> int:
	for k in range(1, joueurs.size() + 1):
		var j: int = (i + k) % joueurs.size()
		if not bool(joueurs[j]["couche"]):
			return j
	return i


func taille() -> int:
	if mode == "holdem":
		return petite if etape <= 1 else grosse
	return petite if etape == 0 else grosse


## Une nouvelle main : on bat, on donne ; les blindes (holdem) ou l'ante (cinq) ; « donneur » tourne.
func nouvelle_main(ante: int = 1) -> void:
	paquet = nouveau_paquet(rng)
	communes = []
	pot = 0
	etape = 0
	journal = []
	for j in joueurs:
		j["cartes"] = []
		j["couche"] = false
		j["mise_tour"] = 0
		j["total"] = 0
		j["a_parle"] = false
	donneur = (donneur + 1) % joueurs.size()
	var n_cartes: int = 2 if mode == "holdem" else 5
	for k in range(n_cartes):
		for i in range(joueurs.size()):
			(joueurs[(donneur + 1 + i) % joueurs.size()]["cartes"] as Array).append(paquet.pop_back())
	_debut_tour()
	if mode == "holdem":
		var sb: int = (donneur + 1) % joueurs.size()
		var bb: int = (donneur + 2) % joueurs.size()
		_mettre(sb, petite / 2 if petite >= 2 else 1)
		_mettre(bb, petite)
		mise_courante = petite
		tour = (donneur + 3) % joueurs.size()
	else:
		for i in range(joueurs.size()):
			_mettre(i, ante)
			joueurs[i]["mise_tour"] = 0
		mise_courante = 0
		tour = (donneur + 1) % joueurs.size()


func _mettre(i: int, n: int) -> void:
	joueurs[i]["mise_tour"] = int(joueurs[i]["mise_tour"]) + n
	joueurs[i]["total"] = int(joueurs[i]["total"]) + n
	pot += n


func _debut_tour() -> void:
	mise_courante = 0
	relances = 0
	for j in joueurs:
		j["mise_tour"] = 0
		j["a_parle"] = false


func a_suivre(i: int) -> int:
	return maxi(0, mise_courante - int(joueurs[i]["mise_tour"]))


func peut_relancer() -> bool:
	return relances < MAX_RELANCES


## Une action du joueur dont c'est le tour : « coucher », « suivre » (ou parler, s'il n'y a rien à
## suivre), « relancer ». Rend ce qu'il a mis au pot.
func agir(action: String) -> int:
	var i: int = tour
	var mis: int = 0
	match action:
		"coucher":
			if a_suivre(i) == 0:
				action = "suivre"
			else:
				joueurs[i]["couche"] = true
		"relancer":
			if not peut_relancer():
				action = "suivre"
	if action == "suivre":
		mis = a_suivre(i)
		_mettre(i, mis)
	elif action == "relancer":
		mis = a_suivre(i) + taille()
		_mettre(i, mis)
		mise_courante = int(joueurs[i]["mise_tour"])
		relances += 1
		for j in joueurs:
			j["a_parle"] = false
	joueurs[i]["a_parle"] = true
	journal.append({"qui": i, "action": action, "mis": mis})
	tour = _suivant(i)
	return mis


## Le tour d'enchères est-il fini ? (tout le monde a parlé et a suivi, ou il ne reste qu'un joueur)
func tour_fini() -> bool:
	var a: Array = actifs()
	if a.size() <= 1:
		return true
	for i in a:
		if not bool(joueurs[i]["a_parle"]) or int(joueurs[i]["mise_tour"]) < mise_courante:
			return false
	return true


## L'étape suivante (holdem : le flop, le tournant, la rivière ; cinq : après l'échange). Rend false
## quand il n'y a plus d'étape (on abat).
func etape_suivante() -> bool:
	if actifs().size() <= 1:
		return false
	etape += 1
	if mode == "holdem":
		if etape > 3:
			return false
		var n: int = 3 if etape == 1 else 1
		for k in range(n):
			communes.append(paquet.pop_back())
	elif etape > 1:
		return false
	_debut_tour()
	tour = _suivant(donneur)
	return true


## Échanger des cartes (cinq) : « indices » des cartes qu'on jette.
func echanger(i: int, indices: Array) -> void:
	var c: Array = joueurs[i]["cartes"]
	var neuves: Array = []
	for k in range(c.size()):
		if k in indices:
			neuves.append(paquet.pop_back())
		else:
			neuves.append(c[k])
	joueurs[i]["cartes"] = neuves


func max_echange(i: int) -> int:
	for c in joueurs[i]["cartes"]:
		if int(c["r"]) == 1:
			return 4
	return 3


func main_de(i: int) -> Array:
	return (joueurs[i]["cartes"] as Array) + communes


## L'abattage : [les gagnants (indices), leur valeur, les valeurs de chacun].
func abattage() -> Array:
	var a: Array = actifs()
	var vals: Dictionary = {}
	var best: Array = []
	var gagnants: Array = []
	for i in a:
		var v: Array = meilleure(main_de(i))[0]
		vals[i] = v
		var c: int = 1 if best.is_empty() else compare(v, best)
		if c > 0:
			best = v
			gagnants = [i]
		elif c == 0:
			gagnants.append(i)
	return [gagnants, best, vals]


# =================================================================== les adversaires

## La force de la main de « i » : la chance de battre les autres (Monte-Carlo).
func force(i: int, essais: int = 40) -> float:
	var adv: int = actifs().size() - 1
	if adv <= 0:
		return 1.0
	var miennes: Array = joueurs[i]["cartes"]
	var connues: Dictionary = {}
	for c in miennes + communes:
		connues["%d_%d" % [int(c["r"]), int(c["c"])]] = true
	var reste: Array = []
	for c2 in range(4):
		for v in range(1, 14):
			if not connues.has("%d_%d" % [v, c2]):
				reste.append({"r": v, "c": c2})
	var gagne: float = 0.0
	var n_main: int = 2 if mode == "holdem" else 5
	for e in range(essais):
		# un tirage au hasard du reste (on mélange juste ce qu'il faut)
		var besoin: int = adv * n_main + (5 - communes.size() if mode == "holdem" else 0)
		for k in range(besoin):
			var j: int = rng.randi_range(k, reste.size() - 1)
			var t: Variant = reste[k]
			reste[k] = reste[j]
			reste[j] = t
		var pos: int = 0
		var board: Array = communes.duplicate()
		if mode == "holdem":
			while board.size() < 5:
				board.append(reste[pos])
				pos += 1
		var moi: Array = meilleure(miennes + board)[0]
		var ok: float = 1.0
		for a in range(adv):
			var lui: Array = []
			for k2 in range(n_main):
				lui.append(reste[pos])
				pos += 1
			var c: int = compare(moi, meilleure(lui + board)[0])
			if c < 0:
				ok = 0.0
				break
			elif c == 0:
				ok *= 0.5
		gagne += ok
	return gagne / essais


## Ce que fait l'adversaire « i » : « coucher », « suivre » ou « relancer » (et la force estimée).
func decider(i: int) -> Array:
	var j: Dictionary = joueurs[i]
	var f: float = force(i, 36)
	var prud: float = float(j["prudence"])
	var alea: float = float(j["alea"])
	var n: float = float(actifs().size())
	var juste: float = 1.0 / n                      # la part « honnête » du pot
	var du: int = a_suivre(i)
	var cote: float = float(du) / float(pot + du) if du > 0 else 0.0
	var x: float = f + rng.randf_range(-alea, alea)
	if x > juste * (1.6 + prud * 0.8) and peut_relancer():
		return ["relancer", f]
	if rng.randf() < float(j["bluff"]) * 0.35 and peut_relancer() and relances == 0:
		return ["relancer", f]
	if du == 0:
		return ["suivre", f]
	if x >= cote * (1.0 + prud * 0.6) or x > juste * 0.9:
		return ["suivre", f]
	return ["coucher", f]


## Les cartes que jette l'adversaire « i » (cinq) : il garde ses paires, ses brelans ; sinon ses plus
## hautes ; il garde tout avec une quinte, une couleur, un full.
func a_jeter(i: int) -> Array:
	var c: Array = joueurs[i]["cartes"]
	var v: Array = valeur5(c)
	if int(v[0]) >= 4:
		return []
	var compte: Dictionary = {}
	for x in c:
		compte[_haut(int(x["r"]))] = int(compte.get(_haut(int(x["r"])), 0)) + 1
	var jeter: Array = []
	if int(v[0]) >= 1:
		for k in range(c.size()):
			if int(compte[_haut(int(c[k]["r"]))]) < 2:
				jeter.append(k)
	else:
		# rien : on garde les deux plus hautes (ou un as seul et l'on en jette quatre)
		var idx: Array = range(c.size())
		idx.sort_custom(func(a, b): return _haut(int(c[a]["r"])) > _haut(int(c[b]["r"])))
		var garder: int = 1 if _haut(int(c[idx[0]]["r"])) == 14 else 2
		for k2 in range(garder, idx.size()):
			jeter.append(idx[k2])
	if jeter.size() > max_echange(i):
		jeter = jeter.slice(0, max_echange(i))
	return jeter
