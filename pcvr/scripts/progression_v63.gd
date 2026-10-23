extends Node
## V63 : la progression du héros.
##  - L'expérience : chaque monstre vaincu, chaque quête accomplie et chaque découverte (les
##    « trouvailles » que le jeu suit déjà : un temple, un boss, une cité…) en rapportent.
##    Niveaux 1 à 30 ; à chaque niveau, un point de caractéristique et un point de talent.
##  - Quatre caractéristiques : Cœur (+1 cœur), Endurance (+2), Force (+1 aux dégâts),
##    Agilité (vitesse, roulade, endurance qui remonte plus vite). Six points au plus chacune.
##  - Un arbre de talents en quatre branches (Agilité, Lame, Garde, Sceaux) de trois talents :
##    double saut, roulade d'esquive, coup chargé, attaque tournoyante, parade parfaite…
##    (appliqués par hero_v28.gd au PC, par vr_tick en VR).
##  - La forge : Ursule (Ramure) puis Borin Barbe-de-Fer (Forgefer) améliorent la lame et
##    forgent des armures ; on les voit sur le héros (épaulières, plastron, lueur des runes).
##  - Les quatre sceaux de la grande enquête : chacun éveille un pouvoir (pouvoirs_v63.gd).
##    PC : 1 à 4 pour choisir, X pour lancer. VR : B pour lancer, B maintenu pour changer.
##  - Le carnet, onglet Héros (H, ou 5 carnet ouvert) : niveau, points, talents, équipement,
##    sceaux. Sur l'écran : le niveau et la barre d'expérience sous les cœurs, le pouvoir choisi.
## V66 : l'évolution passe par les épreuves (epreuves_v66.gd) : énigmes, boss, portes, lieux,
## quêtes du carnet, quêtes des habitants, coffres cachés. Chacune annonce « Épreuve réussie »
## et ce qu'elle rapporte. Le rythme est lent (courbe plus raide, monstres qui rapportent de
## moins en moins quand on en abat beaucoup de la même espèce) ; la page Héros fait le compte.

signal changed

const Ep = preload("res://scripts/epreuves_v66.gd")

const MAX_LEVEL: int = 30
const STAT_MAX: int = 6
const STATS := ["coeur", "endurance", "force", "agilite"]
const STAT_INFO := {
	"coeur": ["♥ Cœur", "+1 cœur par point."],
	"endurance": ["◔ Endurance", "+2 d'endurance par point : courir, rouler, grimper plus longtemps."],
	"force": ["⚔ Force", "+1 aux dégâts de chaque coup."],
	"agilite": ["➶ Agilité", "+4 % de vitesse, une roulade plus longue, une endurance qui remonte plus vite."],
}
const BRANCHES := [["agilite", "Agilité"], ["lame", "Lame"], ["garde", "Garde"], ["sceaux", "Sceaux"]]
const TALENTS := [
	{"id": "double_saut", "branche": "agilite", "rang": 1, "niveau": 2, "nom": "Double saut",
		"desc": "Un second saut en plein vol (Espace, ou A en VR, une deuxième fois en l'air)."},
	{"id": "roulade_esquive", "branche": "agilite", "rang": 2, "niveau": 3, "nom": "Roulade d'esquive",
		"desc": "Pendant la roulade (Ctrl), les coups passent à travers toi. Elle va plus loin et coûte moins d'endurance. En VR : clic du stick gauche pour esquiver."},
	{"id": "pas_du_vent", "branche": "agilite", "rang": 3, "niveau": 6, "nom": "Pas du vent",
		"desc": "Courir coûte deux fois moins d'endurance, et tu cours 10 % plus vite."},
	{"id": "coup_charge", "branche": "lame", "rang": 1, "niveau": 2, "nom": "Coup chargé",
		"desc": "Après un coup d'arme, garde le clic enfoncé : la lame se charge (elle brille). Relâche : un coup terrible (×2,5). En VR : un coup donné très vite."},
	{"id": "tournoyante", "branche": "lame", "rang": 2, "niveau": 4, "nom": "Attaque tournoyante",
		"desc": "Charge plus longtemps (la lueur devient bleue) : en relâchant, tu tournoies et frappes tout autour de toi, deux fois. En VR : clic du stick droit."},
	{"id": "coup_de_grace", "branche": "lame", "rang": 3, "niveau": 8, "nom": "Coup de grâce",
		"desc": "Le dernier coup d'un enchaînement frappe deux fois plus fort, et chaque coup a une chance sur huit d'être critique."},
	{"id": "parade_parfaite", "branche": "garde", "rang": 1, "niveau": 3, "nom": "Parade parfaite",
		"desc": "Lève ta garde (F, ou grip gauche en VR) au dernier moment, juste avant le coup : aucun dégât, l'ennemi est sonné et ta riposte frappe double."},
	{"id": "peau_de_pierre", "branche": "garde", "rang": 2, "niveau": 5, "nom": "Peau de pierre",
		"desc": "Les coups qui enlèvent un cœur ou plus perdent un demi-cœur."},
	{"id": "second_souffle", "branche": "garde", "rang": 3, "niveau": 9, "nom": "Second souffle",
		"desc": "Une fois toutes les dix minutes, un coup qui devait t'assommer te laisse à un demi-cœur."},
	{"id": "sceaux_apaises", "branche": "sceaux", "rang": 1, "niveau": 4, "nom": "Sceaux apaisés",
		"desc": "Les pouvoirs des sceaux se rechargent 30 % plus vite. (Il faut posséder au moins un sceau.)"},
	{"id": "echo_sceaux", "branche": "sceaux", "rang": 2, "niveau": 7, "nom": "Écho des sceaux",
		"desc": "La Flamme brûle plus fort, la Bourrasque souffle plus large, la Lueur de lune dure plus longtemps, le Rouage tourne plus longtemps."},
	{"id": "coeur_sceaux", "branche": "sceaux", "rang": 3, "niveau": 10, "nom": "Cœur des sceaux",
		"desc": "Chaque pouvoir lancé rend de l'endurance ; tous les quatre pouvoirs, un demi-cœur."},
]
## Les quatre sceaux de la grande enquête : couleur, pouvoir, nom du pouvoir, touche PC.
const SEALS := {
	"embruns": {"nom": "Sceau des Embruns", "peuple": "Carène", "pouvoir": "vent", "pnom": "Bourrasque", "touche": "1", "couleur": Color(0.35, 0.85, 0.85),
		"desc": "Un vent du large qui repousse les ennemis, renverse les carapaces, fait tourner les ailes et les moulins."},
	"sables": {"nom": "Sceau des Sables", "peuple": "Tazira", "pouvoir": "flamme", "pnom": "Flamme", "touche": "2", "couleur": Color(1.0, 0.58, 0.18),
		"desc": "Une boule de feu : elle brûle les ennemis et les ronces, allume les braseros et les torches."},
	"airain": {"nom": "Sceau d'Airain", "peuple": "Cliquetis et les bergers du nord", "pouvoir": "rouage", "pnom": "Rouage", "touche": "3", "couleur": Color(0.95, 0.78, 0.35),
		"desc": "Un souffle de mécanique : il remet en marche les vieux mécanismes de loin et paralyse les automates."},
	"brumes": {"nom": "Sceau des Brumes", "peuple": "Ramure", "pouvoir": "lune", "pnom": "Lueur de lune", "touche": "4", "couleur": Color(0.7, 0.8, 1.0),
		"desc": "Une lumière de lune autour de toi : elle révèle ce qui est caché (ponts, dalles, écritures) et rend les spectres vulnérables."},
}
const SEAL_ORDER := ["embruns", "sables", "airain", "brumes"]
const POWER_OF := {"vent": "embruns", "flamme": "sables", "rouage": "airain", "lune": "brumes"}
const POWER_ORDER := ["vent", "flamme", "rouage", "lune"]
## Forge : nom, effet, artisan, prix.
const FORGE_ARME := [
	{"nom": "Lame ordinaire", "bonus": 0},
	{"nom": "Lame affûtée", "bonus": 1, "pnj": "ursule", "prix": [["piece", 30], ["minerai_fer", 1]], "texte": "Ursule passe ta lame sur sa grande meule de grès, longtemps, sans un mot. Le fil chante."},
	{"nom": "Lame trempée", "bonus": 2, "pnj": "ursule", "prix": [["piece", 60], ["minerai_fer", 2], ["eclat_cristal", 1]], "texte": "Ursule chauffe ta lame au rouge, la plonge dans un bac de brume froide : un sifflement, une vapeur bleue. « Elle ne cassera plus. »"},
	{"nom": "Lame runique", "bonus": 4, "pnj": "borin", "prix": [["piece", 120], ["rune_golem", 2], ["coeur_magma", 1]], "texte": "Borin grave trois runes sur ta lame et les nourrit au cœur de magma. Elles s'allument, bleues, et ne s'éteignent plus. « Une lame de roi, gamin. »"},
]
const FORGE_ARMURE := [
	{"nom": "Tunique de voyage", "chance": 0.0},
	{"nom": "Cuir bouilli", "chance": 0.25, "pnj": "ursule", "prix": [["piece", 40]], "texte": "Ursule taille un plastron et des épaulières dans un cuir épais, bouilli dans la cire. « Ça arrête les griffes. Pas les rochers. »"},
	{"nom": "Cotte de mailles", "chance": 0.4, "pnj": "ursule", "prix": [["piece", 80], ["minerai_fer", 3]], "texte": "Trois jours d'anneaux, un par un. Ursule te tend la cotte de mailles : lourde, souple, froide. « Mets-la. Tiens-toi droit. Bien. »"},
	{"nom": "Écailles de bronze", "chance": 0.55, "pnj": "borin", "prix": [["piece", 140], ["minerai_fer", 3], ["coeur_magma", 1]], "texte": "Borin rive des écailles de bronze sur ta cotte, comme la peau d'un dragon. « Les nains en portaient au temps des Grandes Mines. »"},
	{"nom": "Armure runique", "chance": 0.7, "pnj": "borin", "prix": [["piece", 220], ["rune_golem", 2], ["obsidienne", 1], ["piece_or", 1]], "texte": "Toute la forge se tait. Borin et Nori le Runiste gravent l'armure pendant une nuit entière. Au matin, les runes battent doucement, comme un cœur. « La plus belle que j'aie faite. »"},
]
## Expérience des monstres (les autres : 6). V66 : moins qu'avant, et chaque monstre de la même
## espèce rapporte 10 % de moins que le précédent (au moins 1) : on évolue par les épreuves.
const KILL_XP := {
	"crabe": 5, "araignee": 6, "follet": 5, "vipere": 7, "plante": 7, "ronceux": 8, "gargouille": 10, "magma": 11,
	"gardien": 14, "armure": 18, "golem": 21, "plante_mere": 60,
	"scorpion": 8, "ondin": 10, "automate": 14, "spectre": 11,
	"garde_maree": 60, "scorpion_roi": 60, "colosse": 60, "loup_brumes": 60, "gardien_coeur": 80,
}
const KILL_DECAY: float = 0.9

