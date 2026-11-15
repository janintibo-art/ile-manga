extends RefCounted
## V148 : le blackjack du Tripot de la Dame de Pique, la règle. Un sabot de quatre jeux (on le rebat
## quand il en reste moins d'un quart). Chacun reçoit deux cartes, la donneuse aussi (l'une cachée).
## On tire tant qu'on veut ; au-dessus de 21, on « saute ». On peut doubler sur ses deux premières cartes
## (on double la mise, on reçoit une seule carte). La donneuse tire jusqu'à 17 (elle s'arrête sur tous les
## 17). Le blackjack (un as et une figure ou un dix, en deux cartes) paie trois pour deux ; une main
## gagnante paie un pour un ; l'égalité rend la mise.
## Les autres joueurs de la table (Gédéon, Fanchon) jouent « à la règle » (la stratégie de base, à peu près).

const Cartes = preload("res://scripts/cartes_v148.gd")

var sabot: Array = []
var rng := RandomNumberGenerator.new()
var jeux: int = 4


func _init(graine: int = -1, n_jeux: int = 4) -> void:
	jeux = n_jeux
	if graine >= 0:
		rng.seed = graine
	else:
		rng.randomize()
	rebattre()


func rebattre() -> void:
	sabot.clear()
	for j in range(jeux):
		for c in range(4):
			for r in range(1, 14):
				sabot.append({"r": r, "c": c})
	# Fisher-Yates
	for i in range(sabot.size() - 1, 0, -1):
		var k: int = rng.randi_range(0, i)
		var t: Variant = sabot[i]
		sabot[i] = sabot[k]
		sabot[k] = t


func a_rebattre() -> bool:
	return sabot.size() < jeux * 13


func tirer() -> Dictionary:
	if sabot.is_empty():
		rebattre()
	return sabot.pop_back()


static func points(r: int) -> int:
	return 11 if r == 1 else mini(r, 10)


## [total, souple] : souple, si un as compte encore pour 11.
static func valeur(main: Array) -> Array:
	var t: int = 0
	var as_n: int = 0
	for c in main:
		var r: int = int(c["r"])
		if r == 1:
			as_n += 1
		t += points(r)
	while t > 21 and as_n > 0:
		t -= 10
		as_n -= 1
	return [t, as_n > 0]


static func total(main: Array) -> int:
	return int(valeur(main)[0])


static func blackjack(main: Array) -> bool:
	return main.size() == 2 and total(main) == 21


static func saute(main: Array) -> bool:
	return total(main) > 21


## La donneuse tire-t-elle encore ? (jusqu'à 17, et elle s'arrête sur tous les 17)
static func donneuse_tire(main: Array) -> bool:
	return total(main) < 17


## Le gain (en multiple de la mise, déjà retirée) : 0 perdu, 1 égalité, 2 gagné, 2.5 blackjack.
static func reglement(joueur: Array, donneuse: Array) -> float:
	var bj_j: bool = blackjack(joueur)
	var bj_d: bool = blackjack(donneuse)
	if saute(joueur):
		return 0.0
	if bj_j and not bj_d:
		return 2.5
	if bj_d and not bj_j:
		return 0.0
	if saute(donneuse):
		return 2.0
	var tj: int = total(joueur)
	var td: int = total(donneuse)
	if tj > td:
		return 2.0
	if tj == td:
		return 1.0
	return 0.0


## La stratégie de base (simplifiée) d'un joueur : « tirer », « rester » ou « doubler » ; « visible » : la
## carte montrée de la donneuse. « audace » : un peu de fantaisie (0 : à la règle).
static func conseil(main: Array, visible: Dictionary, audace: float = 0.0, r: float = 0.5) -> String:
	var v: Array = valeur(main)
	var t: int = int(v[0])
	var souple: bool = bool(v[1])
	var d: int = points(int(visible["r"]))
	var deux: bool = main.size() == 2
	if souple:
		if t >= 19:
			return "rester"
		if t == 18:
			return "rester" if d <= 8 else "tirer"
		if deux and t >= 15 and d >= 4 and d <= 6:
			return "doubler"
		return "tirer"
	if t >= 17:
		return "tirer" if r < audace * 0.15 and t == 17 else "rester"
	if t <= 8:
		return "tirer"
	if t == 11 or (t == 10 and d <= 9):
		return "doubler" if deux else "tirer"
	if t == 9:
		return "doubler" if deux and d >= 3 and d <= 6 else "tirer"
	if t >= 13 and d <= 6:
		return "tirer" if r < audace * 0.3 else "rester"
	if t == 12 and d >= 4 and d <= 6:
		return "rester"
	return "tirer"


static func texte_main(main: Array) -> String:
	var s: Array = []
	for c in main:
		s.append(Cartes.nom(c))
	return " ".join(s)
