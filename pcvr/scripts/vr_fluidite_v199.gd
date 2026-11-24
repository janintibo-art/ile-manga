extends Node
## V199 : la fluidité en VR, sans toucher à ce qu'on voit. Mesuré dans le casque (Quest 3 par Link,
## RTX 4070) : au village, la carte graphique mettait 34 ms par image (il en faut moins de 13,9 pour
## 72 images/s) et dessinait 37 millions de triangles. D'où ils venaient :
##   - sept modèles (les deux maisons du village, le feu de camp, le mur de son, la table de mixage, le
##     distributeur, l'île flottante) pèsent 0,6 à 2 millions de triangles chacun : des triangles d'un
##     centimètre, plus petits qu'un point de l'écran à cinq mètres, dessinés cinq fois par image (les
##     deux yeux, la passe de profondeur, les étages de l'ombre du soleil). Ces modèles ont des versions
##     allégées, calculées par Godot à l'import : on leur demande de s'en servir un peu plus tôt (écart
##     toléré : 2 points d'écran au lieu de 0,6) ;
##   - le seuil de détail des formes : 1 point d'écran (le réglage d'origine de Godot) au lieu de 0,6 ;
##   - le bord des ombres : adouci en qualité « haute » au lieu d'« ultra » ;
##   - l'herbe rase et les petites fleurs (moins de 70 cm) ne projettent plus d'ombre : on ne la voyait pas.
## Gain mesuré au village : 6 ms pour les trois derniers ; les modèles lourds, eux, y pèsent les trois quarts
## des triangles. Rien de cela ne s'applique au jeu sur PC.
## V203 : de près, ces sept modèles restaient entiers (jusqu'à 2 millions de triangles pour une maison).
## En fluidité optimisée, le casque reçoit leur version « casque » (res://allege/, fabriquée par
## tools/alleger_v203.gd) : huit à trente fois moins de triangles, à 2,5 cm près au plus de l'original.
## Menu > Paramètres > « Fluidité VR » : optimisée (au départ) ou détail maximum (comme avant).

const REGLAGES := "user://reglages_son.cfg"
const SEUIL_FLUIDE := 1.0
const SEUIL_MAX := 0.6
const LOURD := 200000            # triangles : au-delà, un modèle est « lourd »
const BIAIS_LOURD := 0.5         # ses versions allégées arrivent deux fois plus tôt
const PLANTE_BASSE := 0.7        # m : en dessous, une nappe de plantes ne fait pas d'ombre

# V203 : les versions « casque », rangées par nombre de triangles du modèle d'origine
const CASQUE := {
	2094153: "res://allege/Petite_maison_2094153.res",
	1923054: "res://allege/Maison_1923054.res",
	614603: "res://allege/Ile_flottante_614603.res",
	1727404: "res://allege/Mur_de_son_1727404.res",
	1530130: "res://allege/Feu_1530130.res",
	1252914: "res://allege/Distributeur_8_6_1252914.res",
	623612: "res://allege/Table_de_mixage_623612.res",
}

var main: Node
var entiers: Dictionary = {}     # modèle lourd -> son maillage d'origine
var casques: Dictionary = {}     # modèle lourd -> sa version « casque »
var fluide: bool = true
var lourds: Array = []           # les modèles lourds trouvés
var basses: Array = []           # les nappes de petites plantes
var _poids: Dictionary = {}      # maillage -> triangles


func setup(main_node: Node) -> void:
	main = main_node
	name = "Fluidite_VR_v199"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGES) == OK:
		fluide = bool(cfg.get_value("vr", "fluide", true))
	main.add_child(self)
	for n in main.find_children("*", "GeometryInstance3D", true, false):
		_regler(n)
	get_tree().node_added.connect(_ajoute)
	appliquer()
	print("ILE_MANGA_V199: fluidité VR ", "optimisée" if fluide else "au détail maximum")


func libelle() -> String:
	return "Fluidité VR : optimisée" if fluide else "Fluidité VR : détail maximum"


func basculer() -> void:
	fluide = not fluide
	var cfg := ConfigFile.new()
	cfg.load(REGLAGES)
	cfg.set_value("vr", "fluide", fluide)
	cfg.save(REGLAGES)
	appliquer()


func _ajoute(n: Node) -> void:
	if n is GeometryInstance3D:
		_regler.call_deferred(n)


## Le jeu calcule les mouvements au rythme du casque (72, 80, 90 ou 120 fois par seconde). Avant : 90
## calculs par seconde pour 72 images : une image sur quatre avançait de deux pas au lieu d'un, et la
## marche comme la rotation tremblaient, même quand la carte graphique suivait.
var _horloge: float = 0.0
var rythme: int = 0


func _process(delta: float) -> void:
	_horloge -= delta
	if _horloge > 0.0:
		return
	_horloge = 1.0
	var xr: XRInterface = XRServer.primary_interface
	if xr == null or not (xr is OpenXRInterface):
		return
	var hz: int = int(round((xr as OpenXRInterface).display_refresh_rate))
	if hz >= 60 and hz <= 144 and hz != rythme:
		rythme = hz
		Engine.physics_ticks_per_second = hz
		print("ILE_MANGA_V199: mouvements calculés au rythme du casque, ", hz, " fois par seconde")


func _triangles(m: Mesh) -> int:
	if not (m is ArrayMesh):
		return 0
	if _poids.has(m):
		return _poids[m]
	var t := 0
	var am: ArrayMesh = m
	for s in am.get_surface_count():
		var il: int = am.surface_get_array_index_len(s)
		t += (il if il > 0 else am.surface_get_array_len(s)) / 3
	_poids[m] = t
	return t


## Un objet vient d'arriver dans le monde : est-ce un modèle lourd, une nappe de petites plantes ?
func _regler(n: Variant) -> void:
	# (l'objet a pu être retiré entre-temps)
	if not is_instance_valid(n) or not (n as Node).is_inside_tree():
		return
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		if mi.mesh != null and _triangles(mi.mesh) > LOURD and not lourds.has(mi):
			lourds.append(mi)
			mi.lod_bias = BIAIS_LOURD if fluide else 1.0
			var chemin: String = CASQUE.get(_triangles(mi.mesh), "")
			if chemin != "" and ResourceLoader.exists(chemin):
				var leger: ArrayMesh = load(chemin) as ArrayMesh
				if leger != null and leger.get_surface_count() == mi.mesh.get_surface_count():
					for s in leger.get_surface_count():
						leger.surface_set_material(s, mi.mesh.surface_get_material(s))
					entiers[mi] = mi.mesh
					casques[mi] = leger
					if fluide:
						mi.mesh = leger
	elif n is MultiMeshInstance3D:
		var mm: MultiMeshInstance3D = n
		if mm.multimesh == null or mm.multimesh.mesh == null or mm.multimesh.instance_count < 40:
			return
		if mm.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or basses.has(mm):
			return
		var h: float = mm.multimesh.mesh.get_aabb().size.y
		if h > 0.0 and h < PLANTE_BASSE:
			basses.append(mm)
			if fluide:
				mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func appliquer() -> void:
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.mesh_lod_threshold = SEUIL_FLUIDE if fluide else SEUIL_MAX
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH if fluide else RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	for mi in lourds:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).lod_bias = BIAIS_LOURD if fluide else 1.0
			if casques.has(mi):
				(mi as MeshInstance3D).mesh = casques[mi] if fluide else entiers[mi]
	for mm in basses:
		if is_instance_valid(mm):
			(mm as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if fluide else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
