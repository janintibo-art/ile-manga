extends Node
## V120 : la popularité. Chaque île (et chaque monde de Hautefond) se souvient de ce que le joueur
## y a fait : les quêtes et les exploits, la gentillesse (cadeaux, aide, soin des bêtes) la font
## monter ; frapper quelqu'un, casser des choses sous les yeux des gens, se faire mettre dehors
## la font baisser. Une part de la renommée voyage d'île en île (les bonnes nouvelles vont vite ;
## les mauvaises restent sur place).
## Ses effets : les saluts des habitants et des passants, les prix des boutiques (de -15 % à +25 %),
## les portes (mal vu : certaines restent closes ; populaire : on est invité chez les gens).
## L'état est rangé dans la sauvegarde du carnet de quêtes (journal_v56 : « pop »).

const Langue = preload("res://scripts/langue_v104.gd")

## Les régions : id -> nom (avec son article, pour les phrases).
const REGIONS := {
	"village": "l'Île du village", "jungle": "l'île de la jungle", "elfes": "le Bois-Doré", "nains": "Forgefer",
	"ciel": "l'île flottante", "atlantide": "l'Atlantide", "azur": "Port-Azur", "fees": "le royaume des fées",
	"carene": "Carène", "tazira": "Tazira", "cliquetis": "Cliquetis", "ramure": "Ramure", "grande": "la grande île de l'est",
	"arcanelle": "Arcanelle", "balafre": "la Balafre", "soleils": "l'Île des Trois Soleils", "braise": "l'Île de Braise",
	"montjoie": "Montjoie", "boucan": "Port-Boucan", "astralys": "Astralys", "moai": "l'Île aux Moaïs",
	"pixel": "l'Île Pixelithique", "larsen": "l'Île de Larsen", "neo": "Néopolis", "pasta": "l'Île Al Dente",
	"crayon": "l'Île Crayonnée", "hautefond": "Hautefond", "nuees": "la Cité des Nuées", "strates": "les Strates",
	"fronde": "la Fronde", "dome": "le Dôme d'Azur",
}
## Le nom court (pour le carnet).
const COURTS := {
	"village": "Île du village", "jungle": "Jungle", "elfes": "Bois-Doré", "nains": "Forgefer", "ciel": "Île flottante",
	"atlantide": "Atlantide", "azur": "Port-Azur", "fees": "Royaume des fées", "carene": "Carène", "tazira": "Tazira",
	"cliquetis": "Cliquetis", "ramure": "Ramure", "grande": "Grande île de l'est", "arcanelle": "Arcanelle",
	"balafre": "La Balafre", "soleils": "Trois Soleils", "braise": "Île de Braise", "montjoie": "Montjoie",
	"boucan": "Port-Boucan", "astralys": "Astralys", "moai": "Île aux Moaïs", "pixel": "Île Pixelithique",
	"larsen": "Île de Larsen", "neo": "Néopolis", "pasta": "Île Al Dente", "crayon": "Île Crayonnée",
	"hautefond": "Hautefond", "nuees": "Cité des Nuées", "strates": "Les Strates", "fronde": "La Fronde", "dome": "Dôme d'Azur",
}
## Les groupes d'habitants qui ne portent pas le nom de leur région.
const GROUPES := {"fees_ygg": "fees", "teuf": "village"}

## Les niveaux : [seuil (inclus), nom, facteur des prix, couleur du carnet]
const NIVEAUX := [
	[-100, "Mauvaise réputation", 1.25, "#e0605a"],
	[-39, "Méfiance", 1.10, "#e0a05a"],
	[-9, "Visage nouveau", 1.0, "#b8c4cc"],
	[10, "Sympathique", 0.95, "#9fd27a"],
	[35, "Populaire", 0.90, "#7ad2b8"],
	[70, "Légende locale", 0.85, "#ffd27a"],
]

## Ce qui fait bouger la popularité (points).
const GAINS := {
	"quete": 8, "quete_habitant": 6, "bonne_action": 5, "cadeau_aime": 3, "cadeau": 1, "cadeau_deteste": -1,
	"animal": 2, "frappe": -6, "casse": -2, "dehors": -3,
}

