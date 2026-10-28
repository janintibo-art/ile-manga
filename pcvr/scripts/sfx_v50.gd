extends Node3D
## V50 : les bruitages d'action.
## play("nom", position) joue une variante au hasard d'un bruitage (www/assets/sons/sfx/
## nom_1.ogg, nom_2.ogg…), placé dans le monde (son 3D) ou non (interface) si on ne donne
## pas de position. Hauteur légèrement variée à chaque fois pour éviter l'effet « disque
## rayé ». Les pas suivent la marche du joueur et changent selon le sol (herbe, sable, pierre,
## bois, cendre, eau) ; la barque fait clapoter l'eau quand elle avance.
## Tous les sons passent par le bus « Bruitages ».

const DIR := "res://assets/sons/sfx/"
## Volume (dB) de chaque famille de bruitages ; 0 par défaut.
const DB := {
	"pas_herbe": -15.0, "pas_sable": -16.0, "pas_pierre": -15.0, "pas_bois": -13.0, "pas_cendre": -14.0, "pas_eau": -14.0,
	"atterrissage": -8.0, "fendre_air": -8.0, "fendre_lourd": -6.0, "touche_chair": -4.0, "touche_lourd": -3.0,
	"touche_pierre": -4.0, "touche_carapace": -4.0, "touche_bois": -5.0, "parade": -4.0, "jarre_casse": -4.0,
	"joueur_blesse": -6.0, "ramasse": -8.0, "ramasse_pieces": -8.0, "ramasse_gemme": -9.0, "ramasse_pierre": -8.0,
	"ramasse_bois": -8.0, "manger": -6.0, "jeter": -8.0, "equiper": -10.0, "coffre": -3.0, "porte_ouvre": -5.0,
	"porte_ferme": -5.0, "grille": -3.0, "pierre_glisse": -2.0, "serrure": -6.0, "hache": -4.0, "arbre_tombe": -2.0,
	"pelle": -6.0, "lancer": -10.0, "plouf": -6.0, "gros_plouf": -5.0, "moulinet": -14.0, "ferrage": -8.0, "rame": -14.0,
	"ui_ouvrir": -12.0, "ui_fermer": -12.0, "ui_choix": -14.0, "ui_clic": -14.0, "ui_dialogue": -12.0, "ui_erreur": -10.0,
	"ui_quete": -8.0, "boss_cri": 0.0,
	"plongeon": -4.0, "nage": -8.0, "nage_sous": -9.0, "bulles": -10.0, "respiration": -6.0, "suffoque": -4.0,
	"requin_menace": -3.0, "requin_morsure": -2.0, "requin_mort": -3.0, "meduse_pique": -5.0, "dauphin": -6.0,
	"perle": -4.0, "cristal_eveil": 0.0,
	"cloche": -3.0, "cloche_bateau": -5.0, "corne_brume": -2.0,
	"plante_menace": -4.0, "plante_mort": -5.0, "ronce_menace": -4.0, "teleport": -5.0, "fleur_tourne": -9.0, "racines": -3.0,
	"porte_ygg": -2.0, "vapeur": -6.0, "tesla": -5.0, "boum": -2.0, "bip": -8.0, "confettis": -6.0, "esprit": -4.0, "rune_0": -6.0, "rune_1": -6.0, "rune_2": -6.0, "rune_3": -6.0, "rune_4": -6.0,
	"tambour": -4.0, "clochette": -8.0, "ascenseur": -8.0, "tyrolienne": -6.0, "course_depart": -4.0, "course_arrivee": -3.0,
	# V63 : le héros, les pouvoirs des sceaux, la grande enquête, le Cœur-de-Pierre
	"niveau": -10.0, "double_saut": -10.0, "charge_pret": -8.0, "coup_charge": -5.0, "tournoyante": -6.0, "parade_parfaite": -4.0,
	"esquive": -9.0, "armure_bloque": -6.0, "forge": -4.0, "bourrasque": -4.0, "flamme_lance": -5.0, "flamme_impact": -4.0,
	"rouage": -5.0, "lueur": -6.0, "sceau_eveil": -3.0, "sceau_pose": -2.0, "porte_coeur": 0.0, "feu_ronces": -3.0,
	"mecanisme": -4.0, "eau_vanne": -4.0, "geyser": -4.0, "vague": -3.0, "lame": -6.0, "dard": -5.0, "dalle_clic": -4.0,
	"piston": -3.0, "ombre_mains": -5.0, "onde_choc": -1.0, "rune_brisee": -2.0, "boss_coeur_cri": 0.0,
	"scorpion_menace": -4.0, "scorpion_mort": -4.0, "automate_menace": -4.0, "automate_mort": -3.0, "spectre_menace": -5.0,
	"spectre_mort": -5.0, "ondin_menace": -4.0, "ondin_mort": -4.0, "loup_menace": -2.0,
	# V66 : objets à casser, coffres fermés à clé, boire
	"caisse_casse": -3.0, "tonneau_casse": -3.0, "panier_casse": -6.0, "coffre_verrou": -6.0, "boire": -7.0, "rot": -8.0, "hoquet": -9.0,
	# V67 : Arcanelle, l'île des sorciers, et ses six sorts
	"sort_lumiere": -7.0, "sort_gel": -6.0, "sort_levitation": -8.0, "sort_telekinesie": -7.0, "sort_soin": -7.0,
	"brasero": -4.0, "rune_arc": -5.0,
	# V68 : l'Île de la Balafre (bagarres, dés, perroquets, crocodiles, squelettes)
	"coup_poing": -4.0, "ko": -5.0, "foule_bagarre": -9.0, "des_roule": -7.0, "perroquet": -8.0,
	"croco_menace": -3.0, "croco_mort": -4.0, "squelette_menace": -5.0, "squelette_mort": -4.0, "os_choc": -1.0,
	# V69 : l'Île des Trois Soleils et ses donjons
	"momie_menace": -4.0, "momie_mort": -4.0, "jaguar_menace": -3.0, "jaguar_mort": -4.0, "chauve_souris_cri": -6.0,
	"ammit_cri": 0.0, "apophis_cri": 0.0, "camazotz_cri": 0.0, "cipactli_cri": 0.0, "chat": -8.0, "balle": -4.0, "conque": -2.0,
	"sistre": -5.0, "battement": -3.0, "pluie_feu": -3.0, "sable_effondre": -3.0, "verser": -6.0, "statue_parle": -2.0,
	"tambour_azteque": -4.0, "flute_maya": -5.0,
	# V70 : l'Île de Braise, Pandémonia, l'Arène, la Fête des Lanternes et les Neuf Cercles
	"lave_bulles": -6.0, "lave_gerbe": -3.0, "feu_souffle": -4.0, "demon_rire": -5.0, "diablotin_cri": -5.0, "diablotin_mort": -5.0,
	"chien_enfer_aboi": -3.0, "chien_enfer_grogne": -4.0, "chien_enfer_mort": -4.0, "gargouille_cri": -3.0, "gargouille_mort": -3.0,
	"ailes_pierre": -5.0, "ombre_murmure": -6.0, "furie_cri": -4.0, "cerbere_aboi": 0.0, "cerbere_ronfle": -2.0, "charon_rame": -6.0,
	"obole": -6.0, "glace_craque": -4.0, "souffle_givre": -3.0, "titan_rugit": 0.0, "titan_pas": -2.0, "chaines": -5.0,
	"grande_porte": -2.0, "cloche_cathedrale": -3.0, "arene_foule": -4.0, "arene_gong": -2.0, "artifice_depart": -5.0,
	"artifice_eclat": -3.0, "lanterne_allume": -6.0, "forge_marteau": -5.0, "geryon_ailes": -3.0, "contrat_signe": -5.0,
	"bain_soufre": -6.0, "automate_pas": -5.0, "gorgoth_cri": -1.0, "spectre_givre_cri": -4.0,
	"cocyte_vent_coup": -4.0,
	# V71 : l'Île de Montjoie (slimes, grenouilles géantes, gobelins, navets fuyards, mimiques) et les compagnons
	"slime_saut": -8.0, "slime_mort": -5.0, "slime_roi_cri": 0.0, "slime_divise": -2.0, "grenouille_coasse": -3.0,
	"grenouille_langue": -4.0, "grenouille_avale": -2.0, "grenouille_recrache": -2.0, "gobelin_cri": -4.0, "gobelin_mort": -4.0,
	"gobelin_chef_cri": -2.0, "navet_cri": -6.0, "navet_attrape": -5.0, "mimique_morsure": -3.0, "mimique_reveil": -3.0,
	"eclair": -1.0, "eclair_rate": -3.0, "charge_chevalier": -3.0, "chute_armure": -3.0,
	"alerte_cloche": -8.0, "guilde_tampon": -2.0, "rang_monte": -3.0, "cristal_mesure": -4.0, "soin": -4.0, "benediction": -4.0,
	"pas_armure": -6.0, "rocher_roule": -2.0, "piege_dalle": -3.0, "fleche_piege": -3.0, "levier": -4.0, "cristal_retour": -3.0,
	"porte_donjon": -3.0, "moulin": -6.0, "coffre_pieces": -4.0, "lit_dodo": -5.0, "luth": -5.0,
	# V75 : l'Île du Boucan (robots de Lisse & Fils, drones-huissiers, la Grande Pelleteuse, champignards, animaux)
	"robot_bip": -8.0, "robot_servo": -7.0, "robot_pas": -8.0, "robot_mort": -3.0, "robot_voix": -5.0, "drone_vol": -9.0, "drone_zap": -4.0, "soudure": -5.0, "pelleteuse_cri": 0.0, "pelleteuse_frappe": -1.0, "durite": -2.0, "champignard_pouf": -5.0, "champignard_rire": -6.0, "eternuement": -4.0, "aboiement": -5.0, "aboiement_petit": -6.0, "chat_miaou": -8.0, "pigeon": -7.0,
	"sirene_alerte": -4.0, "radio_jingle": -6.0, "champi_magie": -5.0, "champi_fin": -7.0, "bombe_peinture": -6.0, "foule_acclame": -6.0, "pogo": -6.0,
	# V76 : Astralys (rayon d'accueil, ponts de lumière, hologrammes, soucoupes, apesanteur, Lumens), les compagnons, le chantier naval, l'aéronef
	"rayon_montee": -5.0, "rayon_descente": -5.0, "pont_lumiere": -8.0, "holo_bip": -10.0, "fontaine_holo": -10.0, "cristal_chante": -8.0, "teleporteur": -5.0, "soucoupe_vol": -9.0, "soucoupe_pose": -5.0, "deltaplane_vent": -10.0, "helice_pedale": -8.0, "aeronef_moteur": -8.0, "aeronef_evolue": -5.0, "bateau_vapeur": -8.0, "bateau_cristal": -10.0, "bateau_evolue": -5.0, "confettis_canon": 0.0, "scie": -3.0, "marteau_chantier": -2.0, "miaou": -7.0, "ronron": -3.0, "couinement_rat": -9.0, "groin": -7.0, "grouik": -6.0, "creuse_cochon": -6.0, "sifflet_compagnons": -9.0, "etoile_filante": -7.0, "meteorite_impact": -4.0, "apesanteur_saut": -8.0, "anneau_passe": -7.0, "glorb_rire": -6.0, "lumen_salut": -8.0,
}
const STRIDE: float = 0.72          # un pas tous les 72 cm

