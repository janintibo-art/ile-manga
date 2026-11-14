extends CanvasLayer
## V131 : l'écran de chargement. Avant, on voyait le logo de Godot pendant toute la
## construction du monde (les îles sont fabriquées au lancement), sans rien qui dise que le
## jeu chargeait. Maintenant :
##  - dès le lancement : l'affiche du jeu et « Chargement · Loading · Cargando » (l'image de
##    démarrage du projet, chargement_v131.png) ;
##  - puis cet écran : l'affiche, la barre qui avance, ce qui se construit (« L'Île de Braise
##    se dessine… »), le pourcentage, et une astuce qui change de temps en temps.
## main._ready construit le monde par étapes et laisse passer une image entre deux (await
## pas(...)) : la barre avance pour de vrai. Pendant ce temps, l'arbre est en pause (rien ne
## bouge, rien ne tombe) et les caméras ne voient que le calque 20 (rien à dessiner : ça va
## plus vite). En VR, un panneau flotte devant les yeux avec la même barre.
## Les poids des étapes sont les temps mesurés de chaque construction (ms).

const IMAGE := "res://assets/textures/ui/chargement_affiche.jpg"
const CALQUE_VIDE: int = 1 << 19
## clé -> [ce qui se construit, poids (ms mesurées)]
const ETAPES := {
	"ciel": ["Le ciel et la lumière se lèvent", 60],
	"terre": ["L'île du village sort de l'eau", 2440],
	"village": ["Le village et sa plage", 1100],
	"structures": ["Les maisons, les pontons et le temple", 4370],
	"jungle": ["La jungle pousse", 1770],
	"elfes": ["Le Bois-Doré des elfes", 880],
	"nains": ["La Montagne de Feu des nains", 820],
	"azur": ["Port-Azur et son port", 810],
	"grande": ["La grande île de l'est", 4190],
	"arcanelle": ["Arcanelle, le bourg des magiciens", 1500],
	"balafre": ["La Balafre, l'île des pirates", 1370],
	"soleils": ["L'Île des Trois Soleils", 3090],
	"braise": ["L'Île de Braise", 4160],
	"montjoie": ["L'Île de Montjoie", 2460],
	"boucan": ["L'Île du Boucan", 900],
	"astralys": ["Astralys, l'île flottante", 760],
	"moais": ["L'Île aux Moaïs", 530],
	"pixel": ["L'Île Pixelithique", 320],
	"larsen": ["L'Île de Larsen", 380],
	"neopolis": ["Néopolis", 100],
	"aldente": ["L'Île Al Dente", 670],
	"crayon": ["L'Île Crayonnée", 630],
	"hautefond": ["Hautefond, la cité-colonne", 2310],
	"sombreval": ["Sombreval, la ville morte", 370],
	"geants": ["L'Île des Géants", 1760],
	"heros": ["Le héros se réveille", 410],
	"menu": ["Le carnet de voyage", 650],
	"rivages": ["Les rivages et les vagues", 2160],
	"sons": ["Les sons et la musique", 960],
	"ciel_ile": ["L'île flottante et sa citadelle", 950],
	"atlantide": ["L'Atlantide, au fond de l'océan", 2670],
	"habitants_azur": ["Les habitants de Port-Azur", 1170],
	"fees": ["Le royaume des fées", 1870],
	"grande_vie": ["Les villes de la grande île", 2660],
	"sceaux": ["Les sceaux et les pouvoirs", 510],
	"arcanelle_vie": ["Les sorciers d'Arcanelle", 700],
	"balafre_vie": ["Les pirates de la Balafre", 990],
	"soleils_vie": ["Les pyramides et les temples", 1200],
	"braise_vie": ["Pandémonia et ses Neuf Cercles", 2380],
	"montjoie_vie": ["La Guilde et le Donjon des Mille Marches", 4020],
	"boucan_vie": ["Port-Boucan, la ville libre", 1660],
	"astralys_vie": ["Les Lumens d'Astralys", 690],
	"moais_vie": ["Les petits Moaïs", 730],
	"pixel_vie": ["Le clan des cubes", 220],
	"larsen_vie": ["Les yourtes et le festival", 690],
	"neopolis_vie": ["Les androïdes de Néopolis", 1000],
	"aldente_vie": ["Les adeptes du Spaghetti Volant", 980],
	"crayon_vie": ["Le village des arbres-maisons", 1190],
	"hautefond_vie": ["Hautefond, du ciel au fond de la mer", 4130],
	"sombreval_vie": ["Le château du comte", 1580],
	"geants_vie": ["La ferme des Grandpré", 1500],
	"fin": ["Les bateaux, les oiseaux, les derniers détails", 200],
}
const ASTUCES := [
	"Astuce : clic droit maintenu et la souris pour tourner la caméra et lever les yeux au ciel.",
	"Astuce : à la manette, le stick droit tourne la caméra et lève ou baisse le regard.",
	"Astuce : le carnet (I) garde tes quêtes, tes trouvailles et la carte.",
	"Astuce : un « ! » doré au-dessus d'un habitant, c'est une quête à prendre.",
	"Astuce : un ✦ rose au-dessus d'un habitant, c'est un secret ou un cadeau.",
	"Astuce : clic gauche maintenu après un coup : la lame se charge.",
	"Astuce : la partie s'enregistre toute seule toutes les 90 secondes.",
	"Astuce : les habitants se souviennent de toi, de tes cadeaux… et de tes bêtises.",
	"Astuce : la nuit, les villes changent de vie.",
	"Astuce : un objet perdu au fond de l'eau ? Il t'attend toujours dans le carnet.",
]