## Les saluts selon le niveau (les « Visage nouveau » n'en ont pas : rien de spécial).
const SALUTS := [
	["Hmm. C'est toi. On a entendu parler de toi, et pas en bien.", "Ah. Toi. Je t'ai à l'œil, sache-le.", "Encore toi… Tiens-toi tranquille, cette fois.",
		"Tout le monde parle de toi ici. Et personne n'en dit du bien.", "Garde tes distances, veux-tu ? On sait ce que tu as fait."],
	["Oh. Bonjour… On m'a raconté des choses sur toi. J'espère qu'elles sont fausses.", "Tiens, te voilà. On ne sait pas trop quoi penser de toi, ici.",
		"Bonjour. Pas de bêtises, d'accord ?", "Ah, c'est toi… On t'observe, tu sais. Montre-nous ce que tu vaux."],
	[],
	["Oh, bonjour toi ! Ça fait plaisir de te voir.", "Tiens, te revoilà ! On dit du bien de toi, tu sais.", "Salut ! Il paraît que tu donnes un coup de main à tout le monde.",
		"Bonjour ! Ta réputation te précède… et elle est bonne !"],
	["Oh ! C'est toi ! Tout le monde parle de toi, ici !", "Te voilà ! On t'aime bien, par ici, tu sais.", "Ah, notre ami ! Passe me voir chez moi quand tu veux, la porte est ouverte.",
		"Hé, c'est toi ! Les enfants parlent de toi à l'école, figure-toi !", "Bonjour bonjour ! Quelle joie de te voir !"],
	["C'est… c'est vraiment toi ? Oh, quel honneur !", "Notre héros ! Tout le monde ici te doit quelque chose.", "Oh ! Je vais pouvoir raconter que je t'ai parlé !",
		"Te voilà enfin ! On a même donné ton nom à un gâteau, tu sais ?", "Bienvenue, bienvenue ! Ici, tu es chez toi, pour toujours."],
]

## Ce qu'on annonce quand on change de niveau (en montant / en descendant).
const MONTEE := [
	"", "",
	"On commence à te pardonner, à %s.",
	"À %s, les gens t'ont à la bonne : les commerçants te font -5 %%.",
	"Tu es populaire à %s ! Les habitants t'invitent chez eux, et les boutiques te font -10 %%.",
	"Tu es une légende à %s ! Partout, on t'accueille à bras ouverts (-15 %% dans les boutiques).",
]
const DESCENTE := [
	"Tu as mauvaise réputation à %s : des portes restent closes, et les prix grimpent (+25 %%).",
	"On se méfie de toi à %s : les commerçants te font payer plus cher (+10 %%).",
	"À %s, on ne sait plus trop quoi penser de toi.",
	"À %s, on t'aime un peu moins qu'avant.",
	"À %s, ta légende s'effrite un peu.",
	"",
]

static var points: Dictionary = {}          # région -> points (-100 … 100)
static var renommee: float = 0.0            # tout le bien qu'on a fait, partout (l'écho)
static var _cadeaux: Dictionary = {}        # id habitant -> heure de jeu du dernier cadeau compté
static var main_ref: Node = null
static var parle_a: Node = null             # l'habitant à qui l'on parle (pour son salut)


func setup(m: Node) -> void:
	main_ref = m


# =================================================================== état

static func charger(d: Variant) -> void:
	points = {}
	renommee = 0.0
	_cadeaux = {}
	if d is Dictionary:
		var p: Variant = (d as Dictionary).get("points", {})
		if p is Dictionary:
			for k in p:
				points[str(k)] = clampf(float(p[k]), -100.0, 100.0)
		renommee = float((d as Dictionary).get("renommee", 0.0))


static func sauver() -> Dictionary:
	return {"points": points.duplicate(), "renommee": renommee}


## La popularité d'une région : ce qu'on y a fait, plus l'écho de la renommée (jusqu'à +15).
static func valeur(r: String) -> float:
	if r == "":
		return 0.0
	return clampf(float(points.get(r, 0.0)) + clampf(renommee * 0.12, 0.0, 15.0), -100.0, 100.0)


static func niveau_de(v: float) -> int:
	var n: int = 0
	for i in range(NIVEAUX.size()):
		if v >= float(NIVEAUX[i][0]):
			n = i
	return n


static func niveau(r: String) -> int:
	return niveau_de(valeur(r)) if r != "" else 2


static func nom_niveau(r: String) -> String:
	return str(NIVEAUX[niveau(r)][1])


static func nom(r: String) -> String:
	return str(REGIONS.get(r, r))


## Le facteur des prix dans une région (1.25 … 0.85).
static func prix_facteur(r: String) -> float:
	return float(NIVEAUX[niveau(r)][2])


static func prix(base: int, r: String) -> int:
	if base <= 0:
		return base
	return maxi(1, int(round(float(base) * prix_facteur(r))))


# =================================================================== faire bouger

