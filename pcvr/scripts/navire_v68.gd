extends "res://scripts/navire_v60.gd"
## V68 : les navires de Port-Coutelas, sur le modèle du galion de la Murène Noire (V60) : même
## coque, même pont, même mâture, mais chacun sa taille (le repère du navire est mis à
## l'échelle : le galion 1, le brick 3/4, le sloop à peine plus de la moitié), sa coque (couleur,
## bande), ses voiles et son pavillon :
##  - Le Requin Borgne (la capitaine Anne-Rose Corbeau) : coque noire, bande verte, voiles grises ;
##  - La Veuve Écarlate (Barnabé Jambe-de-Bois) : coque rouge sombre, bande noire, voiles rouges ;
##  - La Morue Enragée (Hector Bouche-d'Or) : coque bleu délavé, bande blanche, voiles blanches ;
##  - Le Sans-Pitié : un vieux sloop couché sur la grève de carénage (sans mâts, en réparation).
## Les passerelles passent par-dessus le plat-bord (une rampe de chaque côté).

const PI68 := "res://assets/textures/pirates/"
const PALETTES := {
	"requin": {"tint": Color(0.42, 0.38, 0.36), "band": Color(0.12, 0.38, 0.24), "voile": "voile_grise", "pavillon": "pavillon_requin", "graine": 6861},
	"veuve": {"tint": Color(0.72, 0.36, 0.3), "band": Color(0.08, 0.07, 0.07), "voile": "voile_rouge", "pavillon": "pavillon_veuve", "graine": 6862},
	"morue": {"tint": Color(0.5, 0.6, 0.7), "band": Color(0.86, 0.84, 0.78), "voile": "voile_blanche", "pavillon": "pavillon_morue", "graine": 6863},
	"sanspitie": {"tint": Color(0.55, 0.5, 0.44), "band": Color(0.3, 0.26, 0.2), "voile": "voile_grise", "pavillon": "pavillon_balafre", "graine": 6864},
}

var who: String = "requin"
var k: float = 1.0                       # l'échelle du navire
var masts: bool = true


func setup68(id: String, scale_k: float, with_masts: bool = true) -> void:
	who = id
	k = scale_k
	masts = with_masts


## Pose le navire à l'échelle k (le repère du navire garde ses mesures : tout se convertit).
func place(at: Vector3, yaw: float) -> void:
	place_xf(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * k), at))


## Un repère quelconque (le Sans-Pitié est couché sur le flanc) ; la mise à l'échelle k est ajoutée.
func place_xf(x: Transform3D) -> void:
	if absf(x.basis.get_scale().x - k) > 0.01:
		x.basis = x.basis.orthonormalized().scaled(Vector3.ONE * k)
	xf = x
	inv = xf.affine_inverse()
	transform = xf


func mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var pal: Dictionary = PALETTES.get(who, PALETTES["requin"])
	match key:
		"coque":
			var sm: ShaderMaterial = super.mat("coque")
			sm.set_shader_parameter("tint", pal["tint"])
			sm.set_shader_parameter("band_color", pal["band"])
			sm.set_shader_parameter("hull_inv", Projection(inv))
			return sm
		"voile", "pavillon":
			var s := StandardMaterial3D.new()
			s.albedo_texture = load(PI68 + str(pal[key]) + ".png")
			s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			s.alpha_scissor_threshold = 0.5
			s.cull_mode = BaseMaterial3D.CULL_DISABLED
			s.roughness = 0.92
			_mats[key] = s
			return s
	return super.mat(key)


func build(high_quality: bool) -> void:
	_rng.seed = int((PALETTES.get(who, PALETTES["requin"]) as Dictionary)["graine"])
	body = StaticBody3D.new()
	body.name = "Navire_%s_collision" % who
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_hull()
	_deck()
	_castle()
	_forecastle()
	if masts:
		_masts(high_quality)
	_cannons_and_props()
	print("ILE_MANGA_V68: navire « %s » (échelle %.2f) à %s" % [who, k, str(xf.origin)])


## Le haut du plat-bord (repère monde) au droit de x, sur le flanc « side » (-1 bâbord, +1 tribord).
func rail_at(x: float, side: float) -> Vector3:
	var y: float = bul_y(x)
	return W(Vector3(x, y, side * (hb(x, y) - THICK * 0.5)))