var main: Node
var xp: int = 0
var level: int = 1
var stat_points: int = 0
var talent_points: int = 0
var stats := {"coeur": 0, "endurance": 0, "force": 0, "agilite": 0}
var talents: Dictionary = {}
var forge := {"arme": 0, "armure": 0}
var seals: Dictionary = {}
var power: String = ""
var kills: int = 0
var kills_kind: Dictionary = {}           # V66 : monstres abattus par espèce
var quetes_pnj: Dictionary = {}           # V66 : quêtes des habitants déjà comptées
var coffres: int = 0                      # V66 : coffres ouverts
var _pnj_retro: bool = false
var _queue: Array = []                    # V66 : messages en attente [texte, son]
var _queue_wait: float = 0.0
var xp_log: Dictionary = {"monstres": 0, "quetes": 0, "decouvertes": 0}
var _seen: Dictionary = {}
var _seen_ready: bool = false
var _retro: bool = false
var _poll: float = 0.0
var _vr_b: float = -1.0
var _vr_btn: Dictionary = {}
# HUD
var _hud: Control
var _lvl_label: Label
var _xp_bar: Control
var _pts_label: Label
var _pow_box: Control
var _vr_label: Label3D
var _toast_t: float = 0.0
# page du carnet
var _c: Node
var _page: Control
var _p_head: Label
var _p_xp: Control
var _p_xp_text: Label
var _p_points: Label
var _p_stat_rows: Dictionary = {}
var _p_talent_buttons: Dictionary = {}
var _p_talent_pts: Label
var _p_detail: RichTextLabel
var _p_learn: Button
var _p_selected: String = ""
var _p_right: RichTextLabel


func setup(main_node: Node) -> void:
	main = main_node


# =================================================================== expérience et niveaux

## Expérience à gagner pour passer du niveau l au niveau l + 1.
func need(l: int) -> int:
	return 120 + 90 * (l - 1)


func xp_into_level() -> int:
	return xp


func gain(amount: int, why: String = "", at: Variant = null) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		if level >= MAX_LEVEL:
			xp = 0
		return
	xp += amount
	if xp_log.has(why):
		xp_log[why] = int(xp_log[why]) + amount
	if at is Vector3 and main != null and main.get("combat_v28") != null and main.combat_v28 != null:
		main.combat_v28.float_text((at as Vector3) + Vector3.UP * 0.6, "+%d XP" % amount, Color(0.75, 0.9, 1.0))
	var ups: int = 0
	while level < MAX_LEVEL and xp >= need(level):
		xp -= need(level)
		level += 1
		stat_points += 1
		talent_points += 1
		ups += 1
	if level >= MAX_LEVEL:
		xp = 0
	if ups > 0:
		_level_up_fx()
	_refresh_hud()
	changed.emit()


func _level_up_fx() -> void:
	if main == null:
		return
	if not _retro:
		say("Niveau %d ! +1 point de caractéristique, +1 point de talent. (Carnet, onglet Héros : touche H)" % level)
		if main.has_method("jingle"):
			main.jingle("niveau")
		if main.has_method("sfx"):
			main.sfx("niveau")
	var p: Vector3 = main._player_pos_v27()
	if main.get("combat_v28") != null and main.combat_v28 != null:
		main.combat_v28.float_text(p + Vector3.UP * 2.3, "NIVEAU %d !" % level, Color(1.0, 0.85, 0.35))
		main.combat_v28.puff(p + Vector3.UP * 1.0, Color(1.0, 0.85, 0.4))
	_aura(p)
	_toast_t = 4.0


## Une colonne de lumière dorée autour du héros.
func _aura(p: Vector3) -> void:
	var parts := CPUParticles3D.new()
	parts.name = "Aura_niveau_v63"
	parts.amount = 70
	parts.lifetime = 1.4
	parts.one_shot = true
	parts.explosiveness = 0.35
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	parts.emission_ring_axis = Vector3.UP
	parts.emission_ring_radius = 0.75
	parts.emission_ring_inner_radius = 0.55
	parts.emission_ring_height = 0.2
	parts.direction = Vector3.UP
	parts.spread = 8.0
	parts.gravity = Vector3(0, 1.6, 0)
	parts.initial_velocity_min = 0.6
	parts.initial_velocity_max = 1.8
	parts.scale_amount_min = 0.5
	parts.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.82, 0.35, 0.95)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	parts.mesh = q
	main.add_child(parts)
	parts.global_position = p + Vector3.UP * 0.1
	parts.emitting = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 2.5
	light.omni_range = 5.0
	parts.add_child(light)
	light.position = Vector3.UP * 1.2
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 1.4)
	tw.tween_callback(parts.queue_free)