## Ajoute (ou retire) des points dans une région ; annonce un changement de niveau.
static func change(r: String, delta: float, pourquoi: String = "") -> void:
	if r == "" or not REGIONS.has(r) or delta == 0.0:
		return
	var avant: int = niveau(r)
	points[r] = clampf(float(points.get(r, 0.0)) + delta, -100.0, 100.0)
	if delta > 0.0:
		renommee = minf(renommee + delta, 400.0)
	var apres: int = niveau(r)
	if main_ref == null or not is_instance_valid(main_ref):
		return
	var txt: String = ""
	if apres > avant and str(MONTEE[apres]) != "":
		txt = Langue.t(str(MONTEE[apres])) % Langue.t(nom(r))
	elif apres < avant and str(DESCENTE[apres]) != "":
		txt = Langue.t(str(DESCENTE[apres])) % Langue.t(nom(r))
	else:
		txt = Langue.t("Popularité à %s : %s (%s)") % [Langue.t(nom(r)), ("+%d" % int(round(delta))) if delta > 0.0 else str(int(round(delta))), Langue.t(str(NIVEAUX[apres][1]))]
	if main_ref.has_method("_show_message_v28"):
		main_ref._show_message_v28(txt)
	if apres != avant and main_ref.has_method("sfx"):
		main_ref.sfx("ui_quete" if apres > avant else "ui_erreur")


static func gagne(r: String, quoi: String) -> void:
	change(r, float(GAINS.get(quoi, 0)), quoi)


## Un cadeau à un habitant ne compte qu'une fois par heure de jeu (pas de cadeaux à la chaîne).
static func cadeau(npc: Node, quoi: String) -> void:
	if npc == null:
		return
	var id: String = str((npc.get("profile") as Dictionary).get("id", npc.name)) if npc.get("profile") is Dictionary else str(npc.name)
	var now: float = _now()
	if _cadeaux.has(id) and now - float(_cadeaux[id]) < 3600.0:
		return
	_cadeaux[id] = now
	gagne(region_npc(npc), quoi)


static func _now() -> float:
	if main_ref != null and is_instance_valid(main_ref) and main_ref.get("game_menu") != null:
		return float(main_ref.game_menu.seconds)
	return float(Time.get_ticks_msec()) / 1000.0


## Après une réplique d'un habitant (main._brain_reply_v48, l'échange a réussi).
static func after_reply(r: Dictionary, npc: Node) -> void:
	if npc == null:
		return
	var reg: String = region_npc(npc)
	if r.has("_fin56"):
		gagne(reg, "quete")
	var p: Variant = r.get("_pop120", "")
	if str(p) == "":
		return
	if str(p).begins_with("cadeau"):
		cadeau(npc, str(p))
	else:
		gagne(reg, str(p))


# =================================================================== où ?

## La région d'un habitant : son groupe, sinon l'endroit où il vit.
static func region_npc(npc: Node) -> String:
	if npc == null or not is_instance_valid(npc):
		return ""
	var prof: Variant = npc.get("profile")
	if prof is Dictionary:
		var g: String = str((prof as Dictionary).get("groupe", ""))
		if GROUPES.has(g):
			return str(GROUPES[g])
		if REGIONS.has(g):
			return g
	if npc is Node3D:
		return region_at((npc as Node3D).global_position)
	return ""


static func _ok(m: Node, var_name: String, sub: String = "") -> bool:
	var v: Variant = m.get(var_name)
	if v == null:
		return false
	return sub == "" or (v as Object).get(sub) != null


## La région d'un point du monde (même découpage que journal_v56.place_name).
static func region_at(p: Vector3) -> String:
	var m: Node = main_ref
	if m == null or not is_instance_valid(m):
		return ""
	if _ok(m, "azur_v56") and m.azur_v56.contains(p):
		return "azur"
	if _ok(m, "mer_v55", "atl") and m.mer_v55.atl.in_dome(p + Vector3.UP):
		return "atlantide"
	if _ok(m, "feerie_v58") and m.feerie_v58.contains(p):
		return "fees"
	if _ok(m, "arcanelle_v67") and m.arcanelle_v67.contains(p):
		return "arcanelle"
	for e in [["montjoie_v71", "city", "montjoie"], ["astralys_v76", "city", "astralys"], ["boucan_v75", "city", "boucan"],
			["moai_v87", "ile", "moai"], ["pixel_v90", "ile", "pixel"], ["larsen_v91", "ile", "larsen"], ["neo_v94", "ile", "neo"],
			["pasta_v97", "ile", "pasta"], ["crayon_v99", "ile", "crayon"]]:
		if _ok(m, str(e[0]), str(e[1])) and m.get(str(e[0])).owns_point(p):
			return str(e[2])
	if _ok(m, "hautefond_v112", "city") and m.hautefond_v112.owns_point(p):
		var z: String = str(m.hautefond_v112.zone_at(p))
		if z.begins_with("da_"):
			return "dome"
		if z.begins_with("fr_"):
			return "fronde"
		if z.begins_with("st_"):
			return "strates"
		if z.begins_with("nu_") or z.begins_with("port_") or z.begins_with("belvedere_"):
			return "nuees"
		if m.hautefond_v112.in_dome(p):
			return "dome"
		if m.hautefond_v112.in_strates(p):
			return "strates"
		return "hautefond"
	if _ok(m, "braise_v70", "city") and m.braise_v70.owns_point(p):
		return "braise"
	if _ok(m, "soleils_v69", "egypte") and m.soleils_v69.owns_point(p):
		return "soleils"
	if _ok(m, "pirates_v68") and m.pirates_v68.contains(p):
		return "balafre"
	if _ok(m, "grande_v59") and m.grande_v59.contains(p):
		var gz: String = str(m.grande_v59.zone_at(p))
		for k in ["carene", "ramure", "cliquetis", "tazira"]:
			if gz.begins_with(k):
				return k
		return "grande"
	if p.y > 100.0:
		return "ciel"
	if _ok(m, "nains_v46", "ile") and m.nains_v46.ile.contains(p.x, p.z):
		return "nains"
	if _ok(m, "elfes_v41", "ile") and m.elfes_v41.ile.contains(p.x, p.z):
		return "elfes"
	if _ok(m, "jungle_v29") and m.jungle_v29.contains(p.x, p.z):
		return "jungle"
	if Vector2(p.x, p.z).length() < 160.0:
		return "village"
	return ""