var main: Node
var variants: Dictionary = {}       # nom -> [AudioStream]
var _pool3d: Array = []
var _pool2d: Array = []
var _i3: int = 0
var _i2: int = 0
var _rng := RandomNumberGenerator.new()
var _walked: float = 0.0
var _last_pos: Vector3 = Vector3.INF
var _paddle: float = 0.0
var last_played: String = ""        # pour les tests
var played: Dictionary = {}         # nom -> nombre de fois joué (pour les tests)
var surface: String = ""


func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	var bus: int = AudioServer.get_bus_index("Bruitages")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Bruitages")
		AudioServer.set_bus_send(bus, "Master")
	for i in range(16):
		var p := AudioStreamPlayer3D.new()
		p.name = "Bruitage3D_%d" % i
		p.bus = "Bruitages"
		p.unit_size = 4.0
		p.max_distance = 45.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_pool3d.append(p)
	for i in range(6):
		var q := AudioStreamPlayer.new()
		q.name = "Bruitage2D_%d" % i
		q.bus = "Bruitages"
		add_child(q)
		_pool2d.append(q)
	for name in DB:
		_variants(str(name))


func _variants(name: String) -> Array:
	if variants.has(name):
		return variants[name]
	var list: Array = []
	for k in range(1, 9):
		var path: String = DIR + "%s_%d.ogg" % [name, k]
		if not ResourceLoader.exists(path):
			break
		list.append(load(path))
	variants[name] = list
	return list