func on_kill(kind: String, at: Vector3) -> void:
	kills += 1
	var n: int = int(kills_kind.get(kind, 0))
	kills_kind[kind] = n + 1
	gain(maxi(1, int(round(float(KILL_XP.get(kind, 6)) * pow(KILL_DECAY, n)))), "monstres", at)


## Une quête du carnet accomplie : un peu d'expérience par étape.
func on_quest(qid: String, steps: int) -> void:
	gain(quest_xp(qid, steps), "quetes")


## V66 : ce que rapporte une quête du carnet (le carnet l'annonce avec la récompense).
static func quest_xp(qid: String, steps: int) -> int:
	return 250 if qid == "quatre_sceaux" else 30 + 15 * maxi(steps, 1)


## V66 : un coffre caché ouvert.
func on_chest(at: Vector3) -> void:
	coffres += 1
	gain(Ep.XP_COFFRE, "decouvertes", at)


## Les trouvailles du jeu : chaque épreuve réussie rapporte (epreuves_v66.gd), une seule fois.
## Au premier passage sur une partie d'avant la V63, on compte tout ce qui a déjà été fait
## (expérience rétroactive) ; de même pour les quêtes des habitants d'avant la V66.
func _poll_finds() -> void:
	if main == null or not main.has_method("_npc_ctx_v31"):
		return
	var tr: Dictionary = main._npc_ctx_v31().get("trouvailles", {})
	var total: int = 0
	var names: Array = []
	for k in tr:
		var v: int = int(tr[k])
		var prev: int = int(_seen.get(k, 0))
		if v <= prev:
			continue
		var key: String = str(k)
		var n: int = 0
		if key in Ep.SANS_XP:
			n = 0
		elif Ep.COMPTEURS.has(key):
			var c: Array = Ep.COMPTEURS[key]
			n = (int(c[2]) if prev == 0 else 0) + (v - maxi(prev, 1)) * int(c[3])
			if prev == 0:
				names.append(str(c[0]))
		elif Ep.LISTE.has(key):
			n = int(Ep.LISTE[key][2]) if prev == 0 else 0
			if n > 0:
				names.append(str(Ep.LISTE[key][0]))
		else:
			n = Ep.XP_INCONNUE if prev == 0 else 0
		_seen[key] = v
		total += n
	# les quêtes des habitants (Barnabé, Lyra, les elfes, les nains, les fées…)
	var q_total: int = 0
	var q_names: Array = []
	for st in _npc_quests():
		var id: String = str(st[0])
		if quetes_pnj.has(id):
			continue
		quetes_pnj[id] = true
		q_total += int((Ep.QUETES_PNJ.get(id, ["", 50]) as Array)[1])
		q_names.append(str(st[1]))
	# partie d'avant la V66 : ses quêtes d'habitants déjà faites comptent, en une fois
	if _pnj_retro and _seen_ready and q_total > 0:
		say("Les quêtes que tu as déjà faites pour les habitants comptent aussi : +%d XP." % q_total)
		gain(q_total, "quetes")
		q_total = 0
		q_names = []
	_pnj_retro = false
	if not _seen_ready:
		# partie d'avant la V63 (ou premier passage) : tout ce qui est déjà fait, sans fanfare
		if total + q_total > 0:
			_retro = true
			var before: int = level
			gain(total, "decouvertes")
			gain(q_total, "quetes")
			_retro = false
			if level > before:
				say("Tout ce que tu as déjà accompli compte : te voilà niveau %d ! Ouvre le carnet (H) pour répartir tes points." % level)
	elif total + q_total > 0:
		names.append_array(q_names)
		var at: Vector3 = main._player_pos_v27() + Vector3.UP * 1.4
		if not names.is_empty():
			_announce(names, total + q_total)
		gain(total, "decouvertes", at)
		if total > 0:
			gain(q_total, "quetes")
		else:
			gain(q_total, "quetes", at)
	_seen_ready = true


## Les quêtes d'habitants accomplies : [[id, « La quête de Barnabé »]].
func _npc_quests() -> Array:
	var out: Array = []
	var seen := {}
	for n in main.get("npcs_v31") if main.get("npcs_v31") != null else []:
		if not is_instance_valid(n) or n.get("brain") == null:
			continue
		var id: String = str((n.get("profile") as Dictionary).get("id", ""))
		seen[id] = true
		if str(n.brain.memoire.get("quete", "")) == "finie":
			out.append([id, "La quête de " + str(n.display_name).split(" ")[0]])
	var pend: Variant = main.get("pending_pnj_v31")
	if pend is Dictionary:
		for id2 in pend:
			if seen.has(str(id2)) or not (pend[id2] is Dictionary):
				continue
			var m: Variant = (pend[id2] as Dictionary).get("memoire", {})
			if m is Dictionary and str((m as Dictionary).get("quete", "")) == "finie":
				out.append([str(id2), "La quête de " + str(id2).capitalize()])
	return out


## « Épreuve réussie : … » au milieu de l'écran (et au poignet en VR, par le message).
func _announce(names: Array, total: int) -> void:
	var t: String = ("Épreuve réussie : " + str(names[0])) if names.size() == 1 else ("Épreuves réussies : " + ", ".join(names))
	say("%s  (+%d XP)" % [t, total], "ui_quete")


## V66 : nos messages attendent que celui du jeu ait été lu (l'histoire d'abord, le décompte
## ensuite) ; au plus 6 s d'attente.
func say(text: String, sound: String = "") -> void:
	_queue.append([text, sound])


func _flush_queue(delta: float) -> void:
	if _queue.is_empty() or main == null:
		_queue_wait = 0.0
		return
	_queue_wait += delta
	if float(main.get("message_clock_v28")) > 0.0 and _queue_wait < 6.0:
		return
	var it: Array = _queue.pop_front()
	main._show_message_v28(str(it[0]))
	main.message_clock_v28 = maxf(float(main.message_clock_v28), 4.5)
	if str(it[1]) != "" and main.has_method("sfx"):
		main.sfx(str(it[1]))
	_queue_wait = 0.0


# =================================================================== caractéristiques et talents

func add_stat(s: String) -> bool:
	if stat_points <= 0 or not stats.has(s) or int(stats[s]) >= STAT_MAX:
		return false
	stats[s] = int(stats[s]) + 1
	stat_points -= 1
	apply()
	if main != null and main.has_method("sfx"):
		main.sfx("ui_quete")
	changed.emit()
	return true


func has_talent(id: String) -> bool:
	return talents.has(id)


func talent_info(id: String) -> Dictionary:
	for t in TALENTS:
		if str(t["id"]) == id:
			return t
	return {}


## Pourquoi on ne peut pas (encore) apprendre ce talent ("" : on peut).
func why_not(id: String) -> String:
	var t: Dictionary = talent_info(id)
	if t.is_empty():
		return "?"
	if talents.has(id):
		return "Déjà appris."
	if level < int(t["niveau"]):
		return "Il faut être niveau %d." % int(t["niveau"])
	if int(t["rang"]) > 1:
		for t2 in TALENTS:
			if str(t2["branche"]) == str(t["branche"]) and int(t2["rang"]) == int(t["rang"]) - 1 and not talents.has(str(t2["id"])):
				return "Il faut d'abord « %s »." % str(t2["nom"])
	if str(t["branche"]) == "sceaux" and seals.is_empty():
		return "Il faut posséder au moins un des quatre sceaux."
	if talent_points <= 0:
		return "Pas de point de talent : gagne un niveau."
	return ""