## La région d'une maison (sa porte est dehors, dans le monde).
static func region_maison(e: Dictionary) -> String:
	if e.has("pop_region"):
		return str(e["pop_region"])
	var r: String = region_at(e.get("door", Vector3.ZERO))
	e["pop_region"] = r
	return r


# =================================================================== effets

## Un salut selon la popularité (souvent ; jamais pour un « visage nouveau »).
static func salut(r: String, rng: RandomNumberGenerator = null) -> String:
	if r == "":
		return ""
	var pool: Array = SALUTS[niveau(r)]
	if pool.is_empty():
		return ""
	var x: float = rng.randf() if rng != null else randf()
	if x > 0.7:
		return ""
	var k: int = rng.randi() % pool.size() if rng != null else randi() % pool.size()
	return Langue.t(str(pool[k]))


## Ajoute le salut devant une réplique (chacun traduit à part).
static func avec_salut(r: String, texte: String, rng: RandomNumberGenerator = null) -> String:
	var s: String = salut(r, rng)
	if s == "":
		return texte
	return s + "\n\n" + Langue.t(texte)


## Une porte qui reste close (mauvaise réputation : les gens connus, et une maison sur deux).
static func porte_close(e: Dictionary, a_un_proprio: bool) -> bool:
	if str(e.get("entrer", "")) != "":
		return false
	var r: String = region_maison(e)
	if niveau(r) > 0:
		return false
	return a_un_proprio or (hash(str(e.get("id", ""))) % 2 == 0)


## Populaire : on est invité chez les gens.
static func invite(e: Dictionary) -> bool:
	return niveau(region_maison(e)) >= 4


# =================================================================== carnet

## Le texte « Popularité » du carnet (BBCode).
static func texte_carnet() -> String:
	var s: String = "[font_size=24][color=#ffd27a][b]%s[/b][/color][/font_size]\n" % Langue.t("Popularité")
	var ids: Array = []
	for k in REGIONS:
		if points.has(k):
			ids.append(k)
	if ids.is_empty():
		return s + "[i]%s[/i]\n\n" % Langue.t("Personne ne te connaît encore vraiment. Rends service, fais des cadeaux, accomplis des exploits : on parlera de toi.")
	ids.sort_custom(func(a, b): return valeur(a) > valeur(b))
	for k in ids:
		var v: float = valeur(k)
		var n: int = niveau_de(v)
		var bar: int = clampi(int(round((v + 100.0) / 200.0 * 20.0)), 0, 20)
		s += "[b]%s[/b]  —  [color=%s]%s[/color]  [color=#9aa7b0](%d)[/color]\n" % [Langue.t(str(COURTS.get(k, k))), str(NIVEAUX[n][3]), Langue.t(str(NIVEAUX[n][1])), int(round(v))]
		s += "[color=%s]%s[/color][color=#3a4a55]%s[/color]\n" % [str(NIVEAUX[n][3]), "█".repeat(bar), "█".repeat(20 - bar)]
	if renommee > 0.0:
		s += "[color=#9aa7b0]%s[/color]\n" % (Langue.t("Ta renommée voyage : +%d partout dans l'archipel.") % int(clampf(renommee * 0.12, 0.0, 15.0)))
	return s + "\n"
