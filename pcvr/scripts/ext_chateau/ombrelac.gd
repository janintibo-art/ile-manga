extends Node3D
## Extension « Le Château d'Ombrelac » : le chef d'orchestre. Il construit l'île d'Ombrelac
## (ile_ombrelac), le château géant (chateau_ombrelac), l'eau du lac et du torrent, la végétation ;
## il allume les fenêtres le soir. Tout ce qui touche au reste du jeu passe par ici : main.gd
## n'appelle que setup(), build_island(), dock(), build_town(), et lit contains(), owns_point(),
## place_name(), serialize() / load_data().

const IleScript = preload("res://scripts/ext_chateau/ile_ombrelac.gd")
const ChateauScript = preload("res://scripts/ext_chateau/chateau_ombrelac.gd")
const FloreScript = preload("res://scripts/ext_chateau/flore_ombrelac.gd")
const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")

const PLACES := {"ombrelac": "l'île d'Ombrelac", "ombrelac_debarcadere": "le débarcadère d'Ombrelac",
	"ombrelac_guet": "la Colline du Guet", "ombrelac_viaduc": "le grand viaduc", "ombrelac_cour": "la Cour d'Honneur",
	"ombrelac_chateau": "l'Académie d'Ombrelac", "ombrelac_cloitre": "le Cloître", "ombrelac_lac": "le Lac d'Ombre",
	"ombrelac_monts": "les Monts Gris", "ombrelac_gorge": "la gorge du Torrent", "ombrelac_pont": "le Pont Couvert",
	"ombrelac_vents": "la Tour des Vents", "ombrelac_grande_salle": "la Grande Salle d'Ombrelac",
	"ombrelac_bibliotheque": "la Bibliothèque de l'Académie",
	"ombrelac_salle_astres": "la Salle des Astres", "ombrelac_salle_elixirs": "la Salle des Élixirs",
	"ombrelac_amphitheatre": "l'Amphithéâtre", "ombrelac_tour_dortoirs": "la Tour des Dortoirs",
	"ombrelac_dortoir_aube": "le Dortoir de l'Aube", "ombrelac_salle_commune": "la Salle Commune",
	"ombrelac_dortoir_crepuscule": "le Dortoir du Crépuscule",
	"ombrelac_salle_astrolabe": "la Salle de l'Astrolabe", "ombrelac_observatoire": "l'Observatoire",
	"ombrelac_terrasse_astrolabe": "la Terrasse de l'Astrolabe",
	"ombrelac_tour_horloge": "la Tour de l'Horloge", "ombrelac_chambre_rouages": "la Chambre des Rouages"}

var main: Node
var ile: Node3D
var chateau: Node3D
var flore: Node3D
var pc: bool = true
var state := {"visite": false}
var _nuit: float = -1.0
var _clock: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc") or main == null


## Le relief (avant le reste du monde : la hauteur du sol sert à poser les joueurs)
func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_ombrelac"
	add_child(ile)
	ile.build(pc)


## Le débarcadère : [bout côté terre, bout côté mer] (dans le monde)
func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y, 1.0), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y, 1.0)]


## Le château, l'eau, la végétation (après l'heure du jour)
func build_town() -> void:
	_lac()
	_torrent()
	chateau = ChateauScript.new()
	chateau.name = "Chateau_ombrelac"
	add_child(chateau)
	chateau.build(ile)
	var astro: Node = chateau.get_node_or_null("Ombrelac_astrolabe_dedans")
	if astro != null:
		astro.main = main
	var horl: Node = chateau.get_node_or_null("Ombrelac_horloge_dedans")
	if horl != null:
		horl.main = main
	flore = FloreScript.new()
	flore.name = "Flore_ombrelac"
	add_child(flore)
	flore.plant(ile, pc)


func _eau_mat(deep: Color, shallow: Color) -> Material:
	if ResourceLoader.exists("res://shaders/eau_douce_v69.gdshader"):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/eau_douce_v69.gdshader")
		m.set_shader_parameter("deep", deep)
		m.set_shader_parameter("shallow", shallow)
		m.set_shader_parameter("clarity", 3.0)
		if ResourceLoader.exists("res://assets/textures/water/water_n.png"):
			m.set_shader_parameter("ripple_n", load("res://assets/textures/water/water_n.png"))
		return m
	var s := StandardMaterial3D.new()
	s.albedo_color = deep
	s.roughness = 0.05
	return s