func learn(id: String) -> bool:
	if why_not(id) != "":
		return false
	talents[id] = true
	talent_points -= 1
	apply()
	if main != null:
		if main.has_method("sfx"):
			main.sfx("ui_quete")
		main._show_message_v28("Talent appris : %s" % str(talent_info(id)["nom"]))
	changed.emit()
	return true


## Les effets sur le héros (cœurs, endurance, force, agilité, talents, forge) : on passe par
## le carnet de quêtes qui ajoute ses propres bonus (journal_v56.apply_bonuses).
func apply() -> void:
	if main == null:
		return
	var j: Node = main.get("journal_v56")
	if j != null:
		j.apply_bonuses()
	else:
		apply_hero()
	_dress_hero()
	_refresh_hud()


## Appelé par journal_v56.apply_bonuses après ses propres bonus.
func apply_hero() -> void:
	var hero: Node = main.get("hero_v28") if main != null else null
	if hero == null:
		return
	hero.talents = talents
	hero.agilite = int(stats["agilite"])
	hero.forge_bonus = int(FORGE_ARME[clampi(int(forge["arme"]), 0, FORGE_ARME.size() - 1)]["bonus"])
	hero.armor_chance = float(FORGE_ARMURE[clampi(int(forge["armure"]), 0, FORGE_ARMURE.size() - 1)]["chance"])


func extra(kind: String) -> int:
	match kind:
		"coeur":
			return int(stats["coeur"])
		"endurance":
			return 2 * int(stats["endurance"])
		"force":
			return int(stats["force"])
	return 0


# =================================================================== sceaux et pouvoirs

func has_seal(id: String) -> bool:
	return seals.has(id)


func power_owned(pid: String) -> bool:
	return POWER_OF.has(pid) and seals.has(str(POWER_OF[pid]))


## Un sceau trouvé : son pouvoir s'éveille (et devient le pouvoir choisi).
func give_seal(id: String) -> void:
	if not SEALS.has(id) or seals.has(id):
		return
	seals[id] = true
	power = str(SEALS[id]["pouvoir"])
	gain(100, "decouvertes")
	_refresh_hud()
	changed.emit()


func select_power(pid: String) -> bool:
	if not power_owned(pid):
		return false
	power = pid
	if main != null and main.has_method("sfx"):
		main.sfx("ui_clic")
	_refresh_hud()
	return true


func next_power() -> void:
	var owned: Array = []
	for p in POWER_ORDER:
		if power_owned(p):
			owned.append(p)
	if owned.is_empty():
		return
	var i: int = owned.find(power)
	select_power(str(owned[(i + 1) % owned.size()]))
	var s: Dictionary = SEALS[POWER_OF[power]]
	if main != null:
		main._show_message_v28("Pouvoir choisi : %s" % str(s["pnom"]))


func use_power() -> bool:
	if power == "" or not power_owned(power):
		if main != null:
			main._show_message_v28("Tu n'as pas encore de pouvoir. Les quatre sceaux de la grande île en cachent chacun un…")
		return false
	var pw: Node = main.get("pouvoirs_v63")
	if pw == null:
		return false
	return pw.use(power)


## Touches du PC : 1 à 4 choisissent le pouvoir, X le lance.
func handle_key(k: Key) -> bool:
	match k:
		KEY_X:
			use_power()
			return true
		KEY_1, KEY_KP_1, KEY_2, KEY_KP_2, KEY_3, KEY_KP_3, KEY_4, KEY_KP_4:
			var i: int = {KEY_1: 0, KEY_KP_1: 0, KEY_2: 1, KEY_KP_2: 1, KEY_3: 2, KEY_KP_3: 2, KEY_4: 3, KEY_KP_4: 3}[k]
			var pid: String = str(POWER_ORDER[i])
			if not power_owned(pid):
				return false
			if select_power(pid):
				main._show_message_v28("Pouvoir choisi : %s (X pour le lancer)" % str(SEALS[POWER_OF[pid]]["pnom"]))
			return true
	return false


# =================================================================== VR

## Appelé par main à chaque image en VR : B (main droite) lance le pouvoir, B maintenu le
## change ; grip gauche = garde ; clic du stick gauche = esquive ; clic du stick droit =
## attaque tournoyante.
func vr_tick(delta: float) -> void:
	if main == null or not main.xr_active:
		return
	var hero: Node = main.get("hero_v28")
	var rh: Node = main.right_hand
	var lh: Node = main.left_hand
	var b_now: bool = rh.is_button_pressed("by_button")
	if b_now:
		if _vr_b < 0.0:
			_vr_b = 0.0
		_vr_b += delta
		if _vr_b >= 0.6 and _vr_b - delta < 0.6:
			next_power()
	elif _vr_b >= 0.0:
		if _vr_b < 0.6:
			use_power()
		_vr_b = -1.0
	if hero == null:
		return
	# garde (grip gauche), tournée vers où l'on regarde
	var fwd: Vector3 = -main.xr_camera.global_basis.z
	fwd.y = 0.0
	if fwd.length() > 0.01:
		hero.facing = fwd.normalized()
	var guard: bool = lh.get_float("grip") > 0.6
	if guard and not hero.blocking:
		hero.block_t = 0.0
	hero.blocking = guard
	if guard:
		hero.block_t += delta
	var ls: bool = lh.is_button_pressed("primary_click")
	if ls and not bool(_vr_btn.get("ls", false)) and talents.has("roulade_esquive"):
		hero.vr_dodge()
	_vr_btn["ls"] = ls
	var rs: bool = rh.is_button_pressed("primary_click")
	if rs and not bool(_vr_btn.get("rs", false)) and talents.has("tournoyante"):
		hero.vr_spin()
	_vr_btn["rs"] = rs
	hero.vr_tick(delta)


# =================================================================== forge (Ursule, Borin)

func register_services(journal: Node) -> void:
	for who in ["ursule", "borin"]:
		var w: String = who
		var prev: Variant = journal.services.get(w, null)
		journal.add_service(w, func(npc: Node) -> Array: return _forge_topics(npc, w, prev),
			func(npc: Node, choice: String) -> Dictionary: return _forge_choose(npc, choice, w, prev))


func _next(kind: String) -> Dictionary:
	var list: Array = FORGE_ARME if kind == "arme" else FORGE_ARMURE
	var i: int = int(forge[kind]) + 1
	return list[i] if i < list.size() else {}


func _price_text(prix: Array) -> String:
	var parts: Array = []
	for p in prix:
		var nm: String = str(main.inventory_v28.ITEMS.get(str(p[0]), {"name": str(p[0])})["name"]).to_lower()
		parts.append("%d %s" % [int(p[1]), nm] if str(p[0]) == "piece" else ("%d × %s" % [int(p[1]), nm] if int(p[1]) > 1 else nm))
	return ", ".join(parts)


