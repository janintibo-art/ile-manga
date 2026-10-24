extends "res://scripts/navire_v68.gd"
## V70 : les navires de la Rade de Cendre (le port de Pandémonia), sur le modèle de ceux de
## Port-Coutelas : la même coque, la même mâture, mais aux couleurs des démons :
##  - « La Braise Joyeuse » (le navire du capitaine Charbonnel) : coque noire, bande rouge,
##    voiles rouges, la bannière de Pandémonia au mât ;
##  - « Le Fumeron » (un caboteur) : coque brun sombre, bande d'or, voiles grises.

const BRAISE_PAL := {
	"braise": {"tint": Color(0.2, 0.18, 0.18), "band": Color(0.55, 0.08, 0.05), "voile": "res://assets/textures/pirates/voile_rouge.png", "graine": 7061},
	"fumeron": {"tint": Color(0.36, 0.27, 0.22), "band": Color(0.7, 0.52, 0.16), "voile": "res://assets/textures/pirates/voile_grise.png", "graine": 7062},
}


func mat(key: String) -> Material:
	if _mats.has(key) or not BRAISE_PAL.has(who):
		return super.mat(key)
	var pal: Dictionary = BRAISE_PAL[who]
	match key:
		"coque":
			var sm: ShaderMaterial = super.mat("coque")
			sm.set_shader_parameter("tint", pal["tint"])
			sm.set_shader_parameter("band_color", pal["band"])
			sm.set_shader_parameter("hull_inv", Projection(inv))
			return sm
		"voile", "pavillon":
			var s := StandardMaterial3D.new()
			var p: String = str(pal["voile"]) if key == "voile" else "res://assets/textures/braise/banniere_pandemonia.png"
			if ResourceLoader.exists(p):
				s.albedo_texture = load(p)
			s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			s.alpha_scissor_threshold = 0.5
			s.cull_mode = BaseMaterial3D.CULL_DISABLED
			s.roughness = 0.92
			_mats[key] = s
			return s
	return super.mat(key)