## Joue un bruitage. at = position dans le monde (null : son d'interface, sans position).
func play(name: String, at: Variant = null, db: float = 0.0, pitch_spread: float = 0.08) -> void:
	var list: Array = _variants(name)
	if list.is_empty():
		return
	var stream: AudioStream = list[_rng.randi() % list.size()]
	var vol: float = float(DB.get(name, 0.0)) + db
	var pitch: float = 1.0 + _rng.randf_range(-pitch_spread, pitch_spread)
	last_played = name
	played[name] = int(played.get(name, 0)) + 1
	if at == null:
		var q: AudioStreamPlayer = _pool2d[_i2]
		_i2 = (_i2 + 1) % _pool2d.size()
		q.stream = stream
		q.volume_db = vol
		q.pitch_scale = pitch
		q.play()
		return
	var p: AudioStreamPlayer3D = _pool3d[_i3]
	_i3 = (_i3 + 1) % _pool3d.size()
	p.global_position = at
	p.stream = stream
	p.volume_db = vol
	p.pitch_scale = pitch
	var d: Node = main.get("donjon_v35")
	var mv: Node = main.get("maisons_v81")
	var house: bool = mv != null and bool(mv.get("inside"))
	p.bus = "Ambiance_grotte" if d != null and d.is_inside(at) and not house and AudioServer.get_bus_index("Ambiance_grotte") >= 0 else "Bruitages"
	p.play()