func _forge_topics(npc: Node, who: String, prev: Variant) -> Array:
	var out: Array = []
	if prev is Array:
		out = ((prev as Array)[0] as Callable).call(npc)
	for kind in ["arme", "armure"]:
		var nx: Dictionary = _next(kind)
		if nx.is_empty() or str(nx.get("pnj", "")) != who:
			continue
		var label: String = ("⚒ Améliorer ma lame : %s (%s)" if kind == "arme" else "⚒ Me forger une armure : %s (%s)") % [str(nx["nom"]), _price_text(nx["prix"])]
		out.append({"id": "q56:service:forge63_" + kind, "label": label})
	if who == "ursule" and int(forge["arme"]) >= 2 and int(forge["armure"]) >= 2:
		out.append({"id": "q56:service:forge63_suite", "label": "⚒ Et après ?"})
	return out


func _forge_choose(npc: Node, choice: String, who: String, prev: Variant) -> Dictionary:
	if not choice.begins_with("q56:service:forge63_"):
		if prev is Array:
			return ((prev as Array)[1] as Callable).call(npc, choice)
		return {}
	var kind: String = choice.trim_prefix("q56:service:forge63_")
	if kind == "suite":
		return {"texte": "… Après ? Après, c'est le travail des nains. Borin Barbe-de-Fer, à Forgefer, sous la Montagne de Feu. Lui sait graver des runes. Dis-lui qu'Ursule t'envoie. Il grognera. C'est bon signe.", "geste": "parle"}
	var nx: Dictionary = _next(kind)
	if nx.is_empty() or str(nx.get("pnj", "")) != who:
		return {"texte": "Je n'ai rien de mieux à te faire.", "geste": "parle"}
	if kind == "arme" and (main.inventory_v28.equipped == "" or str(main.inventory_v28.ITEMS.get(main.inventory_v28.equipped, {}).get("kind", "")) != "arme"):
		return {"texte": ("Montre-moi ta lame. Tiens-la en main, que je voie comment tu la tiens." if who == "ursule" else "Une lame, gamin. Tiens-la en main. Je ne grave pas de runes sur du vent."), "geste": "parle"}
	var miss: Array = []
	for p in nx["prix"]:
		if main.inventory_v28.count(str(p[0])) < int(p[1]):
			miss.append(p)
	if not miss.is_empty():
		return {"texte": ("Il me faut : %s. Reviens quand tu les auras." if who == "ursule" else "Il me faut %s. Pas une miette de moins.") % _price_text(nx["prix"]), "geste": "parle"}
	return {"texte": str(nx["texte"]), "geste": "salut", "prendre": nx["prix"], "_forge63": kind}


## Appelé par main après une réplique réussie (le prix est payé) : la pièce est forgée.
func after_reply(r: Dictionary, _npc: Node) -> void:
	if not r.has("_forge63"):
		return
	var kind: String = str(r["_forge63"])
	forge[kind] = int(forge[kind]) + 1
	var nm: String = str((FORGE_ARME if kind == "arme" else FORGE_ARMURE)[int(forge[kind])]["nom"])
	main._show_message_v28("Forgé : %s !" % nm)
	if main.has_method("sfx"):
		main.sfx("forge", main._player_pos_v27() + Vector3.UP)
	if main.has_method("jingle"):
		main.jingle("decouverte")
	gain(30, "quetes")
	apply()
	on_equip(main.inventory_v28.equipped)
	changed.emit()


# =================================================================== l'équipement sur le héros

## L'armure se voit sur le héros (PC) : épaulières, plastron, ceinture, runes.
func _dress_hero() -> void:
	if main == null:
		return
	var hero: Node = main.get("hero_v28")
	if hero == null or hero.skel == null:
		return
	var skel: Skeleton3D = hero.skel
	for n in skel.get_children():
		if str(n.name).begins_with("Armure_v63"):
			n.queue_free()
	var tier: int = int(forge["armure"])
	if tier <= 0:
		return
	var cols := [Color(0.42, 0.26, 0.14), Color(0.6, 0.62, 0.66), Color(0.72, 0.52, 0.24), Color(0.62, 0.68, 0.78)]
	var c: Color = cols[clampi(tier - 1, 0, 3)]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0 if tier == 1 else 0.8
	m.roughness = 0.75 if tier == 1 else 0.35
	if tier == 2:
		m.albedo_texture = load("res://assets/textures/cliquetis/fonte.png") if ResourceLoader.exists("res://assets/textures/cliquetis/fonte.png") else null
		m.uv1_scale = Vector3(6, 6, 6)
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.3, 0.2, 0.12) if tier < 3 else Color(0.85, 0.66, 0.3)
	trim.metallic = 0.0 if tier < 3 else 0.9
	trim.roughness = 0.6 if tier < 3 else 0.3
	var rune: StandardMaterial3D = null
	if tier >= 4:
		rune = StandardMaterial3D.new()
		rune.albedo_color = Color(0.3, 0.6, 1.0)
		rune.emission_enabled = true
		rune.emission = Color(0.35, 0.7, 1.0)
		rune.emission_energy_multiplier = 2.5
	# épaulières
	for side in [["LeftShoulder", -1.0], ["RightShoulder", 1.0]]:
		var pad := Node3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.11
		sm.height = 0.13
		sm.is_hemisphere = true
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = m
		mi.scale = Vector3(1.25, 1.0, 1.15)
		pad.add_child(mi)
		if tier >= 2:
			var mi2 := MeshInstance3D.new()
			var sm2 := SphereMesh.new()
			sm2.radius = 0.09
			sm2.height = 0.1
			sm2.is_hemisphere = true
			mi2.mesh = sm2
			mi2.material_override = trim
			mi2.position = Vector3(float(side[1]) * 0.03, -0.035, 0)
			mi2.scale = Vector3(1.35, 1.0, 1.25)
			pad.add_child(mi2)
		if rune != null:
			var gem := MeshInstance3D.new()
			var gm := SphereMesh.new()
			gm.radius = 0.018
			gm.height = 0.036
			gem.mesh = gm
			gem.material_override = rune
			gem.position = Vector3(0, 0.07, 0.05)
			pad.add_child(gem)
		_attach(skel, str(side[0]), Vector3(float(side[1]) * 9.0, 7.0, 0.0), pad, "Armure_v63_epaule")
	# plastron (sur le haut du dos / la poitrine)
	var chest := Node3D.new()
	var plate := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.165
	cm.bottom_radius = 0.15
	cm.height = 0.28
	cm.radial_segments = 16
	plate.mesh = cm
	plate.material_override = m
	plate.scale = Vector3(1.0, 1.0, 0.72)
	chest.add_child(plate)
	var belt := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.155
	bm.bottom_radius = 0.16
	bm.height = 0.05
	bm.radial_segments = 16
	belt.mesh = bm
	belt.material_override = trim
	belt.scale = Vector3(1.0, 1.0, 0.75)
	belt.position = Vector3(0, -0.17, 0)
	chest.add_child(belt)
	if rune != null:
		for k in range(3):
			var r := MeshInstance3D.new()
			var rb := BoxMesh.new()
			rb.size = Vector3(0.012, 0.07 - k * 0.012, 0.01)
			r.mesh = rb
			r.material_override = rune
			r.position = Vector3(-0.03 + k * 0.03, 0.03, 0.118)
			chest.add_child(r)
	_attach(skel, "Spine02", Vector3(0, 2.0, 0.5), chest, "Armure_v63_torse")


func _attach(skel: Skeleton3D, bone_name: String, offset_cm: Vector3, node: Node3D, label: String) -> void:
	var b: int = skel.find_bone(bone_name)
	if b < 0:
		node.queue_free()
		return
	var att := BoneAttachment3D.new()
	att.name = label
	att.bone_name = bone_name
	skel.add_child(att)
	var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
	var holder := Node3D.new()
	holder.transform = Transform3D(rest.inverse() * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * offset_cm)
	att.add_child(holder)
	holder.add_child(node)