## Le Lac d'Ombre : une eau sombre et profonde, presque noire au milieu
func _lac() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c: Vector3 = IleScript.W(IleScript.LAC.x, IleScript.LAC.y, IleScript.LAC_Y)
	var n: int = 96
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var p1: Vector3 = c + Vector3(cos(a0) * IleScript.LAC_AX.x, 0, sin(a0) * IleScript.LAC_AX.y) * 1.12
		var p2: Vector3 = c + Vector3(cos(a1) * IleScript.LAC_AX.x, 0, sin(a1) * IleScript.LAC_AX.y) * 1.12
		for p in [c, p2, p1]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.x, p.z) * 0.1)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.name = "Lac_ombrelac"
	mi.mesh = st.commit()
	mi.material_override = _eau_mat(Color(0.02, 0.07, 0.09, 1.0), Color(0.1, 0.24, 0.24, 1.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Le torrent dans la gorge : un ruban d'eau qui suit le lit, du lac à la mer
func _torrent() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = IleScript.GORGE
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var steps: int = 0
	for i in range(pts.size() - 1):
		var a := Vector2(float(pts[i][0]), float(pts[i][1]))
		var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		var seg: int = int(a.distance_to(b) / 4.0)
		for j in range(seg + (1 if i == pts.size() - 2 else 0)):
			var t: float = float(j) / seg
			var p: Vector2 = a.lerp(b, t)
			var dir: Vector2 = (b - a).normalized()
			var side := Vector2(-dir.y, dir.x)
			var y: float = maxf(lerpf(float(pts[i][2]), float(pts[i + 1][2]), t) + 0.45, IleScript.WATER + 0.05)
			var l: Vector3 = IleScript.W(p.x + side.x * (IleScript.GORGE_W + 3.0), p.y + side.y * (IleScript.GORGE_W + 3.0), y)
			var r: Vector3 = IleScript.W(p.x - side.x * (IleScript.GORGE_W + 3.0), p.y - side.y * (IleScript.GORGE_W + 3.0), y)
			if steps > 0:
				for q in [prev_l, l, r, prev_l, r, prev_r]:
					st.set_normal(Vector3.UP)
					st.set_uv(Vector2(q.x, q.z) * 0.1)
					st.add_vertex(q)
			prev_l = l
			prev_r = r
			steps += 1
	var mi := MeshInstance3D.new()
	mi.name = "Torrent_ombrelac"
	mi.mesh = st.commit()
	mi.material_override = _eau_mat(Color(0.05, 0.16, 0.17, 1.0), Color(0.2, 0.36, 0.33, 1.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# =================================================================== le monde

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z)


func owns_point(p: Vector3) -> bool:
	return contains(p) and ile.height(p.x, p.z) > IleScript.WATER - 0.5


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	if l.distance_to(IleScript.DOCK_A) < 30.0:
		return "ombrelac_debarcadere"
	if l.distance_to(IleScript.AIGUILLE) < IleScript.AIGUILLE_R + 4.0:
		return "ombrelac_vents"
	if l.distance_to(IleScript.ROC) < IleScript.ROC_R0 and p.y > IleScript.ROC_Y - 3.0:
		var c: Vector2 = l - IleScript.ROC
		if absf(c.x) < 28.6 and c.y > -5.1 and c.y < 13.1:
			return "ombrelac_grande_salle"
		if c.x > 46.7 and c.x < 57.3 and c.y > -28.8 and c.y < 12.8:
			return "ombrelac_bibliotheque"
		if c.distance_to(Vector2(41.5, -46.0)) < 4.6:
			return "ombrelac_tour_dortoirs"
		var dh: Vector2 = c - Vector2(36.0, 34.0)
		if absf(dh.x) < 6.0 and absf(dh.y) < 6.0 and p.y < IleScript.ROC_Y + 40.0:
			return "ombrelac_chambre_rouages" if p.y > IleScript.ROC_Y + 27.5 else "ombrelac_tour_horloge"
		var d: Vector2 = c - Vector2(-44.0, -26.0)
		if absf(d.x) < 9.5 and absf(d.y) < 9.5:
			if p.y > IleScript.ROC_Y + 53.0:
				# l'octogone : |x|, |z| et |x|±|z| sous l'apothème
				var a: float = 5.9
				if absf(d.x) < a and absf(d.y) < a and (absf(d.x) + absf(d.y)) < a * 1.4142:
					return "ombrelac_observatoire"
				return "ombrelac_terrasse_astrolabe"
			if p.y < IleScript.ROC_Y + 11.5:
				return "ombrelac_salle_astrolabe"
		if c.y > -51.3 and c.y < -40.7 and c.x > -11.4 and c.x < 37.4 and p.y > IleScript.ROC_Y + 5.7:
			if c.x < 0.5:
				return "ombrelac_dortoir_aube"
			if c.x > 1.1 and c.x < 22.9:
				return "ombrelac_salle_commune"
			if c.x > 23.5:
				return "ombrelac_dortoir_crepuscule"
		if c.y > -51.3 and c.y < -40.7 and c.x > -11.4 and c.x < 35.4:
			if c.x < 0.5:
				return "ombrelac_salle_astres"
			if c.x > 1.1 and c.x < 22.9:
				return "ombrelac_salle_elixirs"
			if c.x > 23.5:
				return "ombrelac_amphitheatre"
		if c.x > -18.0 and c.x < 38.0 and c.y > -37.0 and c.y < -9.0:
			return "ombrelac_cloitre"
		if c.y > 20.0 and absf(c.x) < 30.0:
			return "ombrelac_cour"
		return "ombrelac_chateau"
	if absf(l.x - IleScript.ROC.x) < 6.0 and l.y > IleScript.VIADUC_N.z and l.y < IleScript.VIADUC_S.z and p.y > 30.0:
		return "ombrelac_viaduc"
	if l.distance_to(IleScript.GUET) < IleScript.GUET_R1 * 0.7:
		return "ombrelac_guet"
	if IleScript.lac_q(l.x, l.y) < 1.0 and p.y < IleScript.LAC_Y + 4.0:
		return "ombrelac_lac"
	if IleScript.gorge_at(l.x, l.y).x < IleScript.GORGE_E:
		return "ombrelac_gorge"
	if l.y < -120.0:
		return "ombrelac_monts"
	return "ombrelac"


func place_name(p: Vector3) -> String:
	return str(PLACES.get(zone_at(p), PLACES["ombrelac"]))


## Où l'on arrive (téléportation, réveil) : [position, direction du regard]
func village_point(id: String) -> Array:
	match id:
		"ombrelac_cour":
			var c: Vector3 = chateau.position + chateau.lieux.get("cour", Vector3.ZERO)
			return [c + Vector3(0, 0.2, 0), Vector3(0, 0, -1)]
	var d: Array = dock()
	var at: Vector3 = d[0] + Vector3(0, 0, -6.0)
	at.y = ile.height(at.x, at.z) + 0.1
	return [at, Vector3(0, 0, -1)]


func respawn_point() -> Array:
	return village_point("ombrelac")


func on_faint(_p: Vector3) -> void:
	pass


# =================================================================== la vie

## L'heure du jeu (0..24) ; midi si on ne la connaît pas
func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _process(delta: float) -> void:
	_clock += delta
	if _clock < 0.5:
		return
	_clock = 0.0
	var h: float = hour()
	# les fenêtres s'allument au crépuscule, s'éteignent à l'aube
	var nuit: float = 1.0 - smoothstep(6.0, 7.5, h) + smoothstep(18.5, 20.5, h)
	nuit = clampf(nuit, 0.0, 1.0)
	if absf(nuit - _nuit) > 0.01:
		_nuit = nuit
		for m in Kit.vitres():
			(m as ShaderMaterial).set_shader_parameter("nuit", nuit)
		for nom in ["Ombrelac_interieurs", "Ombrelac_bibliotheque", "Ombrelac_salles", "Ombrelac_dortoirs", "Ombrelac_astrolabe_dedans", "Ombrelac_horloge_dedans"]:
			var inter: Node = chateau.get_node_or_null(nom) if chateau != null else null
			if inter != null:
				inter.set_nuit(nuit)
	if main != null and not state["visite"] and main.has_method("_player_pos_v27") and owns_point(main._player_pos_v27()):
		state["visite"] = true


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = {"visite": false}
	for k in d:
		state[k] = d[k]