## Joué à la position du joueur.
func here(name: String, db: float = 0.0) -> void:
	play(name, main._player_pos_v27() + Vector3.UP * 0.8, db)


# =================================================================== pas et barque

func _process(delta: float) -> void:
	if main == null or not bool(main.game_started):
		_last_pos = Vector3.INF
		return
	# V54 : en vol sur Ventaile, pas de pas (les ailes s'entendent, voir ciel_v54.gd)
	var sky: Node = main.get("ciel_v54")
	if sky != null and bool(sky.riding):
		_last_pos = Vector3.INF
		return
	var ae: Node = main.get("aeronef_v76")
	if ae != null and bool(ae.riding):
		_last_pos = Vector3.INF
		return
	# V55 : en nageant, pas de pas (les brasses s'entendent, voir mer_v55.gd)
	var sea: Node = main.get("mer_v55")
	if sea != null and bool(sea.swimming):
		_last_pos = Vector3.INF
		return
	var boat: Node = main.get("boat_v29")
	if boat != null and bool(boat.driving):
		_last_pos = Vector3.INF
		# La rame : un clapotis à chaque coup de rame, plus rapproché quand on va vite.
		var spd: float = absf(float(boat.speed))
		if spd > 0.4:
			_paddle -= delta * clampf(spd / 3.0, 0.4, 1.4)
			if _paddle <= 0.0:
				_paddle = 1.1
				play("rame", boat.hull.global_position + Vector3.UP * 0.2)
		return
	var body: CharacterBody3D = main.vr_body if bool(main.xr_active) else main.pc_body
	if body == null:
		return
	var pos: Vector3 = body.global_position
	if _last_pos == Vector3.INF or pos.distance_to(_last_pos) > 3.0:
		_last_pos = pos
		return
	var step: float = Vector2(pos.x - _last_pos.x, pos.z - _last_pos.z).length()
	_last_pos = pos
	# L'image peut être plus rapide que la physique : une image sans déplacement ne remet
	# pas le compteur à zéro ; seul le saut (pieds en l'air) le fait.
	if not body.is_on_floor():
		_walked = minf(_walked, STRIDE * 0.5)
		return
	if step < 0.0005:
		return
	_walked += step
	if _walked >= STRIDE:
		_walked = 0.0
		surface = _surface(body)
		play("pas_" + surface, pos + Vector3.UP * 0.05, 0.0, 0.1)


## La matière sous les pieds : d'après le corps physique touché, sinon l'altitude.
func _surface(body: CharacterBody3D) -> String:
	var pos: Vector3 = body.global_position
	var space := body.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.4, pos + Vector3.DOWN * 1.2, 1, [body.get_rid()])
	var hit := space.intersect_ray(q)
	var name: String = str(hit.collider.name) if not hit.is_empty() and hit.collider != null else ""
	var d: Node = main.get("donjon_v35")
	if d != null and d.is_inside(pos):
		return "pierre"
	if name.contains("Ponton") or name.begins_with("Interieur_") or name.begins_with("Elfes_collision") or name.contains("Tronc"):
		return "bois"
	# V54 : la Citadelle (pierre), le nid (pierre), la prairie de l'île flottante (herbe)
	if name.begins_with("Ciel_chateau") or name.begins_with("Nid_collision"):
		return "pierre"
	if name.begins_with("Ciel_sol"):
		return "herbe"
	# V55 : sous le dôme de l'Atlantide, tout est marbre et mosaïque
	var sea2: Node = main.get("mer_v55")
	if sea2 != null and sea2.atl != null and sea2.atl.in_dome(pos + Vector3.UP * 0.9):
		return "pierre"
	if name.begins_with("Donjon") or name.begins_with("Nains_collision") or name.begins_with("Falaise") or name.begins_with("Village_collision") or name.begins_with("Royaume"):
		return "pierre"
	var h: float = main._height_at(pos.x, pos.z)
	if h < -0.12:
		return "eau"
	if name.begins_with("Sol_nains"):
		# Le dallage de la terrasse de Forgefer est posé sur le sol de l'île.
		var n: Node = main.get("nains_v46")
		if n != null and n.forge_root != null:
			var c: Vector3 = (n.forge_root as Node3D).global_position
			if Vector2(pos.x - c.x, pos.z - c.z).length() < float(n.ile.TERRACE_SIZE) - 1.0 and absf(pos.y - c.y) < 2.5:
				return "pierre"
		return "sable" if h < 1.2 else "cendre"
	if h < 1.4:
		return "sable"
	return "herbe"