## Appelé par main quand on prend une arme en main : la lame trempée a un reflet bleuté, la
## lame runique s'illumine (dans la main du héros PC et dans la main VR).
func on_equip(item_id: String) -> void:
	if main == null or item_id == "":
		return
	var tier: int = int(forge["arme"])
	if tier <= 1 or str(main.inventory_v28.ITEMS.get(item_id, {}).get("kind", "")) != "arme":
		return
	var holders: Array = []
	var hero: Node = main.get("hero_v28")
	if hero != null and hero.sword_holder != null and is_instance_valid(hero.sword_holder):
		holders.append(hero.sword_holder)
	var vr: Node = main.right_hand.get_node_or_null("Arme_VR_v28") if main.get("right_hand") != null and main.right_hand != null else null
	if vr != null:
		holders.append(vr)
	for h in holders:
		for mi in (h as Node).find_children("*", "MeshInstance3D", true, false):
			var g: MeshInstance3D = mi
			var src: Material = g.material_override
			if src == null and g.mesh != null and g.mesh.get_surface_count() > 0:
				src = g.mesh.surface_get_material(0)
			if not (src is StandardMaterial3D):
				continue
			var nm: StandardMaterial3D = (src as StandardMaterial3D).duplicate()
			if nm.metallic < 0.4:
				continue
			nm.emission_enabled = true
			nm.emission = Color(0.35, 0.65, 1.0) if tier >= 3 else Color(0.5, 0.75, 0.9)
			nm.emission_energy_multiplier = 1.6 if tier >= 3 else 0.35
			g.material_override = nm


# =================================================================== HUD

func make_hud(layer: CanvasLayer) -> void:
	if layer == null:
		return
	_hud = Control.new()
	_hud.name = "Progression_v63"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud.offset_left = -330.0
	_hud.offset_right = -20.0
	_hud.offset_top = 60.0
	_hud.offset_bottom = 150.0
	layer.add_child(_hud)
	_lvl_label = Label.new()
	_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lvl_label.add_theme_font_size_override("font_size", 17)
	_lvl_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	_lvl_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_lvl_label.add_theme_constant_override("outline_size", 5)
	_lvl_label.position = Vector2(0, 0)
	_lvl_label.size = Vector2(310, 22)
	_hud.add_child(_lvl_label)
	_xp_bar = Control.new()
	_xp_bar.position = Vector2(110, 25)
	_xp_bar.size = Vector2(200, 8)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.draw.connect(_draw_xp)
	_hud.add_child(_xp_bar)
	_pow_box = Control.new()
	_pow_box.position = Vector2(110, 40)
	_pow_box.size = Vector2(200, 46)
	_pow_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pow_box.draw.connect(_draw_powers)
	_hud.add_child(_pow_box)
	_refresh_hud()


func _draw_xp() -> void:
	var w: float = _xp_bar.size.x
	_xp_bar.draw_rect(Rect2(Vector2.ZERO, _xp_bar.size), Color(0, 0, 0, 0.55))
	var r: float = 1.0 if level >= MAX_LEVEL else clampf(float(xp) / float(need(level)), 0.0, 1.0)
	_xp_bar.draw_rect(Rect2(Vector2(1, 1), Vector2((w - 2) * r, _xp_bar.size.y - 2)), Color(0.98, 0.78, 0.3))