var main: Node
var en_cours: bool = false
var apres: Array = []             # appels à faire une fois le monde construit (_spawn_world_v28…)
var fait: float = 0.0
var total: float = 1.0
var etapes_faites: Array = []     # tests
var _root: Control
var _barre: ColorRect
var _fond_barre: ColorRect
var _titre: Label
var _pct: Label
var _astuce: Label
var _astuce_i: int = 0
var _masques: Dictionary = {}     # caméra -> masque d'origine
var _panneau_vr: Node3D
var _vr_label: Label3D
var _vr_barre: MeshInstance3D
var _t0: int = 0
var _affiche: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Chargement_v131"
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	en_cours = true
	_t0 = Time.get_ticks_msec()
	total = 0.0
	for k in ETAPES:
		total += float(ETAPES[k][1])
	_astuce_i = randi() % ASTUCES.size()
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var noir := ColorRect.new()
	noir.color = Color(0.05, 0.09, 0.14)
	noir.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(noir)
	var tex: Texture2D = load(IMAGE) as Texture2D if ResourceLoader.exists(IMAGE) else null
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_root.add_child(img)
	# un voile sombre en bas, pour lire la barre et les textes
	var voile := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.09, 0.14, 0.0))
	g.set_color(1, Color(0.05, 0.09, 0.14, 0.92))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 4
	gt.height = 64
	voile.texture = gt
	voile.anchor_left = 0.0
	voile.anchor_right = 1.0
	voile.anchor_top = 0.55
	voile.anchor_bottom = 1.0
	voile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	voile.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(voile)
	var bande := ColorRect.new()
	bande.color = Color(0.04, 0.07, 0.11, 0.72)
	bande.anchor_left = 0.0
	bande.anchor_right = 1.0
	bande.anchor_top = 0.71
	bande.anchor_bottom = 1.0
	_root.add_child(bande)
	var box := VBoxContainer.new()
	box.anchor_left = 0.12
	box.anchor_right = 0.88
	box.anchor_top = 0.74
	box.anchor_bottom = 0.97
	box.add_theme_constant_override("separation", 10)
	_root.add_child(box)
	var ligne := HBoxContainer.new()
	box.add_child(ligne)
	_titre = Label.new()
	_titre.text = "Les Mondes de Travers s'éveillent"
	_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titre.add_theme_font_size_override("font_size", 26)
	_titre.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	_titre.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.0))
	_titre.add_theme_constant_override("outline_size", 6)
	ligne.add_child(_titre)
	_pct = Label.new()
	_pct.text = "0 %"
	_pct.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_pct.add_theme_font_size_override("font_size", 26)
	_pct.add_theme_color_override("font_color", Color(1, 1, 1))
	_pct.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.0))
	_pct.add_theme_constant_override("outline_size", 6)
	ligne.add_child(_pct)
	# la barre : un cadre sombre et le remplissage doré
	_fond_barre = ColorRect.new()
	_fond_barre.color = Color(0.02, 0.04, 0.07, 0.85)
	_fond_barre.custom_minimum_size = Vector2(0, 16)
	box.add_child(_fond_barre)
	_barre = ColorRect.new()
	_barre.color = Color(1.0, 0.72, 0.22)
	_barre.position = Vector2(2, 2)
	_barre.size = Vector2(0, 12)
	_fond_barre.add_child(_barre)
	_astuce = Label.new()
	_astuce.text = ASTUCES[_astuce_i]
	_astuce.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_astuce.add_theme_font_size_override("font_size", 19)
	_astuce.add_theme_color_override("font_color", Color(0.85, 0.9, 0.96))
	_astuce.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05))
	_astuce.add_theme_constant_override("outline_size", 4)
	box.add_child(_astuce)


## Une étape de plus est construite : la barre avance, on laisse passer une image.
func pas(cle: String) -> void:
	if not en_cours:
		return
	var e: Array = ETAPES.get(cle, ["", 50])
	fait += float(e[1])
	etapes_faites.append(cle)
	# ce qui se construit ensuite : le libellé de l'étape suivante dans l'ordre
	var suivante: String = ""
	var keys: Array = ETAPES.keys()
	var i: int = keys.find(cle)
	if i >= 0 and i + 1 < keys.size():
		suivante = str(ETAPES[keys[i + 1]][0])
	elif i < 0 and cle == "debut":
		suivante = str(ETAPES[keys[0]][0])
	if suivante != "" and _titre != null:
		_titre.text = suivante
		if _vr_label != null:
			_vr_label.text = _tr(suivante) + "…"
	if etapes_faites.size() % 6 == 0 and _astuce != null:
		_astuce_i = (_astuce_i + 1) % ASTUCES.size()
		_astuce.text = ASTUCES[_astuce_i]
	_masquer()
	_panneau()
	_maj()
	await get_tree().process_frame


func _tr(s: String) -> String:
	var L = load("res://scripts/langue_v104.gd")
	return str(L.t(s)) if L != null and L.has_method("t") else s


func progres() -> float:
	return clampf(fait / maxf(total, 1.0), 0.0, 1.0)


func _maj() -> void:
	var k: float = progres()
	if _pct != null:
		_pct.text = "%d %%" % int(round(k * 100.0))
	if _vr_barre != null:
		_vr_barre.scale = Vector3(maxf(k, 0.01), 1, 1)
		_vr_barre.position.x = -0.5 * (1.0 - k) * 0.8


func _process(delta: float) -> void:
	if _barre == null or _fond_barre == null:
		return
	# la barre glisse doucement vers la vraie valeur
	var cible: float = progres()
	_affiche = move_toward(_affiche, cible, delta * 0.8) if cible > _affiche else cible
	_barre.size = Vector2(maxf((_fond_barre.size.x - 4.0) * _affiche, 0.0), maxf(_fond_barre.size.y - 4.0, 4.0))


## Pendant la construction, les caméras ne voient que le calque 20 (le panneau VR) : rien à
## dessiner, le chargement va plus vite.
func _masquer() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var cam: Camera3D = vp.get_camera_3d()
	if cam != null and not _masques.has(cam):
		_masques[cam] = cam.cull_mask
		cam.cull_mask = CALQUE_VIDE


## En VR : un panneau devant les yeux, avec ce qui se construit et la barre.
func _panneau() -> void:
	if _panneau_vr != null or main == null or not bool(main.get("xr_active")):
		return
	var xc: Node3D = main.get("xr_camera")
	if xc == null:
		return
	_panneau_vr = Node3D.new()
	_panneau_vr.name = "Chargement_VR_v131"
	_panneau_vr.position = Vector3(0, 0, -2.0)
	xc.add_child(_panneau_vr)
	var t := Label3D.new()
	t.text = _tr("Les Mondes de Travers") + "\n" + _tr(_titre.text) + "…"
	t.font_size = 64
	t.pixel_size = 0.0025
	t.outline_size = 12
	t.modulate = Color(1.0, 0.86, 0.5)
	t.layers = CALQUE_VIDE
	t.position = Vector3(0, 0.18, 0)
	t.no_depth_test = true
	_panneau_vr.add_child(t)
	_vr_label = t
	for e in [[Color(0.02, 0.04, 0.07), 0.84, 0.07, 0.0, false], [Color(1.0, 0.72, 0.22), 0.8, 0.045, 0.001, true]]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(float(e[1]), float(e[2]))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = e[0]
		m.no_depth_test = true
		q.material = m
		mi.mesh = q
		mi.layers = CALQUE_VIDE
		mi.position = Vector3(0, -0.05, float(e[3]))
		_panneau_vr.add_child(mi)
		if bool(e[4]):
			_vr_barre = mi


## Le monde est construit : les caméras revoient tout, l'écran s'efface en fondu.
func finir() -> void:
	en_cours = false
	fait = total
	_maj()
	var nb_cam: int = _masques.size()
	for cam in _masques:
		if is_instance_valid(cam):
			(cam as Camera3D).cull_mask = int(_masques[cam])
	_masques.clear()
	if _panneau_vr != null and is_instance_valid(_panneau_vr):
		_panneau_vr.queue_free()
	print("ILE_MANGA_V131: monde construit en %.1f s (%d étapes)" % [(Time.get_ticks_msec() - _t0) / 1000.0, etapes_faites.size()])
	if main != null:
		main.set("chargement_bilan_v131", {"secondes": (Time.get_ticks_msec() - _t0) / 1000.0, "etapes": etapes_faites.size(), "cameras": nb_cam})
	for c in apres:
		(c as Callable).call_deferred()
	apres.clear()
	if _root != null:
		var tw := create_tween()
		tw.tween_interval(0.15)
		tw.tween_property(_root, "modulate:a", 0.0, 0.6)
		tw.tween_callback(queue_free)
	else:
		queue_free()