func _draw_powers() -> void:
	var owned: Array = []
	for p in POWER_ORDER:
		if power_owned(p):
			owned.append(p)
	if owned.is_empty():
		return
	var pw: Node = main.get("pouvoirs_v63") if main != null else null
	var x: float = _pow_box.size.x
	for i in range(POWER_ORDER.size() - 1, -1, -1):
		var pid: String = POWER_ORDER[i]
		if not power_owned(pid):
			continue
		var s: Dictionary = SEALS[POWER_OF[pid]]
		var big: bool = pid == power
		var r: float = 19.0 if big else 12.0
		x -= r + 4.0
		var c := Vector2(x, 22.0)
		x -= r + 2.0
		var col: Color = s["couleur"]
		_pow_box.draw_circle(c, r + 2.0, Color(0, 0, 0, 0.6))
		_pow_box.draw_circle(c, r, col.darkened(0.55))
		var cd: float = float(pw.cooldown_ratio(pid)) if pw != null else 0.0
		if cd < 1.0:
			_pow_box.draw_arc(c, r - 3.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cd), 32, col.darkened(0.2), 5.0, true)
		else:
			_pow_box.draw_circle(c, r - 4.0, col)
		_pow_box.draw_string(ThemeDB.fallback_font, c + Vector2(-5, 6), str(s["touche"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16 if big else 12, Color(0.05, 0.05, 0.08))
	if power != "":
		var s2: Dictionary = SEALS[POWER_OF[power]]
		_pow_box.draw_string(ThemeDB.fallback_font, Vector2(x - 150, 28), "%s  [X]" % str(s2["pnom"]), HORIZONTAL_ALIGNMENT_RIGHT, 150, 14, Color(1, 1, 1, 0.9))


func _refresh_hud() -> void:
	if _lvl_label != null:
		var pts: String = ""
		if stat_points + talent_points > 0:
			pts = "   ✦ %d point%s" % [stat_points + talent_points, "s" if stat_points + talent_points > 1 else ""]
		_lvl_label.text = "Niveau %d%s" % [level, pts]
	if _xp_bar != null:
		_xp_bar.queue_redraw()
	if _pow_box != null:
		_pow_box.queue_redraw()


func _vr_wrist() -> void:
	if main == null or not main.xr_active or main.get("left_hand") == null:
		return
	if _vr_label == null:
		_vr_label = Label3D.new()
		_vr_label.font_size = 40
		_vr_label.pixel_size = 0.001
		_vr_label.outline_size = 8
		_vr_label.no_depth_test = true
		_vr_label.modulate = Color(1.0, 0.9, 0.6)
		_vr_label.position = Vector3(0, 0.045, 0.1)
		_vr_label.rotation_degrees = Vector3(-60, 0, 0)
		main.left_hand.add_child(_vr_label)
	var t: String = "Niv. %d  %d/%d" % [level, xp, need(level)]
	if power != "":
		var pw: Node = main.get("pouvoirs_v63")
		var ready: bool = pw == null or float(pw.cooldown_ratio(power)) >= 1.0
		t += "\n%s %s" % [str(SEALS[POWER_OF[power]]["pnom"]), "●" if ready else "○"]
	_vr_label.text = t


func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		if _hud != null:
			_hud.visible = false
		return
	if _hud != null:
		_hud.visible = not main.xr_active
		if _pow_box != null and power != "":
			_pow_box.queue_redraw()
	_flush_queue(delta)
	_poll -= delta
	if _poll <= 0.0:
		_poll = 2.0
		_poll_finds()
		_vr_wrist()


# =================================================================== la page « Héros » du carnet

## Construit la page (une seule fois) dans le panneau de l'onglet Héros.
func build_page(pg: Control, c: Node) -> void:
	_c = c
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	pg.add_child(row)
	_page = row
	# --- colonne 1 : niveau, expérience, caractéristiques
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	_p_head = c._label("", 30, Color(1.0, 0.84, 0.5), "BoldItalic")
	left.add_child(_p_head)
	_p_xp = Control.new()
	_p_xp.custom_minimum_size = Vector2(420, 18)
	_p_xp.draw.connect(_draw_page_xp)
	left.add_child(_p_xp)
	_p_xp_text = c._label("", 16, c.DIM, "Italic")
	left.add_child(_p_xp_text)
	_p_points = c._label("", 19, c.GOLD, "Bold")
	left.add_child(_p_points)
	for s in STATS:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", c._style(Color(0.05, 0.15, 0.21, 0.95), Color(0.35, 0.45, 0.5), 10, 1, 10))
		left.add_child(box)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		box.add_child(h)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		var name_l: Label = c._label("", 20, c.INK, "Bold")
		col.add_child(name_l)
		var d: Label = c._label(str(STAT_INFO[s][1]), 14, c.DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(300, 0)
		col.add_child(d)
		var plus: Button = c._button("+", 26)
		plus.custom_minimum_size = Vector2(54, 50)
		var ss: String = s
		plus.pressed.connect(func(): add_stat(ss); refresh_page())
		h.add_child(plus)
		_p_stat_rows[s] = [name_l, plus]
	# --- colonne 2 : l'arbre de talents
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(560, 0)
	mid.add_theme_constant_override("separation", 10)
	row.add_child(mid)
	var th := HBoxContainer.new()
	mid.add_child(th)
	th.add_child(c._label("Talents", 26, Color(1.0, 0.84, 0.5), "BoldItalic"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sp)
	_p_talent_pts = c._label("", 18, c.GOLD, "Bold")
	th.add_child(_p_talent_pts)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	mid.add_child(grid)
	for b in BRANCHES:
		var hl: Label = c._label(str(b[1]), 18, c.DIM, "Bold")
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hl.custom_minimum_size = Vector2(132, 0)
		grid.add_child(hl)
	for rank in [1, 2, 3]:
		for b in BRANCHES:
			for t in TALENTS:
				if str(t["branche"]) == str(b[0]) and int(t["rang"]) == rank:
					var bt: Button = c._button(str(t["nom"]), 15)
					bt.custom_minimum_size = Vector2(132, 62)
					bt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					var tid: String = str(t["id"])
					bt.pressed.connect(func(): _p_selected = tid; refresh_page())
					grid.add_child(bt)
					_p_talent_buttons[tid] = bt
	_p_detail = c._rich(16)
	_p_detail.custom_minimum_size = Vector2(540, 150)
	_p_detail.fit_content = false
	mid.add_child(_p_detail)
	_p_learn = c._button("Apprendre ce talent", 18)
	_p_learn.custom_minimum_size = Vector2(260, 44)
	_p_learn.pressed.connect(func(): learn(_p_selected); refresh_page())
	mid.add_child(_p_learn)
	# --- colonne 3 : équipement, sceaux, statistiques
	_p_right = c._rich(16)
	_p_right.custom_minimum_size = Vector2(470, 0)
	_p_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_p_right)


func _draw_page_xp() -> void:
	var s: Vector2 = _p_xp.size
	_p_xp.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.5))
	var r: float = 1.0 if level >= MAX_LEVEL else clampf(float(xp) / float(need(level)), 0.0, 1.0)
	_p_xp.draw_rect(Rect2(Vector2(2, 2), Vector2((s.x - 4) * r, s.y - 4)), Color(0.98, 0.76, 0.3))


func refresh_page() -> void:
	if _page == null or _c == null:
		return
	var c: Node = _c
	_p_head.text = "Le héros — niveau %d" % level
	_p_xp.queue_redraw()
	_p_xp_text.text = ("Niveau maximum atteint." if level >= MAX_LEVEL else "Expérience : %d / %d  (encore %d)" % [xp, need(level), need(level) - xp]) + "   •   %d monstres vaincus" % kills
	_p_points.text = ("Points à répartir : %d" % stat_points) if stat_points > 0 else "Aucun point à répartir (prochain au niveau %d)" % mini(level + 1, MAX_LEVEL)
	var j: Node = main.get("journal_v56")
	var bo: Dictionary = j.bonus if j != null else {"coeur": 0, "endurance": 0, "force": 0}
	for s in STATS:
		var rowd: Array = _p_stat_rows[s]
		var v: int = int(stats[s])
		var base: String = ""
		match s:
			"coeur":
				base = "%d cœurs" % (5 + int(bo["coeur"]) + v)
			"endurance":
				base = "%d" % int(10 + 3 * int(bo["endurance"]) + 2 * v)
			"force":
				base = "+%d aux dégâts" % (int(bo["force"]) + v)
			"agilite":
				base = "+%d %% de vitesse" % (4 * v)
		(rowd[0] as Label).text = "%s   %s   %s" % [str(STAT_INFO[s][0]), "●".repeat(v) + "○".repeat(STAT_MAX - v), base]
		(rowd[1] as Button).disabled = stat_points <= 0 or v >= STAT_MAX
	_p_talent_pts.text = "Points de talent : %d" % talent_points
	for tid in _p_talent_buttons:
		var bt: Button = _p_talent_buttons[tid]
		var got: bool = talents.has(tid)
		var why: String = why_not(tid)
		var col: Color
		var border: Color
		if got:
			col = Color(0.32, 0.25, 0.08, 1.0)
			border = c.GOLD
		elif why == "":
			col = Color(0.08, 0.3, 0.25, 1.0)
			border = Color(0.5, 1.0, 0.7)
		else:
			col = Color(0.05, 0.1, 0.14, 0.9)
			border = Color(0.3, 0.36, 0.4)
		var selected: bool = tid == _p_selected
		bt.add_theme_stylebox_override("normal", c._style(col, Color(1, 1, 1) if selected else border, 9, 3 if selected else 2, 6))
		bt.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6) if got else (Color(0.85, 1.0, 0.9) if why == "" else Color(0.55, 0.6, 0.65)))
		bt.text = ("✓ " if got else "") + str(talent_info(tid)["nom"])
	if _p_selected == "":
		_p_detail.text = "[i]Choisis un talent pour le lire. Les talents d'une branche s'apprennent dans l'ordre, de haut en bas.[/i]"
		_p_learn.visible = false
	else:
		var t: Dictionary = talent_info(_p_selected)
		var why2: String = why_not(_p_selected)
		var state: String = "[color=#ffd27a]Appris.[/color]" if talents.has(_p_selected) else ("[color=#8fffb0]Tu peux l'apprendre.[/color]" if why2 == "" else "[color=#9aa7b0]" + why2 + "[/color]")
		_p_detail.text = "[font_size=22][b]%s[/b][/font_size]   (niveau %d)\n%s\n%s" % [str(t["nom"]), int(t["niveau"]), str(t["desc"]), state]
		_p_learn.visible = why2 == ""
	# colonne de droite
	# V66 : les épreuves d'abord (c'est par elles que le héros grandit)
	var r: String = _trials_text() + "[font_size=24][color=#ffd27a][b]Équipement[/b][/color][/font_size]\n"
	var ta: int = int(forge["arme"])
	var tb: int = int(forge["armure"])
	r += "[b]Lame :[/b] %s%s\n" % [str(FORGE_ARME[ta]["nom"]), ("  (+%d aux dégâts)" % int(FORGE_ARME[ta]["bonus"])) if ta > 0 else ""]
	r += "[b]Armure :[/b] %s%s\n" % [str(FORGE_ARMURE[tb]["nom"]), ("  (%d %% des coups amortis)" % int(round(float(FORGE_ARMURE[tb]["chance"]) * 100.0))) if tb > 0 else ""]
	var nxa: Dictionary = _next("arme")
	var nxb: Dictionary = _next("armure")
	if not nxa.is_empty() or not nxb.is_empty():
		r += "[color=#9aa7b0][i]"
		if not nxa.is_empty():
			r += "Prochaine lame : %s, chez %s.\n" % [str(nxa["nom"]), "Ursule (Ramure)" if str(nxa["pnj"]) == "ursule" else "Borin Barbe-de-Fer (Forgefer)"]
		if not nxb.is_empty():
			r += "Prochaine armure : %s, chez %s.\n" % [str(nxb["nom"]), "Ursule (Ramure)" if str(nxb["pnj"]) == "ursule" else "Borin Barbe-de-Fer (Forgefer)"]
		r += "[/i][/color]"
	r += "\n[font_size=24][color=#ffd27a][b]Les quatre sceaux[/b][/color][/font_size]\n"
	for sid in SEAL_ORDER:
		var s2: Dictionary = SEALS[sid]
		var col2: String = (s2["couleur"] as Color).to_html(false)
		if seals.has(sid):
			r += "[color=#%s]●[/color] [b]%s[/b] — %s (touche %s%s)\n[color=#9aa7b0]%s[/color]\n" % [col2, str(s2["nom"]), str(s2["pnom"]), str(s2["touche"]), ", choisi" if power == str(s2["pouvoir"]) else "", str(s2["desc"])]
		else:
			r += "[color=#3a4a55]●[/color] [color=#9aa7b0]%s — %s[/color]\n" % ["???" if not _heard_of_seals() else str(s2["nom"]), "à trouver" if _heard_of_seals() else "inconnu"]
	r += "[color=#9aa7b0][i]PC : 1 à 4 pour choisir un pouvoir, X pour le lancer. VR : B pour lancer, B maintenu pour changer.[/i][/color]\n\n"
	# V67 : les sorts appris à Arcanelle
	var so: Node = main.get("sorts_v67") if main != null else null
	if so != null and so.any_known():
		r += so.page_text() + "\n"
	if c.has_method("_hero_stats_text"):
		r += c._hero_stats_text()
	_p_right.text = r


## V66 : les épreuves réussies, région par région (seulement celles où l'on a commencé).
func trials_counts() -> Dictionary:
	var out := {}
	for e in Ep.REGIONS:
		out[str(e[0])] = [0, 0]
	for k in Ep.LISTE:
		_count(out, str(Ep.LISTE[k][1]), int(_seen.get(k, 0)) > 0)
	for k2 in Ep.COMPTEURS:
		_count(out, str(Ep.COMPTEURS[k2][1]), int(_seen.get(k2, 0)) > 0)
	for id in Ep.QUETES_PNJ:
		_count(out, str(Ep.QUETES_PNJ[id][0]), quetes_pnj.has(id))
	var j: Node = main.get("journal_v56") if main != null else null
	if j != null:
		for q in j.QUETES:
			var rg: String = Ep.carnet_region(str(q.get("lieu", "")))
			if rg != "":
				_count(out, rg, j.state(str(q["id"])) == "finie")
	var ob: Node = main.get("objets_v66") if main != null else null
	if ob != null:
		var cc: Dictionary = ob.chest_counts()
		for rg2 in cc:
			var a: Array = out.get(rg2, [0, 0])
			out[rg2] = [int(a[0]) + int(cc[rg2][0]), int(a[1]) + int(cc[rg2][1])]
	return out


func _count(out: Dictionary, rg: String, done: bool) -> void:
	var a: Array = out.get(rg, [0, 0])
	out[rg] = [int(a[0]) + (1 if done else 0), int(a[1]) + 1]


func _trials_text() -> String:
	var t: String = "[font_size=24][color=#ffd27a][b]Les épreuves[/b][/color][/font_size]\n"
	t += "[color=#9aa7b0][i]Énigmes, gardiens, portes, quêtes, coffres cachés : c'est en les réussissant que le héros grandit.[/i][/color]\n"
	var cnt: Dictionary = trials_counts()
	var any: bool = false
	var sum: int = 0
	for e in Ep.REGIONS:
		var a: Array = cnt.get(str(e[0]), [0, 0])
		sum += int(a[0])
		if int(a[0]) <= 0:
			continue
		any = true
		var full: bool = int(a[0]) >= int(a[1])
		t += "[color=#%s]●[/color] %s : %d / %d%s\n" % ["ffd27a" if full else "8fd0ff", str(e[1]), int(a[0]), int(a[1]), "  ✓" if full else ""]
	if not any:
		t += "Aucune pour l'instant. La première t'attend peut-être sous le village…\n"
	else:
		t += "[color=#9aa7b0]%d épreuve%s réussie%s, %d coffre%s ouvert%s.[/color]\n" % [sum, "s" if sum > 1 else "", "s" if sum > 1 else "", coffres, "s" if coffres > 1 else "", "s" if coffres > 1 else ""]
	return t + "\n"


func _heard_of_seals() -> bool:
	var j: Node = main.get("journal_v56")
	return j != null and str(j.state("porte_scellee")) == "finie"


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return {"xp": xp, "niveau": level, "points": stat_points, "points_talent": talent_points, "stats": stats.duplicate(),
		"talents": talents.keys(), "forge": forge.duplicate(), "sceaux": seals.keys(), "pouvoir": power, "victoires": kills,
		"vu": _seen.duplicate(), "journal_xp": xp_log.duplicate(),
		"especes": kills_kind.duplicate(), "quetes_pnj": quetes_pnj.keys(), "coffres": coffres}


func load_data(d: Dictionary) -> void:
	xp = int(d.get("xp", 0))
	level = clampi(int(d.get("niveau", 1)), 1, MAX_LEVEL)
	stat_points = int(d.get("points", 0))
	talent_points = int(d.get("points_talent", 0))
	stats = {"coeur": 0, "endurance": 0, "force": 0, "agilite": 0}
	var st: Variant = d.get("stats", {})
	if st is Dictionary:
		for k in stats:
			stats[k] = clampi(int((st as Dictionary).get(k, 0)), 0, STAT_MAX)
	talents = {}
	for t in d.get("talents", []):
		talents[str(t)] = true
	forge = {"arme": 0, "armure": 0}
	var fo: Variant = d.get("forge", {})
	if fo is Dictionary:
		forge["arme"] = clampi(int((fo as Dictionary).get("arme", 0)), 0, FORGE_ARME.size() - 1)
		forge["armure"] = clampi(int((fo as Dictionary).get("armure", 0)), 0, FORGE_ARMURE.size() - 1)
	seals = {}
	for s in d.get("sceaux", []):
		if SEALS.has(str(s)):
			seals[str(s)] = true
	power = str(d.get("pouvoir", ""))
	if power != "" and not power_owned(power):
		power = ""
	kills = int(d.get("victoires", 0))
	# V66 : monstres par espèce, quêtes des habitants comptées, coffres
	kills_kind = {}
	var ek: Variant = d.get("especes", {})
	if ek is Dictionary:
		for k2 in ek:
			kills_kind[str(k2)] = int(ek[k2])
	quetes_pnj = {}
	for q in d.get("quetes_pnj", []):
		quetes_pnj[str(q)] = true
	# partie d'avant la V66 : ses quêtes d'habitants déjà faites comptent, en une fois
	_pnj_retro = not d.has("quetes_pnj") and not d.is_empty()
	coffres = int(d.get("coffres", 0))
	_queue = []
	_seen = {}
	var vu: Variant = d.get("vu", null)
	if vu is Dictionary:
		for k in vu:
			_seen[str(k)] = int(vu[k])
		_seen_ready = true
	else:
		# partie d'avant la V63 (ou nouvelle partie) : on comptera ce qui est déjà fait
		_seen_ready = false
	var jl: Variant = d.get("journal_xp", {})
	xp_log = {"monstres": 0, "quetes": 0, "decouvertes": 0}
	if jl is Dictionary:
		for k in xp_log:
			xp_log[k] = int((jl as Dictionary).get(k, 0))
	_poll = 1.0
	apply()
	changed.emit()
